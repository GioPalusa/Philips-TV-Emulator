#!/usr/bin/env python3
"""Build only the ARM32 broker in a staging directory; never repack a guest image."""
import argparse, hashlib, json, subprocess
from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument('--output-dir',type=Path,default=Path('work/philips-readiness'))
p.add_argument('--platform-dir',type=Path,default=Path('work/philips-software-gles'))
a=p.parse_args();out=a.output_dir.resolve();out.mkdir(parents=True,exist_ok=True)
platform=a.platform_dir.resolve();source=Path(__file__).with_name('hostgpu_broker.c').resolve()
clang='/opt/homebrew/opt/llvm/bin/clang';ld='/opt/homebrew/bin/arm-none-eabi-ld'
libgcc=Path(subprocess.check_output(['arm-none-eabi-gcc','-print-libgcc-file-name'],text=True).strip())
subprocess.run([clang,'--target=armv7a-linux-androideabi26','--sysroot='+str(platform/'sysroot'),'-isystem',str(platform/'sysroot/usr/include/asm-arm'),'-fPIE','-O2','-DANDROID','-Wall','-Wextra','-c',str(source),'-o',str(out/'hostgpu_broker.o')],check=True)
subprocess.run([ld,'-pie','-z','noexecstack','--dynamic-linker=/system/bin/linker','-e','_start','--no-undefined','--allow-shlib-undefined','-L'+str(platform/'sysroot/usr/lib'),str(platform/'sysroot/usr/lib/crtbegin_dynamic.o'),str(out/'hostgpu_broker.o'),'-lc',str(libgcc),str(platform/'sysroot/usr/lib/crtend_android.o'),'-o',str(out/'hostgpu_broker')],check=True)
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
evidence={'source_sha256':digest(source),'artifact_sha256':digest(out/'hostgpu_broker'),'size':(out/'hostgpu_broker').stat().st_size,'clang':subprocess.check_output([clang,'--version'],text=True).splitlines()[0],'linker':subprocess.check_output([ld,'--version'],text=True).splitlines()[0],'libgcc_sha256':digest(libgcc),'guest_image_modified':False}
(out/'broker-build.json').write_text(json.dumps(evidence,indent=2)+'\n');print(json.dumps(evidence,indent=2))
