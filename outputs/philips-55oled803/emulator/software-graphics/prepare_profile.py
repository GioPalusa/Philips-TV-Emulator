#!/usr/bin/env python3
"""Build a separate emulator graphics/Ambilight profile from the stock disk."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
EMU = HERE.parent


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def quoted(path):
    value = str(path)
    if any(c in value for c in '"\n\r\\'):
        raise ValueError("Unsupported character in debugfs path")
    return '"' + value + '"'


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--stock", type=Path, default=EMU / "stock-emmc-107.1.143.0.img")
    ap.add_argument("--output", type=Path, required=True, help="New profile directory")
    ap.add_argument("--scratch", type=Path, required=True, help="New intermediate directory")
    ap.add_argument("--debugfs", type=Path, required=True)
    ap.add_argument("--e2fsck", type=Path, required=True)
    args = ap.parse_args()
    args.output = args.output.absolute()
    args.scratch = args.scratch.absolute()
    args.output.mkdir(parents=True, exist_ok=False)
    args.scratch.mkdir(parents=True, exist_ok=False)
    disk = args.output / "development-emmc.img"
    # This checks the exact disk size and empty NVM, then uses APFS clonefile.
    sys.path.insert(0, str(EMU / "ambilight"))
    from create_synthetic_profile import create_profile
    create_profile(args.stock, disk)
    parts = json.loads((EMU / "partitions.json").read_text())["partitions"]
    part = next(p for p in parts if p["name"] == "system")
    system = args.scratch / "system.img"
    with disk.open("rb") as src, system.open("xb") as dst:
        src.seek(part["start_byte"])
        remaining = part["size_bytes"]
        while remaining:
            block = src.read(min(4 * 1024 * 1024, remaining))
            if not block:
                raise ValueError("Truncated system partition")
            dst.write(block)
            remaining -= len(block)
    contexts = {}
    for name in ("system_file", "vendor_file"):
        path = args.scratch / name
        path.write_bytes(f"u:object_r:{name}:s0\0".encode())
        contexts[name] = path
    files = {
        "/lib/egl/" + name: (HERE / name, "system_file", "0100644")
        for name in ("libEGL_swiftshader.so", "libGLESv2_swiftshader.so",
                     "libGLESv1_CM_swiftshader.so")
    }
    files.update({
        "/vendor/lib/hw/hwcomposer.emulator.so":
            (HERE / "hwcomposer.emulator.so", "vendor_file", "0100644"),
        "/vendor/lib/hw/gralloc.emulator.so":
            (HERE / "gralloc.emulator.so", "vendor_file", "0100644"),
        "/etc/emulator-assets/render_test":
            (HERE / "render_test", "system_file", "0100755"),
        "/etc/emulator-assets/amb-probe":
            (EMU / "ambilight/guest_mtamb_probe_enabled", "system_file", "0100755"),
    })
    commands = [
        "mkdir /etc/emulator-assets",
        f"ea_set -f {quoted(contexts['system_file'])} /etc/emulator-assets security.selinux",
        "link /lib/egl/libGLES_mali.so /lib/egl/libGLES_mali.so.disabled",
        "unlink /lib/egl/libGLES_mali.so",
    ]
    for destination, (source, label, mode) in files.items():
        commands += [
            f"write {quoted(source)} {destination}",
            f"set_inode_field {destination} mode {mode}",
            f"ea_set -f {quoted(contexts[label])} {destination} security.selinux",
        ]
    script = args.scratch / "inject.debugfs"
    script.write_text("\n".join(commands) + "\n")
    result = subprocess.run([str(args.debugfs), "-w", "-f", str(script), str(system)],
                            capture_output=True, text=True, check=True)
    (args.scratch / "inject.log").write_text(result.stdout + result.stderr)
    # debugfs does not reliably return a failing exit status for command errors.
    # Verify every installed byte and each exact SELinux label independently.
    verification = {}
    for index, (destination, (source, label, mode)) in enumerate(files.items()):
        dump = args.scratch / f"verify-{index}"
        subprocess.run([str(args.debugfs), "-R", f"dump {destination} {quoted(dump)}",
                        str(system)], capture_output=True, check=True)
        if digest(dump) != digest(source):
            raise RuntimeError("Installed bytes differ: " + destination)
        result = subprocess.run([str(args.debugfs), "-R",
                                 f"ea_get {destination} security.selinux",
                                 str(system)], capture_output=True, text=True, check=True)
        if f"u:object_r:{label}:s0" not in result.stdout:
            raise RuntimeError("Incorrect SELinux label: " + destination)
        verification[destination] = {"sha256": digest(source), "label": label, "mode": mode}
    result = subprocess.run([str(args.e2fsck), "-fn", str(system)],
                            capture_output=True, text=True, check=True)
    (args.output / "filesystem-check.txt").write_text(result.stdout + result.stderr)
    with disk.open("r+b") as dst, system.open("rb") as src:
        dst.seek(part["start_byte"])
        shutil.copyfileobj(src, dst, 4 * 1024 * 1024)
    ramdisk = args.output / "ramdisk.img"
    subprocess.run([
        sys.executable, str(EMU / "development_ramdisk.py"),
        "--stock", str(EMU / "ramdisk.img"), "--output", str(ramdisk),
        "--disable-system-verity", "--property", "ro.hardware.gralloc=emulator",
        "--property", "ro.hardware.hwcomposer=emulator",
        "--sepolicy", str(HERE / "sepolicy-software-graphics"),
        "--append-init", str(EMU / "ambilight/emulator-ambilight-enabled.rc"),
    ], check=True)
    (args.output / "manifest.json").write_text(json.dumps({
        "purpose": "Emulator development profile, not a physical TV firmware update",
        "stock_image": str(args.stock.resolve()),
        "system_partition_sha256": digest(system),
        "ramdisk_sha256": digest(ramdisk),
        "files": verification,
        "renamed": {"/system/lib/egl/libGLES_mali.so":
                    "/system/lib/egl/libGLES_mali.so.disabled"},
        "system_verity_disabled": True,
        "selinux_enforcing": True,
        "additional_permissions": ["bootanim self:process execmem",
                                   "surfaceflinger self:process execmem"],
        "ambilight_geometry": "Synthetic firmware fallback: 4 left, 9 top, 4 right",
        "ambilight_mode": "Stock measured-input mode 8, enabled after 60 guest seconds",
        "gralloc": "Emulator ashmem-only allocation variant of exact stock fallback HAL",
        "persistent_state_initialization": "Create /user_setting/rw 0777 system:system in post-fs before stock post-fs-data",
        "guest_disk_writes": "Launch with QEMU snapshot overlay",
    }, indent=2) + "\n")
    print(args.output)


if __name__ == "__main__":
    main()
