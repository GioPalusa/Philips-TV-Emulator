#!/bin/sh
set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sdk=${ANDROID_SDK_ROOT:-"$HOME/Library/Android/sdk"}
backend="$sdk/emulator/lib64"
[ -f "$backend/libgfxstream_backend.dylib" ] || { echo 'Android Emulator SDK backend is required' >&2; exit 1; }
clang++ -std=c++17 -O2 -Wno-return-type-c-linkage -I"$here/include" "$here/host_renderer.cpp" -L"$backend" -lgfxstream_backend -Wl,-rpath,"$backend" -o "$here/host_renderer.new"
mv "$here/host_renderer.new" "$here/host_renderer"
