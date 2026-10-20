#!/usr/bin/env python3
"""Verify opt-in measurement fixture through actual QEMU MMIO and virtual time."""
import argparse
import json
import os
from pathlib import Path
import select
import socket
import struct
import subprocess
import tempfile
import time


def exercise(binary: Path, enabled: bool, scratch: Path, vsync=False, rgb16=None,
             framebuffer=False):
    env = dict(os.environ)
    env.pop("PHILIPS_AMBILIGHT_LOG", None)
    env.pop("PHILIPS_AMBILIGHT_FIXTURE", None)
    env.pop("PHILIPS_VIDEO_VSYNC_FIXTURE", None)
    env.pop("PHILIPS_AMBILIGHT_FIXTURE_RGB16", None)
    env.pop("PHILIPS_AMBILIGHT_FRAMEBUFFER", None)
    env.pop("PHILIPS_OSD_SCANOUT", None)
    if enabled:
        env["PHILIPS_AMBILIGHT_FIXTURE"] = "1"
    if vsync:
        env["PHILIPS_VIDEO_VSYNC_FIXTURE"] = "1"
    if rgb16 is not None:
        env["PHILIPS_AMBILIGHT_FIXTURE_RGB16"] = rgb16
    if framebuffer:
        env["PHILIPS_AMBILIGHT_FRAMEBUFFER"] = "1"
        env["PHILIPS_OSD_SCANOUT"] = "1"
    # This QEMU build omits the qtest accelerator, so advance virtual time by
    # executing one synthetic ARM branch instruction under TCG, controlled by QMP.
    loop = scratch / "arm-loop.bin"
    loop.write_bytes(struct.pack("<I", 0xeafffffe))
    monitor = scratch / f"q{int(enabled)}{int(vsync)}{int(rgb16 is not None)}{int(framebuffer)}"
    command = [str(binary.resolve()), "-machine", "virt,gic-version=2,highmem=off",
               "-cpu", "cortex-a53,aarch64=off", "-smp", "1", "-m", "880M",
               "-accel", "tcg", "-S", "-nodefaults", "-display", "none",
               "-monitor", "none", "-serial", "none", "-nic", "none",
               "-device", f"loader,file={loop},addr=0x40000000,cpu-num=0",
               "-qmp", f"unix:{monitor},server=on,wait=off",
               "-qtest", "stdio", "-qtest-log", "/dev/null"]
    with (scratch / f"stderr-{enabled}.log").open("wb") as stderr:
        process = subprocess.Popen(command, env=env, stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE, stderr=stderr)

        def qtest(command):
            process.stdin.write((command + "\n").encode())
            process.stdin.flush()
            if not select.select([process.stdout], [], [], 5)[0]:
                raise TimeoutError(f"QEMU did not answer {command}")
            line = process.stdout.readline().decode().strip()
            if not line.startswith("OK"):
                raise RuntimeError(f"{command}: {line}")
            return line[2:].strip()

        def read(command):
            return int(qtest(command), 0)

        channel = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        channel.settimeout(5)
        for _ in range(100):
            try:
                channel.connect(str(monitor))
                break
            except FileNotFoundError:
                time.sleep(0.01)
        messages = channel.makefile("rwb", buffering=0)
        if process.poll() is not None:
            raise RuntimeError((scratch / f"stderr-{enabled}.log").read_text())
        qtest("readb 0xf0034224")
        json.loads(messages.readline())

        def qmp(name):
            messages.write(json.dumps({"execute": name}).encode() + b"\n")
            while True:
                response = json.loads(messages.readline())
                if "error" in response:
                    raise RuntimeError(response)
                if "return" in response:
                    return response

        qmp("qmp_capabilities")

        def advance():
            qmp("cont")
            time.sleep(0.06)
            qmp("stop")

        try:
            if framebuffer:
                header_address, bitmap_address = 0x01001000, 0x01002000
                header = bytearray(48)
                header[3] = 14 << 4
                struct.pack_into("<I", header, 4, bitmap_address >> 4)
                struct.pack_into("<H", header, 8, 128 >> 4)
                header[11] = 0x24
                struct.pack_into("<HH", header, 36, 32, 20)
                bitmap = bytes(v for y in range(20) for x in range(32)
                               for v in (7, y * 12, x * 8, 255))
                qtest(f"write {header_address:#x} {len(header):#x} 0x{header.hex()}")
                qtest(f"write {bitmap_address:#x} {len(bitmap):#x} 0x{bitmap.hex()}")
                qtest(f"writel 0xf0021304 {header_address >> 4:#x}")
                qtest("writel 0xf0021300 1")
            baseline = read("readb 0xf0034224")
            advance()
            if not enabled:
                assert read("readb 0xf0034224") == baseline
                return {"fixture_enabled": False, "timer_did_not_change_status": True}
            if framebuffer:
                assert read("readw 0xf0027b08") & 31 == 0
                for col in range(32):
                    assert read("readw 0xf0027b0a") == col * 8 << 8
                    assert read("readl 0xf0027b0c") == 7 << 24
                # Change guest bitmap now; existing measurement frame must
                # retain its row 0 snapshot until the next frame boundary.
                green = bytes((0, 255, 0, 255)) * 640
                qtest(f"write {bitmap_address:#x} {len(green):#x} 0x{green.hex()}")
                for row in range(1, 20):
                    qtest("writeb 0xf003422e 0x80")
                    advance()
                    assert read("readw 0xf0027b08") & 31 == row
                    assert read("readw 0xf0027b0a") == 0
                    assert read("readl 0xf0027b0c") == (7 << 24 | row * 12 << 8)
                qtest("writeb 0xf003422e 0x80")
                advance()
                assert read("readw 0xf0027b08") & 31 == 0
                assert read("readw 0xf0027b0a") == 0
                assert read("readl 0xf0027b0c") == 0xff00
                return {"framebuffer_enabled": True,
                        "checks": ["actual guest RAM descriptor and bitmap",
                                   "OSD byte selectors and RGB8 << 8 conversion",
                                   "frame snapshot stable across 20 rows",
                                   "new bitmap takes effect at next row 0"],
                        "stock_algorithm_executed": False}
            if vsync:
                assert read("readb 0xf0034224") & 0xc0 == 0xc0
                # This board maps GIC distributor at f2011000. SPI 95 is INTID
                # 127, bit 31 in ISPENDR3. Default configuration is level IRQ.
                def pending():
                    return bool(read("readl 0xf201120c") & 0x80000000)
                assert pending()
                qtest("writeb 0xf003422e 0x40")
                assert read("readb 0xf0034224") & 0xc0 == 0x80
                assert pending()  # Row remains asserted after VSync ACK.
                advance()
                assert read("readb 0xf0027b08") & 31 == 0
                assert read("readb 0xf0034224") & 0xc0 == 0xc0
                qtest("writeb 0xf003422e 0x80")
                assert read("readb 0xf0034224") & 0xc0 == 0x40
                assert pending()  # VSync remains asserted after row ACK.
                qtest("writeb 0xf003422e 0x40")
                assert read("readb 0xf0034224") & 0xc0 == 0
                assert not pending()
                return {"fixture_enabled": True, "vsync_fixture_enabled": True,
                        "checks": ["independent VSync despite pending row",
                                   "independent bit 6 and bit 7 acknowledgement",
                                   "shared GIC SPI 95 OR assertion/deassertion"]}
            assert read("readb 0xf0034224") == (baseline | 0x80)
            assert read("readb 0xf0027b08") & 31 == 0
            constant = [int(x, 0) for x in rgb16.split(",")] if rgb16 else None
            for col in range(32):
                red, green, blue = constant or [0x1000 + col, 0x2000 + col, 0x3000 + col]
                assert read("readw 0xf0027b0a") == red
                assert (read("readw 0xf0027b08") >> 5) & 31 == col
                assert read("readl 0xf0027b0c") == (blue << 16 | green)
            advance()
            assert read("readb 0xf0027b08") & 31 == 0  # pending row is retained
            qtest("writeb 0xf003422e 0x40")  # unrelated VSync ACK is not row ACK
            assert read("readb 0xf0034224") & 0x80
            qtest("writeb 0xf003422e 0x80")
            assert read("readb 0xf0034224") & 0x80 == 0
            qtest("writeb 0xf003422e 0")
            advance()
            assert read("readb 0xf0027b08") & 31 == 1
            assert read("readw 0xf0027b0a") == (constant[0] if constant else 0x1020)
            # The registered ISR can access the status/ACK in a containing word.
            assert read("readl 0xf0034224") & 0x80
            qtest("writel 0xf003422c 0x00800000")
            assert read("readb 0xf0034224") & 0x80 == 0
            return {"fixture_enabled": True, "rows_checked": 2, "columns_checked": 32,
                    "constant_rgb16": constant,
                    "checks": ["virtual timer under running TCG", "raw three-plane FIFO",
                               "pending-row backpressure", "bit7 ACK only",
                               "overlapping word ACK", "row advancement"]}
        finally:
            messages.close()
            channel.close()
            process.terminate()
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("qemu", type=Path)
    parser.add_argument("--output-directory", type=Path, required=True)
    parser.add_argument("--include-rgb16", action="store_true",
                        help="Also test explicit constant RGB16 fixture support")
    parser.add_argument("--include-framebuffer", action="store_true",
                        help="Also test approximate framebuffer measurement support")
    args = parser.parse_args()
    args.output_directory.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=args.output_directory) as directory:
        results = [exercise(args.qemu, enabled, Path(directory)) for enabled in (False, True)]
        results.append(exercise(args.qemu, True, Path(directory), vsync=True))
        if args.include_rgb16:
            results.append(exercise(args.qemu, True, Path(directory), rgb16="65280,0x8000,255"))
            results.append(exercise(args.qemu, False, Path(directory), rgb16="65280,0,0"))
        if args.include_framebuffer:
            results.append(exercise(args.qemu, True, Path(directory), framebuffer=True))
    report = {"result": "passed", "origin": "synthetic-qtest-measurement",
              "android_booted": False, "stock_ambilight_algorithm_executed": False,
              "irq_delivery_to_guest_handler_verified": False,
              "qemu": str(args.qemu.resolve()), "results": results}
    destination = args.output_directory / "qtest-measure-smoke.json"
    destination.write_text(json.dumps(report, indent=2) + "\n")
    print(destination)
