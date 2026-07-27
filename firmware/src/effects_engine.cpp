#include "effects_engine.h"

EffectsEngine effectsEngine;

void EffectsEngine::begin(CRGB* leds, uint16_t count) {
    _leds = leds;
    _count = count;
    if (_fireHeat) {
        delete[] _fireHeat;
    }
    _fireHeat = new uint8_t[_count]();
}

void EffectsEngine::setEffect(uint8_t effectId) {
    if (effectId >= EFFECT_COUNT) return;
    _effectId = effectId;
    _lastFrameMs = 0; // force an immediate frame on the next tick
}

void EffectsEngine::setSpeed(uint8_t speed) {
    _speed = speed;
}

void EffectsEngine::setColor(uint8_t r, uint8_t g, uint8_t b) {
    _baseR = r;
    _baseG = g;
    _baseB = b;
}

// Maps speed (0-255) to a frame interval in ms. Higher speed = shorter
// interval = faster animation. Clamped to a sane range so speed=0 still
// animates (slowly) rather than freezing, and speed=255 doesn't try to
// push frames faster than the strip/BLE stack can realistically handle.
uint16_t EffectsEngine::frameIntervalMs() const {
    const uint16_t minInterval = 8;   // fastest
    const uint16_t maxInterval = 80;  // slowest
    return maxInterval - ((uint32_t)_speed * (maxInterval - minInterval)) / 255;
}

uint8_t EffectsEngine::bpmFromSpeed() const {
    // beatsin8's bpm parameter; mapped to a musically-sane breathing range.
    return 6 + ((uint32_t)_speed * 54) / 255; // ~6-60 bpm
}

void EffectsEngine::tick(uint32_t nowMs) {
    if (_effectId == EFFECT_SOLID || _leds == nullptr || _count == 0) return;
    if (nowMs - _lastFrameMs < frameIntervalMs()) return;
    _lastFrameMs = nowMs;

    switch (_effectId) {
        case EFFECT_RAINBOW:   stepRainbow();   break;
        case EFFECT_BREATHING: stepBreathing(); break;
        case EFFECT_CHASE:     stepChase();     break;
        case EFFECT_FIRE:      stepFire();      break;
        default: return;
    }

    FastLED.show();
}

void EffectsEngine::stepRainbow() {
    uint8_t deltaHue = _count > 0 ? (255 / _count) : 255;
    if (deltaHue == 0) deltaHue = 1;
    fill_rainbow(_leds, _count, _rainbowHue, deltaHue);
    _rainbowHue++; // uint8_t wraps naturally, which is what we want
}

void EffectsEngine::stepBreathing() {
    // beatsin8 gives a smooth sine pulse; used as brightness rather than
    // a per-pixel effect, so this temporarily overrides the strip's
    // global brightness while breathing is active. Switching back to
    // EFFECT_SOLID or another effect restores the user's brightness
    // setting (handled in main.cpp's SET_EFFECT case).
    uint8_t pulse = beatsin8(bpmFromSpeed(), 20, 255);
    fill_solid(_leds, _count, CRGB(_baseR, _baseG, _baseB));
    FastLED.setBrightness(pulse);
}

void EffectsEngine::stepChase() {
    fadeToBlackBy(_leds, _count, 40);
    _chasePos = (_chasePos + 1) % _count;
    _leds[_chasePos] = CRGB(_baseR, _baseG, _baseB);
}

// Classic Fire2012-style fire, adapted to run at whatever strip length
// is configured. Heat diffuses upward and cools randomly each frame;
// heat values map to a fire palette via HeatColor().
void EffectsEngine::stepFire() {
    // Cool down every cell a little.
    for (uint16_t i = 0; i < _count; i++) {
        _fireHeat[i] = qsub8(_fireHeat[i], random8(0, ((55 * 10) / _count) + 2));
    }

    // Heat drifts up and diffuses.
    for (int k = _count - 1; k >= 2; k--) {
        _fireHeat[k] = (_fireHeat[k - 1] + _fireHeat[k - 2] + _fireHeat[k - 2]) / 3;
    }

    // Randomly ignite new sparks near the base of the strip.
    if (random8() < 120) {
        uint16_t sparkPos = random8(7);
        if (sparkPos < _count) {
            _fireHeat[sparkPos] = qadd8(_fireHeat[sparkPos], random8(160, 255));
        }
    }

    for (uint16_t j = 0; j < _count; j++) {
        _leds[j] = HeatColor(_fireHeat[j]);
    }
}
