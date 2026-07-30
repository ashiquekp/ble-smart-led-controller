# Troubleshooting

Real issues hit during hardware bring-up, kept here rather than silently
fixed and forgotten — this is exactly the kind of thing that comes up in
an interview ("tell me about a bug you had to track down").

## No Serial output at all, even though upload succeeds

**Symptom**: `pio run -t upload` succeeds, `pio device monitor` connects
to the right COM port, but nothing ever prints — not even garbage.

**Cause**: the XIAO ESP32-C3 has no separate USB-to-UART bridge chip
(unlike many other dev boards) — it uses the ESP32-C3's native USB
Serial/JTAG peripheral instead. The Arduino framework needs to be told
explicitly to route `Serial` over that peripheral; without it, calls to
`Serial.print()` compile and run fine, they just write to a UART that
isn't connected to anything.

**Fix**: add to `firmware/platformio.ini`:
```ini
build_flags =
    -DARDUINO_USB_MODE=1
    -DARDUINO_USB_CDC_ON_BOOT=1
```
Then re-upload (not just re-open the monitor — the flags need a rebuild).

**Important side note**: this bug only affects *visibility* via Serial.
BLE advertising doesn't depend on Serial at all — `NimBLEDevice::init()`
and `startAdvertising()` run regardless. So if the app still couldn't
find the device before this fix, treat that as a separate problem to
re-check after fixing Serial, not something this fix alone resolves.

## App scan finds nothing

Work through these roughly in order of likelihood:

1. **Testing on an Android emulator.** Emulators generally have no real
   Bluetooth radio — `flutter_blue_plus` will scan indefinitely and find
   nothing. Test on a real Android phone (USB or wireless debugging).
2. **Confirm the firmware is actually advertising** — see the Serial
   issue above first; you need to see
   `[BOOT] Ready and advertising. Waiting for connections...` in the
   monitor before the app has any chance of finding the device.
3. **Device name missing from the advertising packet.** This one is
   subtle and worth understanding: a legacy BLE advertising packet is
   capped at 31 bytes. Flags (~3 bytes) + a 128-bit service UUID
   (~18 bytes) leave too little room for a device name like
   `GlowLink` in the *same* packet — NimBLE silently drops whatever
   doesn't fit rather than raising an error. Diagnosed by scanning with
   a generic tool like **nRF Connect for Mobile**: if the device shows
   up as "UNKNOWN" with only Flags visible (no name, no service UUID),
   this is the cause. Fixed by explicitly splitting advertising data
   (flags + service UUID) from scan response data (device name) in
   `BleManager::begin()` — each gets its own independent 31-byte budget.
   Since our Flutter scan filters by device name, a dropped name means
   the app structurally could never have found the device, regardless
   of permissions or scan code.
4. **Permissions**: on the real device, confirm the app was granted
   Bluetooth/Nearby devices permission (Android settings → Apps → \[app
   name\] → Permissions), not just that a dialog appeared once.
5. **Bluetooth + Location toggled on** on the phone itself (some Android
   versions still gate BLE scan results behind Location being on, even
   with runtime permission granted).
6. **Name filter mismatch**: the app only shows devices whose advertised
   name contains `SmartLED` (see `BleConstants.deviceNamePrefix`), which
   should match firmware's `DEVICE_NAME "GlowLink"`. If you changed
   one without the other, they'll silently stop matching.
