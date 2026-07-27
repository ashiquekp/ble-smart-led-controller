#pragma once

#include <Arduino.h>
#include "config.h"

struct CRGB; // fwd-declare to avoid pulling FastLED.h into every includer

// Thin, safe wrapper around the LED driver. Nothing outside this file
// should touch FastLED directly for POWER/BRIGHTNESS/SOLID COLOR — that
// keeps ownership of those clear. The effects engine (Phase 3) is the
// one exception: it needs direct pixel access to animate, so it reads
// the buffer via rawLeds() and pushes frames via show().
class LedManager {
public:
    void begin();

    // Applies a solid color across the whole strip at the current
    // brightness. Only used when no animated effect is active.
    void setSolidColor(uint8_t r, uint8_t g, uint8_t b);

    void setBrightness(uint8_t brightness);
    void setPower(bool on);

    uint8_t brightness() const { return _brightness; }
    bool    power() const { return _power; }

    // Direct buffer access for the effects engine only.
    CRGB*    rawLeds();
    uint16_t ledCount() const { return LED_STRIP_COUNT; }
    void     show(); // pushes whatever is currently in the buffer

private:
    void applyAndShow();

    uint8_t _lastR = DEFAULT_R;
    uint8_t _lastG = DEFAULT_G;
    uint8_t _lastB = DEFAULT_B;
    uint8_t _brightness = DEFAULT_BRIGHTNESS;
    bool    _power = true;
};

extern LedManager ledManager;
