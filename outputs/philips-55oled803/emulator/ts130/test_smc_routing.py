import os,subprocess,time,select,json,tempfile
from pathlib import Path
import argparse
a=argparse.ArgumentParser();a.add_argument("--binary",type=Path,default=Path("outputs/philips-55oled803/emulator/qemu-system-aarch64-55oled803"));a=a.parse_args()
qemu=a.binary.resolve()
scratch=Path("work/philips-smc");scratch.mkdir(parents=True,exist_ok=True)
source=Path(__file__).with_name("smc_route.S").resolve()
subprocess.run(["arm-none-eabi-as",str(source),"-o",str(scratch/"smc_route.o")],check=True)
elf=(scratch/"smc_route.elf").resolve()
subprocess.run(["arm-none-eabi-ld","-Ttext=0x40010000","-e","_start",str(scratch/"smc_route.o"),"-o",str(elf)],check=True)
records=[]
for enabled in (False,True):
 env=dict(os.environ);env.pop('PHILIPS_TS130_CONTROL',None)
 if enabled:env['PHILIPS_TS130_CONTROL']='1'
 with tempfile.TemporaryDirectory(dir='work/philips-smc') as tmp:
  with (Path(tmp)/'stderr').open('w+') as log:
   p=subprocess.Popen([str(qemu),'-accel','tcg','-machine','virt,gic-version=2,highmem=off,virtualization=on','-cpu','cortex-a53,aarch64=off','-smp','1','-m','880M','-nodefaults','-display','none','-nic','none','-serial','none','-monitor','none','-kernel',str(elf),'-qtest','stdio','-qtest-log','/dev/null'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=log,env=env)
   try:
    deadline=time.monotonic()+10
    while time.monotonic()<deadline:
     p.stdin.write(b'read 0x40020000 32\n');p.stdin.flush()
     if not select.select([p.stdout],[],[],2)[0]:raise RuntimeError('qtest timed out')
     line=p.stdout.readline().decode().strip();assert line.startswith('OK '),line
     b=bytes.fromhex(line[3:].removeprefix('0x'));words=[int.from_bytes(b[i:i+4],'little') for i in range(0,len(b),4)]
     if words[-1]==0x53544350:break
     time.sleep(.02)
    else:raise RuntimeError('ARM route marker missing '+str(words))
    expected=[10,0,0,0,10,0xffffffff,0x10001] if enabled else [0xffffffff]*6+[0x10001]
    assert words[:-1]==expected,(enabled,words,expected)
    log.flush();log.seek(0);records.append({'enabled':enabled,'results':words[:-1],'expected':expected,'passed':True,'log':log.read()[-2000:]})
   finally:p.terminate();p.wait(timeout=5)
Path('outputs/philips-55oled803/emulator/ts130/smc-routing-test.json').write_text(json.dumps({'schema':'philips-ts130-arm-smc-route-v1','origin':'Actual ARM SMC instructions in an independent bare-metal QEMU guest','records':records},indent=2)+'\n')
print(json.dumps(records,indent=2))
