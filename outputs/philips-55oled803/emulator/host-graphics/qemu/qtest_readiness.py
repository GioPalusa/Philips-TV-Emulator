#!/usr/bin/env python3
"""Exercise actual QEMU transport with a synthetic host, including all 64 slots.

No guest Android or renderer is launched. Counts below measure control MMIO
transactions, not guest CPU load or Android performance.
"""
import argparse, json, os, pathlib, socket, subprocess, tempfile, time
p=argparse.ArgumentParser();p.add_argument('--binary',required=True);p.add_argument('--output',required=True);a=p.parse_args()
BASE=0xa1100000;DATA=0xa1000000
checks=[];peers=[];mmio=0
with tempfile.TemporaryDirectory(prefix='phgpu-ready-',dir='/tmp') as t:
    listener=socket.socket(socket.AF_UNIX);listener.bind(t+'/host');listener.listen(64);listener.settimeout(5)
    env=os.environ.copy();env['PHILIPS_HOSTGPU_SOCKET']=t+'/host'
    with open(t+'/log','wb') as log:
        proc=subprocess.Popen([a.binary,'-machine','virt,gic-version=2,highmem=off','-accel','qtest','-cpu','cortex-a53','-smp','4','-m','880M','-nodefaults','-nic','none','-display','none','-serial','none','-monitor','none','-qtest',f'unix:{t}/test,server=on,wait=off'],env=env,stdout=subprocess.DEVNULL,stderr=log)
        try:
            test=socket.socket(socket.AF_UNIX);test.settimeout(5)
            for _ in range(200):
                try:test.connect(t+'/test');break
                except (FileNotFoundError,ConnectionRefusedError):time.sleep(.01)
            f=test.makefile('rwb',buffering=0)
            def q(command):
                f.write((command+'\n').encode())
                while True:
                    line=f.readline().decode().strip()
                    if line.startswith('IRQ'):continue
                    assert line.startswith('OK'),(command,line)
                    return line.split()[1:]
            def wr(off,val):
                global mmio
                mmio+=1;q(f'writel {BASE+off:#x} {val & 0xffffffff:#x}')
            def rd(off):
                global mmio
                mmio+=1;return int(q(f'readl {BASE+off:#x}')[0],0)
            def put(data):q(f'write {DATA:#x} {len(data)} 0x{data.hex()}')
            def get(n):return bytes.fromhex(q(f'read {DATA:#x} {n}')[0][2:])
            def cmd(op,host=0,length=0):
                wr(8,host);wr(12,length);wr(0,op)
                status=rd(4);return (status if status<2**31 else status-2**32),rd(16)
            def snapshot():
                wr(0,5);assert rd(4)==0
                return rd(32)|(rd(36)<<32)
            assert rd(20)==0x50484750 and rd(24)==1024*1024 and rd(28)==0x10001
            assert snapshot()==0;checks.append('capability version and empty readiness')
            for i in range(64):
                greeting=b'pipe:opengles\0' if i<63 else b'pipe:GLProcessPipe\0'
                put(greeting);assert cmd(1,length=len(greeting))==(0,i+1)
                peer,_=listener.accept();peer.settimeout(5);assert peer.recv(64)==greeting;peers.append(peer)
            assert snapshot()==0;checks.append('64 open idle slots have zero readiness')
            # OP5 does not validate unrelated stale selectors/lengths or mutate payload.
            put(b'preserve');wr(8,999);wr(12,1024*1024+1);assert snapshot()==0 and get(8)==b'preserve'
            checks.append('snapshot ignores stale selector/length and preserves payload')
            for i,peer in enumerate(peers):peer.sendall(bytes([i,255-i,42,99]))
            assert snapshot()==0xffffffffffffffff;checks.append('all 64 readiness bits including bit63')
            for i in range(64):
                assert cmd(3,i+1,1)==(0,1) and get(1)==bytes([i])
            assert snapshot()==0xffffffffffffffff;checks.append('partial reads retain all ready bits')
            for i in range(64):
                assert cmd(3,i+1,8)==(0,3) and get(3)==bytes([255-i,42,99])
            assert snapshot()==0;checks.append('draining clears all readiness bits')
            # Legacy OPEN/WRITE/READ/CLOSE status and exact-byte behavior still work.
            put(b'legacy');assert cmd(2,64,6)==(0,6) and peers[63].recv(6)==b'legacy'
            assert cmd(3,1,64)==(-11,0)
            assert cmd(3,1,1024*1024+1)==(-22,0)
            assert cmd(99,1,0)==(-22,0)
            put(b'pipe:opengles\0');assert cmd(1,length=len(b'pipe:opengles\0'))==(-24,0)
            checks.append('legacy write, EAGAIN, invalid length/command, exhaustion')
            counts=[]
            for n in (1,8,32,64):
                loops=20;start=mmio
                for _ in range(loops):
                    for host in range(1,n+1):assert cmd(3,host,65536)==(-11,0)
                legacy=mmio-start;start=mmio
                for _ in range(loops):assert snapshot()==0
                optimized=mmio-start
                assert legacy==loops*n*5 and optimized==loops*4
                counts.append({'idle_connections':n,'iterations':loops,'before_control_mmio':legacy,'after_control_mmio':optimized,'before_host_commands':loops*n,'after_host_commands':loops,'control_mmio_reduction_percent':round(100*(1-optimized/legacy),2)})
            # HUP with pending bytes remains ready; consume data before EOF.
            peers[63].sendall(b'last');peers[63].close()
            assert snapshot()==1<<63
            assert cmd(3,64,8)==(0,4) and get(4)==b'last'
            assert snapshot()==1<<63 and cmd(3,64,8)==(0,0)
            assert cmd(4,64)==(0,0) and snapshot()==0
            checks.append('EOF readiness retains final bytes and clears after close')
            peers[0].close();assert snapshot()==1 and cmd(3,1,8)==(0,0)
            assert cmd(4,1)==(0,0) and snapshot()==0
            put(b'pipe:opengles\0');assert cmd(1,length=len(b'pipe:opengles\0'))==(0,1)
            peer,_=listener.accept();peer.settimeout(5);assert peer.recv(64)==b'pipe:opengles\0';peers.append(peer)
            assert snapshot()==0;peer.sendall(b'new');assert snapshot()==1
            assert cmd(3,1,8)==(0,3) and get(3)==b'new'
            checks.append('empty EOF and slot reuse')
            for slot in range(1,64):assert cmd(4,slot)==(0,0)
            assert snapshot()==0;checks.append('all closed readiness empty')
            result={'result':'PASS','origin':'Actual QEMU qtest and Unix streams','guest_android_executed':False,'checks':checks,'idle_poll_microbenchmark':counts,'measurement_limit':'Control-MMIO counts only; no live guest CPU or end-to-end latency claim.'}
            pathlib.Path(a.output).write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
        finally:
            for peer in peers:peer.close()
            listener.close();proc.terminate()
            try:proc.wait(timeout=5)
            except subprocess.TimeoutExpired:proc.kill();proc.wait()
