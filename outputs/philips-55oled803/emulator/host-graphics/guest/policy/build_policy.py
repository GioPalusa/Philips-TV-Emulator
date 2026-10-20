#!/usr/bin/env python3
"""Reproduce the exact scoped host-graphics additions from the existing JIT policy."""
from pathlib import Path
import argparse,hashlib,json,subprocess,tarfile,tempfile
p=argparse.ArgumentParser();p.add_argument('input',type=Path);p.add_argument('output',type=Path);p.add_argument('--work-dir',type=Path,default=Path('work/philips-hostgpu-policy-rebuild'));a=p.parse_args()
here=Path(__file__).resolve().parent;manifest=json.loads((here/'manifest.json').read_text())
if a.output.exists():raise SystemExit('Output exists')
if hashlib.sha256(a.input.read_bytes()).hexdigest()!=manifest['input_sha256']:raise SystemExit('Input differs from verified base graphics policy')
a.work_dir.mkdir(parents=True,exist_ok=True)
# The existing software renderer's public libsepol source bundle is reused.
archive=here.parents[2]/'software-graphics/policy/libsepol-3.6.tar.gz'
with tempfile.TemporaryDirectory(dir=a.work_dir) as tmp:
 t=Path(tmp).resolve()
 with tarfile.open(archive) as tar:tar.extractall(t,filter='data')
 lib=t/'libsepol-3.6'
 subprocess.run(['make','-C',str(lib/'src'),'DISABLE_CIL=y','CFLAGS=-O2','libsepol.a','-j8'],check=True)
 tool=t/'allow_hostgpu'
 subprocess.run(['cc','-O2','-I'+str(lib/'include'),str(here/'allow_hostgpu.c'),str(lib/'src/libsepol.a'),'-o',str(tool)],check=True)
 source=a.input.resolve()
 for index,line in enumerate((here/'rules.txt').read_text().splitlines()):
  _,src,tc,perm=line.rstrip(';').split();tgt,cls=tc.split(':')
  target=t/f'policy-{index}'
  subprocess.run([str(tool),str(source),str(target),src,tgt,cls,perm],check=True)
  source=target
 output=source.read_bytes()
 if hashlib.sha256(output).hexdigest()!=manifest['output_sha256']:raise SystemExit('Output hash differs from verified artifact')
 a.output.write_bytes(output)
print('PASS: exact host graphics policy reproduced')
