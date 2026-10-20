#!/usr/bin/env python3
"""Qtest functional MSDC smoke test. Pass --image disk -- <QEMU and machine args>."""
from pathlib import Path
import argparse,json,os,socket,struct,subprocess,tempfile,time

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--image',type=Path,required=True)
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
            cmd(8,blocks=1)
            ext=b''.join(struct.pack('<I',rd(0x1c)) for _ in range(128))
            sectors=struct.unpack_from('<I',ext,212)[0];assert sectors==a.image.stat().st_size//512,(sectors,a.image.stat().st_size//512)
            assert rd(0xc)&0x1000
            with a.image.open('rb') as image:image.seek(a.sector*512);expected=image.read(1024)
            cmd(17,a.sector,blocks=1)
            pio=b''.join(struct.pack('<I',rd(0x1c)) for _ in range(128));assert pio==expected[:512]
            cmd(17,a.sector,blocks=1);wr(0x90,0x100000);wr(0xa8,512);wr(0x98,0x401)
            assert rd(0xc)&0x3000==0x3000;assert memread(0x100000,512)==expected[:512]
            def descriptor(flags,nxt,ptr,length):
                d=bytearray(struct.pack('<IIII',flags,nxt,ptr,length));d[1]=(0xff-sum(d))&255;return d
            memwrite(0x110000,descriptor(3,0x110020,0x111000,0))
            memwrite(0x111000,descriptor(0,0x111010,0x120000,512))
            memwrite(0x111010,descriptor(1,0,0x121000,512))
            cmd(18,a.sector,blocks=2,auto=1);wr(0x9c,2);wr(0x90,0x110000);wr(0x98,0x101)
            status=rd(0xc);assert status&0x3048==0x3048,hex(status)
            assert memread(0x120000,512)+memread(0x121000,512)==expected
            assert not struct.unpack('<I',memread(0x110000,4))[0]&1
            wr(0xc,status);assert rd(0xc)==0
            # BDs can split a card block or straddle its boundary. The bulk
            # card API must preserve stream position across these fragments.
            fragments=[1,510,3,510]
            def fragmented_transfer(writing, data=None):
                memwrite(0x110000,descriptor(3,0x110020,0x111000,0))
                offset=0
                for i,length in enumerate(fragments):
                    last=i==len(fragments)-1
                    memwrite(0x111000+i*16,descriptor(int(last),
                        0 if last else 0x111000+(i+1)*16,0x130000+i*0x1000,length))
                    if writing:memwrite(0x130000+i*0x1000,data[offset:offset+length])
                    offset+=length
                cmd(25 if writing else 18,a.sector,blocks=2,auto=1,writing=writing)
                wr(0x9c,2);wr(0x90,0x110000);wr(0x98,0x101)
                assert rd(0xc)&0x3048==0x3048,hex(rd(0xc))
                return b''.join(memread(0x130000+i*0x1000,n) for i,n in enumerate(fragments))
            assert fragmented_transfer(False)==expected
            # Explicit byte callbacks preserve the old PIO behavior in CMD18.
            cmd(18,a.sector,blocks=2,auto=1)
            byte_pio=bytes(int(q(f'readb {base+0x1c:#x}')[0],0) for _ in range(1024))
            assert byte_pio==expected and rd(0xc)&0x1000
            # Counted multiblock read must stop exactly after two sectors.
            cmd(18,a.sector,blocks=2,auto=2)
            wr(0xa8,1024);wr(0x90,0x140000);wr(0x98,0x401)
            assert memread(0x140000,1024)==expected
            assert rd(0xc)&0x3000==0x3000
            assert (cmd(13,0x10000)>>9)&15==4
            timings=[]
            if a.bench_blocks:
                count=a.bench_blocks*512
                with a.image.open('rb') as source:
                    source.seek(a.sector*512);benchmark_expected=source.read(count)
                assert len(benchmark_expected)==count
                for _ in range(3):
                    cmd(18,a.sector,blocks=a.bench_blocks,auto=1)
                    wr(0xa8,count);wr(0x90,0x200000)
                    begin=time.perf_counter();wr(0x98,0x401)
                    timings.append(round((time.perf_counter()-begin)*1000,3))
                    assert rd(0xc)&0x3000==0x3000
                    assert memread(0x200000,count)==benchmark_expected
            # A malformed BD must raise an error rather than claim transfer success.
            memwrite(0x110000,descriptor(3,0x110020,0x111000,0))
            bad=descriptor(1,0,0x120000,512);bad[1]^=1;memwrite(0x111000,bad)
            cmd(17,a.sector,blocks=1);wr(0x9c,2);wr(0x90,0x110000);wr(0x98,0x101)
            assert rd(0x9c)&0x10 and rd(0xc)&0x4000 and not rd(0xc)&0x1000
            cmd(12,rsp=7)
            more=[]
            if a.writes:
                def read_sector(sector):
                    cmd(17,sector,blocks=1)
                    return b''.join(struct.pack('<I',rd(0x1c)) for _ in range(128))
                pattern=bytes((i*17+31)&255 for i in range(512))
                cmd(24,a.sector,blocks=1,writing=True)
                for word in struct.unpack('<128I',pattern):wr(0x18,word)
                assert rd(0xc)&0x1000 and read_sector(a.sector)==pattern
                pattern=bytes((i*23+51)&255 for i in range(512))
                memwrite(0x120000,pattern)
                cmd(24,a.sector,blocks=1,writing=True);wr(0xa8,512);wr(0x90,0x120000);wr(0x98,0x401)
                assert rd(0xc)&0x3000==0x3000 and read_sector(a.sector)==pattern
                both=bytes((i*37+77)&255 for i in range(1024))
                memwrite(0x120000,both[:512]);memwrite(0x121000,both[512:])
                memwrite(0x110000,descriptor(3,0x110020,0x111000,0))
                memwrite(0x111000,descriptor(0,0x111010,0x120000,512))
                memwrite(0x111010,descriptor(1,0,0x121000,512))
                cmd(25,a.sector,blocks=2,auto=1,writing=True);wr(0x9c,2);wr(0x90,0x110000);wr(0x98,0x101)
                assert rd(0xc)&0x3048==0x3048
                assert read_sector(a.sector)+read_sector(a.sector+1)==both
                assert fragmented_transfer(True,both)==both
                assert read_sector(a.sector)+read_sector(a.sector+1)==both
                # Counted CMD25 retains the stop transition and overlay result.
                memwrite(0x140000,both)
                cmd(25,a.sector,blocks=2,auto=2,writing=True)
                wr(0xa8,1024);wr(0x90,0x140000);wr(0x98,0x401)
                assert rd(0xc)&0x3000==0x3000
                assert (cmd(13,0x10000)>>9)&15==4
                assert read_sector(a.sector)+read_sector(a.sector+1)==both
                # Opposite transfer direction is rejected before sending CMD24.
                wr(0xc,0xffffffff);wr(0x38,a.sector);wr(0x34,24|(1<<7)|(1<<11)|(512<<16))
                assert rd(0xc)&0x4000 and not rd(0xc)&0x1000
                # A final DMA buffer cannot overrun or underrun the command.
                for bad_len in [0,256,1024]:
                    cmd(24,a.sector,blocks=1,writing=True);wr(0xa8,bad_len);wr(0x90,0x120000);wr(0x98,0x401)
                    assert rd(0xc)&0x4000 and not rd(0xc)&0x1000
                    cmd(12,rsp=7)
                assert read_sector(a.sector)==both[:512]
                with a.image.open('rb') as original:original.seek(a.sector*512);assert original.read(1024)==expected
                assert a.image.stat().st_mtime_ns==original_stat.st_mtime_ns
                more=['PIO-overlay-write-readback','basic-DMA-overlay-write-readback','GPD-BD-overlay-write-readback','fragmented-BD-write-readback','counted-CMD25-stop-readback','wrong-direction-rejected','wrong-DMA-length-rejected','base-image-unchanged']
            else:
                # Default controller rejects media writes before forwarding.
                wr(0xc,0xffffffff);wr(0x38,a.sector);wr(0x34,24|(1<<7)|(1<<11)|(1<<13)|(512<<16))
                assert rd(0x40)&(1<<26) and rd(0xc)&0x4000
                more=['media-write-rejected']
            print(json.dumps({'status':'pass','card_sectors':sectors,'benchmark':{'bytes_per_transfer':a.bench_blocks*512,'dma_completion_host_ms':timings,'scope':'qtest MMIO trigger to synchronous DMA completion; not boot or FPS'},'tests':['card-init-CID-CSD','EXT_CSD-size','PIO-read','basic-DMA-read','GPD-BD-checksummed-multiblock-read','fragmented-BD-read','byte-PIO-CMD18','counted-CMD18-stop','auto-CMD12','GPD-ownership','interrupt-W1C','bad-descriptor-rejected']+more},indent=2))
        finally:
            proc.terminate()
            try:proc.wait(timeout=3)
            except subprocess.TimeoutExpired:proc.kill();proc.wait()
            stderr.seek(0);output=stderr.read()
            if proc.returncode not in [0,-15]:print(output[-4000:])
if __name__=='__main__':main()
