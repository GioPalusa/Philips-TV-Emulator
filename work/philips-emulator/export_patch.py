#!/usr/bin/env python3
"""Export all emulator source changes against the pinned upstream tarball."""
from pathlib import Path
import difflib, tarfile
root=Path(__file__).resolve().parents[2]
work=root/'work/philips-emulator'
src=work/'qemu-11.1.2'
files=['hw/arm/virt.c','hw/arm/philips-mmio-trace.h','hw/arm/philips-hostgpu.inc','hw/arm/philips-hostgpu-frame.inc','hw/sd/meson.build','hw/sd/sd.c','hw/sd/mt5891-msdc.c',
       'hw/arm/philips-smp.inc','hw/arm/philips-timer.inc','hw/arm/philips-pdwnc.inc','hw/arm/philips-rtc.inc','hw/arm/philips-ts130.inc','hw/arm/philips-ts130-smc.inc',
       'hw/arm/philips-gfx.inc','hw/arm/philips-aproc.inc',
       'hw/arm/philips-servoadc.inc','hw/arm/philips-demux.inc',
       'hw/arm/philips-osd.inc',
       'hw/arm/mt5891_ambilight_spi.h','hw/arm/mt5891_ambilight_spi.inc',
       'hw/arm/mt5891_ambilight_measure.h','hw/arm/mt5891_ambilight_measure.c',
       'hw/arm/mt5891_ambilight_measure.inc',
       'hw/arm/philips-ambilight-framebuffer.inc',
       'hw/arm/mt5891_ambilight_framebuffer.h','hw/arm/mt5891_ambilight_framebuffer.c',
       'target/arm/cpu.h','target/arm/helper.c','target/arm/tcg/op_helper.c',
       'target/arm/gt24.h']
patch=[]
with tarfile.open(work/'qemu-11.1.2.tar.xz') as archive:
 for name in files:
  try:
   original=archive.extractfile('qemu-11.1.2/'+name).read().decode().splitlines(True)
   old='a/'+name
  except KeyError:
   original=[];old='/dev/null'
  current=(src/name).read_text().splitlines(True)
  patch.extend(difflib.unified_diff(original,current,fromfile=old,tofile='b/'+name))
path=root/'outputs/philips-55oled803/emulator/qemu-11.1.2-55oled803.patch'
path.write_text(''.join(patch))
print(f'Exported {len(files)} source files, {path.stat().st_size:,} bytes')
