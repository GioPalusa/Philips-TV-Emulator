from pathlib import Path
import tarfile
import subprocess
p=Path(__file__).resolve().parent
libgcc=subprocess.check_output(['arm-none-eabi-gcc','-print-libgcc-file-name'],text=True).strip()
for name in ['cutils','sync','system','utils']:
 with tarfile.open(p/f'{name}-headers.tar.gz') as t:
  t.extractall(p/'platform',members=[x for x in t if x.isfile() or x.isdir()],filter='data')
src=p/'source'
f=src/'CMakeLists.txt'
with tarfile.open(p/'swiftshader.tar.gz') as archive:
 original=archive.extractfile('CMakeLists.txt').read().decode()
s=original.replace('cmake_minimum_required(VERSION 2.8)','cmake_minimum_required(VERSION 3.10)')
s=s.replace('if(ARCH EQUAL','if(ARCH STREQUAL')
s=s.replace('set(OS_LIBS dl pthread)', 'set(OS_LIBS '+str(p/'emutls.o')+' '+str(p/'cache_runtime.o')+' c++ c m dl log cutils hardware sync '+libgcc+')')
s=s.replace('list(REMOVE_ITEM SWIFTSHADER_LIST','list(APPEND SWIFTSHADER_LIST\n    ${SOURCE_DIR}/Main/FrameBufferAndroid.cpp\n)\nlist(APPEND SWIFTSHADER_LIST')
s=s.replace('${SUBZERO_LLVM_DIR}/build/Linux/include/','${SUBZERO_LLVM_DIR}/build/Android/include/')
s=s.replace('-Wl,--hash-style=both,--version-script=${DIR}/${TARGET}.lds,--gc-sections,--no-undefined', '--hash-style=both --version-script=${DIR}/${TARGET}.lds --gc-sections --no-undefined --allow-shlib-undefined')
s=s.replace('target_link_libraries(libEGL ${OS_LIBS})', 'target_sources(libEGL PRIVATE ${OPENGL_DIR}/common/Image.cpp)\n    target_link_libraries(libEGL SwiftShader ${Reactor} GLCompiler ${OS_LIBS})')
for name in ['FrameBufferX11.cpp','FrameBufferX11.hpp','libX11.cpp','libX11.hpp']:
 s=s.replace('    ${SOURCE_DIR}/Main/'+name, '    # Android: excludes '+name)
s += '\nset_target_properties(libEGL PROPERTIES OUTPUT_NAME libEGL_swiftshader)\nset_target_properties(libGLESv2 PROPERTIES OUTPUT_NAME libGLESv2_swiftshader)\nset_target_properties(libGLES_CM PROPERTIES OUTPUT_NAME libGLESv1_CM_swiftshader)\n'
f.write_text(s)
if not (p/'config.h').exists():
 (p/'config.h').write_text('#undef LOG_TAG\n#define LOG_TAG "SwiftShader"\n')
link=p/'platform/sync/sync.h'
if not link.exists(): link.symlink_to('../android/sync.h')
flags=f'--target=armv7a-linux-androideabi26 -march=armv7-a -mfloat-abi=softfp -mfpu=neon -DANDROID_PLATFORM_SDK_VERSION=26 -DHAVE_GRALLOC1 -include {p}/config.h -isystem {p}/sysroot/usr/include/asm-arm -I{p}/platform'
(p/'toolchain.cmake').write_text(f'''set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_SYSROOT "{p}/sysroot")
set(CMAKE_C_COMPILER /opt/homebrew/opt/llvm/bin/clang)
set(CMAKE_CXX_COMPILER /opt/homebrew/opt/llvm/bin/clang++)
set(CMAKE_AR /opt/homebrew/bin/arm-none-eabi-ar)
set(CMAKE_RANLIB /opt/homebrew/bin/arm-none-eabi-ranlib)
set(CMAKE_LINKER /opt/homebrew/bin/arm-none-eabi-ld)
set(CMAKE_C_FLAGS_INIT "{flags}")
set(CMAKE_CXX_FLAGS_INIT "{flags} -nostdinc++ -isystem {p}/libcxx")
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_SKIP_RPATH TRUE)
set(CMAKE_CXX_CREATE_SHARED_LIBRARY "<CMAKE_LINKER> --sysroot={p}/sysroot -shared -z noexecstack -soname <TARGET_SONAME> <LINK_FLAGS> {p}/sysroot/usr/lib/crtbegin_so.o <OBJECTS> -o <TARGET> -L{p}/sysroot/usr/lib <LINK_LIBRARIES> {p}/sysroot/usr/lib/crtend_so.o")
''')
