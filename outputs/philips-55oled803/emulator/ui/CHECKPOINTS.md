# Persistent development guest storage

`checkpoint.py` provides an independent **disk checkpoint**, then an optional
persistent writable overlay for future emulator runs. It saves neither guest
RAM nor CPU/peripheral state. Start the guest from reset using the saved disk.
This is only for the isolated local emulator, not a physical-TV update.

## Capture lifecycle

Call `capture_checkpoint(qmp_call, output_path, states, ...)` from a background
operation while preventing simultaneous start/stop/restart or other block graph
changes. `qmp_call(command, arguments=None)` must return the decoded QMP `return`
value, raise on QMP errors, serialize access to its socket, and use a bounded
transport timeout. The viewer's existing method has this shape.

Required caller state:

```python
states = {
    "boot_complete": True,
    "warmup_complete": True,
    "warmup_evidence": "Describe the observed dexopt/service readiness here",
}
```

These are explicit attestations. A black/visible frame, `sys.boot_completed=1`
alone, or elapsed time alone does not prove first-boot work has finished.
Checkpointing too early can preserve incomplete work and cause it to recur.

The helper:

1. Queries supported QMP commands, current run state and `tv-emmc` virtual size.
2. Creates a new private staging directory and empty standalone qcow2 target.
3. Optionally calls an acknowledged fixed guest `sync` callback, then pauses a
   running guest. The callback must return `True`; the helper never sends guest
   shell commands itself.
4. Adds the target with `backing: null`, then starts `blockdev-backup` with
   `sync: full`, `auto-finalize: true`, and `auto-dismiss: false`.
5. Polls `query-jobs` until CONCLUDED, requiring absence of the `error` field.
   Progress callbacks receive the job counters; their units are not guaranteed
   to be bytes. The wait has a bounded deadline.
6. Dismisses the job and removes the target node. It checks qcow2 format, virtual
   size and absence of a backing file, then runs offline `qemu-img check`.
7. Flushes the file and publishes it atomically without overwriting an existing
   destination. It attempts to restore the original running state in `finally`.
   An originally paused guest remains paused.

Example integration:

```python
result = capture_checkpoint(
    emulator.qmp_call,
    checkpoint_path,
    states,
    qemu_img="/opt/homebrew/bin/qemu-img",
    guest_sync=await_fixed_guest_sync,  # Optional; must acknowledge success.
    progress=update_checkpoint_status,
    timeout=600,
)
```

A successful result establishes a complete, checked, independent disk image.
The temporary QEMU snapshot and original base are not backing dependencies.
Save the returned metadata beside the checkpoint for provenance.

### Standalone capture CLI

The CLI needs exclusive ownership of the QMP connection. Release the viewer's
QMP connection while keeping QEMU alive, and prevent other start/stop operations.
Do not connect this CLI to a socket that the viewer still owns. First verify
boot completion and completion of background dexopt/service warmup; record the
observations in `--warmup-evidence`. The output parent directory must exist.

```sh
python3 checkpoint.py capture \
  --qmp /absolute/path/to/qmp.sock \
  --output /absolute/path/warmed-checkpoint.qcow2 \
  --qemu-img /opt/homebrew/bin/qemu-img \
  --boot-complete --warmup-complete \
  --warmup-evidence 'Observed boot property, service readiness and completed dexopt' \
  --timeout 600 --qmp-timeout 10
```

Progress is JSON on stderr; successful metadata is JSON on stdout. Save stdout
beside the image. A new destination is required. `--timeout` bounds the backup
and validation phase; error cleanup has its own bounded interval, and transport
commands have individual timeouts.

If a fixed guest `sync` command has already returned a verified success marker,
add both `--guest-sync-confirmed` and `--guest-sync-evidence 'Observed marker…'`.
This records a prior caller attestation, not a sync executed by the helper.
Consequently `guest_sync_acknowledged` remains false for CLI capture, while
`warmup_attestation.guest_sync_previously_confirmed` records the explicit flag.
Consistency remains crash-consistent. Neither elapsed time nor these flags
perform or independently prove guest warmup.

### Consistency and failures

The saved disk is crash-consistent. Android/ext4 may replay its journal on the
next boot. An acknowledged `sync` before pausing reduces outstanding dirty data,
but is not a filesystem freeze or an application-consistency guarantee.

Timeout or failure triggers cancellation of only this uniquely identified job,
then dismissal and target removal when possible. Resume is always attempted if
the helper requested a stop. If QMP is disconnected or resume fails, the helper
cannot guarantee the VM resumed: it raises `CheckpointError` with explicit
`cleanup_errors` and an artifact path. A completed image can exist even when
resume fails; do not blindly retry capture to the same destination.

Incomplete images remain in a hidden `.NAME.incomplete-*` directory, never at
the requested final filename. `INCOMPLETE.json` records failure and whether a
job/node may still hold the file. Do not use an incomplete image or remove one
while QEMU may still be writing it. The helper does not touch the base image.

## Future persistent runs

Create a new writable overlay over the durable independent checkpoint:

```sh
python3 checkpoint.py overlay \
  --qemu-img /opt/homebrew/bin/qemu-img \
  --base /absolute/path/warmed-checkpoint.qcow2 \
  --output /absolute/path/development-session.qcow2
```

An independent raw image is also accepted as the base. Existing outputs and
bases that already have a backing chain are rejected. The new overlay stores
an absolute backing path; retain that base at the same path.

The future QEMU drive must use:

```text
-drive if=none,format=qcow2,file=/absolute/path/development-session.qcow2,id=tv-emmc
```

Omit `snapshot=on` for that explicit persistent session. Keep controller writes
enabled for the local development guest. Only the new overlay receives writes;
the checkpoint/base stays its read-only backing. Shut QEMU down before copying,
converting, renaming or deleting an active image. A new full checkpoint can later
flatten this session into another independent image.

## Verification

`test_checkpoint.py` launches separate QEMU processes with synthetic 4 MiB
images. It writes a known pattern only into a temporary source overlay, captures
it, compares all disk bytes, stops QEMU, deletes the original base and confirms
the saved disk still reads correctly. Tests also cover persistent overlay
creation, running/paused state restoration, a real throttled-job timeout and
cancellation, failed-start cleanup, failed guest sync, destination preservation
and a reported resume failure with a valid saved image. The standalone CLI is
also tested over an exclusively owned synthetic QMP connection, including
nonempty evidence validation, full byte comparison and resumed guest state.

```sh
python3 test_checkpoint.py -v
```

Set `PHILIPS_CHECKPOINT_TEST_QEMU` and `PHILIPS_QEMU_IMG` to override executable
paths. These tests do not inspect or mutate the running TV emulator.

The command semantics were checked against this build's QEMU 11.1.2
`qapi/block-core.json` and `qapi/job.json`. The implementation uses supported
`blockdev-backup`; it does not depend on the deprecated `drive-backup` command.
Actual capture/reboot of the warmed TV guest remains a separate integration test.
