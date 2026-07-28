#include <Arduino.h>
#include "config.h"
#include "ble_manager.h"
#include "led_manager.h"
#include "effects_engine.h"
#include "status_indicator.h"
#include "scheduler.h"

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
                if (state.effectId == EFFECT_SOLID) {
                    ledManager.setSolidColor(state.r, state.g, state.b);
                } else {
                    effectsEngine.setColor(state.r, state.g, state.b);
                }
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
                if (state.effectId == EFFECT_SOLID) {
                    // Leaving an animated effect: restore the user's actual
                    // brightness (breathing overrides it while running) and
                    // repaint the solid color.
                    ledManager.setBrightness(state.brightness);
                    ledManager.setSolidColor(state.r, state.g, state.b);
                } else {
                    effectsEngine.setEffect(state.effectId);
                    effectsEngine.setColor(state.r, state.g, state.b);
                    effectsEngine.setSpeed(state.speed);
                }
                Serial.printf("[CMD] SET_EFFECT -> %d\n", state.effectId);
            }
            break;

        case OP_SET_SPEED:
            if (len >= 1) {
                state.speed = payload[0];
                effectsEngine.setSpeed(state.speed);
                Serial.printf("[CMD] SET_SPEED -> %d\n", state.speed);
            }
            break;

        case OP_SET_SCHEDULE:
            if (len >= 4) {
                scheduler.setSchedule(payload[0], payload[1], payload[2], payload[3]);
            }
            break;

        case OP_SYNC_TIME:
            if (len >= 4) {
                scheduler.syncTime(payload[0], payload[1], payload[2], payload[3]);
            }
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
    if (bleManager.isConnected()) {
        statusIndicator.setState(BleState::Connected);
    }
}

void setup() {
    Serial.begin(115200);
    delay(500); // let USB serial settle on the C3
    Serial.println("\n[BOOT] BLE Smart LED Controller — firmware starting");

    ledManager.begin();
    effectsEngine.begin(ledManager.rawLeds(), ledManager.ledCount());
    statusIndicator.begin();
    scheduler.begin();

    bleManager.setCommandHandler(onCommand);
    bleManager.setConnectionEventHandler([](bool connected) {
        statusIndicator.setState(connected ? BleState::Connected : BleState::Advertising);
    });
    bleManager.setErrorHandler([](uint8_t errorCode) {
        statusIndicator.setState(BleState::Error);
    });
    bleManager.begin(&state);

    Serial.println("[BOOT] Ready and advertising. Waiting for connections...");
}

void loop() {
    // Non-blocking by design: effectsEngine.tick(), statusIndicator.tick(),
    // and scheduler.tick() all rate-limit themselves internally and
    // return immediately when idle, so this never stalls BLE command
    // processing.
    uint32_t now = millis();

    // Temporary diagnostic heartbeat (Phase 1/2 bring-up only — safe to
    // remove once BLE connectivity is confirmed working). Prints every
    // 2s regardless of when the monitor attaches, so you don't have to
    // catch the exact reset moment to know the board is alive.
    static uint32_t lastHeartbeat = 0;
    if (now - lastHeartbeat >= 2000) {
        lastHeartbeat = now;
        Serial.printf("[HEARTBEAT] uptime=%lus bleConnected=%d power=%d effect=%d\n",
                      now / 1000, bleManager.isConnected(), state.power, state.effectId);
    }

    if (state.power && state.effectId != EFFECT_SOLID) {
        effectsEngine.tick(now);
    }

    statusIndicator.tick(now);

    if (scheduler.tick(now)) {
        // tick() only clears `enabled` for one-shot schedules — the
        // `action` field itself isn't touched, so this reference still
        // reflects the schedule that just fired.
        const ScheduleEntry& firedSchedule = scheduler.schedule();
        state.power = (firedSchedule.action == SCHEDULE_ACTION_ON);
        ledManager.setPower(state.power);
        bleManager.notifyStatus();
        Serial.printf("[SCHEDULER] Applied scheduled power: %d\n", state.power);
    }
}
