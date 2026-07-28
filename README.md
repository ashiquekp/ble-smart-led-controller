# BLE Smart RGB / LED Strip Controller

A full-stack smart lighting system: a Flutter mobile app controlling a
WS2812B LED strip on a Seeed Studio XIAO ESP32-C3, entirely over a custom
Bluetooth Low Energy protocol — in the spirit of Philips Hue / Govee /
WLED, but designed and built from scratch as a portfolio project.

![Status](https://img.shields.io/badge/status-feature--complete-brightgreen)
![Platform](https://img.shields.io/badge/platform-Flutter%20%7C%20ESP32--C3-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## What it does

- Scan for and connect to the LED controller over BLE, with automatic
  reconnection (exponential backoff) if the link drops
- Live color control via a hue-wheel picker, and brightness control
- Five animated effects — Rainbow, Breathing, Chase, Fire, and Solid —
  driven by a non-blocking firmware effects engine, with speed control
- On/off scheduling (one-time or weekly-repeating), synced against a
  lightweight wall-clock the app maintains for the device
- Session history: connect/disconnect times, duration, and summary stats
- A one-tap "reconnect to last device" shortcut

## Why it's interesting (not just a tutorial clone)

- **A self-designed binary BLE protocol** — one command characteristic
  with a versioned, length-prefixed, checksummed packet format, not a
  characteristic-per-feature. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- **A scheduler with no RTC or WiFi in scope** — the firmware can't know
  "real" time on its own, so the app syncs local time once per
  connection and the firmware tracks drift via `millis()`, deliberately
  avoiding epoch/timezone complexity that wouldn't pay for itself here.
- **Fully non-blocking firmware** — effects, status LEDs, and scheduling
  all use a `tick(millis())` pattern; there's no `delay()` anywhere in
  the animation or timing path.
- **Reconnection policy lives in the data layer, not the UI** — the
  Flutter app's BLE repository owns retry/backoff logic entirely; the UI
  just reacts to a status stream.

## Project structure

```
firmware/          ESP32-C3 firmware (PlatformIO, Arduino framework)
  include/          Headers: config, ble_manager, led_manager,
                     effects_engine, status_indicator, scheduler
  src/               Implementations + main.cpp (orchestration only)

app/                Flutter mobile app
  lib/
    core/            Theme, constants, shared providers
    domain/          Models + repository contracts (no BLE plugin deps)
    data/            BLE repository implementation, codec, local storage
    features/        scanning, connection, control, scheduling, history

docs/
  ARCHITECTURE.md    System design, GATT/protocol spec, per-phase design notes
  WIRING.md          Hardware wiring + diagram
  ROADMAP.md         Phase-by-phase build history
  INTERVIEW_NOTES.md Talking points and Q&A this project supports
  RESUME.md          ATS-friendly bullet points and project description
```

## Hardware

| Component | Role |
|---|---|
| Seeed Studio XIAO ESP32-C3 | Main controller, BLE + LED driver |
| WS2812B-60L-IP20-B (1m, 60 LEDs) | Addressable RGB strip |
| Extra LEDs + 220Ω resistors | BLE connection/status indicators |
| Breadboard, jumper wires | Prototyping |

Full wiring diagram and power budget notes: [docs/WIRING.md](docs/WIRING.md).

## BLE protocol at a glance

One service, two characteristics:

| Characteristic | Direction | Purpose |
|---|---|---|
| Command (write) | App → Device | All control commands |
| Status (read/notify) | Device → App | Live state + connection health |

Packet format: `[opcode][payload_len][payload...][xor_checksum]`.
Full opcode table in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Getting started

### Firmware

```bash
cd firmware
# Open in PlatformIO (VS Code extension), then:
pio run -t upload
pio device monitor
```

Wire the strip per [docs/WIRING.md](docs/WIRING.md) before powering on.

### App

```bash
cd app
flutter create --platforms=android .   # generates the android/ project
flutter pub get
```

Add the required BLE permissions to `android/app/src/main/AndroidManifest.xml`
— see [app/README.md](app/README.md) for the exact snippet — then:

```bash
flutter run
```

## Build history

This repo was built in phases, each landing as its own commits — see
[docs/ROADMAP.md](docs/ROADMAP.md) or `git log --oneline` for the full
progression from BLE bring-up through effects, reconnection, scheduling,
and history logging.

## License

MIT — see [LICENSE](LICENSE).
