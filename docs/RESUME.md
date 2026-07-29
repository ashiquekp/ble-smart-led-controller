# Resume / portfolio description

## Short project description (for a resume "Projects" section)

**BLE Smart RGB LED Strip Controller** — Flutter + ESP32-C3
*Personal project | https://github.com/ashiquekp/ble-smart-led-controller*

Designed and built a full-stack IoT lighting controller: a Flutter
mobile app communicating with custom ESP32-C3 firmware over a
self-designed BLE binary protocol, supporting real-time color/brightness
control, five animated lighting effects, wall-clock scheduling, and
automatic reconnection with exponential backoff.

## ATS-friendly bullet points

Use 2–4 of these depending on the role (adjust verbs/tense as needed):

- Designed and implemented a custom binary BLE protocol (opcode +
  length-prefixed payload + checksum) between a Flutter mobile app and
  ESP32-C3 firmware, enabling atomic multi-field state updates and
  forward-compatible protocol versioning without GATT table changes.
- Built a non-blocking embedded animation engine in C++ (FastLED) driving
  5 real-time lighting effects — including a Fire2012-style heat-diffusion
  simulation — with millis()-based frame timing and zero use of delay().
- Implemented automatic BLE reconnection with exponential backoff (up to
  3 attempts) in Flutter, cleanly separating retry policy from UI state
  using a repository pattern and Riverpod StateNotifiers.
- Designed a lightweight wall-clock scheduling system for a
  battery/RTC-less microcontroller, syncing time from the mobile app and
  tracking drift via elapsed millis() rather than requiring
  epoch/timezone handling.
- Built a feature-based, clean-architecture Flutter app (Riverpod) with
  a fully abstracted BLE data layer, enabling the UI and business logic
  to be unit-tested independently of the physical BLE plugin.
- Authored complete project documentation (architecture, GATT protocol
  spec, wiring diagrams) and maintained a phase-by-phase conventional
  commit history from initial scaffold through feature completion.

## Elevator pitch (verbal, ~30 seconds)

"I built a smart LED strip controller from scratch — a Flutter app
talking to an ESP32-C3 over Bluetooth Low Energy, using a binary
protocol I designed myself rather than a REST-style one. It supports
live color and brightness control, five animated effects including a
simulated fire effect, on/off scheduling, and it automatically
reconnects with backoff if the Bluetooth link drops mid-session. The
interesting part was working within real embedded constraints — no
RTC, no WiFi — so scheduling needed a genuinely different design than
you'd use on a normal backend."

## Suggested skills/tags for a portfolio site or LinkedIn

`Flutter` `Riverpod` `Bluetooth Low Energy (BLE)` `ESP32` `Embedded C++`
`FastLED` `IoT` `GATT/Protocol Design` `Clean Architecture`
`State Management` `Firmware Development`
