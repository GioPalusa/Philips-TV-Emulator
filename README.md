# Philips 55OLED803/12 emulator workspace

The emulator source patch, local viewer, virtual remote, Ambilight model,
installation tools, and verification notes are in
[outputs/philips-55oled803/emulator](outputs/philips-55oled803/emulator/README.md).

This repository records the development sources and selected evidence.
Firmware archives, generated disk images, compiled binaries, runtime captures,
third-party build trees, and private credentials are ignored. They are needed
locally for some build and launch steps; a checkout alone is not a runnable TV.
See the emulator and software-graphics READMEs for provenance and reproduction.

Current milestone: the firmware's Android framework has completed boot, rendered
its stock boot animation through the software graphics adaptation, and accepted
virtual remote input. TV-like responsiveness and a reliably usable launcher
remain development work.
