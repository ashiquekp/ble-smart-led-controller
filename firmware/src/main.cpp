#include <Arduino.h>
#include "config.h"
#include "ble_manager.h"
#include "led_manager.h"

// Single source of truth for device state. LED manager, effects engine,
// and scheduler (added in later phases) will all read/write this struct
// through BleManager rather than owning their own copies.
static DeviceState state;

// Handles parsed, checksum-valid commands from the app.
// Updates shared state, drives the LED strip through LedManager, and
// logs to Serial for debugging. Effects (Phase 3) and scheduling
// (Phase 5) hook into this same dispatch.
static void onCommand(CommandOpcode opcode, const uint8_t* payload, uint8_t len) {
    switch (opcode) {
        case OP_SET_POWER:
            if (len >= 1) {
                state.power = payload[0] != 0;
                ledManager.setPower(state.power);
                Serial.printf("[CMD] SET_POWER -> %d\n", state.power);
            }
            break;

        case OP_SET_COLOR:
            if (len >= 3) {
                state.r = payload[0];
                state.g = payload[1];
                state.b = payload[2];
                ledManager.setSolidColor(state.r, state.g, state.b);
                Serial.printf("[CMD] SET_COLOR -> R:%d G:%d B:%d\n", state.r, state.g, state.b);
            }
            break;

        case OP_SET_BRIGHTNESS:
            if (len >= 1) {
                state.brightness = payload[0];
                ledManager.setBrightness(state.brightness);
                Serial.printf("[CMD] SET_BRIGHTNESS -> %d\n", state.brightness);
            }
            break;

        case OP_SET_EFFECT:
            if (len >= 1) {
                state.effectId = payload[0];
                Serial.printf("[CMD] SET_EFFECT -> %d\n", state.effectId);
            }
            break;

        case OP_SET_SPEED:
            if (len >= 1) {
                state.speed = payload[0];
                Serial.printf("[CMD] SET_SPEED -> %d\n", state.speed);
            }
            break;

        case OP_SET_SCHEDULE:
            Serial.println("[CMD] SET_SCHEDULE received (scheduler lands in Phase 5)");
            break;

        case OP_REQUEST_STATUS:
            Serial.println("[CMD] REQUEST_STATUS");
            break;

        default:
            Serial.printf("[CMD] Unknown opcode: 0x%02X\n", opcode);
            return; // don't notify on unknown opcode
    }

    state.errorCode = 0;
    bleManager.notifyStatus();
}

void setup() {
    Serial.begin(115200);
    delay(500); // let USB serial settle on the C3
    Serial.println("\n[BOOT] BLE Smart LED Controller — firmware starting");

    ledManager.begin();

    bleManager.setCommandHandler(onCommand);
    bleManager.begin(&state);

    Serial.println("[BOOT] Ready and advertising. Waiting for connections...");
}

void loop() {
    // Phase 1: nothing time-based yet. Effects engine (Phase 3) and
    // scheduler (Phase 5) will need non-blocking millis()-based ticking
    // here — no delay() calls, ever, once LEDs are driven.
}
