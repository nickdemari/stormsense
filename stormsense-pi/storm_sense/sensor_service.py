"""SensorService — BMP280 reading, CPU heat calibration, and storm detection."""

import time
from collections import deque

try:
    import rainbowhat as rh
except ImportError:
    from storm_sense.mocks import mock_rainbowhat as rh

from storm_sense.config import (
    DisplayMode,
    HISTORY_MAX_SAMPLES,
    SESSION_LOG_MAX,
    STORM_SEVERE_THRESHOLD,
    STORM_WARNING_THRESHOLD,
    STORM_WATCH_THRESHOLD,
    StormLevel,
)

CPU_TEMP_PATH = '/sys/class/thermal/thermal_zone0/temp'
CPU_TEMP_FALLBACK = 45.0


class SensorService:
    """Reads BMP280 via Rainbow HAT, calibrates temperature, detects storms."""

    def __init__(self) -> None:
        self.temperature: float = 0.0
        self.raw_temperature: float = 0.0
        self.pressure: float = 0.0
        self.storm_level: StormLevel = StormLevel.CLEAR
        self.pressure_delta_3h: float | None = None
        self.display_mode: DisplayMode = DisplayMode.TEMPERATURE

        self._pressure_history: deque[tuple[float, float]] = deque(
            maxlen=HISTORY_MAX_SAMPLES,
        )
        self._session_log: deque[dict] = deque(maxlen=SESSION_LOG_MAX)

    # ── Public API ──────────────────────────────────────────────

    def read(self) -> None:
        """Sample BMP280, calibrate, update storm level, append to history."""
        now = time.time()

        self.raw_temperature = rh.weather.temperature()
        cpu_temp = self._read_cpu_temp()
        self.temperature = self.raw_temperature - (cpu_temp - self.raw_temperature) / 2.0

        self.pressure = rh.weather.pressure()

        self._pressure_history.append((now, self.pressure))
        self._update_storm_level()

        self._session_log.append({
            'timestamp': now,
            'temperature': self.temperature,
            'raw_temperature': self.raw_temperature,
            'pressure': self.pressure,
            'storm_level': int(self.storm_level),
        })

    def get_status(self) -> dict:
        """Return current state matching the /api/status contract."""
        return {
            'temperature': self.temperature,
            'raw_temperature': self.raw_temperature,
            'pressure': self.pressure,
            'storm_level': int(self.storm_level),
            'storm_label': self.storm_level.name,
            'samples_collected': len(self._pressure_history),
            'history_full': len(self._pressure_history) == HISTORY_MAX_SAMPLES,
            'display_mode': self.display_mode.name,
            'pressure_delta_3h': self.pressure_delta_3h,
        }

    def get_history(self) -> list[dict]:
        """Return session log matching the /api/history contract."""
        return list(self._session_log)

    def reset_history(self) -> None:
        """Clear all history and reset storm state."""
        self._pressure_history.clear()
        self._session_log.clear()
        self.storm_level = StormLevel.CLEAR
        self.pressure_delta_3h = None

    # ── Private helpers ─────────────────────────────────────────

    def _read_cpu_temp(self) -> float:
        """Read SoC temperature from sysfs. Falls back to 45.0 on macOS."""
        try:
            with open(CPU_TEMP_PATH) as f:
                return int(f.read().strip()) / 1000.0
        except (FileNotFoundError, OSError):
            return CPU_TEMP_FALLBACK

    def _update_storm_level(self) -> None:
        """Compute pressure delta and classify storm severity."""
        if len(self._pressure_history) < 2:
            self.pressure_delta_3h = None
            self.storm_level = StormLevel.CLEAR
            return

        oldest_pressure = self._pressure_history[0][1]
        self.pressure_delta_3h = self.pressure - oldest_pressure

        if self.pressure_delta_3h <= STORM_SEVERE_THRESHOLD:
            self.storm_level = StormLevel.SEVERE
        elif self.pressure_delta_3h <= STORM_WARNING_THRESHOLD:
            self.storm_level = StormLevel.WARNING
        elif self.pressure_delta_3h <= STORM_WATCH_THRESHOLD:
            self.storm_level = StormLevel.WATCH
        else:
            self.storm_level = StormLevel.CLEAR
