# Scoped emulator policy additions

`build_policy.py` reproduces `sepolicy-hostgpu` from the existing software-graphics
JIT policy. Both input and output SHA-256 hashes are pinned in `manifest.json`.
The 63 individual permission additions are listed in `rules.txt`; each is
reparsed and checked by restoring its previous bit/rule and comparing canonical
policy serialization byte-for-byte (`verification.txt`). Permissive-domain and
other policy settings remain unchanged. These files are for the isolated emulator.

## Persistent virtual remote FIFO

The guest's existing UID 2000 `shell` domain creates a private directory under
`/data/local/tmp/philips-input-<session>/` with umask 077. It creates `input.fifo`
using `toybox mkfifo`, opens descriptor 9 read/write, and passes that descriptor
to the persistent `app_process` input bridge. The bridge remains in the existing
shell domain. The directory permissions restrict access to its owner.

An enforcing guest denial showed that `shell` could not create a FIFO labeled
`shell_data_file`. Before this change, direct rules, attribute-derived rules,
and active conditional rules provided **no** TE permissions for this tuple.
The new concrete rule grants only:

```
allow shell shell_data_file:fifo_file { create open read write getattr };
```

`create` supports mkfifo, `open/read/write` support the shared descriptor, and
`getattr` supports descriptor inspection by shell/runtime code. No unlink is
added: the current controller keeps the session FIFO and has no deletion step.
Future cleanup must be reviewed separately. No ioctl, setattr, rename, relabel,
or executable permissions are added.

This is a **type-scoped permission**, not a pathname exception: it covers FIFOs
labeled `shell_data_file` wherever the shell otherwise has access. It creates no
new network endpoint or process-domain transition. DAC, MLS, other SELinux
constraints, and guest enforcement remain applicable. The query helper reports
TE allows only, not a complete SELinux access decision.

`fifo-verification.txt` records the before/after permission masks and successful
reproduction from a fresh build of bundled libsepol. `query_allow.c` is the
read-only inspection source. Host-side semantic verification is complete; live
guest validation follows only after the parent task refreshes the emulator
ramdisk. No physical TV firmware or policy is modified by this build.

Reproduce from the workspace root, choosing a new output filename:

```sh
python3 outputs/philips-55oled803/emulator/host-graphics/guest/policy/build_policy.py \
  outputs/philips-55oled803/emulator/software-graphics/sepolicy-software-graphics \
  work/sepolicy-hostgpu-reproduced
```
