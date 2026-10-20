# Philips TV Lab

Start the local control panel:

```sh
python3 outputs/philips-55oled803/emulator/ui/server.py --port 8765
```

Open **http://127.0.0.1:8765**. Click **Start TV** to boot the development
profile. Stop terminates only the QEMU process group created by this server.
The server binds only to loopback and checks the Host header; mutation requests
require the exact local Origin and a per-session token. There is no arbitrary
command, path or shell-input API.

The default profile uses the bundled emulator/kernel/DTB and:

- `outputs/philips-55oled803/emulator/development/development-emmc.img`
- `outputs/philips-55oled803/emulator/development/ramdisk.img`

Use `--binary`, `--disk`, or `--ramdisk` to choose explicit local alternatives.
Disk writes always use QEMU `snapshot=on`. The guest has no network interface.
Start does not connect to, change, or flash the physical TV.

## What the view means

The main image is an actual QMP PNG screenshot. Empty, black and uninitialized
frames are preserved. The current model displays the uncomposited first region
of OSD plane 2; video mixing, panel scaling and compressed buffers are absent.
A picture is not evidence that Android has completed boot.

Ambilight colors come from decoded guest SPI transfers. Their arrangement around
three sides is for inspection and **does not establish physical LED positions**.
The red/green/blue selection supplies synthetic measurement input to the guest
algorithm; it does not recolor the image. The **Use framebuffer measurements**
option selects the bundled model's experimental framebuffer-measurement path,
without setting the constant RGB fixture. A selection change requires Stop then
Start. The selected input mode is explicit; actual SPI transfers are still
required before any light values appear.

Android boot status is unknown until an actual `getprop sys.boot_completed`
response arrives. The console is checked after its shell prompt appears, and
then every 30 seconds; **Check Android boot status** requests another response.
The same shell starts a background crash/main/system log reader.

## Virtual remote

D-pad, OK, Back, Home, volume and mute map to fixed Android `input keyevent`
codes. Buttons become available once the serial console connects. The server
sends commands in paced chunks and waits for a unique guest exit-status marker.

- **Pending:** delivery started, no acknowledgment yet.
- **Accepted:** the guest command returned zero; visual reaction is unverified.
- **Failed:** a nonzero guest exit or transport error.
- **Timeout:** no matching acknowledgment within 15 seconds. The shell or input
  service may not be ready.

The remote only targets the emulated Android instance. It sends no physical
infrared, Bluetooth, network or HDMI-CEC commands.

## Run records

Each start creates a unique `ui/runs/` directory with the exact launch command,
QEMU log, console/crash log, guest Ambilight JSONL and latest frame PNG. Runtime
control sockets live in a private temporary directory and are cleaned on Stop.
The logs may contain data from the guest; the server does not upload them.

Validation completed: Python/JavaScript syntax checks; foreign-Origin and
missing-token mutations rejected with HTTP 403; actual QEMU image capture and
remote delivery are recorded separately during the current runtime test.
