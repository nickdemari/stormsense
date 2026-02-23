"""Shared configuration constants for StormSense Pi."""

# ── Sensor Configuration ─────────────────────────────────────
SAMPLE_INTERVAL_S = 5              # Read BMP280 every 5 seconds
HISTORY_WINDOW_S = 3 * 60 * 60    # 3-hour rolling window for storm detection
HISTORY_MAX_SAMPLES = HISTORY_WINDOW_S // SAMPLE_INTERVAL_S  # 2160 samples
SESSION_LOG_MAX = 86400 // SAMPLE_INTERVAL_S  # 24 hours of readings

# ── Temperature Calibration ──────────────────────────────────
# The BMP280 sits near the CPU and reads hot. This factor controls
# how aggressively we compensate. Higher = more correction.
# Formula: calibrated = raw - (cpu_temp - raw) / CPU_HEAT_FACTOR
# Default 1.2 works for Pi 3B with Rainbow HAT in a room ~21°C.
# If still reading high, lower toward 1.0. If over-correcting, raise toward 2.0.
CPU_HEAT_FACTOR = 1.2

# ── Weather Condition Thresholds (hPa change over 3 hours) ──
# Barometer scale: Stormy < Rain < Change < Fair < Dry
STORM_SEVERE_THRESHOLD = -10.0     # Stormy: severe pressure drop
STORM_WARNING_THRESHOLD = -6.0     # Rain: rapid pressure drop
STORM_WATCH_THRESHOLD = -3.0       # Change: moderate pressure drop
# Fair: delta between -3.0 and +2.0 (stable)
DRY_THRESHOLD = 2.0                # Dry: pressure rising

# ── API Configuration ────────────────────────────────────────
API_HOST = '0.0.0.0'
API_PORT = 5000

# ── Enums ────────────────────────────────────────────────────
from enum import IntEnum

class DisplayMode(IntEnum):
    TEMPERATURE = 0
    PRESSURE = 1
    STORM_LEVEL = 2

class StormLevel(IntEnum):
    DRY = 0
    FAIR = 1
    CHANGE = 2
    RAIN = 3
    STORMY = 4
