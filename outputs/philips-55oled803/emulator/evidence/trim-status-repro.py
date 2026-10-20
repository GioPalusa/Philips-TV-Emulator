#!/usr/bin/env python3
"""Qtest functional MSDC smoke test. Pass --image disk -- <QEMU and machine args>."""
from pathlib import Path
import argparse,hashlib,json,os,socket,struct,subprocess,tempfile,time

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--image',type=Path,required=True)
    ap.add_argument('--expect-fixed',action='store_true')
    ap.add_argument('--sector',type=int,default=0)
    ap.add_argument('--bench-blocks',type=int,default=0,help='Optional bounded read benchmark, 0..4096 sectors')
    ap.add_argument('--writes',action='store_true',help='Test writes only through an explicitly configured snapshot=on drive')
    ap.add_argument('qemu',nargs=argparse.REMAINDER)
    a=ap.parse_args();args=a.qemu
    if args and args[0]=='--':args=args[1:]
    if not 0 <= a.bench_blocks <= 4096: raise ValueError('Benchmark block limit is 4096')
    if a.writes and not any('snapshot=on' in arg for arg in args):
        raise ValueError('--writes requires snapshot=on in QEMU drive arguments')
    original_stat=a.image.stat()
    original_hash=hashlib.sha256(a.image.read_bytes()).hexdigest()
    base=0xf006d000
    with tempfile.TemporaryDirectory(prefix='msdc-qtest-') as tmp:
        sockpath=tmp+'/qtest.sock';stderr=open(tmp+'/stderr','w+')
        proc=subprocess.Popen(args+['-S','-display','none','-qtest',f'unix:{sockpath},server=on,wait=off'],stdout=subprocess.DEVNULL,stderr=stderr)
        try:
            sock=socket.socket(socket.AF_UNIX)
            for _ in range(100):
                try:sock.connect(sockpath);break
                except (FileNotFoundError,ConnectionRefusedError):
                    if proc.poll() is not None:raise RuntimeError('QEMU exited')
                    time.sleep(.05)
            f=sock.makefile('rwb',buffering=0)
            def q(s):
                f.write((s+'\n').encode())
                while True:
                    answer=f.readline().decode().strip()
                    if answer.startswith('IRQ'):continue
                    if not answer.startswith('OK'):raise RuntimeError((s,answer))
                    return answer.split()[1:]
            def wr(reg,val):q(f'writel {base+reg:#x} {val:#x}')
            def rd(reg):return int(q(f'readl {base+reg:#x}')[0],0)
            def cmd(op,arg=0,rsp=1,blocks=0,auto=0,writing=False):
                wr(0xc,0xffffffff);wr(0x38,arg);wr(0x50,blocks)
                ctrl=op|(rsp<<7)|(auto<<28)|(int(writing)<<13)
                if blocks:ctrl|=(512<<16)|((1 if blocks==1 else 2)<<11)
                wr(0x34,ctrl)
                assert rd(0xc)&0x100,(op,hex(rd(0xc)))
                assert not rd(0xc)&0x4200,(op,hex(rd(0xc)))
                return rd(0x40)
            def memwrite(addr,data):q(f'write {addr:#x} {len(data):#x} 0x{data.hex()}')
            def memread(addr,n):return bytes.fromhex(q(f'read {addr:#x} {n:#x}')[0].removeprefix('0x'))
            wr(0,0x8d);assert rd(0)&0x80 and not rd(0)&4
            cmd(0,rsp=0);ocr=cmd(1,0x40ff8000,rsp=3);assert ocr&0x80000000
            cmd(2,rsp=2);cid=[rd(r) for r in [0x4c,0x48,0x44,0x40]];assert any(cid)
            cmd(3,0x10000);cmd(9,0x10000,rsp=2);cmd(7,0x10000,rsp=7)
            evidence=[]
            for rejected in [35,36,38]:
                wr(0xc,0xffffffff);wr(0x38,0);wr(0x50,0)
                wr(0x34,rejected|(1<<7))
                command_status=rd(0xc); response=rd(0x40)
                assert command_status == (0x100 if a.expect_fixed else 0x4100)
                assert response&(1<<26)
                wr(0xc,0x100) # command polling acknowledges only command-ready
                left=rd(0xc)
                assert left == (0 if a.expect_fixed else 0x4000)
                wr(0x38,0);wr(0x50,2)
                wr(0x34,18|(1<<7)|(2<<11)|(512<<16)|(1<<28))
                wr(0xc,0x100)
                wr(0x90,0x100000);wr(0xa8,1024);wr(0x98,0x401)
                combined=rd(0xc)
                assert combined == (0x3008 if a.expect_fixed else 0x7008)
                with a.image.open('rb') as source:expected=source.read(1024)
                assert memread(0x100000,1024)==expected
                evidence.append({'rejected_command':rejected,'command_status':hex(command_status),'after_command_ack':hex(left),'next_successful_dma_status':hex(combined)})
            assert hashlib.sha256(a.image.read_bytes()).hexdigest()==original_hash
            assert a.image.stat().st_mtime_ns==original_stat.st_mtime_ns
            print(json.dumps({'result':'pass','expect_fixed':a.expect_fixed,'base_unchanged':True,'events':evidence},indent=2))
        finally:
            proc.terminate()
            try:proc.wait(timeout=3)
            except subprocess.TimeoutExpired:proc.kill();proc.wait()
            stderr.seek(0);output=stderr.read()
            if proc.returncode not in [0,-15]:print(output[-4000:])
if __name__=='__main__':main()
