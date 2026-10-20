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
Disk writes default to QEMU `snapshot=on`. An explicitly created persistent
qcow2 development overlay can use `--disk-format qcow2 --persistent-disk`; see
[checkpoint instructions](CHECKPOINTS.md). The guest has no network interface.
Start does not connect to, change, or flash the physical TV.

## What the view means

The main image contains actual guest output. The default path captures raw
QMP PPM pixels from OSD plane 2. With `--host-gpu-socket` and `--host-gpu-frame`,
the viewer reads posted pixels from the host GLES renderer. Empty, black and
uninitialized frames are preserved. Video mixing, panel scaling and compressed
buffers are absent from the OSD model. The displayed visual-update rate counts
distinct sampled images and is not a guaranteed rendering-FPS measurement.
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
codes. Buttons require Android input-service readiness and a verified persistent
Java bridge running as UID 2000 in the shell domain. The bridge uses a private
FIFO, a checked JAR hash, a bounded queue and uniquely identified acknowledgments.
The virtual UART supplies its own pacing; host commands are not artificially
delayed. The host-graphics development policy explicitly permits the required
shell FIFO operations while retaining SELinux enforcing.

- **Pending:** delivery started, no acknowledgment yet.
- **Accepted:** Android input injection acknowledged the key; visual reaction is unverified.
- **Failed:** a nonzero guest exit or transport error.
- **Timeout:** no matching acknowledgment within 15 seconds. The shell or input
  service may not be ready.

The remote only targets the emulated Android instance. It sends no physical
infrared, Bluetooth, network or HDMI-CEC commands.

## Run records

Each start creates a unique `ui/runs/` directory with the exact launch command,
QEMU log, console/crash log, guest Ambilight JSONL and available raw frame capture. Runtime
control sockets live in a private temporary directory and are cleaned on Stop.
The logs may contain data from the guest; the server does not upload them.

Validation completed: Python/JavaScript syntax checks; foreign-Origin and
missing-token mutations rejected with HTTP 403; actual QEMU image capture and
remote delivery are recorded separately during the current runtime test.

## Host graphics and persistent storage

Start [the host renderer](../host-graphics/README.md) first and use the socket
and frame paths it prints. With a prepared host-graphics profile and a new
persistent overlay, launch the viewer with:

```sh
python3 outputs/philips-55oled803/emulator/ui/server.py --port 8765 \
  --disk /absolute/path/development-session.qcow2 \
  --disk-format qcow2 --persistent-disk \
  --ramdisk /absolute/path/host-graphics/profile/ramdisk.img \
  --host-gpu-socket /absolute/path/gpu.sock \
  --host-gpu-frame /absolute/path/frame.rgba
```

The renderer must remain running while the emulator uses it. Disk checkpoints
are local development artifacts; neither this viewer nor its checkpoint helper
flashes a physical TV.
