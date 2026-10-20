# Persistent Android remote-key bridge

`philips-input.jar` is a small DEX JAR for the isolated Android 8 emulator. One
`app_process` instance receives all remote-key requests on standard input. It
caches the framework input manager and reflection methods. It does not start a
new Java process for each key.

**Validation:** compilation and host protocol tests pass. Guest execution,
permission checks and latency measurements remain pending. The expected saving
is repeated process/ART startup; the Android dispatcher and application can
still delay a key.

## Launch and permissions

Place the JAR at `/data/local/tmp/philips-input.jar`, readable by the existing
Android shell. Start it from the same shell UID and SELinux context used for
ordinary `input keyevent` commands. The bridge checks that its UID is 2000
(Android shell) before initializing input access:

```sh
CLASSPATH=/data/local/tmp/philips-input.jar /system/bin/app_process /system/bin tv.emulator.InputBridge
```

Do not run it under the Ambilight service's privileged domain. No root, `su`,
permission grants, policy edits, network listeners, executable user input or
external commands are used by this bridge. The standard Binder permission check
still applies. It fails visibly if the input service or reflection API is
unavailable, or injection is denied.

The implementation follows Android 8's input command: virtual keyboard events,
a down/up pair, and `INJECT_INPUT_EVENT_MODE_WAIT_FOR_FINISH`. The bridge attempts
key-up in a `finally` block even if key-down raises an exception. A process crash
or forced termination can still interrupt that cleanup. It implements taps;
long press, key repeat and text entry are not part of this protocol.

Primary implementation references:

- [AOSP Android 8 Input.java](https://github.com/aosp-mirror/platform_frameworks_base/blob/android-8.0.0_r1/cmds/input/src/com/android/commands/input/Input.java), `sendKeyEvent` and `injectKeyEvent`.
- [AOSP Android 8 InputManager.java](https://github.com/aosp-mirror/platform_frameworks_base/blob/android-8.0.0_r1/core/java/android/hardware/input/InputManager.java), `getInstance`, injection mode constants and `injectInputEvent`.

These establish the Android API approach, not the behavior of the vendor guest.

## Protocol

All lines are ASCII, at most 64 bytes before the line ending. LF and CRLF work.
Commands and fields are case-sensitive, separated by exactly one ASCII space.
IDs are decimal integers from 1 through 2147483647. Use a distinct ID for each
outstanding request; the bridge echoes IDs but does not deduplicate retries.

Startup:

```text
READY PHILIPS_INPUT_V1
```

Requests and responses:

```text
PING 1
ACK 1 PONG
KEY 2 19
ACK 2 KEY 7
QUIT 3
ACK 3 BYE
```

The final integer in a KEY response is elapsed guest uptime milliseconds around
the down/up injection calls. It excludes transport delay and initial startup.
An ACK means both injection calls returned success; it does not prove that the
requested app navigation or a displayed frame changed.

Errors use fixed strings and never echo arbitrary input:

| Response | Meaning |
| --- | --- |
| `ERR 0 BAD_LINE` | Overlong, non-ASCII or invalid control bytes; drained through LF |
| `ERR 0 TRUNCATED` | EOF with an incomplete line; request not executed |
| `ERR 0 BAD_REQUEST` | Missing or invalid request ID |
| `ERR ID BAD_REQUEST` | Unknown command or invalid field structure |
| `ERR ID KEY_NOT_ALLOWED` | Key code outside the fixed allowlist |
| `ERR ID INJECT_REJECTED MS` | A down/up injection returned false |
| `ERR ID INJECT_EXCEPTION MS` | Framework injection threw an exception |
| `FATAL CLASS` | Initialization or I/O failed; process ends |
| `FATAL SHELL_UID_REQUIRED` | Launch UID is not Android shell (2000) |
| `FATAL ARGUMENTS` | Unexpected launch arguments |

No arbitrary text, filesystem path or shell command is accepted. Overlong lines
are discarded with constant memory, and an incomplete line at EOF is never
executed. QUIT stops processing, even if further requests were already buffered.

### Allowed keys

| Android key codes | Meaning |
| --- | --- |
| 3, 4 | Home, Back |
| 19, 20, 21, 22, 23 | Up, Down, Left, Right, Center |
| 24, 25, 164 | Volume up, volume down, mute |
| 82 | Menu |
| 85, 86, 87, 88, 89, 90 | Play/pause, stop, next, previous, rewind, fast-forward |
| 126, 127 | Play, pause |
| 165, 166, 167, 172, 178 | Info, channel up, channel down, guide, TV input |
| 183, 184, 185, 186 | Red, green, yellow, blue buttons |

## Controller integration

1. Keep one process and its input/output connection alive. Wait for READY before
   accepting remote actions. On a terminal, ignore echoed request lines and
   unrelated console messages; match only the complete response grammar.
2. Serialize key requests. A small bounded UI queue prevents unlimited delayed
   clicks. Keep a request pending until its matching ACK/ERR arrives.
3. Measure host monotonic time from request write to matching response, and keep
   the guest duration separately. Measure startup independently. Compare several
   identical key actions with the old `input keyevent` path under the same
   workload before claiming a latency improvement.
4. Injection uses Android's synchronous dispatcher and can block when an app is
   unresponsive. The bridge creates no background timeout or retry thread. A
   host timeout means **unknown outcome**; do not automatically resend the key.
5. QUIT ends the bridge, and EOF ends it without executing a partial command.
   Stop sending protocol lines once it exits; a terminal may then return to its
   shell. Relaunch explicitly after an error or guest reboot.

## Rebuild and tests

Run `./build.sh` in this directory. It uses the installed Android Studio JBR,
SDK platform 35 for public Java API declarations, and build-tools 35.0.1 D8 with
`--min-api 26`. Source is compiled as Java 8. The bridge uses longstanding
Android APIs and reflection for hidden Android 8 input-manager methods.

Optional environment overrides:

- `PHILIPS_JAVA_HOME`: JDK/JBR installation containing `bin/java` and `bin/javac`.
- `PHILIPS_ANDROID_SDK`: Android SDK root.
- `PHILIPS_INPUT_BUILD_DIR`: scratch build directory; defaults to this workspace's
  `work/philips-input/build`.

`ProtocolTest.java` uses a fake injector and clock to test IDs, exact framing,
CRLF, rejected power/arbitrary input, a one-million-byte malformed line,
recovery, EOF, QUIT, and false/exception injection acknowledgements. These host
tests do not inject Android events. `build-evidence.json` records artifact hashes
and pending guest checks.

## UI integration

`bridge_controller.py` connects the bridge to the viewer's existing paced serial
sender and console receiver. The server prepares it once Android reports that
the input service exists. Preparation first verifies UID 2000 and
`u:r:shell:s0`; it does not change either credential.

The controller creates a private directory named
`/data/local/tmp/philips-input-<session>/`. It prefers a matching preinstalled
`/system/etc/emulator-assets/philips-input.jar`; otherwise it uploads the packaged
JAR in 256-character Base64 chunks, with a maximum JAR size of 16 KiB. It checks
the final guest SHA-256 before launching. Failed checks stop preparation.

The directory's `input.fifo` is unique to this controller session. File descriptor
9 stays open in the existing interactive shell to prevent EOF between requests.
The one background app_process reads that descriptor, and a shell loop prefixes
its responses with the session token. Keys use a shell `printf` builtin to write
the FIFO; they do not launch another app_process. Normal boot/status queries can
continue on the console. The controller never interpolates user command text.

A small host manifest in the run directory permits a viewer restart to reconnect
with PING, avoiding another reader on the same FIFO. Pending key outcomes from a
lost viewer connection are not reconstructed or retried. Temporary guest files
remain in the emulator's snapshot overlay until the guest stops.

The UI permits at most four outstanding keys, including the active request, and
sends one at a time. It reports host time from first serial write to ACK and the
guest's injection duration separately. After 15 seconds without an ACK, the
active result becomes unknown, queued keys are cancelled without being sent,
and further input pauses. A late matching acknowledgement resolves that outcome;
no automatic key retry occurs. Preparation errors require a fresh guest session.

`test_bridge_controller.py` passes six host tests covering credential and hash
failures, preinstalled assets, bounded queueing, response timing, timeout without
retry, late acknowledgement, reattachment and session reset. Guest deployment
and measured latency remain pending.
