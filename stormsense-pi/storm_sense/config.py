"""Shared configuration constants for StormSense Pi."""

# ── Sensor Configuration ─────────────────────────────────────
SAMPLE_INTERVAL_S = 30            # Read BMP280 every 30 seconds
HISTORY_WINDOW_S = 3 * 60 * 60    # 3-hour rolling window for storm detection
HISTORY_MAX_SAMPLES = HISTORY_WINDOW_S // SAMPLE_INTERVAL_S  # 360 samples
SESSION_LOG_MAX = 2880             # 24 hours at 30s intervals

# ── Storm Thresholds (hPa change over 3 hours) ──────────────
STORM_WATCH_THRESHOLD = -3.0       # Moderate pressure drop
STORM_WARNING_THRESHOLD = -6.0     # Rapid pressure drop
STORM_SEVERE_THRESHOLD = -10.0     # Severe pressure drop

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
    CLEAR = 0
    WATCH = 1
    WARNING = 2
    SEVERE = 3
