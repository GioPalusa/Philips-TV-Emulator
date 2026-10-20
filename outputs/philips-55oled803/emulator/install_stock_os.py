#!/usr/bin/env python3
"""Install the 2021 Philips stock update into a sparse, local eMMC image.

This is a firmware reconstruction for offline emulation. It does not contact,
reboot, or write to a TV. It cannot create the TV's unique factory data.
"""

import argparse
import hashlib
import json
import os
import shutil
import stat
import subprocess
import tempfile
from pathlib import Path, PurePosixPath
from zipfile import ZipFile


HERE = Path(__file__).resolve().parent
BLOCK = 1024 * 1024

# The first item is the encrypted entry in autorun.upg, the second is the
# decrypted ZIP member, and the rest are partition names from /proc/partinfo.
COMPONENTS = [
    ("uboot.bin.zip", "uboot.bin", ("uboot", "ubootB")),
    ("uenv.bin.zip", "uenv.bin", ("uboot_env", "ubootB_env")),
    ("recovery.img.zip", "recovery.img", ("recovery", "recoveryB")),
    ("boot.img.zip", "boot.img", ("boot",)),
    ("rootfs.bin.zip", "rootfs.bin", ("linux_rootfs",)),
    ("factory.img.zip", "factory.img", ("factory",)),
    ("3rd_file.zip", "3rd_file", ("3rd_ro",)),
    ("tz.bin.lzhs.zip", "tz.bin.lzhs", ("tzbp",)),
    ("adsp.bin.zip", "adsp.bin", ("adsp",)),
    ("pq.bin.zip", "pq.bin", ("pq",)),
    ("AQ.bin.zip", "AQ.bin", ("aq",)),
]

WRITABLE_EXT4 = (
    ("userdata", "data"),
    ("cache", "cache"),
    ("factory_setting", "factory_setting"),
    ("3rd_rw", "3rd_rw"),
    ("usersetting", "user_setting"),
)


def decrypt_entry(firmware: Path, entry: str, passfile: Path, destination: Path) -> None:
    """Stream one encrypted outer ZIP member through the OTA's AES format."""
    outer = subprocess.Popen(
        ["unzip", "-p", str(firmware), entry],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    with destination.open("wb") as output:
        decrypted = subprocess.run(
            ["openssl", "enc", "-d", "-aes-256-cbc", "-md", "md5",
             "-pass", f"file:{passfile}"],
            stdin=outer.stdout,
            stdout=output,
            stderr=subprocess.PIPE,
            check=False,
        )
    assert outer.stdout is not None
    outer.stdout.close()
    _, outer_errors = outer.communicate()
    if outer.returncode or decrypted.returncode:
        raise RuntimeError(
            f"Could not decrypt {entry}: unzip={outer.returncode}, "
            f"openssl={decrypted.returncode}; "
            f"{outer_errors.decode(errors='replace').strip()} "
            f"{decrypted.stderr.decode(errors='replace').strip()}"
        )


def install_member(
    disk, zipfile: ZipFile, member: str, *,
    offset: int, limit: int, outer_entry: str,
) -> dict:
    info = zipfile.getinfo(member)
    if info.file_size > limit:
        raise ValueError(f"{member} ({info.file_size} bytes) exceeds its partition")
    digest = hashlib.sha256()
    position = 0
    with zipfile.open(info) as source:
        while True:
            block = source.read(BLOCK)
            if not block:
                break
            digest.update(block)
            if any(block):  # Preserve zero-filled ext4 space as a sparse hole.
                disk.seek(offset + position)
                disk.write(block)
            position += len(block)
    if position != info.file_size:
        raise IOError(f"Truncated {member}")
    return {
        "outer_entry": outer_entry,
        "member": member,
        "disk_offset": offset,
        "size_bytes": position,
        "sha256": digest.hexdigest(),
    }


def extract_tree(zipfile: ZipFile, prefix: str, destination: Path) -> dict:
    """Extract one OTA directory tree, ignoring adjacent .sh/.lst scripts."""
    destination.mkdir(parents=True, exist_ok=True)
    files = 0
    total = 0
    for info in zipfile.infolist():
        if not info.filename.startswith(prefix + "/"):
            continue
        path = PurePosixPath(info.filename)
        parts = path.parts[1:]
        if not parts:
            continue
        if path.is_absolute() or any(part in ("", ".", "..") for part in parts):
            raise ValueError(f"Unsafe path in {prefix} ZIP: {info.filename}")
        mode = info.external_attr >> 16
        if stat.S_IFMT(mode) not in (stat.S_IFREG, stat.S_IFDIR):
            raise ValueError(f"Unexpected file type in {prefix} ZIP: {info.filename}")
        target = destination.joinpath(*parts)
        if info.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            target.chmod(mode & 0o777 or 0o755)
            continue
        files += 1
        total += info.file_size
        if files > 100_000 or total > 512 * 1024 * 1024:
            raise ValueError(f"{prefix} ZIP exceeds extraction limits")
        target.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.open(info) as source, target.open("wb") as output:
            shutil.copyfileobj(source, output, BLOCK)
        target.chmod(mode & 0o777 or 0o644)
    return {"entry_prefix": prefix, "files": files, "size_bytes": total}


def format_partition(image: Path, part: dict, label: str, source_tree: Path | None) -> None:
    if part["size_bytes"] % 4096:
        raise ValueError(f"{part['name']} is not 4 KiB aligned")
    command = [
        "mke2fs", "-F", "-q", "-t", "ext4", "-b", "4096", "-m", "0",
        # The stock Linux 3.10 kernel rejects current mke2fs defaults.
        "-O", "^metadata_csum,^metadata_csum_seed,^64bit,^orphan_file",
        "-E", f"offset={part['start_byte']},root_owner=0:0", "-L", label,
    ]
    if source_tree is not None:
        command += ["-d", str(source_tree)]
    command += [str(image), str(part["size_bytes"] // 4096)]
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        raise RuntimeError(
            f"Could not format {part['name']}: {result.stderr.decode(errors='replace')}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--firmware", required=True, type=Path, help="2021 autorun.upg")
    parser.add_argument("--passfile", required=True, type=Path, help="Locally recovered update passfile")
    parser.add_argument("--output", required=True, type=Path, help="New sparse raw eMMC image")
    parser.add_argument("--temp-dir", type=Path, help="Directory for one temporary decrypted ZIP at a time")
    parser.add_argument(
        "--skip-writable-fs", action="store_true",
        help="Leave data, cache and other writable partitions empty",
    )
    args = parser.parse_args()
    for required in (args.firmware, args.passfile):
        if not required.is_file():
            parser.error(f"missing {required}")
    if args.output.exists() or args.output.with_suffix(args.output.suffix + ".partial").exists():
        parser.error("refusing to overwrite an existing image or partial image")

    manifest = json.loads((HERE / "partitions.json").read_text())
    partitions = {part["name"]: part for part in manifest["partitions"]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    partial = args.output.with_suffix(args.output.suffix + ".partial")
    report = {
        "model": manifest["model"],
        "firmware": "TPM171E_R.107.001.143.000",
        "disk_size_bytes": manifest["emmc_size_bytes"],
        "status": "Stock update payloads installed; no unique TV data",
        "writes": [],
        "formatted_ext4": [],
        "default_files": [],
        "ext4_profile": {
            "block_size": 4096,
            "root_owner": "0:0",
            "disabled_features": ["metadata_csum", "metadata_csum_seed",
                                  "64bit", "orphan_file"],
            "target_kernel": "3.10.79",
        },
    }

    try:
        with args.firmware.open("rb") as input_file, ZipFile(input_file) as outer:
            required = [name for name, _, _ in COMPONENTS]
            required += [f"system{number}.img.zip" for number in range(1, 9)]
            if not args.skip_writable_fs:
                required += ["user_setting.zip", "cache.zip", "tvupgrades.zip", "edid.zip"]
            absent = [name for name in required if name not in outer.namelist()]
            if absent:
                raise ValueError(f"Firmware is missing: {', '.join(absent)}")
        with partial.open("xb") as disk:
            disk.truncate(manifest["emmc_size_bytes"])
            for entry, member, target_names in COMPONENTS:
                with tempfile.NamedTemporaryFile(
                    prefix="philips-decrypted-", suffix=".zip",
                    dir=args.temp_dir, delete=False,
                ) as temp:
                    temp_path = Path(temp.name)
                try:
                    decrypt_entry(args.firmware, entry, args.passfile, temp_path)
                    with ZipFile(temp_path) as inner:
                        for target_name in target_names:
                            part = partitions[target_name]
                            write = install_member(
                                disk, inner, member,
                                offset=part["start_byte"], limit=part["size_bytes"],
                                outer_entry=entry,
                            )
                            write["partition"] = target_name
                            report["writes"].append(write)
                            print(f"Installed {member} -> {target_name} ({write['size_bytes']:,} bytes)", flush=True)
                finally:
                    temp_path.unlink(missing_ok=True)

            system = partitions["system"]
            system_position = 0
            for number in range(1, 9):
                entry = f"system{number}.img.zip"
                member = f"system{number}.img"
                with tempfile.NamedTemporaryFile(
                    prefix="philips-decrypted-", suffix=".zip",
                    dir=args.temp_dir, delete=False,
                ) as temp:
                    temp_path = Path(temp.name)
                try:
                    decrypt_entry(args.firmware, entry, args.passfile, temp_path)
                    with ZipFile(temp_path) as inner:
                        write = install_member(
                            disk, inner, member,
                            offset=system["start_byte"] + system_position,
                            limit=system["size_bytes"] - system_position,
                            outer_entry=entry,
                        )
                        write["partition"] = "system"
                        report["writes"].append(write)
                        system_position += write["size_bytes"]
                        print(f"Installed {member} -> system + {system_position:,} bytes", flush=True)
                finally:
                    temp_path.unlink(missing_ok=True)
            if system_position != system["size_bytes"]:
                raise ValueError(
                    f"System chunks total {system_position}, expected {system['size_bytes']} bytes"
                )
            disk.flush()
            os.fsync(disk.fileno())
        if not args.skip_writable_fs:
            with tempfile.TemporaryDirectory(
                prefix="philips-default-files-", dir=args.temp_dir,
            ) as tree_dir:
                tree_root = Path(tree_dir)
                user_tree = tree_root / "user_setting"
                cache_tree = tree_root / "cache"
                for entry, prefix, target in (
                    ("user_setting.zip", "user_setting", user_tree),
                    ("cache.zip", "cache", cache_tree),
                    ("tvupgrades.zip", "tvupgrades", cache_tree / "tvupgrades"),
                    ("edid.zip", "edid", cache_tree / "tvupgrades" / "edid"),
                ):
                    encrypted_zip = tree_root / (entry + ".decrypted")
                    decrypt_entry(args.firmware, entry, args.passfile, encrypted_zip)
                    with ZipFile(encrypted_zip) as inner:
                        extracted = extract_tree(inner, prefix, target)
                    extracted["outer_entry"] = entry
                    report["default_files"].append(extracted)
                    encrypted_zip.unlink()
                    print(f"Extracted {extracted['files']:,} default files from {entry}", flush=True)
                for partition_name, label in WRITABLE_EXT4:
                    source_tree = {
                        "cache": cache_tree,
                        "usersetting": user_tree,
                    }.get(partition_name)
                    format_partition(partial, partitions[partition_name], label, source_tree)
                    report["formatted_ext4"].append(partition_name)
                    print(f"Formatted {partition_name} as ext4", flush=True)
        else:
            report["status"] += "; writable partitions left blank"
        os.replace(partial, args.output)
        report_path = args.output.with_suffix(args.output.suffix + ".install.json")
        report_path.write_text(json.dumps(report, indent=2) + "\n")
    except BaseException:
        partial.unlink(missing_ok=True)
        raise

    print(f"Installed stock firmware payloads into {args.output.resolve()}")
    print(f"Physical disk used: {args.output.stat().st_blocks * 512:,} bytes")
    print("Use run.py with a temporary writable overlay for emulator boot tests.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
