"""Persistent shell-input transport for the isolated emulator UI."""
import base64
from collections import deque
import hashlib
import json
from pathlib import Path
import re
import secrets
import threading
import time


class InputBridgeController:
    MAX_PENDING = 4
    ACK_TIMEOUT = 15
    def __init__(self, emulator):
        self.emulator = emulator
        self.lock = threading.RLock()
        self.reset()

    def reset(self):
        with self.lock:
            self.generation = getattr(self, "generation", 0) + 1
            for entry in getattr(self, "pending", {}).values():
                entry["item"].update(status="cancelled", error="Guest session ended")
                entry["done"].set()
            self.status, self.error = "idle", ""
            self.session = secrets.token_hex(6)
            self.queue, self.pending = deque(), {}
            self.stage_values, self.stage_event = {}, threading.Event()
            self.worker_running = False
            self.guest_uid = self.guest_context = None

    def state(self):
        with self.lock:
            return {"status": self.status, "error": self.error,
                    "pending": len(self.pending), "capacity": self.MAX_PENDING,
                    "guest_uid": self.guest_uid, "guest_context": self.guest_context}

    def start(self):
        with self.lock:
            if self.status in ("preparing", "ready"):
                return
            if self.status != "idle":
                raise ValueError("Input bridge needs a fresh guest session after a failure")
            self.status = "preparing"
            generation = self.generation
        threading.Thread(target=self._prepare, args=(generation,), daemon=True).start()

    def _wait_stage(self, name, generation, timeout=30):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            with self.lock:
                if generation != self.generation:
                    raise RuntimeError("Guest session changed")
                if name in self.stage_values:
                    return self.stage_values.pop(name)
                if self.status == "failed":
                    raise RuntimeError(self.error)
                self.stage_event.clear()
            self.stage_event.wait(min(.5, max(0, deadline - time.monotonic())))
        raise TimeoutError("Input bridge " + name.lower() + " response timed out")

    def _prepare(self, generation):
        try:
            emulator = self.emulator
            jar = Path(__file__).with_name("philips-input.jar").read_bytes()
            if not 0 < len(jar) <= 16384:
                raise ValueError("Input bridge JAR exceeds the upload bound")
            digest = hashlib.sha256(jar).hexdigest()
            # Reattach to this run's previous bridge, without starting a second reader.
            manifest = emulator.run_dir / "input-bridge.json"
            if manifest.exists():
                saved = json.loads(manifest.read_text())
                session = saved.get("session", "")
                if not re.fullmatch(r"[0-9a-f]{12}", session) or saved.get("sha256") != digest:
                    raise ValueError("Existing bridge differs; use a fresh guest session")
                if saved.get("launch_state") == "failed_before_start":
                    # The FIFO branch failed before app_process could start.
                    # Keep the evidence and prepare a new private directory.
                    manifest.rename(manifest.with_name("input-bridge-failed-" + session + ".json"))
                else:
                    with self.lock:
                        self.session = session
                    emulator.send("printf 'PING 2147483647\\n' >&9\n")
                    self._wait_stage("PONG", generation)
                    with self.lock:
                        self.guest_uid, self.guest_context = 2000, "u:r:shell:s0"
                        self.status = "ready"
                    return
            prefix = "TVUI_BRIDGE_" + self.session
            emulator.send("printf '\\n" + prefix + "_IDENTITY:%s:%s\\n' "
                          '"$(id -u)" "$(id -Z)"\n')
            identity = self._wait_stage("IDENTITY", generation)
            # Vendor toolbox id prefixes -Z with "context="; toybox does not.
            if identity not in ("2000:u:r:shell:s0", "2000:context=u:r:shell:s0"):
                raise ValueError("Input bridge requires the existing UID 2000 shell domain: " + identity)
            with self.lock:
                self.guest_uid, self.guest_context = 2000, "u:r:shell:s0"
            directory = "/data/local/tmp/philips-input-" + self.session
            # Unique directory avoids replacing another bridge's FIFO or assets.
            emulator.send("( umask 077; mkdir " + directory + "; r=$?; printf '\\n" +
                          prefix + "_DIRECTORY:%d\\n' \"$r\" )\n")
            if self._wait_stage("DIRECTORY", generation) != "0":
                raise RuntimeError("Could not create private input bridge directory")
            asset = "/system/etc/emulator-assets/philips-input.jar"
            emulator.send("printf '\\n" + prefix + "_ASSET:%s\\n' "
                          '"$(if [ -r ' + asset + " ]; then sha256sum " + asset +
                          " | cut -d' ' -f1; else echo missing; fi)\"\n")
            installed_hash = self._wait_stage("ASSET", generation)
            if installed_hash == digest:
                emulator.send("cp " + asset + " " + directory + "/bridge.jar\n")
            else:
                payload = base64.b64encode(jar).decode("ascii")
                for offset in range(0, len(payload), 256):
                    if generation != self.generation:
                        return
                    emulator.send("printf '%s' '" + payload[offset:offset+256] + "' >> " +
                                  directory + "/payload.b64\n")
                emulator.send("base64 -d " + directory + "/payload.b64 > " + directory +
                              "/bridge.jar\n")
            emulator.send("printf '\\n" + prefix + "_HASH:%s\\n' "
                          '"$(sha256sum ' + directory + "/bridge.jar | cut -d' ' -f1)\"\n")
            if self._wait_stage("HASH", generation) != digest:
                raise RuntimeError("Guest input bridge hash does not match; not launching")
            # FD 9 stays open in the existing shell, preventing FIFO EOF between keys.
            # The child reads this descriptor; its output carries a session marker.
            # Record the attempt before sending: an immediate FIFO failure must
            # be able to mark it, and a lost reply must never create two readers.
            manifest.write_text(json.dumps({"session": self.session, "sha256": digest,
                                            "directory": directory}, indent=2))
            emulator.send("if /system/bin/toybox mkfifo " + directory + "/input.fifo && exec 9<>" + directory +
                          "/input.fifo; then ( trap '' TTOU; CLASSPATH=" + directory +
                          "/bridge.jar /system/bin/app_process /system/bin tv.emulator.InputBridge "
                          "<&9 2>&1 | while IFS= read -r l; do printf '\\n" + prefix +
                          ":%s\\n' \"$l\"; done ) & else printf '\\n" + prefix + ":FATAL FIFO\\n'; fi\n")
            self._wait_stage("READY", generation, timeout=60)
            with self.lock:
                if generation == self.generation:
                    self.status = "ready"
        except Exception as exc:
            with self.lock:
                if generation == self.generation:
                    self.status, self.error = "failed", str(exc)

    def receive(self, line):
        line = line.strip()
        with self.lock:
            prefix = "TVUI_BRIDGE_" + self.session
            stage = re.fullmatch(re.escape(prefix) + r"_(IDENTITY|DIRECTORY|ASSET|HASH):(.*)", line)
            if stage:
                self.stage_values[stage[1]] = stage[2]
                self.stage_event.set()
                return
            if not line.startswith(prefix + ":"):
                return
            response = line[len(prefix)+1:]
            if response == "READY PHILIPS_INPUT_V1":
                self.stage_values["READY"] = True
                self.stage_event.set()
                return
            if response == "ACK 2147483647 PONG":
                self.stage_values["PONG"] = True
                self.stage_event.set()
                return
            if response.startswith("FATAL "):
                self.status, self.error = "failed", response
                if response == "FATAL FIFO":
                    manifest = self.emulator.run_dir / "input-bridge.json"
                    if manifest.exists():
                        saved = json.loads(manifest.read_text())
                        if saved.get("session") == self.session:
                            saved["launch_state"] = "failed_before_start"
                            manifest.write_text(json.dumps(saved, indent=2))
                self.stage_event.set()
                return
            match = re.fullmatch(r"(ACK|ERR) ([0-9]+) ([A-Z_]+)(?: ([0-9]+))?", response)
            if not match:
                return
            entry = self.pending.get(match[2])
            if not entry:
                return
            item = entry["item"]
            if item["status"] not in ("pending", "timeout"):
                return
            accepted = match[1] == "ACK" and match[3] == "KEY" and match[4] is not None
            late = item["status"] == "timeout"
            item.update(status=("accepted_late" if late else "accepted") if accepted else "failed",
                        host_ms=round((time.monotonic() - entry["sent_at"]) * 1000, 1),
                        guest_ms=int(match[4]) if match[4] is not None else None)
            if not accepted:
                item["error"] = match[3]
            entry["done"].set()
            if late:
                self.pending.pop(match[2], None)
                self.status, self.error = "ready", ""

    def enqueue(self, key, code):
        with self.lock:
            if self.status != "ready":
                raise ValueError("Persistent input bridge is " + self.status)
            if len(self.pending) >= self.MAX_PENDING:
                raise ValueError("Remote queue is full; wait for a guest acknowledgement")
            ident = str(secrets.randbelow(2147483646) + 1)
            while ident in self.pending:
                ident = str(secrets.randbelow(2147483646) + 1)
            item = {"id": ident, "key": key, "status": "queued", "time": time.time()}
            entry = {"item": item, "code": code, "done": threading.Event()}
            self.pending[ident] = entry
            self.queue.append(entry)
            # Parent state already holds emulator.lock; queue locks are always
            # acquired under that lock by callers, never in the reverse order.
            self.emulator.commands.append(item)
            if not self.worker_running:
                self.worker_running = True
                threading.Thread(target=self._dispatch, args=(self.generation,), daemon=True).start()
            return dict(item)

    def _dispatch(self, generation):
        while True:
            with self.lock:
                if generation != self.generation:
                    return
                if not self.queue or self.status != "ready":
                    self.worker_running = False
                    return
                entry = self.queue.popleft()
                item = entry["item"]
            try:
                def sent():
                    with self.lock:
                        if generation != self.generation:
                            raise RuntimeError("Guest session changed before sending key")
                        entry["sent_at"] = time.monotonic()
                        item["status"] = "pending"
                self.emulator.send("printf 'KEY " + item["id"] + " " + str(entry["code"]) +
                                   "\\n' >&9\n", on_send=sent)
                if not entry["done"].wait(self.ACK_TIMEOUT):
                    with self.lock:
                        if generation != self.generation:
                            return
                        if not entry["done"].is_set():
                            item.update(status="timeout", error="Outcome unknown; key was not retried")
                            self.status, self.error = "uncertain", "Waiting for a late key acknowledgement"
                            self._cancel_queued()
                            self.worker_running = False
                            return
            except Exception as exc:
                with self.lock:
                    if generation != self.generation:
                        return
                    item.update(status="timeout", error="Transport failed; outcome unknown: " + str(exc))
                    self.status, self.error = "uncertain", item["error"]
                    self._cancel_queued()
                    self.worker_running = False
                return
            with self.lock:
                self.pending.pop(item["id"], None)

    def _cancel_queued(self):
        while self.queue:
            entry = self.queue.popleft()
            entry["item"].update(status="cancelled", error="Not sent after an earlier uncertain request")
            self.pending.pop(entry["item"]["id"], None)
            entry["done"].set()
