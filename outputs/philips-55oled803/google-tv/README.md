# Google TV Basic home on the physical 55OLED803/12

Updated **21 October 2026**, from physical-TV observations made on **20 October 2026** (Europe/Stockholm). This report describes the retail TV, separately from the model-specific QEMU emulator.

## Current result

An adapted **Google TV Home 1.0.478096200 (174690)** runs on the physical Philips 55OLED803/12 and is selected for the Home button. The TV still runs **Android 8.0.0 / API 26**, firmware **TPM171E_R.107.001.143.000**, with 32-bit ARM userspace on MT5891. This is an interface backport, not a newer Android OS, firmware flash or certified Google TV conversion.

The final installed APK has SHA-256:

```text
88bacd76c160487437bab3a8eebae70fdfa4518e0a81664e9367b9fb4cdadb71
```

Its installed-file readback matched that hash. Local APK signature verification passed v2 and v3. The package uses a local development signing key; Google's original signing identity is not retained. APKs and signing material remain local.

The selected Home component is:

```text
com.google.android.apps.tv.launcherx/.home.VanillaModeHomeActivity
```

## What is available

| Surface | Physical-TV evidence | Limits |
| --- | --- | --- |
| Google TV Basic home | Swedish interface renders, enumerates installed apps and accepts directional focus | Uses the built-in pseudonymous/Basic mode |
| Home button | Preferred Home resolves to the component above; navigation returns to Google TV | Immediate power-on behavior remains untested |
| Installed apps | YouTube launches; Back returns to Google TV | No broad streaming-app or DRM certification claim |
| Inputs / Indatakällor | Opens the retained native input selector directly | Original launcher package remains installed for this component |
| Apple TV / HDMI 1 | Native playback, active source `(0x08, 0x1000)` and routing `0x1000`; owner confirmed **“Picture, sound and Ambilight work”** | Other HDMI ports, HDR/4K formats and standby behavior were not separately validated |
| Philips settings | Opens the native menu with Picture, Sound and Ambilight | No calibration, picture, sound or Ambilight settings were changed |
| Play Store | Original signed store opens its catalogue; native tile opens it and Back returns to Google TV | No new login, app purchase or download was verified |
| Google account | Owner reports native setup says the account already exists | This does not authenticate the modified Google TV launcher |
| Assistant / search | Original signed Assistant opens over Google TV; logs show it launching Plex; Back returns to Google TV | Spoken response was not heard or confirmed by the owner |
| Channel editor / Anpassa kanaler | Opens the original Android TV channel editor; Back returns to Google TV | Edits the original Android TV rows; it does not add rows to Google TV Basic |

The current top row contains **Inputs, Philips settings, Play Store, Assistant and the native channel editor**. An experimental shortcut to the old Android TV HOME was removed after the owner's Back-navigation report. The original package remains installed for native inputs, settings and rollback.

## Root Back crash: reproduced and fixed

The owner reported that pressing Back from Google TV home revealed the old interface. Early checks did not reproduce the exact transition. A later fresh-task test reproduced a crash at **23:36:44**:

```text
java.lang.NoSuchMethodError: No virtual method dream(J)V
in class Landroid/os/PowerManager;
    at ikf.d(Unknown Source:47)
```

The shipped Basic-home Back handler requests `PowerManager.dream(long)` when already at its first row. That method is absent on this TV's Android 8 framework. The crash exposed a screen underneath: Play Store in the controlled reproduction, while an old Android TV HOME task was also present during the owner's report.

The fix consumes Back at the first row without requesting that screensaver operation. Existing setup dismissal and lower-row focus reset are retained. Global screensaver, power and standby settings were not changed. The old HOME shortcut was also removed and its stale tasks cleared.

Final physical checks:

- Four consecutive Back presses at Google TV's root stayed in the same Home activity.
- Back from the native channel editor, Assistant and Inputs returned to Google TV.
- Play Store returned after two Back presses through its own navigation.
- Preferred Home resolved to Google TV after the checks.
- The final live task-stack inspection contained no old Android TV HOME task.

The structured results and artifact identity are in [verification.json](verification.json). The TV was left at Google TV home. Earlier experiment APKs contain this Back bug and are historical snapshots, not the current working build.

## Google account features: the remaining boundary

The original Google apps retain their own account handling. The Play Store catalogue works and an account already exists on the TV. That is separate from a signed-in Google TV launcher profile.

A separate emulator-only probe restored the real LauncherX account selector while keeping the compatibility changes. `HomeActivity` started but repeatedly logged:

```text
Caller isn't signed with recognized keys!
```

The error came through `AccountInvalidator` / `HomeActivityPeerImpl`. The modified APK does not have Google's original signing identity; changing local account-selection branches does not supply that identity. Google's [client authentication documentation](https://developers.google.com/android/guides/client-auth) explains the certificate-bound identity used by its Android services. The observed rejection, rather than that general documentation alone, establishes this build's limit.

**Full Google TV profiles, account switching and its personalized cloud feed remain unresolved.** App/content channel rows inside Google TV Basic are also unimplemented. The native channel editor must not be presented as having restored those rows. A sign-in promotional footer is still visible; it is not evidence that the modified launcher can complete Google TV setup.

## Startup: what can actually be claimed

Google TV is installed and selected for **Home**. An earlier accepted Basic build also passed a force-stop followed by a Home-key relaunch, with one new process observed over 18 seconds. That earlier build is identified separately in the evidence file; it is not a final-build cold-boot test.

**A full physical-TV restart and standby/wake cycle have not been tested.** Immediate Google TV display after power-on is therefore unconfirmed. Philips may resume the last HDMI input, but that is a possibility, not an observed startup result in this investigation.

A future startup test should record the first visible screen, active input, preferred Home, Home-key response, HDMI picture/sound, Ambilight, and standby/wake behavior. No restart was performed merely to update this report.

## Implementation and source boundary

Source package: Google's official **Google TV Android 12 / API 31 ARM64 emulator image, revision 4**. The original launcher requires API 29 and has ARM64 native code. Its APK SHA-256 is:

```text
6424cf054762dbc7a7109fad0456830be2c446a000d489eb3f6419125aa4555e
```

The local adaptation includes:

- API 26 manifest compatibility, the enabled Basic activity and one Basic HOME registration in the installed variant.
- An independently implemented ARMv7 mapped-counter JNI library. Its physical-runtime harness passed invalid-descriptor, shared-mapping, concurrent-increment and persistence checks.
- Runtime-guided fallbacks for framework calls absent on Android 8, including strict view lookup, process naming, asynchronous Handler creation, tracing, lifecycle dispatch, notification queries, text layout, focus styling and accessibility metadata/actions.
- Restored older-Android lifecycle/accessibility handling based on official AndroidX behavior. Android 8 retains its native black elevation shadows.
- Existing anonymous account selection and readiness handling, with Basic-mode profile cleanup suppressed. Services run in their normal user scope; no system privilege was acquired.
- Native Inputs/settings/Google-app entry points and the root Back correction above.

Rebuilds stop on compilation or DEX integrity failures, publish completed DEX files atomically, preserve original resources, align native libraries and sign the resulting APK. A timed-out network transfer was checked against the installed hash before retrying. The final update reconstructed the exact signed APK from a locally verified ZIP-entry delta, checked its full hash on the TV, then used ordinary package installation. Temporary transfer files were removed.

The extracted package, decompiled bytecode, full build workspace, signing key, raw ADB logs and account-bearing captures remain local. This report and its curated evidence do not redistribute Google APKs or device credentials. Local analysis used the REA investigation workflow and APK/DEX tooling; unavailable Java-provider/native analysis was not treated as successful REA decompilation.

## Evidence retained locally

The local `Analysis/google-home/` workspace contains:

| Evidence | What it establishes |
| --- | --- |
| `account-lab/installed-root-back-fix.json` | Installed APK readback matches the final hash |
| `account-lab/back-fix-results.json` | Root Back and native-screen return results |
| `account-lab/root-back-crash.log` | Missing `dream(long)` call before the fix |
| `account-lab/back-fix-task-stack.txt` | Final Home activity and absence of the old HOME task |
| `account-lab/signed-selector-emulator.log` | Modified launcher's account-service rejection in the emulator |
| `account-lab/native-channel-settings.xml` | Native channel editor, rather than Basic-home channel rows |
| `backport/hardware-verification/final-apple-hdmi.txt` | Native Apple TV / HDMI 1 routing |
| `backport/hardware-verification/ambilight-*.json` | Ambilight configuration and processed color observations, not a substitute for seeing the LEDs |
| `backport/hardware-verification/home-restart-observations.json` | Earlier-build process relaunch; not a full TV restart |

The owner's physical HDMI picture/sound/Ambilight confirmation complements the routing/API observations. Empty HDMI screenshots were not counted as visual proof. Raw files may include personal or device-specific data and are not copied into this public repository. [verification.json](verification.json) is a curated summary, not a replacement for raw capture provenance.

## Restore the original Home

With the owner's already authorized ADB connection, select the retained original launcher:

```sh
adb -s "$TV_ADB_SERIAL" shell cmd package set-home-activity --user 0 com.google.android.tvlauncher/.MainActivity
adb -s "$TV_ADB_SERIAL" shell input keyevent 3
```

`TV_ADB_SERIAL` must be set to the TV's ADB serial/address. This changes the Home preference; it does not flash firmware, clear accounts or perform a factory reset.

## Separation from the emulator / OS port

These physical-TV launcher observations do not prove complete Philips fidelity in [the model-specific emulator](../emulator/README.md). Conversely, emulator boot or generic Android 12 guest rendering did not prove this APK worked on the retail TV; the physical checks above provide that evidence.

No newer Android OS image has been built and booted on the physical TV. A board-specific OS port still requires a recovery/readback path and separate validation of the Philips/MediaTek hardware services, native modules, HDMI, tuner, Ambilight, DRM and standby. No physical root exploit, firmware flash or TV reboot was performed for this interface backport.
