#!/usr/bin/env python3
from pathlib import Path
import subprocess, concurrent.futures, os
H=Path(os.environ.get('PHILIPS_GUEST_GPU_WORK',Path.cwd()/'work/philips-guest-gpu')).resolve(); S=H/'source'; D=H.parent/'philips-software-gles'; B=H/'build'; B.mkdir(exist_ok=True)
clang='/opt/homebrew/opt/llvm/bin/clang++'; ld='/opt/homebrew/bin/arm-none-eabi-ld'
incs=[S/'system/include',S/'host/include/libOpenglRender',S/'shared/OpenglCodecCommon',D/'platform',H/'include']+[p for p in (S/'system').iterdir() if p.is_dir()]
flags=['--target=armv7a-linux-androideabi26','--sysroot='+str(D/'sysroot'),'-isystem',str(D/'sysroot/usr/include/asm-arm'),'-nostdinc++','-isystem',str(D/'libcxx'),'-fPIC','-fno-rtti','-fno-exceptions','-O2','-std=c++11','-DANDROID','-DWITH_GLES2','-DPLATFORM_SDK_VERSION=26','-DGOLDFISH_HIDL_GRALLOC','-DEGL_EGLEXT_PROTOTYPES','-DGL_GLEXT_PROTOTYPES','-Wno-deprecated-declarations']+['-I'+str(x) for x in incs]
groups={
'OpenglCodecCommon':('shared/OpenglCodecCommon',['GLClientState','GLESTextureUtils','ChecksumCalculator','GLSharedGroup','glUtils','IndexRangeCache','SocketStream','TcpStream']),
'GLESv1_enc':('system/GLESv1_enc',['gl_client_context','gl_enc','GLEncoder','GLEncoderUtils','gl_entry']),
'GLESv2_enc':('system/GLESv2_enc',['GL2EncoderUtils','GL2Encoder','GLESv2Validation','gl2_client_context','gl2_enc','gl2_entry']),
'_renderControl_enc':('system/renderControl_enc',['renderControl_client_context','renderControl_enc','renderControl_entry']),
'OpenglSystemCommon':('system/OpenglSystemCommon',['goldfish_dma','goldfishHwc2','FormatConversions','HostConnection','ProcessPipe','QemuPipeStream','ThreadInfo']),
'GLESv1_CM_emulation':('system/GLESv1',['gl']),
'GLESv2_emulation':('system/GLESv2',['gl2']),
'EGL_emulation':('system/egl',['eglDisplay','egl','ClientAPIExts']),
'gralloc.goldfish':('system/gralloc',['gralloc']),
}
libgcc=subprocess.check_output(['arm-none-eabi-gcc','-print-libgcc-file-name'],text=True).strip()
for name,(folder,files) in groups.items():
    objects=[B/(name+'-'+f+'.o') for f in files]
    def compile(pair):
        f,o=pair; subprocess.run([clang,*flags,'-c',str(S/folder/(f+'.cpp')),'-o',str(o)],check=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool: list(pool.map(compile,zip(files,objects)))
    if name=='OpenglCodecCommon':
        subprocess.run(['arm-none-eabi-ar','rcs',str(B/'libOpenglCodecCommon.a'),*map(str,objects)],check=True); continue
    deps=['-lOpenglCodecCommon','-lc++','-lcutils','-lutils','-llog','-lc','-ldl','-lm']
    if name not in ('GLESv1_enc','GLESv2_enc','_renderControl_enc'): deps+=['-lGLESv1_enc','-lGLESv2_enc','-l_renderControl_enc']
    if name not in ('GLESv1_enc','GLESv2_enc','_renderControl_enc','OpenglSystemCommon'): deps+=['-lOpenglSystemCommon','-lsync','-lhardware','-lnativewindow']
    out=('' if name.startswith('gralloc.') else 'lib')+name+'.so'
    subprocess.run([ld,'-shared','-z','noexecstack','--no-undefined','--allow-shlib-undefined','-soname',out,'-L'+str(B),'-L'+str(D/'sysroot/usr/lib'),str(D/'sysroot/usr/lib/crtbegin_so.o'),*map(str,objects),*deps,libgcc,str(D/'sysroot/usr/lib/crtend_so.o'),'-o',str(B/out)],check=True)

cflags=[f for f in flags if f not in ['-std=c++11','-fno-rtti','-fno-exceptions','-nostdinc++']]
subprocess.run(['/opt/homebrew/opt/llvm/bin/clang',*cflags,'-fPIE','-c',str(H/'render_test.c'),'-o',str(B/'render_test.o')],check=True)
subprocess.run([ld,'-pie','-z','noexecstack','--dynamic-linker=/system/bin/linker','-e','_start','--no-undefined','--allow-shlib-undefined','-L'+str(B),'-L'+str(D/'sysroot/usr/lib'),str(D/'sysroot/usr/lib/crtbegin_dynamic.o'),str(B/'render_test.o'),'-lEGL_emulation','-lGLESv2_emulation','-lc','-ldl','-lm',libgcc,str(D/'sysroot/usr/lib/crtend_android.o'),'-o',str(B/'hostgpu_render_test')],check=True)

subprocess.run(['/opt/homebrew/opt/llvm/bin/clang',*cflags,'-fPIE','-c',str(H/'hostgpu_broker.c'),'-o',str(B/'hostgpu_broker.o')],check=True)
subprocess.run([ld,'-pie','-z','noexecstack','--dynamic-linker=/system/bin/linker','-e','_start','--no-undefined','--allow-shlib-undefined','-L'+str(D/'sysroot/usr/lib'),str(D/'sysroot/usr/lib/crtbegin_dynamic.o'),str(B/'hostgpu_broker.o'),'-lc',libgcc,str(D/'sysroot/usr/lib/crtend_android.o'),'-o',str(B/'hostgpu_broker')],check=True)
