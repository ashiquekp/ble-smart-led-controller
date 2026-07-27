#pragma once

#include <Arduino.h>
#include "config.h"

// Thin, safe wrapper around the LED driver. Nothing outside this file
// should touch FastLED directly — that keeps effects_engine (Phase 3)
// and the scheduler (Phase 5) working purely in terms of "set solid
// color" / "set brightness" rather than raw pixel arrays.
class LedManager {
public:
    void begin();

    // Applies a solid color across the whole strip at the current
    // brightness. Effects (Phase 3) will bypass this and drive pixels
    // themselves each tick, then call show().
    void setSolidColor(uint8_t r, uint8_t g, uint8_t b);

    void setBrightness(uint8_t brightness);
    void setPower(bool on);

    uint8_t brightness() const { return _brightness; }
    bool    power() const { return _power; }

private:
    void applyAndShow();

    uint8_t _lastR = DEFAULT_R;
    uint8_t _lastG = DEFAULT_G;
    uint8_t _lastB = DEFAULT_B;
    uint8_t _brightness = DEFAULT_BRIGHTNESS;
    bool    _power = true;
};

extern LedManager ledManager;
