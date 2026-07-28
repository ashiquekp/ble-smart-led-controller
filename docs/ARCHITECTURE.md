# Architecture

## Overview

```
Flutter App                         ESP32-C3 Firmware
------------                        ------------------
UI screens (dashboard, control)     BLE manager (advertising, GATT)
Riverpod state                      LED manager (FastLED wrapper)
BLE service layer (encode/decode)   Effects engine (non-blocking)
                                     Scheduler (timers)
                                     Status LED indicators
        \___________ custom binary BLE protocol ___________/
```

The app never talks "colors" or "effects" directly to the BLE plugin — it
goes through a single `BleCommandCodec` that turns domain models into binary
packets, and a single `BleConnectionRepository` that owns the actual
connection. This keeps the BLE plugin swappable and the domain layer 100%
testable without hardware.

## Why one command characteristic instead of one-per-feature

A characteristic-per-feature (one for color, one for brightness, one for
effect...) is the "tutorial" approach. Real products (WLED, Govee, Tuya)
use a small number of characteristics with structured binary payloads,
because:

- Multi-field updates (e.g. "set color AND brightness") should be atomic —
  one write, one state transition on the device.
- Fewer BLE round-trips = lower latency, less connection interval overhead.
- It's versionable: add new opcodes without changing the GATT table, so
  firmware and app can evolve independently.

## GATT design

**Service:** BLE Smart LED Service (custom 128-bit UUID)

| Characteristic | Properties | Direction | Purpose |
|---|---|---|---|
| Command | Write, Write-without-response | App → Device | All control commands |
| Status | Read, Notify | Device → App | State, connection health, sensor/status data |

### Command packet format

```
Byte 0:   opcode        (1 byte)
Byte 1:   payload_len   (1 byte)
Byte 2..n: payload      (opcode-specific)
Byte n+1: checksum      (1 byte, XOR of all preceding bytes)
```

### Advertising packet layout

A legacy BLE advertising PDU is capped at 31 bytes, which isn't enough
for flags + a 128-bit service UUID + a device name in one packet. The
firmware splits them across the two independent 31-byte budgets legacy
advertising provides:

- **Advertising data**: flags + the service UUID (so scanners can
  filter by service without connecting)
- **Scan response data**: the device name

(This was found the hard way during Phase 1 hardware bring-up — see
`docs/TROUBLESHOOTING.md`.)

### Opcode table (v1)

| Opcode | Name | Payload |
|---|---|---|
| 0x01 | SET_POWER | 1 byte: 0 = off, 1 = on |
| 0x02 | SET_COLOR | 3 bytes: R, G, B |
| 0x03 | SET_BRIGHTNESS | 1 byte: 0–255 |
| 0x04 | SET_EFFECT | 1 byte: effect ID |
| 0x05 | SET_SPEED | 1 byte: 0–255 |
| 0x06 | SET_SCHEDULE | 4 bytes: action (0=off,1=on,2=clear), hour, minute, repeatMask |
| 0x07 | REQUEST_STATUS | 0 bytes |
| 0x08 | SYNC_TIME | 4 bytes: hour, minute, second, weekday (0=Sunday) |

Opcodes 0x09–0x1F are reserved for future features (multi-zone, custom
effect params) without breaking the wire format.

### Status packet format (notify)

```
Byte 0:   power        (0/1)
Byte 1-3: current RGB
Byte 4:   brightness
Byte 5:   effect ID
Byte 6:   speed
Byte 7:   error_code   (0 = ok)
```

## Effects engine design (Phase 3)

`EffectsEngine` writes directly into `LedManager`'s pixel buffer and is
driven from `loop()` via a single `tick(millis())` call — there is no
`delay()` anywhere in the animation path, since a blocked `loop()` would
also stall other future firmware work sharing the main task.

- **Speed → frame interval**: `speed` (0-255) maps to a frame interval
  between 80ms (slow) and 8ms (fast); `tick()` no-ops until that interval
  has elapsed, so effects self-throttle without blocking.
- **Effect registry**: `EffectId` enum (`SOLID`, `RAINBOW`, `BREATHING`,
  `CHASE`, `FIRE`) — adding a new effect means adding an enum value and a
  `step*()` method, no changes to the dispatch/BLE layer.
- **Fire** uses a classic Fire2012-style heat-diffusion algorithm sized to
  whatever `LED_STRIP_COUNT` is configured.
- **Breathing** temporarily overrides the strip's global brightness with
  a sine pulse (`beatsin8`) while active; switching back to `SOLID`
  restores the user's actual brightness setting.

## Status indicators + reconnection (Phase 4)

**Firmware — `StatusIndicator`**: drives the three status LEDs from BLE
connection/error events, decoupled from `BleManager` via two callback
types (`ConnectionEventHandler`, `ErrorHandler`) so `BleManager` doesn't
need to know LEDs exist. Same non-blocking `tick()` pattern as the
effects engine — advertising blinks slowly, error blinks fast, connected
is solid.

**App — automatic reconnection**: `FlutterBluePlusRepository` tracks
whether a disconnect was user-initiated (via `disconnect()`) or not. An
unexpected drop triggers `_scheduleReconnect()`: up to 3 attempts with
exponential backoff (1s, 2s, 4s), surfacing `ConnectionStatus.reconnecting`
throughout. If all attempts fail, it lands on `ConnectionStatus.error`
(rather than silently giving up), and the Connection screen offers a
manual "Retry" button. A short interview-worthy point: the backoff and
retry-count live entirely in the repository, not the UI — the UI just
reacts to a status stream, so the retry policy could change without
touching any widget.

**App — last-device persistence**: on every successful connect, the
device id/name is saved via `LastDeviceStorage` (SharedPreferences). The
scan screen shows a "Last used" banner for one-tap reconnect, without
requiring a fresh scan to find the same device again.

## Scheduling (Phase 5)

**The core design problem**: the XIAO ESP32-C3 has no battery-backed RTC,
and this project has no WiFi/NTP in scope — so the firmware has no way
to know "real" time on its own.

**The chosen solution**: rather than epoch timestamps + timezone
handling (which would add real complexity for a single on/off timer),
the app sends the phone's current **local** time once per connection
(`SYNC_TIME`: hour/minute/second/weekday), and `Scheduler` advances that
clock using `millis()` elapsed since the sync. This drifts slowly (no
crystal-accurate reference) but is entirely acceptable for a lighting
schedule, and sidesteps an entire class of timezone/epoch bugs. Worth
stating plainly in an interview: this was a deliberate scope trade-off,
not an oversight — a DS3231-style RTC module would be the natural next
step for long-unattended accuracy.

- **Single schedule slot** in v1 — `SET_SCHEDULE` always targets slot 0.
  The wire format (opcode + length-prefixed payload) already supports
  adding a slot-index byte later without breaking existing clients.
- **One-shot vs repeating**: `repeatMask == 0` means "fire once, then
  disable"; a non-zero bitmask (bit0=Sunday..bit6=Saturday) repeats
  weekly on the matching days.
- **Fire guard**: `Scheduler` tracks a monotonic "minutes since sync"
  counter for the last fire, not a minute-of-day value — so a daily
  repeat correctly fires again the next day without extra day-rollover
  bookkeeping, and a schedule can never double-fire within one matching
  minute.
- **App side**: `ConnectionController` sends `SYNC_TIME` automatically
  right after every successful connect (including after an automatic
  reconnect), so the clock the scheduler uses is never more than one
  connection-session old.

## Session history (Phase 6)

Purely client-side — the firmware has no involvement (there's nothing
for it to log; it doesn't persist anything across power cycles by
design). `ConnectionController` already sees every connection state
transition, so it's the natural place to bookend a session:

- A session starts the first time status becomes `connected` after being
  disconnected — importantly, a **reconnect that recovers mid-session
  extends the existing session** rather than starting a new one (checked
  via `_sessionStart ??= ...`, not an unconditional assignment).
- A session ends on `disconnected` (intentional) or `error` (automatic
  reconnection exhausted its attempts) — both go through the same
  `_closeSessionIfOpen()` so there's one code path for "a session just
  ended," not two.
- `HistoryStorage` persists a capped rolling list (50 entries) via
  SharedPreferences, newest first.

## Firmware modules

- `ble_manager` — advertising, GATT setup, command parsing, notify dispatch
- `led_manager` — safe wrapper around the LED driver (color/brightness/power)
- `effects_engine` — registry of non-blocking effects (millis()-based)
- `scheduler` — timer-based delayed/repeated actions
- `status_indicator` — extra LEDs reflect BLE connection state
- `config.h` — pins, device name, LED count, defaults

## Flutter modules

- `core/` — theming, constants, error types
- `data/ble/` — BLE plugin wrapper, packet encode/decode (`BleCommandCodec`)
- `domain/models/` — `LedColor`, `EffectPreset`, `Schedule`, `DeviceInfo`
- `domain/repositories/` — abstract contracts (mockable for tests)
- `features/scanning/` — discover + saved device list
- `features/connection/` — connect screen, connection state UI
- `features/control/` — dashboard: color, brightness, effects, speed
- `features/scheduling/` — timer UI
- `features/history/` — session/usage log screen
- `features/settings/`
