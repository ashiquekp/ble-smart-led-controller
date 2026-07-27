#pragma once

#include <Arduino.h>
#include <functional>
#include "config.h"

// Current device state, mirrored to the Status characteristic on every
// change so a freshly-connected app can read the live state, and existing
// connections get a notify.
struct DeviceState {
    bool    power        = true;
    uint8_t r             = DEFAULT_R;
    uint8_t g             = DEFAULT_G;
    uint8_t b             = DEFAULT_B;
    uint8_t brightness    = DEFAULT_BRIGHTNESS;
    uint8_t effectId      = 0;     // 0 = solid color, see effects_engine
    uint8_t speed         = 128;
    uint8_t errorCode     = 0;     // 0 = ok
};

// Called whenever a valid command packet is parsed. main.cpp wires this up
// to the LED manager / effects engine / scheduler once those exist.
using CommandHandler = std::function<void(CommandOpcode opcode, const uint8_t* payload, uint8_t len)>;

class BleManager {
public:
    void begin(DeviceState* state);
    void setCommandHandler(CommandHandler handler);

    // Call after any state change so connected clients get a fresh notify.
    void notifyStatus();

    bool isConnected() const { return _connected; }

private:
    DeviceState*   _state = nullptr;
    CommandHandler _onCommand;
    bool           _connected = false;

    friend class ServerCallbacks;
    friend class CommandCharacteristicCallbacks;
};

extern BleManager bleManager;
