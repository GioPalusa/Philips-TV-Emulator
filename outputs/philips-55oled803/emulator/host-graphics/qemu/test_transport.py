#!/usr/bin/env python3
"""Actual QEMU MMIO/socket tests. This does not execute Android or Mali code."""
import argparse
import json
import os
from pathlib import Path
import select
import socket
import struct
import subprocess
import tempfile

PAYLOAD, CTRL = 0xA1000000, 0xA1100000


def run(binary, output):
    with tempfile.TemporaryDirectory(prefix="phgpu-", dir="/tmp") as directory:
        root = Path(directory)
        listener = socket.socket(socket.AF_UNIX)
        listener.bind(str(root / "gpu"))
        listener.listen(64)
        listener.settimeout(2)
        env = dict(os.environ, PHILIPS_HOSTGPU_SOCKET=str(root / "gpu"))
        command = [str(binary.resolve()), "-machine", "virt,gic-version=2,highmem=off",
                   "-cpu", "cortex-a53,aarch64=off", "-m", "880M",
                   "-accel", "tcg", "-S", "-nodefaults", "-display", "none",
                   "-monitor", "none", "-serial", "none", "-nic", "none",
                   "-qtest", "stdio", "-qtest-log", "/dev/null"]
        with (root / "stderr").open("wb") as log:
            process = subprocess.Popen(command, stdin=subprocess.PIPE,
                                       stdout=subprocess.PIPE, stderr=log, env=env)
            peers = []
            def qtest(command):
                process.stdin.write((command + "\n").encode())
                process.stdin.flush()
                if not select.select([process.stdout], [], [], 3)[0]:
                    raise TimeoutError(command[:100])
                line = process.stdout.readline().decode().strip()
                assert line.startswith("OK"), line
                return line[2:].strip()
            def read(reg):
                return int(qtest(f"readl {CTRL+reg:#x}"), 0)
            def signed(value):
                return struct.unpack("<i", struct.pack("<I", value))[0]
            def write(reg, value):
                qtest(f"writel {CTRL+reg:#x} {value:#x}")
            def payload(data):
                qtest(f"write {PAYLOAD:#x} {len(data)} 0x{data.hex()}")
            def transaction(command, connection=0, data=None, length=0):
                if data is not None:
                    payload(data)
                    length = len(data)
                write(8, connection)
                write(12, length)
                write(0, command)
                return signed(read(4)), signed(read(16))
            try:
                assert read(20) == 0x50484750
                assert read(24) == 1024 * 1024
                assert transaction(1, data=b"invalid\0")[0] == -22
                assert transaction(2, connection=1, data=b"x")[0] == -9
                ids = []
                for index in range(64):
                    status, ident = transaction(1, data=b"pipe:opengles\0")
                    assert status == 0 and ident > 0
                    peer, _ = listener.accept()
                    peer.settimeout(2)
                    assert peer.recv(len(b"pipe:opengles\0")) == b"pipe:opengles\0"
                    peers.append(peer)
                    ids.append(ident)
                assert len(set(ids)) == 64
                assert transaction(1, data=b"pipe:opengles\0")[0] == -24
                # Empty receive must immediately return Linux EAGAIN, even on macOS.
                assert transaction(3, ids[0], length=4096) == (-11, 0)
                packet = bytes(range(256)) * 16
                assert transaction(2, ids[0], data=packet) == (0, len(packet))
                received = b""
                while len(received) < len(packet):
                    received += peers[0].recv(len(packet) - len(received))
                assert received == packet
                peers[0].sendall(packet[::-1])
                assert transaction(3, ids[0], length=len(packet)) == (0, len(packet))
                raw = qtest(f"read {PAYLOAD:#x} {len(packet)}")
                assert bytes.fromhex(raw.removeprefix("0x")) == packet[::-1]
                assert transaction(2, ids[0], length=1024*1024+1)[0] == -22
                assert transaction(99, ids[0])[0] == -22
                peers[0].close()
                assert transaction(3, ids[0], length=1) == (0, 0)
                for ident in ids:
                    assert transaction(4, ident) == (0, 0)
                assert transaction(4, ids[0])[0] == -9
                assert transaction(1, data=b"pipe:GLProcessPipe\0") == (0, 1)
                peer, _ = listener.accept()
                peers.append(peer)
                assert peer.recv(len(b"pipe:GLProcessPipe\0")) == b"pipe:GLProcessPipe\0"
                output.write_text(json.dumps({
                    "result": "PASS", "origin": "QEMU qtest with synthetic host socket",
                    "guest_android_executed": False, "host_gpu_rendered": False,
                    "checks": ["magic", "capacity", "handshake allowlist",
                               "64 independent connections", "connection exhaustion",
                               "nonblocking Linux EAGAIN", "bidirectional exact bytes",
                               "oversize rejected", "unknown command rejected",
                               "EOF", "close", "slot reuse", "process pipe"]
                }, indent=2) + "\n")
                print(output)
            finally:
                for peer in peers:
                    peer.close()
                listener.close()
                process.terminate()
                try:
                    process.wait(3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    run(args.binary, args.output)
