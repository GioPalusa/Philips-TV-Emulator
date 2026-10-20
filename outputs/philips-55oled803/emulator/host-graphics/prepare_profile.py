#!/usr/bin/env python3
"""Clone the existing development disk into a distinct host-GLES profile."""
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
EMU = HERE.parent
ROOT = EMU.parents[2]
PROFILE = HERE / "profile"
SCRATCH = ROOT / "work/philips-hostgpu-profile"
DEBUGFS = ROOT / "work/philips-ext4/e2fsprogs-1.47.2/debugfs/debugfs"
E2FSCK = ROOT / "work/philips-ext4/e2fsprogs-1.47.2/e2fsck/e2fsck"


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def quote(path):
    path = str(path)
    if any(c in path for c in '"\\\r\n'):
        raise ValueError("Unsupported debugfs path")
    return '"' + path + '"'


def main():
    PROFILE.mkdir(exist_ok=False)
    SCRATCH.mkdir(exist_ok=False)
    disk = PROFILE / "hostgpu-emmc.img"
    # APFS clone: the previous software-rendered profile is preserved.
    subprocess.run(["cp", "-c", str(EMU / "development/development-emmc.img"),
                    str(disk)], check=True)
    parts = json.loads((EMU / "partitions.json").read_text())["partitions"]
    part = next(p for p in parts if p["name"] == "system")
    system = SCRATCH / "system.img"
    with disk.open("rb") as src, system.open("xb") as dst:
        src.seek(part["start_byte"])
        remaining = part["size_bytes"]
        while remaining:
            block = src.read(min(4*1024*1024, remaining))
            if not block:
                raise ValueError("Truncated system image")
            dst.write(block)
            remaining -= len(block)
    guest = HERE / "guest"
    files = {}
    for name in ("libEGL_emulation.so", "libGLESv1_CM_emulation.so",
                 "libGLESv2_emulation.so"):
        files["/lib/egl/" + name] = guest / name
    for name in ("libGLESv1_enc.so", "libGLESv2_enc.so",
                 "lib_renderControl_enc.so", "libOpenglSystemCommon.so"):
        files["/lib/" + name] = guest / name
    files["/lib/hw/gralloc.goldfish.so"] = guest / "gralloc.goldfish.so"
    for name in ("hostgpu_broker", "hostgpu_render_test"):
        files["/etc/emulator-assets/" + name] = guest / name
    files["/etc/emulator-assets/philips-input.jar"] = EMU / "input/philips-input.jar"
    label = SCRATCH / "system-file-context"
    label.write_bytes(b"u:object_r:system_file:s0\0")
    commands = []
    for name in ("libEGL_swiftshader.so", "libGLESv1_CM_swiftshader.so",
                 "libGLESv2_swiftshader.so"):
        commands += [f"link /lib/egl/{name} /lib/egl/{name}.disabled",
                     f"unlink /lib/egl/{name}"]
    for target, source in files.items():
        executable = target.endswith(("hostgpu_broker", "hostgpu_render_test"))
        commands += [f"write {quote(source)} {target}",
                     f"set_inode_field {target} mode {'0100755' if executable else '0100644'}",
                     f"ea_set -f {quote(label)} {target} security.selinux"]
    script = SCRATCH / "install.debugfs"
    script.write_text("\n".join(commands) + "\n")
    result = subprocess.run([str(DEBUGFS), "-w", "-f", str(script), str(system)],
                            capture_output=True, text=True, check=True)
    (SCRATCH / "install.log").write_text(result.stdout + result.stderr)
    verified = {}
    for index, (target, source) in enumerate(files.items()):
        dump = SCRATCH / f"check-{index}"
        subprocess.run([str(DEBUGFS), "-R", f"dump {target} {quote(dump)}", str(system)],
                       capture_output=True, check=True)
        if digest(dump) != digest(source):
            raise RuntimeError("Installed bytes differ: " + target)
        verified[target] = digest(source)
    result = subprocess.run([str(E2FSCK), "-fn", str(system)],
                            capture_output=True, text=True, check=True)
    (PROFILE / "filesystem-check.txt").write_text(result.stdout + result.stderr)
    with disk.open("r+b") as dst, system.open("rb") as src:
        dst.seek(part["start_byte"])
        shutil.copyfileobj(src, dst, 4*1024*1024)
    fragment = SCRATCH / "init.rc"
    fragment.write_bytes((EMU / "ambilight/emulator-ambilight-enabled.rc").read_bytes() +
                         b"\n" + (guest / "emulator-hostgpu.rc").read_bytes())
    subprocess.run([
        sys.executable, str(EMU / "development_ramdisk.py"),
        "--stock", str(EMU / "ramdisk.img"), "--output", str(PROFILE / "ramdisk.img"),
        "--disable-system-verity", "--property", "ro.hardware.gralloc=goldfish",
        "--property", "ro.hardware.hwcomposer=emulator",
        "--property", "ro.hardware.egl=emulation",
        "--property", "ro.kernel.qemu.gles=1",
        "--sepolicy", str(guest / "policy/sepolicy-hostgpu"),
        "--append-init", str(fragment)
    ], check=True)
    (PROFILE / "manifest.json").write_text(json.dumps({
        "purpose": "Emulator-only host GLES integration; never flash to physical TV",
        "source_profile": str(EMU / "development"),
        "files": verified, "system_sha256": digest(system),
        "ramdisk_sha256": digest(PROFILE / "ramdisk.img"),
        "graphics": "Goldfish GLES transport to host ANGLE Metal, not Mali emulation",
        "selinux": "Enforcing; concrete permissions recorded in guest/policy",
        "guest_disk_writes": "Temporary QEMU snapshot overlay"
    }, indent=2) + "\n")
    print(PROFILE)


if __name__ == "__main__":
    main()
