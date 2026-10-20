#!/usr/bin/env python3
"""Reproduce the two scoped graphics JIT permissions from the stock policy."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tarfile
import tempfile

p = argparse.ArgumentParser()
p.add_argument("stock_policy", type=Path)
p.add_argument("output", type=Path, help="New file; existing files are refused")
p.add_argument("--work-dir", type=Path, default=Path("work/philips-policy-rebuild"))
a = p.parse_args()
here = Path(__file__).resolve().parent
manifest = json.loads((here / "changes.json").read_text())
source = a.stock_policy.resolve()
output = a.output.resolve()
if output.exists():
    raise SystemExit("Output already exists")
if hashlib.sha256(source.read_bytes()).hexdigest() != manifest["input_sha256"]:
    raise SystemExit("Input policy does not match the verified stock firmware")
a.work_dir.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(dir=a.work_dir, prefix="policy-") as temporary:
    build = Path(temporary).resolve()
    with tarfile.open(here / "libsepol-3.6.tar.gz") as archive:
        archive.extractall(build, filter="data")
    library = build / "libsepol-3.6"
    subprocess.run(["make", "-C", str(library / "src"), "DISABLE_CIL=y",
                    "CFLAGS=-O2", "libsepol.a", "-j8"], check=True)
    tool = build / "allow_graphics_execmem"
    subprocess.run(["cc", "-O2", "-Wall", "-Wextra", "-Werror",
                    "-I" + str(library / "include"),
                    str(here / "allow_graphics_execmem.c"),
                    str(library / "src/libsepol.a"), "-o", str(tool)], check=True)
    intermediate = build / "bootanim-only"
    subprocess.run([str(tool), str(source), str(intermediate), "bootanim"], check=True)
    subprocess.run([str(tool), str(intermediate), str(output), "surfaceflinger"],
                   check=True)
if hashlib.sha256(output.read_bytes()).hexdigest() != manifest["output_sha256"]:
    raise SystemExit("Output differs from the verified artifact; retain for inspection")
print("PASS: output SHA-256 matches the verified development policy")
