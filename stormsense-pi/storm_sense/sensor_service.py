"""SensorService — BMP280 reading, CPU heat calibration, and storm detection."""

from __future__ import annotations

import logging
import time
from collections import deque

try:
    import rainbowhat as rh
except ImportError:
    from storm_sense.mocks import mock_rainbowhat as rh

from storm_sense.config import (
    CPU_HEAT_FACTOR,
    DRY_THRESHOLD,
    DisplayMode,
    HISTORY_MAX_SAMPLES,
    SESSION_LOG_MAX,
    STORM_SEVERE_THRESHOLD,
    STORM_WARNING_THRESHOLD,
    STORM_WATCH_THRESHOLD,
    StormLevel,
)
from storm_sense.history_store import HistoryStore, DEFAULT_DB_PATH

logger = logging.getLogger(__name__)

CPU_TEMP_PATH = '/sys/class/thermal/thermal_zone0/temp'
CPU_TEMP_FALLBACK = 45.0


class SensorService:
    """Reads BMP280 via Rainbow HAT, calibrates temperature, detects storms."""

    def __init__(self, db_path: str = DEFAULT_DB_PATH) -> None:
        self.temperature: float = 0.0
        self.temperature_f: float = 32.0
        self.raw_temperature: float = 0.0
        self.pressure: float = 0.0
        self.storm_level: StormLevel = StormLevel.FAIR
        self.pressure_delta_3h: float | None = None
        self.display_mode: DisplayMode = DisplayMode.TEMPERATURE

        self._pressure_history: deque[tuple[float, float]] = deque(
            maxlen=HISTORY_MAX_SAMPLES,
        )
        self._session_log: deque[dict] = deque(maxlen=SESSION_LOG_MAX)

        # SQLite persistence — survives restarts
        self._store = HistoryStore(db_path)
        self._seed_from_store()

    # ── Public API ──────────────────────────────────────────────

    def read(self) -> None:
        """Sample BMP280, calibrate, update storm level, append to history."""
        now = time.time()

        self.raw_temperature = rh.weather.temperature()
        cpu_temp = self._read_cpu_temp()
        self.temperature = self.raw_temperature - (cpu_temp - self.raw_temperature) / CPU_HEAT_FACTOR

        self.pressure = rh.weather.pressure()
        self.temperature_f = self.temperature * 9.0 / 5.0 + 32.0

        self._pressure_history.append((now, self.pressure))
        self._update_storm_level()

        reading = {
            'timestamp': now,
            'temperature': self.temperature,
            'temperature_f': self.temperature_f,
            'raw_temperature': self.raw_temperature,
            'pressure': self.pressure,
            'storm_level': int(self.storm_level),
        }
        self._session_log.append(reading)
        self._store.add_reading(reading)
        self._store.prune_if_due()

    def get_status(self) -> dict:
        """Return current state matching the /api/status contract."""
        return {
            'temperature': self.temperature,
            'temperature_f': self.temperature_f,
            'raw_temperature': self.raw_temperature,
            'pressure': self.pressure,
            'storm_level': int(self.storm_level),
            'storm_label': self.storm_level.name,
            'samples_collected': len(self._pressure_history),
            'history_full': len(self._pressure_history) == HISTORY_MAX_SAMPLES,
            'display_mode': self.display_mode.name,
            'pressure_delta_3h': self.pressure_delta_3h,
        }

    def get_history(self, since: float = 0) -> list[dict]:
        """Return readings matching the /api/history contract.

        Queries SQLite when available (full multi-day history); falls back to
        the capped in-memory session log otherwise.
        """
        if self._store.is_available:
            return self._store.get_history(limit=5000, since=since)
        if since > 0:
            return [r for r in self._session_log if r['timestamp'] > since]
        return list(self._session_log)

    def reset_history(self) -> None:
        """Clear all history (in-memory and persisted) and reset storm state."""
        self._pressure_history.clear()
        self._session_log.clear()
        self._store.clear()
        self.storm_level = StormLevel.FAIR
        self.pressure_delta_3h = None

    def close(self) -> None:
        """Shut down the history store cleanly."""
        self._store.close()

    # ── Private helpers ─────────────────────────────────────────

    def _seed_from_store(self) -> None:
        """Populate in-memory structures from persisted history on startup."""
        if not self._store.is_available:
            return

        # Seed session log (most recent SESSION_LOG_MAX readings)
        rows = self._store.get_latest(limit=SESSION_LOG_MAX)
        for row in rows:
            self._session_log.append(row)

        # Seed pressure history for storm detection (most recent 3-hour window)
        # Only use the tail end that fits the rolling window
        for row in rows[-HISTORY_MAX_SAMPLES:]:
            self._pressure_history.append((row['timestamp'], row['pressure']))

        if rows:
            # Restore latest values so get_status() works before first read()
            latest = rows[-1]
            self.temperature = latest['temperature']
            self.temperature_f = latest['temperature_f']
            self.raw_temperature = latest['raw_temperature']
            self.pressure = latest['pressure']
            self.storm_level = StormLevel(latest['storm_level'])
            self._update_storm_level()

            logger.info(
                'Seeded %d readings from SQLite (%d for storm detection)',
                len(rows),
                len(self._pressure_history),
            )

    def _read_cpu_temp(self) -> float:
        """Read SoC temperature from sysfs. Falls back to 45.0 on macOS."""
        try:
            with open(CPU_TEMP_PATH) as f:
                return int(f.read().strip()) / 1000.0
        except (FileNotFoundError, OSError):
            return CPU_TEMP_FALLBACK

    def _update_storm_level(self) -> None:
        """Compute pressure delta and classify weather condition.

        Barometer scale (left to right on LEDs):
        Stormy | Rain | Change | Fair | Dry
        """
        if len(self._pressure_history) < 2:
            self.pressure_delta_3h = None
            self.storm_level = StormLevel.FAIR
            return

        oldest_pressure = self._pressure_history[0][1]
        self.pressure_delta_3h = self.pressure - oldest_pressure

        if self.pressure_delta_3h <= STORM_SEVERE_THRESHOLD:
            self.storm_level = StormLevel.STORMY
        elif self.pressure_delta_3h <= STORM_WARNING_THRESHOLD:
            self.storm_level = StormLevel.RAIN
        elif self.pressure_delta_3h <= STORM_WATCH_THRESHOLD:
            self.storm_level = StormLevel.CHANGE
        elif self.pressure_delta_3h >= DRY_THRESHOLD:
            self.storm_level = StormLevel.DRY
        else:
            self.storm_level = StormLevel.FAIR
