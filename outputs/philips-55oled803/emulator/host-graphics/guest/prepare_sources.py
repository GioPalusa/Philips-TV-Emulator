#!/usr/bin/env python3
"""Fetch pinned public source archives, apply the socket transport, stage build inputs."""
from pathlib import Path
import hashlib,json,os,shutil,subprocess,tarfile,urllib.request
here=Path(__file__).resolve().parent
work=Path(os.environ.get('PHILIPS_GUEST_GPU_WORK',Path.cwd()/'work/philips-guest-gpu')).resolve()
work.mkdir(parents=True,exist_ok=True)
manifest=json.loads((here/'manifest.json').read_text())
for name,item in manifest['sources'].items():
    archive=work/name
    if not archive.exists():
        with urllib.request.urlopen(item['url']) as response: archive.write_bytes(response.read())
    if hashlib.sha256(archive.read_bytes()).hexdigest()!=item['sha256']: raise SystemExit(f'Archive hash mismatch: {name}')
    target=work/('source' if name.startswith('goldfish') else 'include')
    target.mkdir(exist_ok=True)
    with tarfile.open(archive) as tar:
        tar.extractall(target,members=[m for m in tar if m.isfile() or m.isdir()],filter='data')
for name in ['unix-socket-transport.patch','egl-client-state-order.patch']:
    subprocess.run(['patch','-p1','-i',str(here/name)],cwd=work/'source',check=True)
for name in ['hostgpu_broker.c','render_test.c']:shutil.copy2(here/name,work/name)
print(f'Prepared public Android8 source in {work}')
