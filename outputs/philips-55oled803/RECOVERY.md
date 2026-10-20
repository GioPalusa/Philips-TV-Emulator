# Recovery for Philips 55OLED803/12 (TPM171E)

## What is prepared

- The TV reports firmware `TPM171E_R.107.001.143.000` and board `PH7M_EU_5596`.
- `upgrade_loader.pkg` was extracted from `TPM171E_107.1.143.0_upgrade_loader.zip`, linked for TPM171E in the [Toengel firmware archive](https://toengel.net/philipsblog/firmware-archiv/).
- The ZIP download is 2,154,113,926 bytes, contains one entry, and passed `unzip -tq` CRC validation. SHA-256: `4e195d9a5948aa1bdb08c5008add421782158d5fc036e569a0f15f0431fdf0e7`.
- The extracted `upgrade_loader.pkg` is 2,183,351,736 bytes. SHA-256: `8a0f33ae0d95a28935b2c7a2753524503506b837085fe7114f5734ec7c73f6d9`.

## Decide whether to flash

- **ADB/network connection lost but TV picture and menus still work:** restore the network connection or ADB authorization. Firmware flashing is not indicated.
- **TV crashes or freezes after a temporary root attempt:** unplug power, wait, then reconnect power without the recovery USB. The temporary kernel-memory patch disappears after a full power cycle.
- **Persistent bootloop or stuck at the Philips logo after a boot-partition flash:** use the USB recovery procedure below.

## USB recovery procedure

This follows [Toengel's upgrade-loader recovery instructions](https://toengel.net/philipsblog/philips-downgrade-mit-upgrade-loader/). It has **not** been physically tested on this individual TV.

1. Use a spare, fast USB stick of **8 GB or less**. Format the physical stick with an **MBR partition map** and one **FAT32** partition. Formatting erases the stick. A larger stick with an 8 GB partition may work, but the small-stick route is documented.
2. Copy **only `upgrade_loader.pkg`** to the root of the FAT32 stick. Do not copy the ZIP or `autorun.upg` for this procedure. Verify the copied file's size is 2,183,351,736 bytes. If possible, compare its SHA-256 with the value above.
3. Disconnect the TV from power and remove other cables, including CAM/CI modules. Insert the stick into the **black USB 2.0 port**.
4. Reconnect power. Leave the remote untouched initially; the TV should start the loader automatically. If nothing happens, try powering on with the remote. The source also describes disconnecting and reconnecting power with the stick inserted if the loader does not start.
5. Allow **up to 25 minutes** for recovery. Do not interrupt power during an active installation. When finished, remove the stick and delete the package from it so it cannot be installed accidentally again.
6. If the TV boots but behaves inconsistently, the source recommends **Settings → All settings → General settings → Reinstall TV**. This factory reset erases TV settings and installed-app data.

## Limits

The package is community-hosted and matches the TV's firmware family and version; its ZIP integrity was checked locally. Recovery is **not guaranteed**. A failed bootloader, damaged device-specific NVM/calibration data, or a TV that cannot start the USB loader may require a service serial/ISP procedure or board repair. A full live backup of unique partitions has not been made yet because the current ADB shell lacks root.
