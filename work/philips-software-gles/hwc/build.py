#!/usr/bin/env python3
"""Compile the framebuffer HWC development HAL against stock Android libraries."""
from pathlib import Path
import subprocess

p = Path(__file__).resolve().parent
root = p.parent
libgcc = subprocess.check_output(
    ["arm-none-eabi-gcc", "-print-libgcc-file-name"], text=True).strip()


def run(*args):
    subprocess.run([str(a) for a in args], check=True)


run("/opt/homebrew/opt/llvm/bin/clang",
    "--target=armv7a-linux-androideabi26",
    "--sysroot=" + str(root / "sysroot"),
    "-isystem", root / "sysroot/usr/include/asm-arm",
    "-I" + str(root / "platform"),
    "-fPIC", "-fvisibility=hidden", "-O2", "-Wall", "-Wextra", "-Werror",
    "-c", p / "hwcomposer_emulator.c", "-o", p / "hwcomposer_emulator.o")
run("arm-none-eabi-ld", "-shared", "-z", "noexecstack",
    "-soname", "hwcomposer.emulator.so", "--no-undefined",
    "--allow-shlib-undefined", "-L" + str(root / "sysroot/usr/lib"),
    root / "sysroot/usr/lib/crtbegin_so.o", p / "hwcomposer_emulator.o",
    "-lhardware", "-lsync", "-llog", "-lc", "-ldl", "-lm", libgcc,
    root / "sysroot/usr/lib/crtend_so.o", "-o", p / "hwcomposer.emulator.so")
