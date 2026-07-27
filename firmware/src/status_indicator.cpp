#include "status_indicator.h"

StatusIndicator statusIndicator;

void StatusIndicator::begin() {
    pinMode(STATUS_LED_ADVERTISING_PIN, OUTPUT);
    pinMode(STATUS_LED_CONNECTED_PIN, OUTPUT);
    pinMode(STATUS_LED_ERROR_PIN, OUTPUT);
    setState(BleState::Advertising);
}

void StatusIndicator::setState(BleState state) {
    _state = state;
    _lastBlinkMs = 0;   // resync blink timing on every state change
    _blinkPhase = false;
}

void StatusIndicator::applyPins(bool advertisingOn, bool connectedOn, bool errorOn) {
    digitalWrite(STATUS_LED_ADVERTISING_PIN, advertisingOn ? HIGH : LOW);
    digitalWrite(STATUS_LED_CONNECTED_PIN, connectedOn ? HIGH : LOW);
    digitalWrite(STATUS_LED_ERROR_PIN, errorOn ? HIGH : LOW);
}

void StatusIndicator::tick(uint32_t nowMs) {
    switch (_state) {
        case BleState::Connected:
            // Solid on connected LED, everything else off. No blinking
            // needed, so this is a no-op after the first apply.
            applyPins(false, true, false);
            return;

        case BleState::Advertising: {
            const uint32_t blinkIntervalMs = 500; // slow, "waiting" blink
            if (nowMs - _lastBlinkMs >= blinkIntervalMs) {
                _lastBlinkMs = nowMs;
                _blinkPhase = !_blinkPhase;
            }
            applyPins(_blinkPhase, false, false);
            return;
        }

        case BleState::Error: {
            const uint32_t blinkIntervalMs = 150; // fast, "attention" blink
            if (nowMs - _lastBlinkMs >= blinkIntervalMs) {
                _lastBlinkMs = nowMs;
                _blinkPhase = !_blinkPhase;
            }
            applyPins(false, false, _blinkPhase);
            return;
        }
    }
}
