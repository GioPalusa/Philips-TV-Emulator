#!/usr/bin/env python3
"""Launch a private local renderer session using the installed Android Emulator SDK."""
import os,pathlib,tempfile,json
here=pathlib.Path(__file__).resolve().parent
sdk=pathlib.Path(os.environ.get('ANDROID_SDK_ROOT',str(pathlib.Path.home()/'Library/Android/sdk')))
run=pathlib.Path(tempfile.mkdtemp(prefix='philips-hostgpu-'));run.chmod(0o700)
sock=str(run/'gpu.sock');frame=str(run/'frame.rgba')
print(json.dumps({'socket':sock,'frame':frame,'pid':os.getpid(),'qemu_environment':{'PHILIPS_HOSTGPU_SOCKET':sock}},indent=2),flush=True)
env=os.environ.copy();env['DYLD_LIBRARY_PATH']=str(sdk/'emulator/lib64/gles_angle');env['ANGLE_DEFAULT_PLATFORM']='metal'
os.execve(str(here/'host_renderer'),[str(here/'host_renderer'),'--socket',sock,'--frame',frame],env)
