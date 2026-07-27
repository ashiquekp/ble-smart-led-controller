#pragma once

#include <Arduino.h>
#include "config.h"

enum class BleState : uint8_t {
    Advertising,
    Connected,
    Error,
};

// Drives the three status LEDs (see docs/WIRING.md for pins) so the
// device's BLE state is visible without needing the phone at all —
// useful for debugging on the bench and for a quick visual sanity check
// during a demo.
//
// Non-blocking: advertising/error states blink via tick(millis()), same
// pattern as EffectsEngine — no delay() calls.
class StatusIndicator {
public:
    void begin();
    void setState(BleState state);
    void tick(uint32_t nowMs);

private:
    void applyPins(bool advertisingOn, bool connectedOn, bool errorOn);

    BleState _state = BleState::Advertising;
    uint32_t _lastBlinkMs = 0;
    bool     _blinkPhase = false;
};

extern StatusIndicator statusIndicator;
