// Philips emulator host graphics bridge. Uses the installed Android Emulator SDK.
// Guest GLES is translated through gfxstream and ANGLE Metal; this is not Mali emulation.
#include <render-utils/render_api.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cerrno>
#include <atomic>
#include <mutex>
#include <thread>
#include <vector>
#include <chrono>
#include <string>
#include <algorithm>
#include <map>
struct FrameHeader {uint32_t magic,version,width,height,stride,format;uint64_t sequence,frameCount;uint8_t reserved[24];};
static_assert(sizeof(FrameHeader)==64);
struct Output {uint8_t* data;size_t size;std::mutex mutex;gfxstream::Renderer::ReadPixelsCallback readPixels;bool async;};
static std::atomic<uint64_t> nextUid{1};
static std::atomic<unsigned> clients{0};
// Optional passive command counting; never changes bytes or enables checksums.
struct StreamStats {
 std::mutex mutex;std::map<uint32_t,uint64_t> counts;uint64_t bytes=0;
 std::chrono::steady_clock::time_point start=std::chrono::steady_clock::now();
 void add(const std::map<uint32_t,uint64_t>& ops,size_t n){
  std::lock_guard<std::mutex>lock(mutex);bytes+=n;for(auto [op,count]:ops)counts[op]+=count;
  auto now=std::chrono::steady_clock::now();double elapsed=std::chrono::duration<double>(now-start).count();if(elapsed<5)return;
  fprintf(stderr,"HOSTGPU_STREAM seconds=%.3f bytes=%llu ops=",elapsed,bytes);
  for(auto [op,count]:counts)fprintf(stderr,"%u:%llu,",op,count);fprintf(stderr,"\n");fflush(stderr);
  counts.clear();bytes=0;start=now;
 }
} streamStats;
struct StreamObserver {
 bool enabled=getenv("PHILIPS_HOSTGPU_TRACE")!=nullptr;size_t remaining=4,used=0;uint8_t header[8];
 void feed(const char*p,size_t n){
  if(!enabled)return;size_t original=n;std::map<uint32_t,uint64_t>ops;
  while(n){if(remaining){size_t take=std::min(n,remaining);n-=take;p+=take;remaining-=take;continue;}
   size_t take=std::min(n,8-used);memcpy(header+used,p,take);used+=take;p+=take;n-=take;
   if(used==8){uint32_t op,len;memcpy(&op,header,4);memcpy(&len,header+4,4);if(len<8||len>256*1024*1024){enabled=false;fprintf(stderr,"HOSTGPU_TRACE invalid length=%u opcode=%u; observer disabled\n",len,op);return;}ops[op]++;remaining=len-8;used=0;}
  }streamStats.add(ops,original);
 }
};

static bool sendAll(int fd,const void*ptr,size_t n){auto*p=(const char*)ptr;while(n){ssize_t r=send(fd,p,n,0);if(r<0&&errno==EINTR)continue;if(r<=0)return false;p+=r;n-=r;}return true;}
static bool receiveAll(int fd,void*ptr,size_t n){auto*p=(char*)ptr;while(n){ssize_t r=recv(fd,p,n,0);if(r<0&&errno==EINTR)continue;if(r<=0)return false;p+=r;n-=r;}return true;}
static void onFrame(void*ctx,uint32_t display,int w,int h,int ydir,int format,int type,unsigned char*pixels){
 if(display||w!=1920||h!=1080||format!=0x1908||type!=0x1401)return;
 auto&o=*(Output*)ctx;std::lock_guard<std::mutex>guard(o.mutex);auto*hdr=(FrameHeader*)o.data;
 const bool separateReadback=o.async||!pixels;
 std::vector<uint8_t> asyncPixels;if(separateReadback){asyncPixels.resize(w*h*4);o.readPixels(asyncPixels.data(),asyncPixels.size(),display);pixels=asyncPixels.data();}
 // SDK 36.6.11 ANGLE Metal's posted async image is already top-down relative
 // to guest window coordinates (orientation_probe.py verifies four quadrants).
 // gfxstream doPostCallback hardcodes ydir=-1; it does not describe this
 // separate readback's observed orientation. Applying it again inverted the
 // shared frame, affecting both display and Ambilight. Keep callback row-order
 // handling for the synchronous path; SDK/backend changes need revalidation.
 const bool flipRows=!separateReadback&&ydir<0;
 if(!hdr->frameCount){fprintf(stderr,"HOSTGPU_ROW_ORDER async=%d separate=%d callback_ydir=%d flip=%d output=top-down\n",o.async,separateReadback,ydir,flipRows);fflush(stderr);}
 __atomic_add_fetch(&hdr->sequence,1,__ATOMIC_SEQ_CST);
 for(int y=0;y<h;y++)memcpy(o.data+64+y*w*4,pixels+(flipRows?h-y-1:y)*w*4,w*4);
 hdr->frameCount++;__atomic_add_fetch(&hdr->sequence,1,__ATOMIC_SEQ_CST);
 if(hdr->frameCount<=3||hdr->frameCount%300==0){fprintf(stderr,"HOSTGPU_FRAME %llu\n",hdr->frameCount);fflush(stderr);}
}
static void connection(int fd,gfxstream::RendererPtr renderer){
 struct Close {int fd;~Close(){close(fd);clients--;}}closeFd{fd};
 char name[128];size_t n=0;for(;n<sizeof(name);n++){if(!receiveAll(fd,name+n,1))return;if(!name[n])break;}if(n==sizeof(name))return;
 if(!strcmp(name,"pipe:GLProcessPipe")){
  uint32_t confirm;if(!receiveAll(fd,&confirm,4)||confirm!=100)return;uint64_t uid=nextUid++;renderer->onGuestGraphicsProcessCreate(uid);if(!sendAll(fd,&uid,8)){renderer->cleanupProcGLObjects(uid);return;}
  char dummy;while(recv(fd,&dummy,1,0)>0){}renderer->cleanupProcGLObjects(uid);return;
 }
 if(strcmp(name,"pipe:opengles")){fprintf(stderr,"unsupported service %s\n",name);return;}
 auto channel=renderer->createRenderChannel();if(!channel)return;
 StreamObserver observer;std::atomic<bool>done{false};std::thread rx([&](){while(!done){gfxstream::RenderChannel::Buffer b;auto r=channel->tryRead(&b);if(r==gfxstream::RenderChannel::IoResult::Ok){if(!sendAll(fd,b.data(),b.size()))break;}else if(r==gfxstream::RenderChannel::IoResult::Error)break;else channel->waitUntilReadable();}done=true;shutdown(fd,SHUT_RDWR);});
 while(!done){gfxstream::RenderChannel::Buffer b;b.resize(65536);ssize_t got=recv(fd,b.data(),b.size(),0);if(got<0&&errno==EINTR)continue;if(got<=0)break;b.resize(got);observer.feed(b.data(),b.size());for(;;){auto r=channel->tryWrite(std::move(b));if(r==gfxstream::RenderChannel::IoResult::Ok)break;if(r==gfxstream::RenderChannel::IoResult::Error){done=true;break;}channel->waitUntilWritable();}}
 done=true;channel->stop();shutdown(fd,SHUT_RDWR);rx.join();
}
int main(int argc,char**argv){
 const char*sockpath=nullptr,*framepath=nullptr;for(int i=1;i+1<argc;i+=2){if(!strcmp(argv[i],"--socket"))sockpath=argv[i+1];else if(!strcmp(argv[i],"--frame"))framepath=argv[i+1];else return 1;}
 if(!sockpath||!framepath){fprintf(stderr,"usage: %s --socket PATH --frame PATH\n",argv[0]);return 1;}
 signal(SIGPIPE,SIG_IGN);umask(0077);setenv("ANGLE_DEFAULT_PLATFORM","metal",1);
 int f=open(framepath,O_RDWR|O_CREAT|O_EXCL,0600);if(f<0){perror("create frame (must not exist)");return 2;}
 Output out;out.size=64+1920*1080*4;if(ftruncate(f,out.size)){perror("ftruncate");return 2;}out.data=(uint8_t*)mmap(nullptr,out.size,PROT_READ|PROT_WRITE,MAP_SHARED,f,0);close(f);if(out.data==MAP_FAILED)return 2;
 auto*h=(FrameHeader*)out.data;*h={0x55475048,1,1920,1080,1920*4,1,0,0,{0}};
 auto lib=gfxstream::initLibrary();lib->setRenderer(SELECTED_RENDERER_ANGLE_INDIRECT);lib->setGuestAndroidApiLevel(26);
 gfxstream::host::FeatureSet features;features.EglOnEgl.setEnabled(true);features.GlesDynamicVersion.setEnabled(true);
 auto renderer=lib->initRenderer(1920,1080,features,false);if(!renderer){fprintf(stderr,"renderer init failed\n");return 3;}out.readPixels=renderer->getReadPixelsCallback();out.async=renderer->asyncReadbackSupported();renderer->setPostCallback(onFrame,&out,false,0);
 auto hw=renderer->getHardwareStrings();fprintf(stderr,"HOSTGPU_RENDERER %s\n",hw.renderer.c_str());
 int listener=socket(AF_UNIX,SOCK_STREAM,0);sockaddr_un addr{};addr.sun_family=AF_UNIX;if(strlen(sockpath)>=sizeof(addr.sun_path))return 4;strcpy(addr.sun_path,sockpath);
 if(bind(listener,(sockaddr*)&addr,sizeof(addr))||listen(listener,64)){perror("listen");return 4;}fprintf(stderr,"HOSTGPU_READY %s\n",sockpath);fflush(stderr);
 for(;;){int fd=accept(listener,nullptr,nullptr);if(fd<0){if(errno==EINTR)continue;perror("accept");return 5;}if(clients.fetch_add(1)>=128){clients--;close(fd);continue;}std::thread(connection,fd,renderer).detach();}
}
