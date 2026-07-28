# Interview notes

Talking points and likely questions this project equips you to answer
well, organized by theme. Each answer references the actual design
decision in the code, not a generic textbook answer.

## BLE / protocol design

**Q: Why one command characteristic instead of one per feature (color,
brightness, effect...)?**
A: A characteristic-per-feature is the tutorial approach. Real products
(WLED, Govee, Tuya) use a small number of characteristics with
structured binary payloads because multi-field updates should be atomic
(one write, one state transition), it minimizes BLE round-trips, and
it's versionable — new opcodes can be added without changing the GATT
table. See `docs/ARCHITECTURE.md` → GATT design.

**Q: Walk me through your packet format.**
A: `[opcode][payload_len][payload...][xor_checksum]`. The length prefix
means the protocol isn't locked to fixed-size payloads — `SYNC_TIME` and
`SET_SCHEDULE` both use 4-byte payloads that were added well after the
original 1–3 byte commands, with zero changes to the parsing code path.
The checksum is deliberately simple (XOR) — BLE already has its own
link-layer CRC, so this is a second, cheap application-layer sanity
check against a corrupted or truncated GATT write, not meant to replace
transport-level error correction.

**Q: What happens with a malformed packet?**
A: `BleManager` validates checksum and length before the opcode ever
reaches command dispatch. On failure it sets `errorCode` on the shared
`DeviceState`, notifies the app, and fires an `ErrorHandler` callback
that the status LED reacts to — all without ever calling into
`LedManager` or `EffectsEngine` with bad data.

## Firmware architecture

**Q: How is the firmware organized, and why?**
A: Each concern is an isolated module with a narrow interface:
`BleManager` (transport), `LedManager` (hardware output + power/
brightness/solid-color ownership), `EffectsEngine` (animation, given
direct buffer access via `LedManager::rawLeds()`), `StatusIndicator`
(visual BLE state), `Scheduler` (timer logic). `main.cpp` is orchestration
only — it wires callbacks between modules and does not itself own logic.
Any module can be tested/reasoned about independently.

**Q: Why is nothing blocking (`delay()`)?**
A: A blocked `loop()` would stall the whole cooperative-scheduling
system — status LED blinking, effect frames, and BLE command processing
all share one thread on the Arduino framework. Every module that needs
to do something time-based (`EffectsEngine`, `StatusIndicator`,
`Scheduler`) uses a `tick(millis())` pattern: check elapsed time, no-op
if not due, otherwise do one unit of work and return.

**Q: How does speed (a 0–255 UI slider) become animation timing?**
A: `EffectsEngine::frameIntervalMs()` linearly maps 0–255 to an 8–80ms
frame interval. This is a small but real example of translating a
UI-friendly abstraction into a hardware-appropriate unit.

## The scheduler's clock problem

**Q: How does scheduling work without a battery-backed RTC?**
A: It doesn't try to know "real" time independently. The XIAO ESP32-C3
has no RTC, and this project has no WiFi/NTP in scope. Rather than epoch
timestamps + timezone conversion (real complexity for a single on/off
timer), the app sends its current local time once per connection
(`SYNC_TIME`), and `Scheduler` advances that using `millis()` elapsed
since the sync. This drifts slowly over long sessions — an accepted,
documented trade-off, not an oversight. A DS3231-style RTC module would
be the natural next step for long-unattended accuracy.

**Q: How do you avoid a repeating schedule double-firing?**
A: The fire guard is a monotonic "minutes since sync" counter, not a
minute-of-day value — so a daily repeat correctly fires again the next
day without extra day-rollover bookkeeping, and it structurally can't
fire twice within the same matching minute regardless of how often
`tick()` is called.

## App architecture (Flutter/Riverpod)

**Q: How is BLE abstracted in the app?**
A: `BleRepository` is an abstract contract; `FlutterBluePlusRepository`
is the only file that imports the BLE plugin directly. Every feature
(scanning, connection, control, scheduling, history) depends on the
abstraction, so the whole app is unit-testable against a fake
implementation, and the underlying BLE plugin could be swapped by
touching one file.

**Q: How do you keep the color wheel feeling responsive without
flooding the BLE link?**
A: `previewColor()` updates local UI state instantly (no network call);
`sendColor()` is debounced 80ms behind it. Dragging the wheel feels
immediate, but a fast drag gesture doesn't turn into a command-per-pixel
flood over the air. This is a general "optimistic UI decoupled from its
network side-effect" pattern, not BLE-specific.

**Q: How does reconnection work?**
A: `FlutterBluePlusRepository` distinguishes a user-requested disconnect
from an unexpected drop. An unexpected drop triggers up to 3 retries
with exponential backoff (1s/2s/4s), surfaced as
`ConnectionStatus.reconnecting`. If all attempts fail, it lands on
`ConnectionStatus.error` with a manual retry option, rather than
silently giving up. The retry policy lives entirely in the repository —
the UI just reacts to a status stream, so the policy could change
without touching a widget.

**Q: How is state management structured?**
A: Riverpod `StateNotifier`s per feature (`ConnectionController`,
`LedControlController`, `SchedulingController`), each backed by the
shared `BleRepository`. State flows one way: commands go out through the
repository, and the Status characteristic's notify stream flows back in
and resyncs local state — so the UI never drifts out of sync with the
device for long, even if a write silently fails.

## Product/systems thinking

**Q: What's a design trade-off you made and why?**
A: Minimal local persistence (Phase 1 decision) — only the last
connected device is saved, not full presets/favorites. That created a
real tension later: scheduling and history both need *some* persistence,
which is why `LastDeviceStorage` and `HistoryStorage` exist as separate,
narrowly-scoped stores rather than growing a single "app settings" blob.
Good answer to "tell me about a decision you'd revisit": a unified
persistence layer from the start would have been slightly cleaner, at
the cost of building infrastructure before knowing what it needed to hold.
