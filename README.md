# BLE Smart RGB / LED Strip Controller

A BLE-based smart lighting system built with Flutter and an ESP32-C3, in the
spirit of Philips Hue / Govee / WLED — but built from scratch as a learning
and portfolio project.

## What this is

- **Firmware** (`/firmware`): ESP32-C3 (Seeed Studio XIAO) firmware that
  drives a WS2812B RGB LED strip and exposes a custom BLE GATT service.
- **App** (`/app`): Flutter mobile app (Android-first) that scans, connects,
  and controls the device — color, brightness, effects, schedules, and
  connection history — using a custom compact binary protocol over BLE.

## Status

🚧 Under active development. See [ROADMAP.md](docs/ROADMAP.md) for the
phase-by-phase build plan and commit history for progress.

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the system diagram,
BLE GATT design, and firmware/app module breakdown.

## Hardware

| Component | Role |
|---|---|
| Seeed Studio XIAO ESP32-C3 | Main controller, BLE + LED driver |
| WS2812B-60L-IP20-B (1m, 60 LEDs) | Addressable RGB strip |
| Extra LEDs + 220Ω resistors | BLE connection/status indicators |
| Breadboard, jumper wires | Prototyping |

See [docs/WIRING.md](docs/WIRING.md) for the full wiring diagram (added in
Phase 1).

## Getting started

Instructions for flashing firmware and running the app will be added as
each phase lands (Phase 0/1 in progress).
