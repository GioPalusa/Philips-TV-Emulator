#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import threading
import time
import unittest
from collections import deque
from bridge_controller import InputBridgeController


class FakeEmulator:
    def __init__(self, directory):
        self.run_dir = Path(directory)
        self.commands = deque(maxlen=12)
        self.sent = []
        self.reply_keys = True
        self.identity = '2000:u:r:shell:s0'
        self.bad_hash = False
        self.asset = False
        self.fail_fifo = False
        self.bridge = InputBridgeController(self)

    def send(self, text, on_send=None):
        self.sent.append(text)
        if on_send:
            on_send()
        prefix = 'TVUI_BRIDGE_' + self.bridge.session
        if '_IDENTITY:' in text:
            self.bridge.receive(prefix + '_IDENTITY:' + self.identity)
        elif '_DIRECTORY:' in text:
            self.bridge.receive(prefix + '_DIRECTORY:0')
        elif '_ASSET:' in text:
            digest = hashlib.sha256(Path(__file__).with_name('philips-input.jar').read_bytes()).hexdigest()
            self.bridge.receive(prefix + '_ASSET:' + (digest if self.asset else 'missing'))
        elif '_HASH:' in text:
            digest = hashlib.sha256(Path(__file__).with_name('philips-input.jar').read_bytes()).hexdigest()
            self.bridge.receive(prefix + '_HASH:' + ('0' * 64 if self.bad_hash else digest))
        elif 'app_process' in text:
            subprocess.run(['/bin/sh', '-n'], input=text, text=True, check=True)
            self.bridge.receive(prefix + (':FATAL FIFO' if self.fail_fifo else ':READY PHILIPS_INPUT_V1'))
        elif "printf 'PING" in text:
            self.bridge.receive(prefix + ':ACK 2147483647 PONG')
        elif "printf 'KEY " in text and self.reply_keys:
            ident = re.search(r"KEY (\d+)", text)[1]
            self.bridge.receive(prefix + ':ACK ' + ident + ' KEY 5')


class ControllerTests(unittest.TestCase):
    def setUp(self):
        scratch = Path(__file__).resolve().parents[4] / 'work/philips-input'
        self.temp = tempfile.TemporaryDirectory(dir=scratch)
        self.addCleanup(self.temp.cleanup)
        self.emu = FakeEmulator(self.temp.name)
        self.bridge = self.emu.bridge

    def wait(self, condition):
        end = time.monotonic() + 2
        while not condition():
            if time.monotonic() > end:
                self.fail('condition timed out')
            time.sleep(.005)

    def test_prepare_hash_and_reattach(self):
        self.bridge._prepare(self.bridge.generation)
        self.assertEqual(self.bridge.status, 'ready')
        self.assertTrue(any('exec 9<>' in s for s in self.emu.sent))
        self.assertTrue(all(len(s) < 600 for s in self.emu.sent))
        self.bridge.reset()
        self.emu.sent.clear()
        self.bridge._prepare(self.bridge.generation)
        self.assertEqual(self.bridge.status, 'ready')
        self.assertEqual(self.emu.sent, ["printf 'PING 2147483647\\n' >&9\n"])

    def test_preinstalled_asset_skips_upload(self):
        self.emu.asset = True
        self.bridge._prepare(self.bridge.generation)
        self.assertEqual(self.bridge.status, 'ready')
        self.assertTrue(any('cp /system/etc/emulator-assets/philips-input.jar' in s for s in self.emu.sent))
        self.assertFalse(any('payload.b64' in s for s in self.emu.sent))

    def test_vendor_id_context_prefix(self):
        self.emu.identity = '2000:context=u:r:shell:s0'
        self.bridge._prepare(self.bridge.generation)
        self.assertEqual(self.bridge.status, 'ready')

    def test_failed_fifo_can_prepare_fresh_session_after_reattach(self):
        self.emu.fail_fifo = True
        self.bridge._prepare(self.bridge.generation)
        self.assertEqual(self.bridge.status, 'failed')
        manifest = self.emu.run_dir / 'input-bridge.json'
        failed = json.loads(manifest.read_text())
        self.assertEqual(failed['launch_state'], 'failed_before_start')
        self.bridge.reset()
        self.emu.fail_fifo = False
        self.bridge._prepare(self.bridge.generation)
        self.assertEqual(self.bridge.status, 'ready')
        self.assertNotEqual(failed['session'], self.bridge.session)
        self.assertTrue((self.emu.run_dir / ('input-bridge-failed-' + failed['session'] + '.json')).exists())

    def test_identity_and_hash_fail_closed(self):
        self.emu.identity = '0:u:r:init:s0'
        self.bridge._prepare(self.bridge.generation)
        self.assertEqual(self.bridge.status, 'failed')
        self.assertFalse(any('payload.b64' in s for s in self.emu.sent))
        self.bridge.reset()
        self.emu.identity = '2000:u:r:shell:s0'
        self.emu.bad_hash = True
        self.bridge._prepare(self.bridge.generation)
        self.assertEqual(self.bridge.status, 'failed')
        self.assertFalse(any('app_process' in s for s in self.emu.sent))

    def test_ack_timing_and_serial_dispatch(self):
        self.bridge.status = 'ready'
        for _ in range(3):
            self.bridge.enqueue('up', 19)
        self.wait(lambda: not self.bridge.pending)
        self.assertEqual(len(self.emu.sent), 3)
        for item in self.emu.commands:
            self.assertEqual(item['status'], 'accepted')
            self.assertEqual(item['guest_ms'], 5)
            self.assertGreaterEqual(item['host_ms'], 0)

    def test_queue_bound_timeout_no_retry_and_late_ack(self):
        self.bridge.status = 'ready'
        self.bridge.ACK_TIMEOUT = .08
        self.emu.reply_keys = False
        for _ in range(4):
            self.bridge.enqueue('up', 19)
        with self.assertRaises(ValueError):
            self.bridge.enqueue('up', 19)
        self.wait(lambda: self.bridge.status == 'uncertain')
        self.assertEqual(len(self.emu.sent), 1)
        self.assertEqual([x['status'] for x in self.emu.commands], ['timeout'] + ['cancelled'] * 3)
        ident = self.emu.commands[0]['id']
        self.bridge.receive('TVUI_BRIDGE_' + self.bridge.session + ':ACK ' + ident + ' KEY 30')
        self.assertEqual(self.emu.commands[0]['status'], 'accepted_late')
        self.assertEqual(self.bridge.status, 'ready')
        self.assertEqual(len(self.emu.sent), 1)

    def test_wrong_session_and_reset(self):
        self.bridge.status = 'ready'
        self.emu.reply_keys = False
        self.bridge.enqueue('up', 19)
        self.wait(lambda: len(self.emu.sent) == 1)
        item = self.emu.commands[0]
        self.bridge.receive('TVUI_BRIDGE_bad:ACK ' + item['id'] + ' KEY 5')
        self.assertEqual(item['status'], 'pending')
        self.bridge.reset()
        time.sleep(.03)
        self.assertEqual(self.bridge.status, 'idle')
        self.assertEqual(item['status'], 'cancelled')


if __name__ == '__main__':
    unittest.main()
