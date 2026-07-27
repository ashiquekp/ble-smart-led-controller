#pragma once

#include <Arduino.h>
#include "config.h"

enum ScheduleAction : uint8_t {
    SCHEDULE_ACTION_OFF   = 0,
    SCHEDULE_ACTION_ON    = 1,
    SCHEDULE_ACTION_CLEAR = 2, // cancels the active schedule, no time fields used
};

// Days-of-week repeat bitmask: bit0 = Sunday .. bit6 = Saturday.
// A mask of 0 means "one-shot": fires once, then disables itself.
struct ScheduleEntry {
    bool    enabled    = false;
    uint8_t action     = SCHEDULE_ACTION_OFF;
    uint8_t hour       = 0;
    uint8_t minute     = 0;
    uint8_t repeatMask = 0;
};

// A single-slot wall-clock scheduler.
//
// The XIAO ESP32-C3 has no battery-backed RTC and this project has no
// WiFi/NTP in scope, so there's no way for the firmware to know "real"
// time on its own. Rather than pulling in epoch timestamps and timezone
// handling for a single on/off timer, the app syncs the phone's current
// LOCAL time once (SYNC_TIME: hour/minute/second/weekday), and the
// firmware advances that clock using millis() elapsed since the sync.
//
// This drifts slowly (no crystal-accurate reference), which is an
// acceptable trade-off for a lighting on/off schedule and avoids an
// entire class of timezone/epoch bugs that would add no real value at
// this scope. A future version could resync periodically from the app,
// or add a DS3231-style RTC module for long-term accuracy.
class Scheduler {
public:
    void begin();

    void syncTime(uint8_t hour, uint8_t minute, uint8_t second, uint8_t weekday);
    bool hasTimeSync() const { return _hasSync; }

    void setSchedule(uint8_t action, uint8_t hour, uint8_t minute, uint8_t repeatMask);
    void clearSchedule();
    const ScheduleEntry& schedule() const { return _schedule; }

    // Call every loop() iteration. Returns true the instant the active
    // schedule should fire; main.cpp reacts to that (turns the strip on
    // or off) rather than Scheduler touching LedManager directly. Fires
    // at most once per matching minute, even across many tick() calls.
    bool tick(uint32_t nowMs);

    // Current computed wall-clock time, for status/debugging.
    void currentTime(uint8_t& hour, uint8_t& minute, uint8_t& second, uint8_t& weekday) const;

private:
    ScheduleEntry _schedule;

    bool     _hasSync = false;
    uint8_t  _syncHour = 0, _syncMinute = 0, _syncSecond = 0, _syncWeekday = 0;
    uint32_t _syncMillis = 0;

    // Monotonic "minutes since sync" of the last fire, used as a guard
    // so a schedule can't fire twice for the same minute. Using a
    // monotonic counter (rather than minute-of-day) means daily repeats
    // correctly fire again on the next day without extra day-rollover
    // bookkeeping.
    uint32_t _lastFiredTotalMinutes = 0xFFFFFFFF;
};

extern Scheduler scheduler;
