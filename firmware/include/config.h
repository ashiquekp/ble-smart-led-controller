#pragma once

// -----------------------------------------------------------------------
// Device identity
// -----------------------------------------------------------------------
#define DEVICE_NAME "SmartLED-C3"

// -----------------------------------------------------------------------
// BLE Smart LED Service — custom 128-bit UUIDs
// Generated once for this project; keep stable across firmware versions.
// -----------------------------------------------------------------------
#define SERVICE_UUID           "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define COMMAND_CHAR_UUID       "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define STATUS_CHAR_UUID        "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

// -----------------------------------------------------------------------
// Pins
// -----------------------------------------------------------------------
// Main WS2812B strip data pin (XIAO ESP32-C3 usable GPIO)
#define LED_STRIP_PIN     D0
#define LED_STRIP_COUNT   60

// Status indicator LEDs (discrete LEDs through 220ohm resistors),
// used to show BLE connection state: advertising / connected / error.
#define STATUS_LED_ADVERTISING_PIN   D1
#define STATUS_LED_CONNECTED_PIN     D2
#define STATUS_LED_ERROR_PIN         D3

// -----------------------------------------------------------------------
// Defaults
// -----------------------------------------------------------------------
#define DEFAULT_BRIGHTNESS   128   // 0-255
#define DEFAULT_R            255
#define DEFAULT_G            255
#define DEFAULT_B            255

// -----------------------------------------------------------------------
// Command opcodes (see docs/ARCHITECTURE.md for full table)
// -----------------------------------------------------------------------
enum CommandOpcode : uint8_t {
    OP_SET_POWER       = 0x01,
    OP_SET_COLOR       = 0x02,
    OP_SET_BRIGHTNESS  = 0x03,
    OP_SET_EFFECT      = 0x04,
    OP_SET_SPEED       = 0x05,
    OP_SET_SCHEDULE    = 0x06,
    OP_REQUEST_STATUS  = 0x07,
    OP_SYNC_TIME       = 0x08,
};
