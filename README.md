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
its stock boot animation, and accepted virtual remote input. Actual Android
guest GLES pixel and shader tests now execute through ANGLE on the Mac's Metal
GPU. This is a development graphics adaptation; Mali hardware emulation,
TV-like responsiveness and a reliably usable launcher remain incomplete.

## Physical TV: Google TV interface

An adapted Google TV Basic home now runs on the retail 55OLED803/12, with
native Inputs, Philips settings, Play Store and Assistant access. HDMI 1 picture,
sound and Ambilight were confirmed on the physical TV. The root Back crash was
reproduced and fixed. This leaves Android 8 in place; Google TV account profiles,
its personalized feed, channel rows within Basic mode, and immediate power-on
behavior remain unresolved or untested.

See the [physical-TV findings and verification](outputs/philips-55oled803/google-tv/README.md).
These are separate from the emulator's boot and graphics milestones above.

The [development history in the wiki](https://github.com/GioPalusa/Philips-TV-Emulator/wiki/Development-History)
records the verified stages, evidence, commits and remaining work.
