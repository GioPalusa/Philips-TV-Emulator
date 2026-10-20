#!/usr/bin/env python3
"""Rebuild the development ARM32 Android renderer from downloaded sources."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tarfile

HERE = Path(__file__).resolve().parent
WORKSPACE = HERE.parents[1]
CLANG = "/opt/homebrew/opt/llvm/bin/clang"
LD = "/opt/homebrew/bin/arm-none-eabi-ld"
LIBGCC = subprocess.check_output(
    ["arm-none-eabi-gcc", "-print-libgcc-file-name"], text=True).strip()


def run(*args):
    subprocess.run([str(a) for a in args], check=True)


def extract(archive, target):
    target.mkdir(parents=True, exist_ok=True)
    with tarfile.open(HERE / archive) as t:
        # Some AOSP source-tree symlinks point to other repositories. Only
        # regular files are extracted; the one local sync alias is set below.
        t.extractall(target, members=[m for m in t if m.isfile() or m.isdir()],
                     filter="data")


if not (HERE / "source/src/Reactor/SubzeroReactor.cpp").exists():
    extract("swiftshader.tar.gz", HERE / "source")
for name, target in [
    ("ndk-api24-arm", "sysroot"),
    ("bionic-headers", "sysroot/usr/include"),
    ("kernel-headers", "sysroot/usr/include"),
    ("kernel-android-headers", "sysroot/usr/include"),
    ("libcxx-headers", "libcxx"),
    ("hardware-headers", "platform"),
    ("core-headers", "platform"),
    ("nativewindow-headers", "platform"),
    ("native-headers", "platform"),
    ("log-headers", "platform"),
    ("compiler-rt-builtins", "compiler-rt"),
]:
    extract(name + ".tar.gz", HERE / target)

spec = importlib.util.spec_from_file_location(
    "ext4", HERE.parent / "philips-gfx/read_ext4.py")
ext4 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ext4)
stock = WORKSPACE / "outputs/philips-55oled803/emulator"
partition = next(p for p in json.loads((stock / "partitions.json").read_text())
                 ["partitions"] if p["name"] == "system")
fs = ext4.Ext4(stock / "stock-emmc-107.1.143.0.img",
               partition["start_byte"], partition["size_bytes"])
for name in ["libc++", "libc", "libm", "libdl", "liblog", "libhardware",
             "libcutils", "libsync", "libnativewindow", "libutils"]:
    (HERE / "sysroot/usr/lib" / (name + ".so")).write_bytes(
        fs.data(fs.resolve("/lib/" + name + ".so")))

flags = ["--target=armv7a-linux-androideabi26",
         "--sysroot=" + str(HERE / "sysroot"),
         "-isystem", str(HERE / "sysroot/usr/include/asm-arm")]
for source, output in [("compiler-rt/emutls.c", "emutls.o"),
                       ("cache_runtime.c", "cache_runtime.o")]:
    run(CLANG, *flags, "-fPIC", "-fvisibility=hidden", "-O2",
        "-c", HERE / source, "-o", HERE / output)

run("python3", HERE / "prepare_build.py")
run("cmake", "-S", HERE / "source", "-B", HERE / "build", "-G", "Ninja",
    "-DCMAKE_MAKE_PROGRAM=" + str(HERE.parent / "philips-emulator/venv/bin/ninja"),
    "-DCMAKE_TOOLCHAIN_FILE=" + str(HERE / "toolchain.cmake"),
    "-DREACTOR_BACKEND=Subzero", "-DBUILD_SAMPLES=OFF", "-DBUILD_TESTS=OFF")
run("cmake", "--build", HERE / "build", "--target",
    "libEGL", "libGLESv2", "libGLES_CM", "-j", "8")
run(CLANG, *flags, "-I" + str(HERE / "source/include"),
    "-I" + str(HERE / "platform"), "-fPIE", "-O2",
    "-c", HERE / "render_test.c", "-o", HERE / "render_test.o")
run(LD, "-pie", "-z", "noexecstack", "--dynamic-linker=/system/bin/linker",
    "-e", "_start", "--no-undefined", "--allow-shlib-undefined",
    "-L" + str(HERE / "sysroot/usr/lib"), "-L" + str(HERE / "build"),
    HERE / "sysroot/usr/lib/crtbegin_dynamic.o", HERE / "render_test.o",
    "-lEGL_swiftshader", "-lGLESv2_swiftshader", "-lc", "-ldl", "-lm",
    LIBGCC, HERE / "sysroot/usr/lib/crtend_android.o", "-o", HERE / "render_test")
