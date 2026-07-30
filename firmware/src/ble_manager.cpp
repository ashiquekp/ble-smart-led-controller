#include "ble_manager.h"
#include <NimBLEDevice.h>

BleManager bleManager;

static NimBLEServer*          pServer          = nullptr;
static NimBLECharacteristic*  pCommandChar     = nullptr;
static NimBLECharacteristic*  pStatusChar      = nullptr;

// -----------------------------------------------------------------------
// Packet helpers
// -----------------------------------------------------------------------
// Command packet: [opcode][len][payload...][xor_checksum]
static bool validateChecksum(const uint8_t* data, size_t size) {
    if (size < 3) return false; // opcode + len + checksum minimum
    uint8_t computed = 0;
    for (size_t i = 0; i < size - 1; i++) computed ^= data[i];
    return computed == data[size - 1];
}

// -----------------------------------------------------------------------
// Server (connection) callbacks
// -----------------------------------------------------------------------
class ServerCallbacks : public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* server, NimBLEConnInfo& connInfo) override {
        bleManager._connected = true;
        Serial.println("[BLE] Client connected");
        if (bleManager._onConnectionEvent) {
            bleManager._onConnectionEvent(true);
        }
    }

    void onDisconnect(NimBLEServer* server, NimBLEConnInfo& connInfo, int reason) override {
        bleManager._connected = false;
        Serial.println("[BLE] Client disconnected, resuming advertising");
        if (bleManager._onConnectionEvent) {
            bleManager._onConnectionEvent(false);
        }
        NimBLEDevice::startAdvertising();
    }
};

// -----------------------------------------------------------------------
// Command characteristic write callback
// -----------------------------------------------------------------------
class CommandCharacteristicCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* characteristic, NimBLEConnInfo& connInfo) override {
        std::string value = characteristic->getValue();
        const uint8_t* data = reinterpret_cast<const uint8_t*>(value.data());
        size_t size = value.size();

        if (!validateChecksum(data, size)) {
            Serial.println("[BLE] Dropped packet: checksum mismatch");
            if (bleManager._state) {
                bleManager._state->errorCode = 1; // 1 = bad checksum
                bleManager.notifyStatus();
            }
            if (bleManager._onError) bleManager._onError(1);
            return;
        }

        CommandOpcode opcode = static_cast<CommandOpcode>(data[0]);
        uint8_t payloadLen   = data[1];

        if (payloadLen != size - 3) {
            Serial.println("[BLE] Dropped packet: length mismatch");
            if (bleManager._state) {
                bleManager._state->errorCode = 2; // 2 = bad length
                bleManager.notifyStatus();
            }
            if (bleManager._onError) bleManager._onError(2);
            return;
        }

        if (bleManager._onCommand) {
            bleManager._onCommand(opcode, data + 2, payloadLen);
        }
    }
};

// -----------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------
void BleManager::begin(DeviceState* state) {
    _state = state;

    NimBLEDevice::init(DEVICE_NAME);
    // NimBLE default MTU is enough for our small fixed-size packets.

    pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    NimBLEService* pService = pServer->createService(SERVICE_UUID);

    pCommandChar = pService->createCharacteristic(
        COMMAND_CHAR_UUID,
        NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR
    );
    pCommandChar->setCallbacks(new CommandCharacteristicCallbacks());

    pStatusChar = pService->createCharacteristic(
        STATUS_CHAR_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
    );

    // Note: NimBLEService::start() is deprecated in NimBLE-Arduino 2.x —
    // services now start automatically when the server starts, which
    // happens implicitly via advertising below.

    // IMPORTANT: a legacy BLE advertising packet is capped at 31 bytes.
    // Flags (~3 bytes) + a 128-bit service UUID (~18 bytes) already use
    // most of that budget, leaving too little room for the device name
    // ("GlowLink" needs ~13 bytes) in the SAME packet — NimBLE will
    // silently drop whatever doesn't fit rather than erroring. The fix
    // is to put the name in the separate scan response packet instead,
    // which has its own independent 31-byte budget.
    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();

    NimBLEAdvertisementData advData;
    advData.setFlags(0x06); // LE General Discoverable Mode | BR/EDR Not Supported
    advData.setCompleteServices(NimBLEUUID(SERVICE_UUID));
    pAdvertising->setAdvertisementData(advData);

    NimBLEAdvertisementData scanResponseData;
    scanResponseData.setName(DEVICE_NAME);
    pAdvertising->setScanResponseData(scanResponseData);

    pAdvertising->start();

    Serial.println("[BLE] Advertising started as " DEVICE_NAME);
}

void BleManager::setCommandHandler(CommandHandler handler) {
    _onCommand = handler;
}

void BleManager::setConnectionEventHandler(ConnectionEventHandler handler) {
    _onConnectionEvent = handler;
}

void BleManager::setErrorHandler(ErrorHandler handler) {
    _onError = handler;
}

void BleManager::notifyStatus() {
    if (!_state || !pStatusChar) return;

    uint8_t packet[8] = {
        static_cast<uint8_t>(_state->power ? 1 : 0),
        _state->r,
        _state->g,
        _state->b,
        _state->brightness,
        _state->effectId,
        _state->speed,
        _state->errorCode,
    };

    pStatusChar->setValue(packet, sizeof(packet));
    if (_connected) {
        pStatusChar->notify();
    }
}
