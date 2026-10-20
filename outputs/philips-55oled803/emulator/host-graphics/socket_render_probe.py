import socket,struct,time,mmap,json,argparse
p=argparse.ArgumentParser();p.add_argument('--socket',required=True);p.add_argument('--frame',required=True);a=p.parse_args()
s=socket.socket(socket.AF_UNIX);s.settimeout(5);s.connect(a.socket);s.sendall(b'pipe:opengles\0'+struct.pack('<I',0))
def read(n):
 b=b''
 while len(b)<n:
  d=s.recv(n-len(b))
  if not d:raise RuntimeError('renderer closed')
  b+=d
 return b
def call(op,args=(),response=0,payload=None):
 b=payload if payload is not None else struct.pack('<'+'I'*len(args),*args);s.sendall(struct.pack('<II',op,len(b)+8)+b)
 return struct.unpack('<'+'I'*(response//4),read(response)) if response else None
attrs=[0x3040,4,0x3024,8,0x3023,8,0x3022,8,0x3021,8,0x3038];raw=struct.pack('<'+'I'*len(attrs),*attrs)
r=call(10006,payload=struct.pack('<I',len(raw))+raw+struct.pack('<III',len(raw),4,1),response=8);cfg,count=r;assert count>0,r
ctx,=call(10008,[cfg,0,2],4);win,=call(10010,[cfg,1920,1080],4);color,=call(10012,[1920,1080,0x1908],4);call(10015,[win,color]);assert call(10017,[ctx,win,win],4)==(1,)
results=[]
with open(a.frame,'r+b') as f:
 mm=mmap.mmap(f.fileno(),0)
 for rgba in [(1.,0.,0.,1.),(0.,1.,0.,1.),(0.,0.,1.,1.)]:
  before=struct.unpack_from('<Q',mm,32)[0];start=time.perf_counter();call(2064,payload=struct.pack('<4f',*rgba));call(2063,[0x4000]);flushed=call(10016,[win],4);call(10018,[color]);call(10018,[color]);call(10018,[color]);call(10018,[color]);deadline=time.monotonic()+5
  while time.monotonic()<deadline:
   seq=struct.unpack_from('<Q',mm,24)[0];frame=struct.unpack_from('<Q',mm,32)[0]
   if frame>before and not seq%2 and list(mm[64+(540*1920+960)*4:64+(540*1920+960)*4+4])==[round(x*255) for x in rgba]:break
   call(10018,[color])
   time.sleep(.02)
  pixel=list(mm[64+(540*1920+960)*4:64+(540*1920+960)*4+4]);expected=[round(x*255) for x in rgba]
  results.append({'requested':expected,'actual':pixel,'flush':flushed,'frame':frame,'latency_ms':round((time.perf_counter()-start)*1000,3),'pass':pixel==expected and frame>before});assert results[-1]['pass'],results[-1]
 call(10017,[0,0,0],4);call(10011,[win]);call(10014,[color]);call(10009,[ctx])
print(json.dumps({'transport':'Unix socket → gfxstream → ANGLE Metal → RGBA mmap','results':results},indent=2))
