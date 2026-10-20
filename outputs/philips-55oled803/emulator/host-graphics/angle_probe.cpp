#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <dlfcn.h>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <chrono>
#include <algorithm>
#define FN(ret,name,args) auto name=(ret (*)args)dlsym(lib,#name); if(!name){fprintf(stderr,"missing %s\n",#name);return 2;}
int main(int argc,char**argv){
 const char* base=argc>1?argv[1]:"/Users/palusa/Library/Android/sdk/emulator/lib64/gles_angle";
 char path[4096]; snprintf(path,sizeof(path),"%s/libEGL.dylib",base); void* lib=dlopen(path,RTLD_NOW|RTLD_LOCAL); if(!lib){fprintf(stderr,"%s\n",dlerror());return 1;}
 FN(void*,eglGetProcAddress,(const char*)); FN(EGLBoolean,eglInitialize,(EGLDisplay,EGLint*,EGLint*)); FN(EGLint,eglGetError,(void)); FN(EGLBoolean,eglChooseConfig,(EGLDisplay,const EGLint*,EGLConfig*,EGLint,EGLint*)); FN(EGLSurface,eglCreatePbufferSurface,(EGLDisplay,EGLConfig,const EGLint*)); FN(EGLContext,eglCreateContext,(EGLDisplay,EGLConfig,EGLContext,const EGLint*)); FN(EGLBoolean,eglMakeCurrent,(EGLDisplay,EGLSurface,EGLSurface,EGLContext));
 auto platform=(EGLDisplay(*)(EGLenum,void*,const EGLint*))eglGetProcAddress("eglGetPlatformDisplayEXT");
 const EGLint attrs[]={0x3203,0x3489,EGL_NONE}; // ANGLE type = Metal
 EGLDisplay d=platform(0x3202,nullptr,attrs); EGLint maj,min;
 if(!eglInitialize(d,&maj,&min)){fprintf(stderr,"eglInitialize: %x\n",eglGetError());return 3;}
 EGLint ca[]={EGL_SURFACE_TYPE,EGL_PBUFFER_BIT,EGL_RENDERABLE_TYPE,EGL_OPENGL_ES2_BIT,EGL_RED_SIZE,8,EGL_GREEN_SIZE,8,EGL_BLUE_SIZE,8,EGL_ALPHA_SIZE,8,EGL_NONE}; EGLConfig c; EGLint n; eglChooseConfig(d,ca,&c,1,&n); if(!n)return 4;
 EGLint pa[]={EGL_WIDTH,1920,EGL_HEIGHT,1080,EGL_NONE}; EGLSurface s=eglCreatePbufferSurface(d,c,pa); EGLint ctxa[]={EGL_CONTEXT_CLIENT_VERSION,2,EGL_NONE}; EGLContext ctx=eglCreateContext(d,c,EGL_NO_CONTEXT,ctxa); if(!eglMakeCurrent(d,s,s,ctx)){fprintf(stderr,"makeCurrent: %x\n",eglGetError());return 5;}
 snprintf(path,sizeof(path),"%s/libGLESv2.dylib",base);lib=dlopen(path,RTLD_NOW|RTLD_LOCAL);if(!lib)return 6;
 FN(const GLubyte*,glGetString,(GLenum));FN(void,glClearColor,(float,float,float,float));FN(void,glClear,(GLbitfield));FN(void,glFinish,(void));FN(void,glReadPixels,(GLint,GLint,GLsizei,GLsizei,GLenum,GLenum,void*));FN(GLuint,glCreateShader,(GLenum));FN(void,glShaderSource,(GLuint,GLsizei,const char*const*,const GLint*));FN(void,glCompileShader,(GLuint));FN(GLuint,glCreateProgram,(void));FN(void,glAttachShader,(GLuint,GLuint));FN(void,glBindAttribLocation,(GLuint,GLuint,const char*));FN(void,glLinkProgram,(GLuint));FN(void,glUseProgram,(GLuint));FN(void,glEnableVertexAttribArray,(GLuint));FN(void,glVertexAttribPointer,(GLuint,GLint,GLenum,GLboolean,GLsizei,const void*));FN(void,glDrawArrays,(GLenum,GLint,GLsizei));FN(GLenum,glGetError,(void));FN(void,glViewport,(GLint,GLint,GLsizei,GLsizei));FN(void,glGenBuffers,(GLsizei,GLuint*));FN(void,glBindBuffer,(GLenum,GLuint));FN(void,glBufferData,(GLenum,GLsizeiptr,const void*,GLenum));
 const char*vs="attribute vec2 p;void main(){gl_Position=vec4(p,0.,1.);}";const char*fs="precision mediump float;void main(){gl_FragColor=vec4(1.,0.25,0.,1.);}"; GLuint v=glCreateShader(GL_VERTEX_SHADER),f=glCreateShader(GL_FRAGMENT_SHADER);glShaderSource(v,1,&vs,nullptr);glShaderSource(f,1,&fs,nullptr);glCompileShader(v);glCompileShader(f);GLuint prog=glCreateProgram();glAttachShader(prog,v);glAttachShader(prog,f);glBindAttribLocation(prog,0,"p");glLinkProgram(prog);glUseProgram(prog);float vertices[]={-1,-1,1,-1,0,1};GLuint vb;glGenBuffers(1,&vb);glBindBuffer(GL_ARRAY_BUFFER,vb);glBufferData(GL_ARRAY_BUFFER,sizeof(vertices),vertices,GL_STATIC_DRAW);glEnableVertexAttribArray(0);glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,nullptr);glViewport(0,0,1920,1080);
 std::vector<unsigned char> pixels(1920*1080*4); std::vector<double> times,readtimes; auto draw=[&](){glClearColor(0,0.1,0.4,1);glClear(GL_COLOR_BUFFER_BIT);glDrawArrays(GL_TRIANGLES,0,3);glFinish();};
 for(int i=0;i<140;i++){auto a=std::chrono::steady_clock::now();draw();auto b=std::chrono::steady_clock::now();glReadPixels(0,0,1920,1080,GL_RGBA,GL_UNSIGNED_BYTE,pixels.data());auto e=std::chrono::steady_clock::now();if(i>=20){times.push_back(std::chrono::duration<double,std::milli>(b-a).count());readtimes.push_back(std::chrono::duration<double,std::milli>(e-b).count());}}
 std::sort(times.begin(),times.end());std::sort(readtimes.begin(),readtimes.end());auto*p=&pixels[(540*1920+960)*4];bool ok=p[0]>250&&p[1]>=62&&p[1]<=65&&p[2]==0&&p[3]==255&&glGetError()==GL_NO_ERROR;
 printf("{\"renderer\":\"%s\",\"vendor\":\"%s\",\"version\":\"%s\",\"width\":1920,\"height\":1080,\"frames\":120,\"draw_finish_median_ms\":%.3f,\"draw_finish_p95_ms\":%.3f,\"readback_median_ms\":%.3f,\"readback_p95_ms\":%.3f,\"center_rgba\":[%d,%d,%d,%d],\"pixel_check\":%s}\n",glGetString(GL_RENDERER),glGetString(GL_VENDOR),glGetString(GL_VERSION),times[60],times[114],readtimes[60],readtimes[114],p[0],p[1],p[2],p[3],ok?"true":"false");
 if(argc>2){FILE*out=fopen(argv[2],"wb");if(out){fprintf(out,"P6\n1920 1080\n255\n");for(int y=1079;y>=0;y--)for(int x=0;x<1920;x++)fwrite(&pixels[(y*1920+x)*4],1,3,out);fclose(out);}}return ok?0:7;
}
