#!/usr/bin/env python3
"""Independent disk checkpoints and persistent overlays for the local emulator.

No physical-device paths or guest commands are accepted. QMP belongs to the
caller's isolated emulator; its callback must have a bounded transport timeout.
"""
import argparse
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import threading
import sys
import stat
import subprocess
import tempfile
import time


class CheckpointError(RuntimeError):
    def __init__(self, message, partial_path=None, cleanup_errors=()):
        super().__init__(message)
        self.partial_path = str(partial_path) if partial_path else None
        self.cleanup_errors = list(cleanup_errors)


def _tool(qemu_img, *arguments, timeout=120):
    result = subprocess.run([str(qemu_img), *map(str, arguments)],
                            capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError("qemu-img failed: " + result.stderr.strip()[:2000])
    return result.stdout


def _info(qemu_img, path):
    return json.loads(_tool(qemu_img, "info", "--output=json", path))


def _destination(output):
    output = Path(output).expanduser().absolute()
    parent = output.parent.resolve(strict=True)
    output = parent / output.name
    if output.name in ("", ".", "..") or output.exists() or output.is_symlink():
        raise ValueError("Checkpoint destination must be a new local file")
    staging = Path(tempfile.mkdtemp(prefix="." + output.name + ".incomplete-", dir=parent))
    return output, staging, staging / "image.qcow2"


def _publish(staging_image, output):
    # Hard-link publication is atomic and refuses an existing destination.
    # Staging is on the same filesystem; never replace a user's existing file.
    with staging_image.open("rb") as stream:
        os.fsync(stream.fileno())
    os.link(staging_image, output)
    descriptor = os.open(output.parent, os.O_RDONLY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def _job(qmp_call, job_id):
    return next((j for j in qmp_call("query-jobs") if j["id"] == job_id), None)


def _wait_job(qmp_call, job_id, deadline, progress=None):
    while True:
        job = _job(qmp_call, job_id)
        if job is None:
            raise RuntimeError("Backup job disappeared before its result was inspected")
        if progress:
            progress({"phase": "backup", "job": dict(job)})
        if job["status"] == "concluded":
            return job
        if time.monotonic() >= deadline:
            raise TimeoutError("Checkpoint backup timed out")
        time.sleep(min(.2, max(0, deadline - time.monotonic())))


def capture_checkpoint(qmp_call, output, states, *, qemu_img="qemu-img",
                       source_device="tv-emmc", timeout=600, cleanup_timeout=15,
                       guest_sync=None, progress=None):
    """Capture a full, independent disk image and restore the prior run state.

    states must explicitly contain boot_complete=True, warmup_complete=True.
    These are caller attestations, not inferred from the existence of a frame.
    guest_sync, when supplied, must await a fixed guest sync command's success
    and return True. It is called before pausing a running guest. Without this,
    the disk checkpoint is crash-consistent and can require journal replay.

    The caller must serialize this operation against start/stop/restart and
    other block graph changes. Return only after backup conclusion, no-error
    status, target closure, no-backing validation, and offline qemu-img check.
    No RAM, CPU or peripheral state is saved. Boot the disk from reset.
    """
    if states.get("boot_complete") is not True or states.get("warmup_complete") is not True:
        raise ValueError("Boot and warmup must both be confirmed before checkpointing")
    if not 0 < timeout <= 3600 or not 0 < cleanup_timeout <= 60:
        raise ValueError("Checkpoint and cleanup timeouts must be bounded")
    required = {"query-status", "stop", "cont", "query-block", "blockdev-add",
                "blockdev-del", "blockdev-backup", "query-jobs", "job-dismiss",
                "block-job-cancel"}
    commands = {c["name"] for c in qmp_call("query-commands")}
    if not required.issubset(commands):
        raise ValueError("QEMU lacks required checkpoint commands: " + ", ".join(sorted(required - commands)))
    status = qmp_call("query-status")
    if status.get("status") not in ("running", "paused", "prelaunch"):
        raise ValueError("Guest is not in a checkpointable run state")
    was_running = bool(status.get("running"))
    source = next((b for b in qmp_call("query-block") if b.get("device") == source_device), None)
    if not source or not source.get("inserted") or source["inserted"].get("ro"):
        raise ValueError("Expected writable emulator disk is unavailable")
    size = source["inserted"]["image"]["virtual-size"]
    if not isinstance(size, int) or size <= 0:
        raise ValueError("Invalid source virtual size")
    if guest_sync and not was_running:
        raise ValueError("An acknowledged guest sync requires a running guest")
    synced = False
    output, staging, image = _destination(output)
    suffix = secrets.token_hex(6)
    node, job_id = "checkpoint-target-" + suffix, "checkpoint-backup-" + suffix
    stop_attempted = node_requested = job_requested = published = False
    result, failure, cleanup_errors = None, None, []
    deadline = time.monotonic() + timeout
    try:
        _tool(qemu_img, "create", "-q", "-f", "qcow2", image, size,
              timeout=min(120, timeout))
        if guest_sync:
            if guest_sync() is not True:
                raise RuntimeError("Guest sync did not report success")
            synced = True
        if was_running:
            stop_attempted = True
            qmp_call("stop")
        if qmp_call("query-status").get("running"):
            raise RuntimeError("QEMU did not pause the guest")
        if progress:
            progress({"phase": "paused", "source_device": source_device})
        node_requested = True
        qmp_call("blockdev-add", {"driver": "qcow2", "node-name": node,
                                  "file": {"driver": "file", "filename": str(image)},
                                  "backing": None})
        job_requested = True
        qmp_call("blockdev-backup", {"job-id": job_id, "device": source_device,
                                     "target": node, "sync": "full",
                                     "auto-finalize": True, "auto-dismiss": False,
                                     "on-source-error": "report", "on-target-error": "report"})
        job = _wait_job(qmp_call, job_id, deadline, progress)
        if "error" in job:
            raise RuntimeError("Backup failed: " + job["error"])
        qmp_call("job-dismiss", {"id": job_id})
        job_requested = False
        qmp_call("blockdev-del", {"node-name": node})
        node_requested = False
        info = _info(qemu_img, image)
        if info.get("format") != "qcow2" or info.get("virtual-size") != size or info.get("backing-filename"):
            raise RuntimeError("Backup is not an independent qcow2 of the source size")
        check = json.loads(_tool(qemu_img, "check", "--output=json", image,
                                timeout=max(1, min(120, deadline - time.monotonic()))))
        if check.get("corruptions", 0) or check.get("check-errors", 0) or check.get("leaks", 0):
            raise RuntimeError("Backup integrity check reported errors")
        if time.monotonic() >= deadline:
            raise TimeoutError("Checkpoint validation exceeded its deadline")
        _publish(image, output)
        published = True
        result = {"schema": "philips-disk-checkpoint-v1", "path": str(output),
                  "format": "qcow2", "virtual_size": size, "independent": True,
                  "guest_sync_acknowledged": synced, "disk_only": True,
                  "consistency": "crash-consistent paused disk; guest sync acknowledged before pause" if synced else "crash-consistent paused disk",
                  "source_device": source_device, "original_run_state": status["status"],
                  "warmup_attestation": dict(states), "check": check}
    except Exception as exc:
        failure = exc
        if image.exists() and output.exists():
            published = os.path.samefile(image, output)
    finally:
        if job_requested:
            try:
                job = _job(qmp_call, job_id)
                if job and job["status"] != "concluded":
                    qmp_call("block-job-cancel", {"device": job_id, "force": True})
                    job = _wait_job(qmp_call, job_id, time.monotonic() + cleanup_timeout)
                if job:
                    qmp_call("job-dismiss", {"id": job_id})
                job_requested = False
            except Exception as exc:
                cleanup_errors.append("Backup cancellation/dismissal: " + str(exc))
        if node_requested and not job_requested:
            try:
                qmp_call("blockdev-del", {"node-name": node})
                node_requested = False
            except Exception as exc:
                cleanup_errors.append("Target node removal: " + str(exc))
        if stop_attempted:
            try:
                qmp_call("cont")
                if not qmp_call("query-status").get("running"):
                    raise RuntimeError("QEMU did not resume")
            except Exception as exc:
                cleanup_errors.append("Guest resume: " + str(exc))
        try:
            if published:
                shutil.rmtree(staging)
            else:
                # Keep incomplete output distinct and never delete a file still
                # in use by a backup job. The caller can inspect it later.
                (staging / "INCOMPLETE.json").write_text(json.dumps({
                    "error": str(failure), "cleanup_errors": cleanup_errors,
                    "job_id": job_id, "target_node": node,
                    "may_still_be_in_use": job_requested or node_requested}, indent=2))
        except OSError as exc:
            cleanup_errors.append("Staging cleanup/report: " + str(exc))
    if failure or cleanup_errors:
        message = str(failure) if failure else "Checkpoint saved but guest cleanup/resume failed"
        raise CheckpointError(message, output if published else image, cleanup_errors)
    return result


def create_persistent_overlay(base, output, *, qemu_img="qemu-img"):
    """New writable qcow2 overlay over an independent durable base; no overwrite."""
    base = Path(base).expanduser().resolve(strict=True)
    if not stat.S_ISREG(base.stat().st_mode):
        raise ValueError("Overlay base must be a regular local image file")
    info = _info(qemu_img, base)
    if info.get("format") not in ("raw", "qcow2") or info.get("backing-filename"):
        raise ValueError("Overlay base must be an independent raw or qcow2 image")
    output, staging, image = _destination(output)
    try:
        _tool(qemu_img, "create", "-q", "-f", "qcow2", "-F", info["format"],
              "-b", base, image)
        created = _info(qemu_img, image)
        if created.get("virtual-size") != info["virtual-size"] or created.get("full-backing-filename", created.get("backing-filename")) != str(base):
            raise RuntimeError("Overlay geometry/backing verification failed")
        _publish(image, output)
        return {"schema": "philips-persistent-overlay-v1", "path": str(output),
                "format": "qcow2", "backing_file": str(base), "backing_format": info["format"],
                "virtual_size": info["virtual-size"], "snapshot": False,
                "note": "Keep the durable backing file at this path; boot with format=qcow2 and without snapshot=on."}
    finally:
        shutil.rmtree(staging)


class SocketQMP:
    """Exclusive standalone QMP connection; do not share it with the UI."""
    def __init__(self, path, timeout=10):
        if not 0 < timeout <= 60:
            raise ValueError("QMP transport timeout must be in (0, 60]")
        self.lock = threading.Lock()
        self.timeout = timeout
        self.serial = 0
        self.stream = None
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.socket.settimeout(timeout)
        try:
            self.socket.connect(str(path))
            self.stream = self.socket.makefile("rwb", buffering=0)
            greeting = self._read()
            if "QMP" not in greeting:
                raise RuntimeError("QMP greeting not received; exclusive socket access is required")
            self.call("qmp_capabilities")
        except Exception:
            self.close()
            raise

    def _read(self):
        line = self.stream.readline(1024 * 1024)
        if not line or not line.endswith(b"\n"):
            raise RuntimeError("QMP connection closed or response exceeded 1 MiB")
        return json.loads(line)

    def call(self, name, arguments=None):
        with self.lock:
            self.serial += 1
            identifier = self.serial
            self.stream.write((json.dumps({"execute": name, "arguments": arguments or {},
                                          "id": identifier}) + "\n").encode())
            deadline = time.monotonic() + self.timeout
            try:
                while True:
                    remaining = deadline - time.monotonic()
                    if remaining <= 0:
                        raise TimeoutError("QMP command response timed out")
                    self.socket.settimeout(remaining)
                    reply = self._read()
                    if "event" in reply:
                        continue
                    if reply.get("id") != identifier:
                        raise RuntimeError("Unexpected QMP response ID")
                    if "error" in reply:
                        raise RuntimeError(reply["error"].get("desc", str(reply["error"])))
                    if "return" in reply:
                        return reply["return"]
            finally:
                self.socket.settimeout(self.timeout)

    def close(self):
        if self.stream is not None:
            self.stream.close()
            self.stream = None
        self.socket.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    overlay = sub.add_parser("overlay", help="Create a new persistent development overlay")
    overlay.add_argument("--base", required=True, type=Path)
    overlay.add_argument("--output", required=True, type=Path)
    overlay.add_argument("--qemu-img", default="qemu-img")
    capture = sub.add_parser("capture", help="Capture via an exclusively owned local QMP socket")
    capture.add_argument("--qmp", required=True, type=Path)
    capture.add_argument("--output", required=True, type=Path)
    capture.add_argument("--qemu-img", default="qemu-img")
    capture.add_argument("--boot-complete", action="store_true", required=True)
    capture.add_argument("--warmup-complete", action="store_true", required=True)
    capture.add_argument("--warmup-evidence", required=True)
    capture.add_argument("--guest-sync-confirmed", action="store_true")
    capture.add_argument("--guest-sync-evidence")
    capture.add_argument("--timeout", type=float, default=600)
    capture.add_argument("--qmp-timeout", type=float, default=10)
    args = parser.parse_args()
    if args.action == "overlay":
        result = create_persistent_overlay(args.base, args.output, qemu_img=args.qemu_img)
    else:
        if not args.warmup_evidence.strip():
            parser.error("--warmup-evidence must be nonempty")
        if args.guest_sync_confirmed != bool(args.guest_sync_evidence and args.guest_sync_evidence.strip()):
            parser.error("--guest-sync-confirmed and nonempty --guest-sync-evidence must be supplied together")
        states = {"boot_complete": args.boot_complete, "warmup_complete": args.warmup_complete,
                  "warmup_evidence": args.warmup_evidence,
                  "guest_sync_previously_confirmed": args.guest_sync_confirmed,
                  "guest_sync_evidence": args.guest_sync_evidence}
        # A prior sync attestation is recorded, not represented as a new sync
        # executed at capture time. Consistency remains crash-consistent.
        client = SocketQMP(args.qmp, args.qmp_timeout)
        last_progress = [0.0]
        def progress(value):
            now = time.monotonic()
            if value["phase"] != "backup" or now - last_progress[0] >= 1:
                print(json.dumps(value), file=sys.stderr, flush=True)
                last_progress[0] = now
        try:
            result = capture_checkpoint(client.call, args.output, states,
                                        qemu_img=args.qemu_img, timeout=args.timeout,
                                        progress=progress)
        except CheckpointError as exc:
            print(json.dumps({"error": str(exc), "artifact_path": exc.partial_path,
                              "cleanup_errors": exc.cleanup_errors}), file=sys.stderr)
            raise SystemExit(1)
        finally:
            client.close()
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
