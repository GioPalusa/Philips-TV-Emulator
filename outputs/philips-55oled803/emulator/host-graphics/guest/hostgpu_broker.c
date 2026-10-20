/* Philips emulator-only host graphics transport broker. Never use on a TV.
 * Base protocol v1 plus optional readiness extension v1. One stream/client.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <sys/xattr.h>
#include <unistd.h>
#define DATA_PA 0xa1000000ULL
#define CTRL_PA 0xa1100000ULL
#define APERTURE_SIZE (1024*1024)
#define MAGIC 0x50484750u
#define CLIENTS 64
#define CHUNK 65536
#define ENDPOINT "/dev/socket/philips_hostgpu"
enum { CMD=0, STATUS=1, CONNECTION=2, LENGTH=3, RESULT=4, MAGIC_REG=5, CAPABILITIES=7, READY_LOW=8, READY_HIGH=9 };
enum { OP_OPEN=1, OP_WRITE=2, OP_READ=3, OP_CLOSE=4, OP_READINESS=5 };
typedef struct { int fd, host, handshake; size_t tx_len, tx_off, rx_len, rx_off; unsigned char tx[CHUNK], rx[CHUNK]; } Client;
static volatile uint32_t *ctrl;
static unsigned char *payload;
static volatile sig_atomic_t stopping;
static void stop(int sig) { (void)sig; stopping=1; }
static void barrier(void) { __sync_synchronize(); }
static int command(int op,int host,const void *input,size_t len,void *output) {
    if (len>APERTURE_SIZE) return -EMSGSIZE;
    if (input && len) memcpy(payload,input,len);
    ctrl[CONNECTION]=(uint32_t)host;
    ctrl[LENGTH]=(uint32_t)len;
    barrier(); ctrl[CMD]=(uint32_t)op; barrier();
    int status=(int32_t)ctrl[STATUS], result=(int32_t)ctrl[RESULT];
    if (status<0) return status;
    if (status!=0) return -EPROTO;
    if (output && result>0) {
        if ((size_t)result>len) return -EPROTO;
        memcpy(output,payload,(size_t)result);
    }
    return result;
}
static void close_client(Client *c) {
    if(c->host>=0) command(OP_CLOSE,c->host,NULL,0,NULL);
    if(c->fd>=0) close(c->fd);
    memset(c,0,sizeof(*c)); c->fd=c->host=-1;
}
/* Snapshot after all queued writes so newly available replies can be read in
 * this iteration. A failed optional query falls back to legacy reads, never
 * suppressing data or EOF. The next iteration retries the snapshot.
 */
static uint64_t host_readiness(int supported) {
    if(!supported)return UINT64_MAX;
    barrier();ctrl[CMD]=OP_READINESS;barrier();
    if((int32_t)ctrl[STATUS]!=0)return UINT64_MAX;
    uint32_t low=ctrl[READY_LOW],high=ctrl[READY_HIGH];
    return (uint64_t)low|((uint64_t)high<<32);
}
static int would_block(int n) { return n==-EAGAIN || n==-EWOULDBLOCK || n==-EINPROGRESS; }
/* Preserve pending replies across backpressure. Even a host EOF readiness bit
 * must not trigger another READ until all previously received bytes are sent.
 */
static void service_host_reply(Client *c,uint64_t readable) {
    if(c->rx_off==c->rx_len && (readable&(UINT64_C(1)<<(c->host-1)))) {
        c->rx_off=c->rx_len=0;
        int n=command(OP_READ,c->host,NULL,CHUNK,c->rx);
        if(n>0)c->rx_len=(size_t)n;
        else if(!would_block(n)) {close_client(c);return;}
    }
    if(c->rx_len>c->rx_off) {
        ssize_t n=send(c->fd,c->rx+c->rx_off,c->rx_len-c->rx_off,MSG_DONTWAIT|MSG_NOSIGNAL);
        if(n>0)c->rx_off+=(size_t)n;
        else if(n==0 || (errno!=EAGAIN && errno!=EINTR))close_client(c);
    }
}
int main(int argc, char **argv) {
    int probe = argc == 2 && !strcmp(argv[1], "--probe");
    if(argc > 1 && !probe) {fprintf(stderr,"usage: hostgpu_broker [--probe]\n");return 2;}
    setvbuf(stderr,NULL,_IONBF,0);
    int mem=-1;
    for(int attempt=0;attempt<(probe?1:300);attempt++) {
        mem=open("/dev/rmmgr",O_RDWR|O_SYNC|O_CLOEXEC);
        if(mem>=0 || (errno!=ENOENT && errno!=ENODEV && errno!=ENXIO))break;
        usleep(100000);
    }
    if(mem<0) { perror("hostgpu /dev/rmmgr"); return 1; }
    ctrl=mmap64(NULL,4096,PROT_READ|PROT_WRITE,MAP_SHARED,mem,CTRL_PA);
    if(ctrl==MAP_FAILED) { perror("hostgpu control mmap"); close(mem); return 1; }
    /* Read before issuing any command: reject physical hardware / other boards. */
    if(ctrl[MAGIC_REG]!=MAGIC) { fprintf(stderr,"hostgpu: emulator device absent\n"); munmap((void*)ctrl,4096); close(mem); return 1; }
    uint32_t capabilities=ctrl[CAPABILITIES];
    int readiness_supported=(capabilities>>16)==1 && (capabilities&1);
    if(probe) {fprintf(stderr,"HOSTGPU_PROBE PASS magic=%08x PA=%llx\n",ctrl[MAGIC_REG],CTRL_PA);munmap((void*)ctrl,4096);close(mem);return 0;}
    payload=mmap64(NULL,APERTURE_SIZE,PROT_READ|PROT_WRITE,MAP_SHARED,mem,DATA_PA);
    close(mem);
    if(payload==MAP_FAILED) { perror("hostgpu payload mmap"); munmap((void*)ctrl,4096); return 1; }
    int listener=-1, inherited=0;
    const char *inherited_fd=getenv("ANDROID_SOCKET_philips_hostgpu");
    if(inherited_fd) {
        char *end=NULL; long fd=strtol(inherited_fd,&end,10);
        struct stat st;
        if(!*inherited_fd || *end || fd<0 || fd>65535 || fstat((int)fd,&st) || !S_ISSOCK(st.st_mode)) {fprintf(stderr,"hostgpu invalid init socket\n");return 1;}
        listener=(int)fd; inherited=1;
        fcntl(listener,F_SETFD,FD_CLOEXEC);
        int flags=fcntl(listener,F_GETFL);
        if(flags<0 || fcntl(listener,F_SETFL,flags|O_NONBLOCK)<0){perror("hostgpu nonblock");return 1;}
    } else {
        listener=socket(AF_UNIX,SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK,0);
        if(listener<0) { perror("hostgpu socket"); return 1; }
        struct sockaddr_un addr; memset(&addr,0,sizeof(addr)); addr.sun_family=AF_UNIX; strcpy(addr.sun_path,ENDPOINT);
        /* Never unlink an existing socket: a second broker must fail safely. */
        if(bind(listener,(struct sockaddr*)&addr,sizeof(addr)) || chmod(ENDPOINT,0666)) { perror("hostgpu bind"); close(listener); return 1; }
    }
    const char label[]="u:object_r:pdx_display_client_endpoint_socket:s0";
    if(lsetxattr(ENDPOINT,"security.selinux",label,sizeof(label),0)) {perror("hostgpu socket label");close(listener);return 1;}
    if(listen(listener,64)) {perror("hostgpu listen");close(listener);return 1;}
    signal(SIGTERM,stop); signal(SIGINT,stop); signal(SIGPIPE,SIG_IGN);
    Client *clients=calloc(CLIENTS,sizeof(*clients));
    if(!clients) { close(listener); if(!inherited)unlink(ENDPOINT); return 1; }
    for(int i=0;i<CLIENTS;i++) clients[i].fd=clients[i].host=-1;
    fprintf(stderr,"hostgpu: ready, nonblocking v1 readiness=%d payload=%llx ctrl=%llx\n",readiness_supported,DATA_PA,CTRL_PA);
    while(!stopping) {
        struct pollfd fds[CLIENTS+1]; int active=0;
        fds[0]=(struct pollfd){listener,POLLIN,0};
        for(int i=0;i<CLIENTS;i++) {
            Client *c=&clients[i]; short events=0;
            if(c->fd>=0) {active++; if(c->tx_len<CHUNK) events|=POLLIN; if(c->rx_len>c->rx_off) events|=POLLOUT;}
            fds[i+1]=(struct pollfd){c->fd,events,0};
        }
        int ready=poll(fds,CLIENTS+1,active?4:100);
        if(ready<0) { if(errno==EINTR) continue; perror("hostgpu poll"); break; }
        if(fds[0].revents&POLLIN) {
            int fd=accept4(listener,NULL,NULL,SOCK_CLOEXEC|SOCK_NONBLOCK);
            if(fd>=0) { int i; for(i=0;i<CLIENTS;i++) if(clients[i].fd<0) {clients[i].fd=fd;break;} if(i==CLIENTS)close(fd); }
        }
        for(int i=0;i<CLIENTS;i++) {
            Client *c=&clients[i]; if(c->fd<0)continue;
            if(fds[i+1].revents&(POLLERR|POLLHUP|POLLNVAL)) {close_client(c);continue;}
            if((fds[i+1].revents&POLLIN) && c->tx_len<CHUNK) {
                ssize_t n=recv(c->fd,c->tx+c->tx_len,CHUNK-c->tx_len,MSG_DONTWAIT);
                if(n>0)c->tx_len+=(size_t)n;
                else if(n==0 || (errno!=EAGAIN && errno!=EINTR)) {close_client(c);continue;}
            }
            if(c->host<0) {
                unsigned char *end=memchr(c->tx,0,c->tx_len);
                if(!end) {if(c->tx_len>=256)close_client(c);continue;}
                size_t n=(size_t)(end-c->tx)+1;
                if(strcmp((char*)c->tx,"pipe:opengles") && strcmp((char*)c->tx,"pipe:GLProcessPipe")) {close_client(c);continue;}
                int host=command(OP_OPEN,0,c->tx,n,NULL);
                if(would_block(host))continue;
                if(host<1 || host>CLIENTS) {fprintf(stderr,"hostgpu open failed %d\n",host);close_client(c);continue;}
                c->host=host; c->tx_off=n;
            }
            if(c->tx_len>c->tx_off) {
                int n=command(OP_WRITE,c->host,c->tx+c->tx_off,c->tx_len-c->tx_off,NULL);
                if(n>0 && (size_t)n<=c->tx_len-c->tx_off)c->tx_off+=(size_t)n;
                else if(!would_block(n)) {close_client(c);continue;}
            }
            if(c->tx_off==c->tx_len)c->tx_off=c->tx_len=0;
        }
        uint64_t readable=host_readiness(readiness_supported);
        for(int i=0;i<CLIENTS;i++) {
            Client *c=&clients[i];if(c->fd<0||c->host<1)continue;
            service_host_reply(c,readable);
        }
    }
    for(int i=0;i<CLIENTS;i++)close_client(&clients[i]);
    free(clients); close(listener); if(!inherited)unlink(ENDPOINT);
    munmap(payload,APERTURE_SIZE); munmap((void*)ctrl,4096);
    return 0;
}
