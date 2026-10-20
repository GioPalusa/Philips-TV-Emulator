#!/usr/bin/env python3
"""Loopback-only control panel for the local Philips development emulator."""
import argparse
import atexit
from collections import deque
import importlib.util
import json
import os
from pathlib import Path
import re
import secrets
import signal
import socket
import subprocess
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

HERE = Path(__file__).resolve().parent
EMU = HERE.parent
ROOT = HERE.parents[3]
KEYS = {"up": 19, "down": 20, "left": 21, "right": 22, "ok": 23,
        "back": 4, "home": 3, "volume_up": 24, "volume_down": 25, "mute": 164}
COLORS = {"red": "65535,0,0", "green": "0,65535,0", "blue": "0,0,65535"}


class AttachedProcess:
    """Reattach only to a verified QEMU process from this viewer's saved run."""
    def __init__(self, pid, command):
        self.pid, self.returncode = pid, None
        self.identity = [command[0], command[command.index("-qmp") + 1],
                         command[command.index("-chardev") + 1]]
        if self.poll() is not None:
            raise ValueError("Saved run does not match the live emulator process")

    def poll(self):
        result = subprocess.run(["ps", "-p", str(self.pid), "-o", "command="],
                                capture_output=True, text=True)
        if result.returncode or not all(value in result.stdout for value in self.identity):
            self.returncode = 0
        return self.returncode

    def wait(self, timeout):
        deadline = time.monotonic() + timeout
        while self.poll() is None:
            if time.monotonic() >= deadline:
                raise subprocess.TimeoutExpired("attached emulator", timeout)
            time.sleep(.1)
        return self.returncode
spec = importlib.util.spec_from_file_location("spi_decoder",
                                             EMU / "ambilight/decode_spi.py")
decoder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(decoder)
input_spec = importlib.util.spec_from_file_location("input_bridge_controller",
                                                   EMU / "input/bridge_controller.py")
input_module = importlib.util.module_from_spec(input_spec)
input_spec.loader.exec_module(input_module)


def tail(path, count=18000):
    if not path:
        return ""
    try:
        with path.open("rb") as stream:
            stream.seek(max(0, path.stat().st_size - count))
            return stream.read(count).decode("utf-8", errors="replace")
    except OSError:
        return ""


class Emulator:
    def __init__(self, args):
        self.args = args
        self.lock = threading.RLock()
        self.send_lock = threading.Lock()
        self.qmp_lock = threading.Lock()
        self.process = None
        self.console = None
        self.qmp = None
        self.temp = None
        self.run_dir = None
        self.frame = None
        self.frame_time = None
        self.frame_bytes = None
        self.capture_ms = None
        self.started = None
        self.fixture = "framebuffer"
        self.error = ""
        self.commands = deque(maxlen=12)
        self.boot = "unknown"
        self.input_ready = False
        self.scanout_observed = False
        self.scanout_log_offset = 0
        self.scanout_log_tail = b""
        self.last_boot_check = 0
        self.diagnostics_started = False
        self.input_bridge = input_module.InputBridgeController(self)

    def attach(self, run_dir, pid):
        run_dir = run_dir.resolve(strict=True)
        if run_dir.parent != (HERE / "runs").resolve():
            raise ValueError("Only this viewer's saved runs can be reattached")
        launch = json.loads((run_dir / "launch.json").read_text())
        command = launch["command"]
        qmp_path = Path(command[command.index("-qmp") + 1].split(",")[0][5:])
        console_arg = command[command.index("-chardev") + 1]
        console_path = Path(next(v[5:] for v in console_arg.split(",") if v.startswith("path=")))
        if qmp_path.parent != console_path.parent or not str(qmp_path.parent).startswith("/tmp/philips-ui-"):
            raise ValueError("Unexpected saved control socket paths")
        self.process = AttachedProcess(pid, command)
        self.run_dir, self.fixture = run_dir, launch["measurement_fixture"]
        self.started = time.monotonic()
        # The previous viewer's guest logcat continues on the serial device.
        self.diagnostics_started = True
        threading.Thread(target=self.monitor, args=(self.process, qmp_path, console_path),
                         daemon=True).start()

    def start(self, fixture):
        if not isinstance(fixture, str) or fixture not in (*COLORS, "framebuffer"):
            raise ValueError("Unknown measurement fixture")
        with self.lock:
            if self.process and self.process.poll() is None:
                raise ValueError("Emulator is already running; stop before changing fixture")
            inputs = [self.args.binary, self.args.disk, self.args.ramdisk,
                      EMU / "kernel-without-dtb.bin", EMU / "mt5891-sanitized.dtb"]
            missing = [str(p) for p in inputs if not p.is_file()]
            if missing:
                raise ValueError("Missing emulator input: " + ", ".join(missing))
            self.run_dir = HERE / "runs" / (time.strftime("%Y%m%d-%H%M%S") +
                                           "-" + secrets.token_hex(3))
            self.run_dir.mkdir(parents=True)
            self.temp = tempfile.TemporaryDirectory(prefix="philips-ui-", dir="/tmp")
            self.fixture = fixture
            self.frame = self.frame_time = None
            self.frame_bytes = None
            self.capture_ms = None
            self.boot, self.error = "unknown", ""
            self.input_ready = False
            self.input_bridge.reset()
            self.scanout_observed = False
            self.scanout_log_offset = 0
            self.scanout_log_tail = b""
            self.commands.clear()
            self.diagnostics_started = False
            self.last_boot_check = 0
            qmp_path = Path(self.temp.name) / "qmp"
            console_path = Path(self.temp.name) / "console"
            command = [
                str(self.args.binary), "-accel", "tcg", "-machine",
                "virt,gic-version=2,highmem=off,virtualization=on", "-cpu",
                "cortex-a53,aarch64=off,cntfrq=24000000", "-smp", "4", "-m", "880M",
                "-nodefaults", "-nic", "none", "-display", "none",
                "-serial", "none", "-monitor", "none", "-no-reboot",
                "-kernel", str(inputs[3]), "-initrd", str(self.args.ramdisk),
                "-dtb", str(inputs[4]), "-append",
                "console=ttyMT0,115200n1 earlyprintk=serial,ttyMT0 "
                "androidboot.hardware=mt5891 device_name=55OLED803/12 vmalloc=650mb "
                + (EMU / "partition-bootargs.txt").read_text().strip(),
                "-drive", "if=none,format=raw,snapshot=on,file=" +
                str(self.args.disk).replace(",", ",,") + ",id=tv-emmc",
                "-global", "mt5891-msdc.allow-writes=on",
                "-global", "emmc.reliable-write-sector-count=0",
                "-qmp", f"unix:{qmp_path},server=on,wait=off",
                "-chardev", f"socket,id=tv-console,path={console_path},server=on,wait=off",
            ]
            env = dict(os.environ)
            for name in ("PHILIPS_AMBILIGHT_FIXTURE", "PHILIPS_VIDEO_VSYNC_FIXTURE",
                         "PHILIPS_AMBILIGHT_FIXTURE_RGB16", "PHILIPS_AMBILIGHT_FRAMEBUFFER"):
                env.pop(name, None)
            env.update(PHILIPS_OSD_SCANOUT="1", PHILIPS_VIDEO_VSYNC_FIXTURE="1",
                       PHILIPS_AMBILIGHT_LOG=str(self.run_dir / "ambilight.jsonl"))
            if fixture == "framebuffer":
                env["PHILIPS_AMBILIGHT_FRAMEBUFFER"] = "1"
            else:
                env["PHILIPS_AMBILIGHT_FIXTURE"] = "1"
                env["PHILIPS_AMBILIGHT_FIXTURE_RGB16"] = COLORS[fixture]
            (self.run_dir / "launch.json").write_text(json.dumps({
                "command": command, "measurement_fixture": fixture,
                "disk_writes": "temporary QEMU snapshot overlay"}, indent=2))
            with (self.run_dir / "qemu.log").open("wb") as log:
                self.process = subprocess.Popen(command, stdout=log, stderr=log,
                                                env=env, start_new_session=True)
            self.started = time.monotonic()
            proc = self.process
            threading.Thread(target=self.monitor, args=(proc, qmp_path, console_path),
                             daemon=True).start()

    def connect(self, path, proc):
        for _ in range(200):
            if proc.poll() is not None:
                raise RuntimeError(f"QEMU exited with status {proc.returncode}")
            stream = socket.socket(socket.AF_UNIX)
            stream.settimeout(5)
            try:
                stream.connect(str(path))
                return stream
            except (FileNotFoundError, ConnectionRefusedError):
                stream.close()
                time.sleep(.05)
        raise TimeoutError("QEMU control socket did not become ready")

    def qmp_call(self, name, arguments=None):
        with self.qmp_lock:
            if not self.qmp:
                raise RuntimeError("QMP is not connected")
            self.qmp.write((json.dumps({"execute": name,
                                       "arguments": arguments or {}}) + "\n").encode())
            while True:
                line = self.qmp.readline()
                if not line:
                    raise RuntimeError("QMP connection closed")
                answer = json.loads(line)
                if "error" in answer:
                    raise RuntimeError(answer["error"].get("desc", str(answer)))
                if "return" in answer:
                    return answer["return"]

    def monitor(self, proc, qmp_path, console_path):
        qsocket = None
        try:
            qsocket = self.connect(qmp_path, proc)
            qstream = qsocket.makefile("rwb", buffering=0)
            assert "QMP" in json.loads(qstream.readline())
            with self.lock:
                self.qmp = qstream
            self.qmp_call("qmp_capabilities")
            console = self.connect(console_path, proc)
            console.settimeout(.5)
            with self.lock:
                self.console = console
            threading.Thread(target=self.receive_console, args=(proc, console),
                             daemon=True).start()
            while proc.poll() is None and self.process is proc:
                capture_started = time.monotonic()
                try:
                    if not self.scanout_observed:
                        with (self.run_dir / "qemu.log").open("rb") as stream:
                            stream.seek(self.scanout_log_offset)
                            chunk = stream.read(1024 * 1024)
                            self.scanout_log_offset += len(chunk)
                        observed = self.scanout_log_tail + chunk
                        self.scanout_observed = b"[mt5891 osd] raw plane2" in observed
                        self.scanout_log_tail = observed[-64:]
                    # Raw PPM avoids PNG compression inside QEMU's global lock.
                    # The browser converts these actual RGB pixels to a canvas.
                    temporary = self.run_dir / "frame-next.ppm"
                    self.qmp_call("screendump", {"filename": str(temporary), "format": "ppm"})
                    captured = temporary.read_bytes()
                    temporary.replace(self.run_dir / "frame.ppm")
                    with self.lock:
                        self.frame = self.run_dir / "frame.ppm"
                        self.frame_bytes = captured
                        self.frame_time = time.time()
                        self.capture_ms = round((time.monotonic() - capture_started) * 1000, 2)
                    if self.diagnostics_started and time.monotonic() - self.last_boot_check > 30:
                        self.check_boot()
                        self.last_boot_check = time.monotonic()
                    elif not self.diagnostics_started and not self.last_boot_check and time.monotonic() - self.started > 20:
                        # The first shell prompt may have preceded connection;
                        # this fixed query solicits its current prompt.
                        self.check_boot()
                        self.last_boot_check = time.monotonic()
                except Exception as exc:
                    with self.lock:
                        self.error = "Frame capture: " + str(exc)
                # Bound host work to 20 captures/s; never queue old frames.
                time.sleep(max(.005, .05 - (time.monotonic() - capture_started)))
        except Exception as exc:
            with self.lock:
                self.error = str(exc)
        finally:
            with self.lock:
                if self.process is proc:
                    self.qmp = None
                    if self.console:
                        self.console.close()
                    self.console = None
            if qsocket:
                qsocket.close()

    def receive_console(self, proc, console):
        pending = ""
        with (self.run_dir / "console.log").open("ab") as log:
            while proc.poll() is None and self.process is proc:
                try:
                    data = console.recv(65536)
                    if not data:
                        break
                except socket.timeout:
                    continue
                except OSError:
                    break
                log.write(data)
                log.flush()
                pending += data.decode("utf-8", errors="replace")
                if not self.diagnostics_started and re.search(r":/ [#$]", pending):
                    self.diagnostics_started = True
                    def diagnostics():
                        try:
                            self.send("logcat -v threadtime -b crash -b main -b system '*:W' MTKAPI:S TV_HAL:S MTK_KL:S SwiftShader:I SystemServer:I ActivityManager:I &\n")
                            self.check_boot()
                            self.last_boot_check = time.monotonic()
                        except (OSError, ValueError):
                            pass
                    threading.Thread(target=diagnostics, daemon=True).start()
                lines = pending.split("\n")
                pending = lines.pop()[-4096:]
                for line in lines:
                    self.input_bridge.receive(line)
                    boot = re.fullmatch(r"\s*TVUI_BOOT:(.*?)\s*", line)
                    if boot:
                        with self.lock:
                            self.boot = "complete" if boot[1] == "1" else "not_complete"
                    ready = re.fullmatch(r"\s*TVUI_INPUT:(.*?)\s*", line)
                    if ready:
                        with self.lock:
                            self.input_ready = ready[1].strip() == "Service input: found"
                            if self.input_ready and self.input_bridge.state()["status"] == "idle":
                                self.input_bridge.start()

    def send(self, text, on_send=None):
        with self.send_lock:
            with self.lock:
                console = self.console
            if not console:
                raise ValueError("Serial console is not connected")
            if on_send:
                on_send()
            data = text.encode()
            for pos in range(0, len(data), 12):
                console.sendall(data[pos:pos+12])
                time.sleep(.02)

    def key(self, key):
        if not isinstance(key, str) or key not in KEYS:
            raise ValueError("Unknown remote button")
        with self.lock:
            if not self.console:
                raise ValueError("Serial console is not connected")
            if not self.input_ready:
                raise ValueError("Android input service is not ready")
            return self.input_bridge.enqueue(key, KEYS[key])

    def check_boot(self):
        self.send("printf '\\nTVUI_BOOT:%s\\nTVUI_INPUT:%s\\n' "
                  "\"$(getprop sys.boot_completed)\" \"$(service check input)\"\n")

    def report(self, name):
        commands = {
            "services": "getprop init.svc.dtv-svc; getprop init.svc.bootanim; service list",
            "activity": "dumpsys activity activities",
            "processes": "ps -A",
            "identity": "id; id -Z",
            "graphics": "dumpsys SurfaceFlinger",
            "settings": "am start -a android.settings.SETTINGS",
            "launcher": "am start -n com.google.android.tvlauncher/.HomeScreen",
            "boot-files": "ls -ld /user_setting /user_setting/rw /tmp/mtk_rm_end /tmp/dtv_svc_is_ready; getprop service.bootanim.exit; getprop init.svc.bootanim",
            "storage": "ls -lZ /user_setting/rw",
            "dtv-threads": "for p in $(pidof dtv_svc); do echo PID:$p; ps -T -p $p; done",
            "quiet-log": "pkill -x logcat 2>/dev/null; logcat -v threadtime -b crash -b main -b system '*:W' MTKAPI:S TV_HAL:S MTK_KL:S SwiftShader:I SystemServer:I ActivityManager:I &",
        }
        if not isinstance(name, str) or name not in commands:
            raise ValueError("Unknown diagnostic")
        # Some stock utilities touch terminal settings even for a read-only
        # report. Prevent job-control SIGTTOU from stopping the background job.
        self.send(f"( trap '' TTOU; echo TVUI_REPORT_{name}_BEGIN; {commands[name]}; "
                  f"echo TVUI_REPORT_{name}_END ) &\n")

    def stop(self):
        with self.lock:
            proc = self.process
            self.input_bridge.reset()
        if proc and proc.poll() is None:
            # Only our still-live child, started in its own process group.
            os.killpg(proc.pid, signal.SIGTERM)
            try:
                proc.wait(timeout=4)
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid, signal.SIGKILL)
                proc.wait(timeout=4)
        if self.temp:
            self.temp.cleanup()
            self.temp = None

    def state(self):
        with self.lock:
            proc, run_dir = self.process, self.run_dir
            running = bool(proc and proc.poll() is None)
            qlog = tail(run_dir / "qemu.log") if run_dir else ""
            clog = tail(run_dir / "console.log") if run_dir else ""
            pixels, sequence, spi_error = [], None, ""
            if run_dir:
                for line in reversed(tail(run_dir / "ambilight.jsonl", 65536).splitlines()):
                    try:
                        record = json.loads(line)
                        decoded = list(decoder.decode_record(record))
                        pixels = [p["rgb_application"] for p in decoded]
                        sequence = record["sequence"]
                        break
                    except (ValueError, KeyError, TypeError) as exc:
                        spi_error = str(exc)
            return {
                "running": running, "pid": proc.pid if running else None,
                "exit_code": proc.returncode if proc else None,
                "uptime": round(time.monotonic() - self.started) if running else None,
                "console_connected": bool(self.console and running),
                "input_ready": bool(self.input_ready and self.console and running),
                "input_bridge": self.input_bridge.state(),
                "qmp_connected": bool(self.qmp and running), "boot": self.boot,
                "fixture": self.fixture, "frame": bool(self.frame),
                "frame_time": self.frame_time,
                "capture_ms": self.capture_ms,
                "scanout_observed": self.scanout_observed,
                "pixels": pixels, "spi_sequence": sequence, "spi_error": spi_error,
                "commands": list(self.commands), "error": self.error,
                "console_log": clog, "qemu_log": qlog,
                "run_directory": str(run_dir) if run_dir else None,
            }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        if args and str(args[0]).startswith("POST"):
            super().log_message(fmt, *args)

    def reply(self, code, body, content_type="application/json"):
        if not isinstance(body, bytes):
            body = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Security-Policy",
                         "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; "
                         "img-src 'self'; connect-src 'self'; frame-ancestors 'none'")
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def host_valid(self):
        return self.headers.get("Host") == self.server.authority

    def do_GET(self):
        if not self.host_valid():
            return self.reply(403, {"error": "Invalid Host"})
        path = urlsplit(self.path).path
        if path == "/api/state":
            return self.reply(200, self.server.emulator.state())
        if path == "/api/session":
            return self.reply(200, {"token": self.server.token})
        if path == "/frame.png":
            emulator = self.server.emulator
            if emulator.frame and emulator.qmp:
                try:
                    frame = emulator.run_dir / "snapshot.png"
                    emulator.qmp_call("screendump", {"filename": str(frame), "format": "png"})
                    return self.reply(200, frame.read_bytes(), "image/png")
                except (OSError, RuntimeError) as exc:
                    return self.reply(503, {"error": str(exc)})
            return self.reply(404, {"error": "No QEMU frame captured yet"})
        if path == "/frame.ppm":
            with self.server.emulator.lock:
                pixels = self.server.emulator.frame_bytes
            if pixels:
                return self.reply(200, pixels, "image/x-portable-pixmap")
            return self.reply(404, {"error": "No QEMU frame captured yet"})
        names = {"/": ("index.html", "text/html; charset=utf-8"),
                 "/app.js": ("app.js", "text/javascript; charset=utf-8"),
                 "/style.css": ("style.css", "text/css; charset=utf-8")}
        if path in names:
            name, kind = names[path]
            return self.reply(200, (HERE / name).read_bytes(), kind)
        return self.reply(404, {"error": "Not found"})

    def do_POST(self):
        if (not self.host_valid() or self.headers.get("Origin") != self.server.origin or
                not secrets.compare_digest(self.headers.get("X-TVUI-Token", ""),
                                           self.server.token)):
            return self.reply(403, {"error": "Origin and session token required"})
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length < 0 or length > 1024:
                raise ValueError("Invalid request length")
            data = json.loads(self.rfile.read(length))
            if not isinstance(data, dict):
                raise ValueError("JSON object required")
            path = urlsplit(self.path).path
            with self.server.operation_lock:
                if path == "/api/start":
                    self.server.emulator.start(data.get("fixture", "framebuffer"))
                elif path == "/api/stop":
                    self.server.emulator.stop()
                elif path == "/api/key":
                    return self.reply(200, self.server.emulator.key(data.get("key")))
                elif path == "/api/input-bridge":
                    self.server.emulator.input_bridge.start()
                elif path == "/api/check-boot":
                    self.server.emulator.check_boot()
                elif path == "/api/report":
                    self.server.emulator.report(data.get("name"))
                else:
                    return self.reply(404, {"error": "Unknown action"})
            self.reply(200, {"ok": True})
        except (ValueError, OSError, RuntimeError) as exc:
            self.reply(400, {"error": str(exc)})


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--attach-run", type=Path)
    ap.add_argument("--attach-pid", type=int)
    ap.add_argument("--binary", type=Path, default=EMU / "qemu-system-aarch64-55oled803")
    ap.add_argument("--disk", type=Path,
                    default=EMU / "development/development-emmc.img")
    ap.add_argument("--ramdisk", type=Path,
                    default=EMU / "development/ramdisk.img")
    args = ap.parse_args()
    for name in ("binary", "disk", "ramdisk"):
        setattr(args, name, getattr(args, name).resolve())
    emulator = Emulator(args)
    if bool(args.attach_run) != bool(args.attach_pid):
        ap.error("--attach-run and --attach-pid must be supplied together")
    if args.attach_run:
        emulator.attach(args.attach_run, args.attach_pid)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    server.authority = f"127.0.0.1:{server.server_port}"
    server.origin = "http://" + server.authority
    server.token = secrets.token_urlsafe(32)
    server.emulator = emulator
    server.operation_lock = threading.Lock()
    atexit.register(emulator.stop)
    print(f"Philips emulator UI: {server.origin}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        emulator.stop()
        server.server_close()


if __name__ == "__main__":
    main()
