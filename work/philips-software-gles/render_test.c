/* Execute real software GLES2 work and verify pixels inside the Android guest. */
#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define REQUIRE(x) do { \
    if (!(x)) { \
        printf("FAIL line=%d expression=%s egl=%04x gl=%04x\n", \
               __LINE__, #x, eglGetError(), glGetError()); \
        return 1; \
    } \
} while (0)

static GLuint shader(GLenum type, const char *source)
{
    GLuint s = glCreateShader(type);
    GLint compiled = 0;
    glShaderSource(s, 1, &source, NULL);
    glCompileShader(s);
    glGetShaderiv(s, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        char log[2048];
        glGetShaderInfoLog(s, sizeof(log), NULL, log);
        printf("SHADER FAIL: %s\n", log);
        return 0;
    }
    return s;
}

int main(void)
{
    setvbuf(stdout, NULL, _IONBF, 0);
    puts("SWIFTSHADER TEST BEGIN");
    EGLDisplay d = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    EGLint major = 0, minor = 0, count = 0;
    REQUIRE(d != EGL_NO_DISPLAY);
    REQUIRE(eglInitialize(d, &major, &minor));
    printf("EGL %d.%d vendor=%s\n", major, minor, eglQueryString(d, EGL_VENDOR));
    EGLint attrs[] = {
        EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8, EGL_NONE
    };
    EGLConfig config;
    REQUIRE(eglChooseConfig(d, attrs, &config, 1, &count) && count == 1);
    EGLint surface_attrs[] = {EGL_WIDTH, 32, EGL_HEIGHT, 32, EGL_NONE};
    EGLSurface surface = eglCreatePbufferSurface(d, config, surface_attrs);
    REQUIRE(surface != EGL_NO_SURFACE);
    EGLint context_attrs[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
    EGLContext context = eglCreateContext(d, config, EGL_NO_CONTEXT, context_attrs);
    REQUIRE(context != EGL_NO_CONTEXT);
    REQUIRE(eglMakeCurrent(d, surface, surface, context));
    printf("GLES vendor=%s renderer=%s version=%s\n",
           glGetString(GL_VENDOR), glGetString(GL_RENDERER), glGetString(GL_VERSION));
    glViewport(0, 0, 32, 32);
    glClearColor(1, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    unsigned char pixel[4] = {0};
    glReadPixels(0, 0, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixel);
    REQUIRE(glGetError() == GL_NO_ERROR);
    REQUIRE(pixel[0] == 255 && pixel[1] == 0 && pixel[2] == 0 && pixel[3] == 255);
    puts("PASS clear/readback red RGBA=255,0,0,255");

    GLuint vertex = shader(GL_VERTEX_SHADER,
        "attribute vec2 position; void main(){gl_Position=vec4(position,0.0,1.0);}");
    GLuint fragment = shader(GL_FRAGMENT_SHADER,
        "precision mediump float; void main(){gl_FragColor=vec4(0.0,1.0,0.0,1.0);}");
    REQUIRE(vertex && fragment);
    GLuint program = glCreateProgram();
    glAttachShader(program, vertex);
    glAttachShader(program, fragment);
    glBindAttribLocation(program, 0, "position");
    glLinkProgram(program);
    GLint linked = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    REQUIRE(linked);
    glUseProgram(program);
    const GLfloat triangle[] = {-0.75f, -0.75f, 0.75f, -0.75f, 0.0f, 0.75f};
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, triangle);
    glEnableVertexAttribArray(0);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    glFinish();
    REQUIRE(glGetError() == GL_NO_ERROR);
    glReadPixels(16, 16, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixel);
    REQUIRE(pixel[0] == 0 && pixel[1] == 255 && pixel[2] == 0 && pixel[3] == 255);
    glReadPixels(0, 31, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixel);
    REQUIRE(pixel[0] == 255 && pixel[1] == 0 && pixel[2] == 0 && pixel[3] == 255);
    puts("PASS shaders/triangle interior green; exterior preserved red");
    glDeleteProgram(program);
    glDeleteShader(vertex);
    glDeleteShader(fragment);
    eglMakeCurrent(d, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    eglDestroyContext(d, context);
    eglDestroySurface(d, surface);
    eglTerminate(d);
    puts("SWIFTSHADER TEST PASS");
    return 0;
}
