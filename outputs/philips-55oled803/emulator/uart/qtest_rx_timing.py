#!/usr/bin/env python3
"""Actual UART device/character socket test. qtest clock walks each deadline."""
import argparse,json,os,socket,subprocess,tempfile,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--binary',required=True);a=p.parse_args()
with tempfile.TemporaryDirectory(prefix='phuart-',dir='/tmp') as t:
    log=open(t+'/log','wb')
    proc=subprocess.Popen([a.binary,'-machine','virt,gic-version=2,highmem=off','-accel','qtest','-cpu','cortex-a53','-smp','4','-m','880M','-nodefaults','-nic','none','-display','none','-serial','none','-monitor','none','-qtest',f'unix:{t}/test,server=on,wait=off','-chardev',f'socket,id=tv-console,path={t}/console,server=on,wait=off'],stdout=subprocess.DEVNULL,stderr=log)
    def connect(path):
        s=socket.socket(socket.AF_UNIX);s.settimeout(5)
        for _ in range(100):
            try:s.connect(path);return s
            except (FileNotFoundError,ConnectionRefusedError):time.sleep(.01)
        raise TimeoutError(path)
    try:
        test=connect(t+'/test');console=connect(t+'/console');f=test.makefile('rwb',buffering=0)
        def q(command):
            f.write((command+'\n').encode())
            while True:
                line=f.readline().decode().strip()
                if line.startswith('IRQ'):continue
                assert line.startswith('OK'),(command,line)
                return line.split()[1:]
        def wr(off,val):q(f'writel {0xf000c000+off:#x} {val:#x}')
        def rd(off):return int(q(f'readl {0xf000c000+off:#x}')[0],0)
        def count():return rd(0x4c)&0x1f
        def step(ns):return int(q(f'clock_step {ns}')[0])
        wr(4,0x40);wr(12,(1<<17)|(1<<18))
        payload=bytes(range(31));console.sendall(payload)
        # Let the backend accept the host burst; virtual qtest time stays zero.
        time.sleep(.03);assert count()==0
        t1=step(86805);assert count()==0
        t2=step(1);assert count()==1
        t3=step(1000000-86806);assert count()==11
        t4=step(2000000);assert count()==31
        assert bytes(rd(0) for _ in range(31))==payload
        assert count()==0
        # FIFO-disabled mode admits one byte and pauses line scheduling until read.
        wr(4,0);console.sendall(b'AB');time.sleep(.03)
        step(1000000);assert count()==1 and rd(0)==65
        assert count()==0;step(86805);assert count()==0
        step(1);assert count()==1 and rd(0)==66
        print(json.dumps({'result':'pass','clock_semantics':'Each intermediate timer deadline is visited; not a delayed-dispatch test','fifo_counts':{'86805ns':0,'86806ns':1,'1000000ns':11,'3000000ns':31},'byte_order':'pass','fifo_disabled_backpressure':'pass'},indent=2))
    finally:
        proc.terminate();proc.wait(timeout=5);log.close()
