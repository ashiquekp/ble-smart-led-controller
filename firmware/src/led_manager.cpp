#include "led_manager.h"
#include <FastLED.h>

LedManager ledManager;

static CRGB leds[LED_STRIP_COUNT];

void LedManager::begin() {
    FastLED.addLeds<WS2812B, LED_STRIP_PIN, GRB>(leds, LED_STRIP_COUNT);
    FastLED.setBrightness(_brightness);
    fill_solid(leds, LED_STRIP_COUNT, CRGB(_lastR, _lastG, _lastB));
    FastLED.show();
    Serial.printf("[LED] Strip initialized: %d LEDs on pin %d\n", LED_STRIP_COUNT, LED_STRIP_PIN);
}

void LedManager::setSolidColor(uint8_t r, uint8_t g, uint8_t b) {
    _lastR = r;
    _lastG = g;
    _lastB = b;
    applyAndShow();
}

void LedManager::setBrightness(uint8_t brightness) {
    _brightness = brightness;
    applyAndShow();
}

void LedManager::setPower(bool on) {
    _power = on;
    applyAndShow();
}

void LedManager::applyAndShow() {
    if (!_power) {
        FastLED.setBrightness(0);
        fill_solid(leds, LED_STRIP_COUNT, CRGB::Black);
        FastLED.show();
        return;
    }

    FastLED.setBrightness(_brightness);
    fill_solid(leds, LED_STRIP_COUNT, CRGB(_lastR, _lastG, _lastB));
    FastLED.show();
}
