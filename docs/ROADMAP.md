# Roadmap

- [x] **Phase 0** — Repo scaffolding, README, architecture docs
- [x] **Phase 1** — BLE foundation: firmware advertising + GATT service,
      app scanning + connect/disconnect screen
- [x] **Phase 2** — Basic LED control: color, brightness, power
- [x] **Phase 3** — Effects engine: rainbow, breathing, chase, fire + speed
- [x] **Phase 4** — Status LED indicators + reconnection handling
- [x] **Phase 5** — Scheduling (timers)
- [x] **Phase 6** — Usage/session history logging
- [x] **Phase 7** — Polish: full README, wiring diagrams, interview notes,
      resume-ready project description

## Future work (not implemented, but designed for)

- **Multi-device support**: the app's `BleRepository` abstraction and
  `DeviceInfo` model don't assume a single device, but the UI currently
  connects to one at a time. Extending to a device list/dashboard is a
  UI-layer change, not an architecture change.
- **Multi-slot scheduling**: the wire protocol (length-prefixed payload)
  supports adding a slot-index byte to `SET_SCHEDULE` without breaking
  existing clients; firmware would need a small array instead of one
  `ScheduleEntry`.
- **RTC module**: swapping the sync-once wall clock for a DS3231-style
  RTC (I2C) would remove clock drift entirely for long-unattended
  schedules — the `Scheduler` interface wouldn't need to change, just
  `currentTime()`'s implementation.
- **Full local persistence**: presets/favorites were deliberately scoped
  out in Phase 1 (minimal persistence decision) — `LastDeviceStorage`
  and `HistoryStorage` show the pattern a `PresetStorage` would follow.
- **Automated tests**: the BLE abstraction layers (`BleRepository`,
  `BleCommandCodec`) are structured to be unit-testable against a fake
  implementation; none are written yet.
