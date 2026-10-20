#!/usr/bin/env python3
"""Bounded localhost checks/control of our own UI; never sends arbitrary shell."""
import argparse
import json
import urllib.error
import urllib.request
BASE = "http://127.0.0.1:8765"
parser = argparse.ArgumentParser()
parser.add_argument("action", choices=["start", "stop", "state", "key", "boot", "security", "report"])
parser.add_argument("--key", default="up")
parser.add_argument("--report", choices=["services", "activity", "processes", "graphics", "settings", "launcher", "boot-files", "storage", "dtv-threads", "quiet-log"], default="services")
args = parser.parse_args()
if args.action == "security":
    for headers in ({}, {"Origin": "http://evil.invalid"}):
        req = urllib.request.Request(BASE + "/api/start", data=b"{}", headers=headers)
        try:
            urllib.request.urlopen(req, timeout=10)
            raise AssertionError("Unauthorized POST allowed")
        except urllib.error.HTTPError as exc:
            assert exc.code == 403
    print("PASS missing token/origin and foreign origin rejected")
else:
    if args.action != "state":
        session = json.load(urllib.request.urlopen(BASE + "/api/session", timeout=10))
        path, body = {
            "start": ("/api/start", {"fixture": "framebuffer"}),
            "stop": ("/api/stop", {}),
            "key": ("/api/key", {"key": args.key}),
            "boot": ("/api/check-boot", {}),
            "report": ("/api/report", {"name": args.report}),
        }[args.action]
        req = urllib.request.Request(BASE + path, data=json.dumps(body).encode(),
            headers={"Content-Type": "application/json", "Origin": BASE,
                     "X-TVUI-Token": session["token"]})
        print(json.load(urllib.request.urlopen(req, timeout=10)))
    state = json.load(urllib.request.urlopen(BASE + "/api/state", timeout=10))
    print(json.dumps({k: v for k, v in state.items()
                      if k not in ("qemu_log", "console_log", "pixels")}, indent=2))
