#!/bin/sh
set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sdk=${ANDROID_SDK_ROOT:-"$HOME/Library/Android/sdk"}
clang++ -std=c++17 -O2 -I"$here/include" "$here/angle_probe.cpp" -o "$here/angle_probe.new"
mv "$here/angle_probe.new" "$here/angle_probe"
exec "$here/angle_probe" "$sdk/emulator/lib64/gles_angle"
