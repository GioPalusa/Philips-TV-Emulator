#!/usr/bin/env python3
"""Render asymmetric GLES quadrants and assert shared RGBA is top-down.

Runs its own renderer; never connects to the live guest renderer. OpenGL window
coordinates have their origin at the bottom left. The expected mmap order is
red/green across the top and blue/yellow across the bottom.
"""
import argparse, hashlib, json, mmap, os, pathlib, socket, struct, subprocess, tempfile, time

HERE = pathlib.Path(__file__).resolve().parent
p = argparse.ArgumentParser()
p.add_argument('--renderer', type=pathlib.Path, default=HERE / 'host_renderer')
p.add_argument('--output', type=pathlib.Path, required=True)
a = p.parse_args()
sdk = pathlib.Path(os.environ.get('ANDROID_SDK_ROOT', str(pathlib.Path.home() / 'Library/Android/sdk')))
result = {'renderer_sha256': hashlib.sha256(a.renderer.read_bytes()).hexdigest(),
          'transport': 'Android 8 GLES packets → gfxstream → ANGLE Metal → shared RGBA',
          'coordinates': 'Expected mmap top-left red, top-right green, bottom-left blue, bottom-right yellow'}
with tempfile.TemporaryDirectory(prefix='philips-orientation-') as directory:
    run = pathlib.Path(directory)
    env = os.environ.copy()
    env['DYLD_LIBRARY_PATH'] = str(sdk / 'emulator/lib64/gles_angle')
    env['ANGLE_DEFAULT_PLATFORM'] = 'metal'
    with (run / 'renderer.log').open('w+') as log:
        proc = subprocess.Popen([str(a.renderer.resolve()), '--socket', str(run / 'gpu.sock'), '--frame', str(run / 'frame.rgba')], env=env, stdout=log, stderr=log)
        try:
            deadline = time.monotonic() + 20
            while not (run / 'gpu.sock').exists():
                if proc.poll() is not None or time.monotonic() >= deadline:
                    raise RuntimeError('renderer did not become ready')
                time.sleep(.05)
            with socket.socket(socket.AF_UNIX) as s:
                s.settimeout(10)
                s.connect(str(run / 'gpu.sock'))
                s.sendall(b'pipe:opengles\0' + struct.pack('<I', 0))
                def call(op, args=(), response=0, payload=None):
                    body = payload if payload is not None else struct.pack('<' + 'I' * len(args), *args)
                    s.sendall(struct.pack('<II', op, len(body) + 8) + body)
                    data = b''
                    while len(data) < response:
                        part = s.recv(response - len(data))
                        if not part: raise RuntimeError('renderer closed')
                        data += part
                    return struct.unpack('<' + 'I' * (response // 4), data)
                attrs = [0x3040, 4, 0x3024, 8, 0x3023, 8, 0x3022, 8, 0x3021, 8, 0x3038]
                raw = struct.pack('<' + 'I' * len(attrs), *attrs)
                cfg, count = call(10006, payload=struct.pack('<I', len(raw)) + raw + struct.pack('<III', len(raw), 4, 1), response=8)
                assert count > 0
                ctx, = call(10008, [cfg, 0, 2], 4)
                win, = call(10010, [cfg, 1920, 1080], 4)
                color, = call(10012, [1920, 1080, 0x1908], 4)
                call(10015, [win, color])
                assert call(10017, [ctx, win, win], 4) == (1,)
                # glEnable(GL_SCISSOR_TEST), glScissor, glClearColor, glClear.
                call(2090, [0x0C11])
                for x, y, rgb in [(0, 540, (1., 0., 0.)), (960, 540, (0., 1., 0.)),
                                  (0, 0, (0., 0., 1.)), (960, 0, (1., 1., 0.))]:
                    call(2144, [x, y, 960, 540])
                    call(2064, payload=struct.pack('<4f', *rgb, 1.))
                    call(2063, [0x4000])
                call(2086, [0x0C11])
                result['flush_result'] = call(10016, [win], 4)[0]
                expected = {'top_left': [255, 0, 0, 255], 'top_right': [0, 255, 0, 255],
                            'bottom_left': [0, 0, 255, 255], 'bottom_right': [255, 255, 0, 255]}
                positions = {'top_left': (100, 100), 'top_right': (1820, 100),
                             'bottom_left': (100, 980), 'bottom_right': (1820, 980)}
                with (run / 'frame.rgba').open('rb') as f, mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
                    deadline = time.monotonic() + 10
                    actual = {}
                    while time.monotonic() < deadline:
                        call(10018, [color])
                        time.sleep(.02)
                        sequence = struct.unpack_from('<Q', mm, 24)[0]
                        if sequence % 2: continue
                        frame_count = struct.unpack_from('<Q', mm, 32)[0]
                        actual = {name: list(mm[64 + (y * 1920 + x) * 4:64 + (y * 1920 + x) * 4 + 4]) for name, (x, y) in positions.items()}
                        if sequence != struct.unpack_from('<Q', mm, 24)[0]: continue
                        # Four repeated posts fill the SDK asynchronous pipeline.
                        if frame_count >= 4 and all(pixel[3] == 255 for pixel in actual.values()): break
                    result.update(expected=expected, actual=actual, frame_count=frame_count,
                                  stable_sequence=sequence, passed=actual == expected)
                call(10017, [0, 0, 0], 4)
                call(10011, [win]); call(10014, [color]); call(10009, [ctx])
        finally:
            proc.terminate()
            try: proc.wait(timeout=5)
            except subprocess.TimeoutExpired: proc.kill(); proc.wait()
            log.seek(0)
            result['renderer_log'] = log.read()
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
raise SystemExit(0 if result['passed'] else 1)
