#!/usr/bin/env python3
import importlib.util
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[4]
spec = importlib.util.spec_from_file_location('checkpoint', Path(__file__).with_name('checkpoint.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
QEMU = Path(os.environ.get('PHILIPS_CHECKPOINT_TEST_QEMU', str(ROOT / 'work/philips-emulator/qemu-11.1.2/build/qemu-system-aarch64')))
IMG = os.environ.get('PHILIPS_QEMU_IMG', '/opt/homebrew/bin/qemu-img')


class QMP:
    def __init__(self, path):
        self.socket = socket.socket(socket.AF_UNIX)
        self.socket.settimeout(10)
        for _ in range(100):
            try:
                self.socket.connect(str(path))
                break
            except (FileNotFoundError, ConnectionRefusedError):
                time.sleep(.03)
        self.stream = self.socket.makefile('rwb', buffering=0)
        assert 'QMP' in json.loads(self.stream.readline())
        self.call('qmp_capabilities')
    def call(self, name, arguments=None):
        self.stream.write((json.dumps({'execute':name,'arguments':arguments or {}})+'\n').encode())
        while True:
            reply = json.loads(self.stream.readline())
            if 'error' in reply: raise RuntimeError(reply['error']['desc'])
            if 'return' in reply: return reply['return']
    def close(self):
        self.stream.close(); self.socket.close()


class CheckpointTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix='phcp-', dir='/tmp')
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.base = self.root/'base.raw'
        data = bytearray(4*1024*1024)
        data[:10] = b'PHILIPS-CP'
        data[-512:] = bytes(range(256))*2
        self.base.write_bytes(data)
        self.original = bytes(data)
        self.expected = self.root/'expected.raw'
        data[65536:69632] = b'Z'*4096
        self.expected.write_bytes(data)
        self.log = (self.root/'qemu.log').open('wb')
        self.proc = subprocess.Popen([str(QEMU),'-machine','none','-nodefaults','-display','none','-S',
            '-qmp',f'unix:{self.root}/qmp,server=on,wait=off',
            '-drive',f'if=none,format=raw,snapshot=on,id=tv-emmc,file={self.base}'],stdout=self.log,stderr=self.log)
        self.addCleanup(self.stop)
        self.qmp = QMP(self.root/'qmp')
        self.addCleanup(self.qmp.close)
        text=self.qmp.call('human-monitor-command',{'command-line':'qemu-io tv-emmc "write -P 0x5a 65536 4096"'})
        self.qmp.call('cont')
        self.states={'boot_complete':True,'warmup_complete':True,'test':'synthetic disk; no Android'}

    def stop(self):
        if self.proc.poll() is None:
            self.proc.terminate()
            self.proc.wait(timeout=5)
        self.log.close()

    def compare(self, disk):
        subprocess.run([IMG,'compare','-q','-f','raw','-F','qcow2',str(self.expected),str(disk)],check=True)

    def test_full_checkpoint_resume_independence_overlay(self):
        output=self.root/'checkpoint.qcow2'
        result=module.capture_checkpoint(self.qmp.call, output, self.states, qemu_img=IMG,timeout=15)
        self.assertTrue(result['independent'])
        self.assertTrue(self.qmp.call('query-status')['running'])
        self.assertEqual(self.base.read_bytes(), self.original)
        self.assertFalse(self.qmp.call('query-jobs'))
        self.compare(output)
        self.qmp.call('stop')
        second=self.root/'paused.qcow2'
        module.capture_checkpoint(self.qmp.call,second,self.states,qemu_img=IMG,timeout=15)
        self.assertFalse(self.qmp.call('query-status')['running'])
        self.stop()
        self.base.unlink() # The original base and temporary snapshot are now gone.
        self.compare(output)
        overlay=self.root/'persistent.qcow2'
        overlay_result=module.create_persistent_overlay(output,overlay,qemu_img=IMG)
        self.assertEqual(overlay_result['backing_file'],str(output.resolve()))
        self.compare(overlay)
        with self.assertRaises(ValueError):
            module.create_persistent_overlay(output,overlay,qemu_img=IMG)

    def test_failed_start_resumes_and_keeps_incomplete(self):
        def failing(name,args=None):
            if name=='blockdev-backup':raise RuntimeError('injected start failure')
            return self.qmp.call(name,args)
        with self.assertRaises(module.CheckpointError) as caught:
            module.capture_checkpoint(failing,self.root/'failed.qcow2',self.states,qemu_img=IMG,timeout=15)
        self.assertTrue(self.qmp.call('query-status')['running'])
        self.assertFalse((self.root/'failed.qcow2').exists())
        self.assertTrue(Path(caught.exception.partial_path).exists())
        self.assertFalse(caught.exception.cleanup_errors)
        self.assertFalse(any(n['node-name'].startswith('checkpoint-target-') for n in self.qmp.call('query-named-block-nodes')))

    def test_timeout_cancels_real_paused_job_and_resumes(self):
        def paused(name,args=None):
            if name=='blockdev-backup':
                args=dict(args, speed=1)
            return self.qmp.call(name,args)
        with self.assertRaises(module.CheckpointError):
            module.capture_checkpoint(paused,self.root/'timed-out.qcow2',self.states,qemu_img=IMG,timeout=.2,cleanup_timeout=3)
        self.assertTrue(self.qmp.call('query-status')['running'])
        self.assertFalse(self.qmp.call('query-jobs'))
        self.assertFalse((self.root/'timed-out.qcow2').exists())

    def test_resume_failure_reports_saved_artifact(self):
        def fail_resume(name,args=None):
            if name=='cont':raise RuntimeError('injected resume failure')
            return self.qmp.call(name,args)
        output=self.root/'saved.qcow2'
        with self.assertRaises(module.CheckpointError) as caught:
            module.capture_checkpoint(fail_resume,output,self.states,qemu_img=IMG,timeout=15)
        self.assertTrue(output.exists())
        self.assertEqual(caught.exception.partial_path,str(output.resolve()))
        self.assertTrue(any('Guest resume' in s for s in caught.exception.cleanup_errors))
        self.assertFalse(self.qmp.call('query-status')['running'])
        self.compare(output)
        self.qmp.call('cont')

    def test_preconditions_and_sync_failure(self):
        with self.assertRaises(ValueError):
            module.capture_checkpoint(self.qmp.call,self.root/'no.qcow2',{'boot_complete':True},qemu_img=IMG)
        with self.assertRaises(module.CheckpointError):
            module.capture_checkpoint(self.qmp.call,self.root/'nosync.qcow2',self.states,qemu_img=IMG,guest_sync=lambda:False)
        self.assertTrue(self.qmp.call('query-status')['running'])
        self.assertEqual(self.base.read_bytes(),self.original)
        existing=self.root/'existing.qcow2';existing.write_bytes(b'preserve')
        with self.assertRaises(ValueError):
            module.capture_checkpoint(self.qmp.call,existing,self.states,qemu_img=IMG)
        self.assertEqual(existing.read_bytes(),b'preserve')
        self.assertTrue(self.qmp.call('query-status')['running'])

    def test_capture_cli_exclusive_socket_and_attestation(self):
        output = self.root/'cli.qcow2'
        script = Path(__file__).with_name('checkpoint.py')
        arguments = [sys.executable, str(script), 'capture',
                     '--qmp', str(self.root/'qmp'), '--output', str(output),
                     '--qemu-img', IMG, '--timeout', '15',
                     '--boot-complete', '--warmup-complete', '--warmup-evidence']
        invalid = subprocess.run(arguments + [' '], capture_output=True, text=True, timeout=5)
        self.assertEqual(invalid.returncode, 2)
        self.assertIn('must be nonempty', invalid.stderr)
        self.assertFalse(output.exists())
        self.qmp.close()
        result = subprocess.run(arguments + ['Synthetic 4 MiB test; no Android',
            '--guest-sync-confirmed', '--guest-sync-evidence', 'Synthetic caller attestation only'],
            capture_output=True, text=True, timeout=25, check=True)
        metadata = json.loads(result.stdout)
        self.assertTrue(metadata['independent'])
        self.assertFalse(metadata['guest_sync_acknowledged'])
        self.assertTrue(metadata['warmup_attestation']['guest_sync_previously_confirmed'])
        self.qmp = QMP(self.root/'qmp')
        self.addCleanup(self.qmp.close)
        self.assertTrue(self.qmp.call('query-status')['running'])
        self.assertFalse(self.qmp.call('query-jobs'))
        self.assertEqual(self.base.read_bytes(), self.original)
        self.compare(output)


if __name__=='__main__':unittest.main()
