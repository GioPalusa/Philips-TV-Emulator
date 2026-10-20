#!/bin/sh
set -eu
src_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
java_dir=${PHILIPS_JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}
sdk_dir=${PHILIPS_ANDROID_SDK:-/Users/palusa/Library/Android/sdk}
build_dir=${PHILIPS_INPUT_BUILD_DIR:-"$src_dir/../../../../work/philips-input/build"}
mkdir -p "$build_dir/classes" "$build_dir/tests"
"$java_dir/bin/javac" --release 8 -Xlint:all,-options -Werror -d "$build_dir/tests" "$src_dir/BridgeProtocol.java" "$src_dir/ProtocolTest.java"
"$java_dir/bin/java" -cp "$build_dir/tests" tv.emulator.ProtocolTest
"$java_dir/bin/javac" --release 8 -Xlint:all,-options -Werror -cp "$sdk_dir/platforms/android-35/android.jar" -d "$build_dir/classes" "$src_dir/BridgeProtocol.java" "$src_dir/InputBridge.java"
"$java_dir/bin/jar" cf "$build_dir/classes.jar" -C "$build_dir/classes" .
"$java_dir/bin/java" -cp "$sdk_dir/build-tools/35.0.1/lib/d8.jar" com.android.tools.r8.D8 --release --min-api 26 --lib "$sdk_dir/platforms/android-35/android.jar" --output "$build_dir/philips-input.jar" "$build_dir/classes.jar"
cp "$build_dir/philips-input.jar" "$src_dir/philips-input.jar"
printf 'Built %s\n' "$src_dir/philips-input.jar"
