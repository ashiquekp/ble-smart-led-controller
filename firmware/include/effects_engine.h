#pragma once

#include <Arduino.h>
#include <FastLED.h>
#include "config.h"

// Effect IDs — sent by the app in SET_EFFECT and mirrored back in the
// Status notify's effectId byte. 0 is reserved for "no animation, solid
// color" and is handled by LedManager directly, not here.
enum EffectId : uint8_t {
    EFFECT_SOLID     = 0,
    EFFECT_RAINBOW   = 1,
    EFFECT_BREATHING = 2,
    EFFECT_CHASE     = 3,
    EFFECT_FIRE      = 4,
    EFFECT_COUNT     = 5,
};

// Drives one animated effect at a time directly into the LedManager's
// pixel buffer. Entirely non-blocking: tick() is cheap to call on every
// loop() iteration and internally rate-limits itself based on _speed —
// there is no delay() anywhere in this class, which matters because a
// blocked loop() would also stall BLE command processing.
class EffectsEngine {
public:
    // leds/count come from LedManager::rawLeds()/ledCount() — the engine
    // does not own the buffer, it just writes into it.
    void begin(CRGB* leds, uint16_t count);

    void setEffect(uint8_t effectId);
    void setSpeed(uint8_t speed);                       // 0-255
    void setColor(uint8_t r, uint8_t g, uint8_t b);      // base color for chase/breathing

    // Call every loop() iteration. No-ops immediately if effect is
    // EFFECT_SOLID or count/leds aren't set.
    void tick(uint32_t nowMs);

    uint8_t currentEffect() const { return _effectId; }

private:
    void stepRainbow();
    void stepBreathing();
    void stepChase();
    void stepFire();

    uint16_t frameIntervalMs() const;
    uint8_t  bpmFromSpeed() const;

    CRGB*    _leds = nullptr;
    uint16_t _count = 0;

    uint8_t  _effectId = EFFECT_SOLID;
    uint8_t  _speed = 128;
    uint8_t  _baseR = DEFAULT_R;
    uint8_t  _baseG = DEFAULT_G;
    uint8_t  _baseB = DEFAULT_B;

    uint32_t _lastFrameMs = 0;
    uint8_t  _rainbowHue = 0;
    int16_t  _chasePos = 0;
    uint8_t* _fireHeat = nullptr; // allocated in begin(), sized to _count
};

extern EffectsEngine effectsEngine;
