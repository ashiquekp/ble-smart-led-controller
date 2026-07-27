#include "scheduler.h"

Scheduler scheduler;

void Scheduler::begin() {
    // Nothing to initialize beyond defaults — waits for the app's first
    // SYNC_TIME command before hasTimeSync() becomes true.
}

void Scheduler::syncTime(uint8_t hour, uint8_t minute, uint8_t second, uint8_t weekday) {
    _syncHour = hour % 24;
    _syncMinute = minute % 60;
    _syncSecond = second % 60;
    _syncWeekday = weekday % 7;
    _syncMillis = millis();
    _hasSync = true;
    Serial.printf("[SCHEDULER] Time synced: %02d:%02d:%02d (weekday %d)\n",
                  _syncHour, _syncMinute, _syncSecond, _syncWeekday);
}

void Scheduler::setSchedule(uint8_t action, uint8_t hour, uint8_t minute, uint8_t repeatMask) {
    if (action == SCHEDULE_ACTION_CLEAR) {
        clearSchedule();
        return;
    }
    _schedule.enabled = true;
    _schedule.action = action;
    _schedule.hour = hour % 24;
    _schedule.minute = minute % 60;
    _schedule.repeatMask = repeatMask;
    Serial.printf("[SCHEDULER] Schedule set: action=%d at %02d:%02d repeat=0x%02X\n",
                  action, _schedule.hour, _schedule.minute, repeatMask);
}

void Scheduler::clearSchedule() {
    _schedule.enabled = false;
    Serial.println("[SCHEDULER] Schedule cleared");
}

void Scheduler::currentTime(uint8_t& hour, uint8_t& minute, uint8_t& second, uint8_t& weekday) const {
    if (!_hasSync) {
        hour = minute = second = weekday = 0;
        return;
    }
    uint32_t elapsedSec = (millis() - _syncMillis) / 1000;
    uint32_t totalSec = (uint32_t)_syncHour * 3600 + (uint32_t)_syncMinute * 60 + _syncSecond + elapsedSec;
    uint32_t daysElapsed = totalSec / 86400;
    uint32_t secToday = totalSec % 86400;

    hour = secToday / 3600;
    minute = (secToday % 3600) / 60;
    second = secToday % 60;
    weekday = (_syncWeekday + daysElapsed) % 7;
}

bool Scheduler::tick(uint32_t nowMs) {
    if (!_hasSync || !_schedule.enabled) return false;

    uint32_t elapsedSec = (nowMs - _syncMillis) / 1000;
    uint32_t totalSec = (uint32_t)_syncHour * 3600 + (uint32_t)_syncMinute * 60 + _syncSecond + elapsedSec;
    uint32_t totalMinutes = totalSec / 60;

    uint8_t hour, minute, second, weekday;
    currentTime(hour, minute, second, weekday);

    bool timeMatches = (hour == _schedule.hour && minute == _schedule.minute);
    bool dayMatches = _schedule.repeatMask == 0 || (_schedule.repeatMask & (1 << weekday));

    if (timeMatches && dayMatches && totalMinutes != _lastFiredTotalMinutes) {
        _lastFiredTotalMinutes = totalMinutes;
        Serial.printf("[SCHEDULER] Firing schedule: action=%d at %02d:%02d\n",
                      _schedule.action, hour, minute);
        if (_schedule.repeatMask == 0) {
            _schedule.enabled = false; // one-shot: consume it
        }
        return true;
    }
    return false;
}
