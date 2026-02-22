# StormSense Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a complete weather station + Flutter companion app — Raspberry Pi backend (Python/Flask) and Flutter mobile app with BLoC state management.

**Architecture:** Hierarchical swarm with 4 phases matching the PRD dependency graph. Pi backend uses BMP280 sensor via Rainbow HAT for storm detection. Flutter app polls Pi REST API, displays live weather data with charts and push notifications. All hardware mocked for macOS development.

**Tech Stack:** Python 3.9+ / Flask / rainbowhat (Pi), Flutter / BLoC / Dio / fl_chart / freezed (mobile)

---

## Phase 0: Scaffolding (Coordinator — Sequential)

> Done by coordinator before spawning any agents. Establishes shared files all agents depend on.

### Task 0.1: Initialize Git Repository + Pi Project Structure

**Files:**
- Create: `stormsense-pi/storm_sense/__init__.py`
- Create: `stormsense-pi/storm_sense/config.py`
- Create: `stormsense-pi/storm_sense/mocks/__init__.py`
- Create: `stormsense-pi/storm_sense/mocks/mock_rainbowhat.py`
- Create: `stormsense-pi/tests/__init__.py`

**Step 1: Create Pi directory structure**

```bash
mkdir -p stormsense-pi/storm_sense/mocks
mkdir -p stormsense-pi/tests
```

**Step 2: Create `stormsense-pi/storm_sense/__init__.py`**

```python
"""StormSense — Weather station and storm predictor."""
```

**Step 3: Create `stormsense-pi/storm_sense/config.py`**

Exact copy from PRD §3.3:

```python
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
```

**Step 4: Create `stormsense-pi/storm_sense/mocks/__init__.py`**

```python
"""Hardware mocks for macOS development."""
```

**Step 5: Create `stormsense-pi/storm_sense/mocks/mock_rainbowhat.py`**

```python
"""Drop-in mock for the rainbowhat library. Allows Pi code to run on macOS."""

import time


class _Weather:
    """Mock BMP280 sensor readings."""

    def __init__(self):
        self._temperature = 25.0
        self._pressure = 1013.25

    def temperature(self):
        return self._temperature

    def pressure(self):
        return self._pressure


class _Display:
    """Mock 14-segment alphanumeric display."""

    def print_str(self, text):
        pass

    def print_float(self, value):
        pass

    def print_number_str(self, text):
        pass

    def show(self):
        pass

    def clear(self):
        pass

    def set_decimal(self, index, state):
        pass


class _Rainbow:
    """Mock APA102 7-LED rainbow arc."""

    def set_pixel(self, index, r, g, b, brightness=0.5):
        pass

    def show(self):
        pass

    def clear(self):
        pass

    def set_all(self, r, g, b, brightness=0.5):
        pass


class _Buzzer:
    """Mock piezo buzzer."""

    def midi_note(self, note, duration):
        pass

    def note(self, frequency, duration):
        pass

    def stop(self):
        pass


class _TouchButton:
    """Mock capacitive touch button."""

    def __init__(self):
        self._press_handler = None
        self._release_handler = None

    def press(self, handler=None):
        if handler is not None:
            self._press_handler = handler

    def release(self, handler=None):
        if handler is not None:
            self._release_handler = handler

    def _simulate_press(self):
        if self._press_handler:
            self._press_handler()

    def _simulate_release(self):
        if self._release_handler:
            self._release_handler()


class _Touch:
    """Mock touch interface with three buttons."""

    def __init__(self):
        self.A = _TouchButton()
        self.B = _TouchButton()
        self.C = _TouchButton()


class _Lights:
    """Mock button LED lights."""

    def rgb(self, r, g, b):
        pass


# Module-level singletons (matches rainbowhat API)
weather = _Weather()
display = _Display()
rainbow = _Rainbow()
buzzer = _Buzzer()
touch = _Touch()
lights = _Lights()
```

**Step 6: Create `stormsense-pi/tests/__init__.py`**

```python
```

**Step 7: Commit scaffold**

```bash
git add stormsense-pi/
git commit -m "scaffold: Pi project structure with config and hardware mocks"
```

---

### Task 0.2: Initialize Flutter Project

**Step 1: Create Flutter project**

```bash
flutter create --org com.stormsense --project-name storm_sense storm_sense
```

**Step 2: Create directory structure per PRD §3.2**

```bash
mkdir -p storm_sense/lib/app
mkdir -p storm_sense/lib/core/api
mkdir -p storm_sense/lib/core/storm
mkdir -p storm_sense/lib/core/theme
mkdir -p storm_sense/lib/features/connection/bloc
mkdir -p storm_sense/lib/features/connection/view
mkdir -p storm_sense/lib/features/dashboard/bloc
mkdir -p storm_sense/lib/features/dashboard/view
mkdir -p storm_sense/lib/features/history/bloc
mkdir -p storm_sense/lib/features/history/view
mkdir -p storm_sense/lib/features/settings/bloc
mkdir -p storm_sense/lib/features/settings/view
mkdir -p storm_sense/lib/notifications
mkdir -p storm_sense/test/core/api
mkdir -p storm_sense/test/features/connection
mkdir -p storm_sense/test/features/dashboard
mkdir -p storm_sense/test/features/history
mkdir -p storm_sense/test/features/settings
```

**Step 3: Write placeholder `lib/main.dart`**

```dart
// Placeholder — replaced by WU-12
void main() {}
```

**Step 4: Commit scaffold**

```bash
git add storm_sense/
git commit -m "scaffold: Flutter project structure per PRD §3.2"
```

---

### Task 0.3: Create `.gitignore`

**File:** `.gitignore` (project root)

```
# Python
__pycache__/
*.pyc
*.pyo
.venv/
*.egg-info/

# Flutter
storm_sense/.dart_tool/
storm_sense/.packages
storm_sense/build/
storm_sense/.flutter-plugins
storm_sense/.flutter-plugins-dependencies
storm_sense/pubspec.lock
storm_sense/**/*.g.dart
storm_sense/**/*.freezed.dart

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Env
.env
*.env

# Claude Flow internals
.claude-flow/
.claude/
```

**Commit:**

```bash
git add .gitignore
git commit -m "scaffold: add .gitignore for Python, Flutter, IDE"
```

---

## Phase 1 — Group A (4 Parallel Agents)

> All 4 agents spawn simultaneously. No inter-dependencies within this phase.

---

### Task 1 (WU-1): Pi SensorService — Sensor + Storm Detection

**Agent:** `pi-sensor`
**Files:**
- Create: `stormsense-pi/storm_sense/sensor_service.py`
- Create: `stormsense-pi/tests/test_sensor_service.py`

**Context for agent:** You are building the core sensor service for a Raspberry Pi weather station. It reads BMP280 temperature/pressure from the Rainbow HAT, applies CPU heat calibration, maintains a 3-hour rolling pressure window for storm detection, and a 24-hour session log for history. All constants come from `config.py` (already exists). The `rainbowhat` library may not be available (macOS dev) — use try/except import with mock fallback.

**Step 1: Write `stormsense-pi/storm_sense/sensor_service.py`**

```python
"""WU-1: BMP280 sensor reading + storm detection engine."""

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
    """Reads BMP280 sensor, tracks pressure history, detects storms."""

    def __init__(self):
        self.temperature: float = 0.0
        self.raw_temperature: float = 0.0
        self.pressure: float = 0.0
        self.storm_level: StormLevel = StormLevel.CLEAR
        self.pressure_delta_3h: float | None = None
        self.display_mode: DisplayMode = DisplayMode.TEMPERATURE

        self._pressure_history: deque[tuple[float, float]] = deque(
            maxlen=HISTORY_MAX_SAMPLES
        )
        self._session_log: deque[dict] = deque(maxlen=SESSION_LOG_MAX)
        self._samples_collected: int = 0

    def _read_cpu_temp(self) -> float:
        """Read CPU temperature for heat calibration. Returns fallback on macOS."""
        try:
            with open(CPU_TEMP_PATH, 'r') as f:
                return int(f.read().strip()) / 1000.0
        except (FileNotFoundError, ValueError, PermissionError):
            return CPU_TEMP_FALLBACK

    def _calibrate_temperature(self, measured: float, cpu_temp: float) -> float:
        """Apply CPU heat calibration: corrected = measured - (cpu_temp - measured) / 2.0"""
        return measured - (cpu_temp - measured) / 2.0

    def _detect_storm(self) -> None:
        """Run storm detection against rolling pressure window."""
        if len(self._pressure_history) < 2:
            self.pressure_delta_3h = None
            self.storm_level = StormLevel.CLEAR
            return

        oldest_pressure = self._pressure_history[0][1]
        current_pressure = self.pressure
        delta = current_pressure - oldest_pressure
        self.pressure_delta_3h = round(delta, 2)

        if delta <= STORM_SEVERE_THRESHOLD:
            self.storm_level = StormLevel.SEVERE
        elif delta <= STORM_WARNING_THRESHOLD:
            self.storm_level = StormLevel.WARNING
        elif delta <= STORM_WATCH_THRESHOLD:
            self.storm_level = StormLevel.WATCH
        else:
            self.storm_level = StormLevel.CLEAR

    def read(self) -> None:
        """Take one BMP280 reading and update all state."""
        now = time.time()
        self.raw_temperature = rh.weather.temperature()
        self.pressure = rh.weather.pressure()

        cpu_temp = self._read_cpu_temp()
        self.temperature = round(
            self._calibrate_temperature(self.raw_temperature, cpu_temp), 2
        )

        self._pressure_history.append((now, self.pressure))
        self._samples_collected = len(self._pressure_history)

        self._detect_storm()

        self._session_log.append({
            'timestamp': now,
            'temperature': self.temperature,
            'raw_temperature': self.raw_temperature,
            'pressure': self.pressure,
            'storm_level': int(self.storm_level),
        })

    def get_status(self) -> dict:
        """Return status dict matching /api/status JSON contract."""
        return {
            'temperature': self.temperature,
            'raw_temperature': self.raw_temperature,
            'pressure': self.pressure,
            'storm_level': int(self.storm_level),
            'storm_label': self.storm_level.name,
            'samples_collected': self._samples_collected,
            'history_full': self._samples_collected >= HISTORY_MAX_SAMPLES,
            'display_mode': self.display_mode.name,
            'pressure_delta_3h': self.pressure_delta_3h,
        }

    def get_history(self) -> list[dict]:
        """Return history list matching /api/history JSON contract."""
        return list(self._session_log)

    def reset_history(self) -> None:
        """Clear pressure history and reset storm level to CLEAR."""
        self._pressure_history.clear()
        self._session_log.clear()
        self._samples_collected = 0
        self.storm_level = StormLevel.CLEAR
        self.pressure_delta_3h = None
```

**Step 2: Write `stormsense-pi/tests/test_sensor_service.py`**

```python
"""Tests for WU-1: SensorService."""

import unittest
from unittest.mock import patch, mock_open

from storm_sense.sensor_service import SensorService
from storm_sense.config import StormLevel, HISTORY_MAX_SAMPLES, SESSION_LOG_MAX


class TestSensorService(unittest.TestCase):
    """Test suite for SensorService."""

    def setUp(self):
        self.service = SensorService()

    @patch('storm_sense.sensor_service.rh')
    def test_read_updates_all_state(self, mock_rh):
        mock_rh.weather.temperature.return_value = 28.0
        mock_rh.weather.pressure.return_value = 1013.25

        self.service.read()

        self.assertEqual(self.service.raw_temperature, 28.0)
        self.assertEqual(self.service.pressure, 1013.25)
        self.assertIsInstance(self.service.temperature, float)
        self.assertNotEqual(self.service.temperature, 0.0)

    @patch('storm_sense.sensor_service.rh')
    def test_temperature_calibration(self, mock_rh):
        mock_rh.weather.temperature.return_value = 28.0
        mock_rh.weather.pressure.return_value = 1013.0

        with patch.object(self.service, '_read_cpu_temp', return_value=45.0):
            self.service.read()

        # corrected = 28.0 - (45.0 - 28.0) / 2.0 = 28.0 - 8.5 = 19.5
        self.assertEqual(self.service.temperature, 19.5)

    @patch('storm_sense.sensor_service.rh')
    def test_storm_clear_with_stable_pressure(self, mock_rh):
        mock_rh.weather.temperature.return_value = 25.0
        mock_rh.weather.pressure.return_value = 1013.0

        for _ in range(10):
            self.service.read()

        self.assertEqual(self.service.storm_level, StormLevel.CLEAR)

    @patch('storm_sense.sensor_service.rh')
    def test_storm_watch_threshold(self, mock_rh):
        mock_rh.weather.temperature.return_value = 25.0

        # Start high, then drop by 3.5 hPa
        mock_rh.weather.pressure.return_value = 1013.0
        self.service.read()

        mock_rh.weather.pressure.return_value = 1009.5
        self.service.read()

        self.assertEqual(self.service.storm_level, StormLevel.WATCH)

    @patch('storm_sense.sensor_service.rh')
    def test_storm_warning_threshold(self, mock_rh):
        mock_rh.weather.temperature.return_value = 25.0

        mock_rh.weather.pressure.return_value = 1013.0
        self.service.read()

        mock_rh.weather.pressure.return_value = 1006.5
        self.service.read()

        self.assertEqual(self.service.storm_level, StormLevel.WARNING)

    @patch('storm_sense.sensor_service.rh')
    def test_storm_severe_threshold(self, mock_rh):
        mock_rh.weather.temperature.return_value = 25.0

        mock_rh.weather.pressure.return_value = 1013.0
        self.service.read()

        mock_rh.weather.pressure.return_value = 1002.5
        self.service.read()

        self.assertEqual(self.service.storm_level, StormLevel.SEVERE)

    @patch('storm_sense.sensor_service.rh')
    def test_storm_deescalation(self, mock_rh):
        mock_rh.weather.temperature.return_value = 25.0

        # First: drop to SEVERE
        mock_rh.weather.pressure.return_value = 1013.0
        self.service.read()
        mock_rh.weather.pressure.return_value = 1002.0
        self.service.read()
        self.assertEqual(self.service.storm_level, StormLevel.SEVERE)

        # Reset and recover
        self.service.reset_history()
        mock_rh.weather.pressure.return_value = 1013.0
        self.service.read()
        mock_rh.weather.pressure.return_value = 1013.0
        self.service.read()
        self.assertEqual(self.service.storm_level, StormLevel.CLEAR)

    @patch('storm_sense.sensor_service.rh')
    def test_pressure_delta_none_with_single_sample(self, mock_rh):
        mock_rh.weather.temperature.return_value = 25.0
        mock_rh.weather.pressure.return_value = 1013.0

        self.service.read()

        self.assertIsNone(self.service.pressure_delta_3h)

    @patch('storm_sense.sensor_service.rh')
    def test_pressure_history_capped(self, mock_rh):
        mock_rh.weather.temperature.return_value = 25.0
        mock_rh.weather.pressure.return_value = 1013.0

        for _ in range(HISTORY_MAX_SAMPLES + 50):
            self.service.read()

        self.assertEqual(len(self.service._pressure_history), HISTORY_MAX_SAMPLES)

    @patch('storm_sense.sensor_service.rh')
    def test_session_log_capped(self, mock_rh):
        mock_rh.weather.temperature.return_value = 25.0
        mock_rh.weather.pressure.return_value = 1013.0

        for _ in range(SESSION_LOG_MAX + 50):
            self.service.read()

        self.assertEqual(len(self.service._session_log), SESSION_LOG_MAX)

    @patch('storm_sense.sensor_service.rh')
    def test_get_status_matches_contract(self, mock_rh):
        mock_rh.weather.temperature.return_value = 28.0
        mock_rh.weather.pressure.return_value = 1013.25

        self.service.read()
        status = self.service.get_status()

        required_keys = {
            'temperature', 'raw_temperature', 'pressure', 'storm_level',
            'storm_label', 'samples_collected', 'history_full',
            'display_mode', 'pressure_delta_3h',
        }
        self.assertEqual(set(status.keys()), required_keys)
        self.assertIsInstance(status['temperature'], float)
        self.assertIsInstance(status['raw_temperature'], float)
        self.assertIsInstance(status['pressure'], float)
        self.assertIsInstance(status['storm_level'], int)
        self.assertIsInstance(status['storm_label'], str)
        self.assertIsInstance(status['samples_collected'], int)
        self.assertIsInstance(status['history_full'], bool)
        self.assertIsInstance(status['display_mode'], str)

    @patch('storm_sense.sensor_service.rh')
    def test_get_history_matches_contract(self, mock_rh):
        mock_rh.weather.temperature.return_value = 25.0
        mock_rh.weather.pressure.return_value = 1013.0

        self.service.read()
        history = self.service.get_history()

        self.assertEqual(len(history), 1)
        entry = history[0]
        required_keys = {'timestamp', 'temperature', 'raw_temperature', 'pressure', 'storm_level'}
        self.assertEqual(set(entry.keys()), required_keys)

    def test_reset_history(self):
        self.service._samples_collected = 10
        self.service.storm_level = StormLevel.WARNING
        self.service.pressure_delta_3h = -5.0

        self.service.reset_history()

        self.assertEqual(self.service._samples_collected, 0)
        self.assertEqual(self.service.storm_level, StormLevel.CLEAR)
        self.assertIsNone(self.service.pressure_delta_3h)
        self.assertEqual(len(self.service._pressure_history), 0)
        self.assertEqual(len(self.service._session_log), 0)

    def test_cpu_temp_fallback_on_macos(self):
        result = self.service._read_cpu_temp()
        # On macOS, file doesn't exist, should return fallback
        self.assertIsInstance(result, float)


if __name__ == '__main__':
    unittest.main()
```

**Step 3: Run tests**

```bash
cd stormsense-pi && python -m pytest tests/test_sensor_service.py -v
```

Expected: All tests PASS.

**Step 4: Commit**

```bash
git add stormsense-pi/storm_sense/sensor_service.py stormsense-pi/tests/test_sensor_service.py
git commit -m "feat(WU-1): SensorService with BMP280 reading, calibration, and storm detection"
```

---

### Task 2 (WU-2): Pi HATInterface — Display, LEDs, Buttons

**Agent:** `pi-hat`
**Files:**
- Create: `stormsense-pi/storm_sense/hat_interface.py`
- Create: `stormsense-pi/tests/test_hat_interface.py`

**Context for agent:** You are building the Rainbow HAT hardware interface for display, LEDs, buzzer, and buttons. All hardware calls go through the `rainbowhat` library (mocked on macOS). Constants and enums come from `config.py` (already exists).

**Step 1: Write `stormsense-pi/storm_sense/hat_interface.py`**

```python
"""WU-2: Rainbow HAT interface — display, LEDs, buttons, buzzer."""

import time
from typing import Callable

try:
    import rainbowhat as rh
except ImportError:
    from storm_sense.mocks import mock_rainbowhat as rh

from storm_sense.config import StormLevel

# Storm level display labels (4-char max for 14-segment)
STORM_LABELS = {
    StormLevel.CLEAR: 'CLR ',
    StormLevel.WATCH: 'WTCH',
    StormLevel.WARNING: 'WARN',
    StormLevel.SEVERE: 'SEVR',
}

# LED palettes — 7 LEDs, (R, G, B) tuples
LED_PALETTES = {
    StormLevel.CLEAR: [(0, 80, 0)] * 7,
    StormLevel.WATCH: [(0, 80, 0)] * 4 + [(80, 80, 0)] * 3,
    StormLevel.WARNING: [(0, 80, 0)] * 2 + [(80, 80, 0)] * 2 + [(80, 30, 0)] * 3,
    StormLevel.SEVERE: [(80, 0, 0)] * 7,
}


class HATInterface:
    """Drives Rainbow HAT display, LEDs, buzzer, and button callbacks."""

    def __init__(self):
        self.on_button_a: Callable | None = None
        self.on_button_b: Callable | None = None
        self.on_button_c: Callable | None = None

        self._setup_buttons()

    def _setup_buttons(self) -> None:
        """Register capacitive touch button press handlers."""
        rh.touch.A.press(self._handle_button_a)
        rh.touch.B.press(self._handle_button_b)
        rh.touch.C.press(self._handle_button_c)

    def _handle_button_a(self) -> None:
        if self.on_button_a:
            self.on_button_a()

    def _handle_button_b(self) -> None:
        if self.on_button_b:
            self.on_button_b()

    def _handle_button_c(self) -> None:
        if self.on_button_c:
            self.on_button_c()

    def show_temperature(self, temp: float) -> None:
        """Display temperature on 14-segment (e.g. '23.5')."""
        text = f'{temp:4.1f}'
        rh.display.print_str(text[:4])
        rh.display.show()

    def show_pressure(self, pressure: float) -> None:
        """Display pressure on 14-segment (e.g. '1013')."""
        text = f'{pressure:4.0f}'
        rh.display.print_str(text[:4])
        rh.display.show()

    def show_storm_level(self, level: StormLevel) -> None:
        """Display storm label on 14-segment (e.g. 'WTCH')."""
        label = STORM_LABELS.get(level, 'ERR ')
        rh.display.print_str(label)
        rh.display.show()

    def show_text(self, text: str) -> None:
        """Display arbitrary 4-char string."""
        rh.display.print_str(text[:4])
        rh.display.show()

    def update_leds(self, level: StormLevel) -> None:
        """Set Rainbow LED colors based on storm severity."""
        palette = LED_PALETTES.get(level, LED_PALETTES[StormLevel.CLEAR])
        for i, (r, g, b) in enumerate(palette):
            rh.rainbow.set_pixel(i, r, g, b)
        rh.rainbow.show()

    def buzz_alert(self, level: StormLevel) -> None:
        """Sound buzzer for storm escalation."""
        if level == StormLevel.WATCH:
            # Single C4 note (midi 60), 0.3s
            rh.buzzer.midi_note(60, 0.3)
        elif level in (StormLevel.WARNING, StormLevel.SEVERE):
            # Three A4 notes (midi 69), 0.2s each, 0.1s gap
            for _ in range(3):
                rh.buzzer.midi_note(69, 0.2)
                time.sleep(0.1)

    def clear_all(self) -> None:
        """Turn off all display, LEDs, buzzer."""
        rh.display.clear()
        rh.rainbow.clear()
        rh.rainbow.show()
        rh.buzzer.stop()
```

**Step 2: Write `stormsense-pi/tests/test_hat_interface.py`**

```python
"""Tests for WU-2: HATInterface."""

import unittest
from unittest.mock import patch, call, MagicMock

from storm_sense.hat_interface import HATInterface, STORM_LABELS, LED_PALETTES
from storm_sense.config import StormLevel


class TestHATInterface(unittest.TestCase):
    """Test suite for HATInterface."""

    @patch('storm_sense.hat_interface.rh')
    def setUp(self, mock_rh):
        self.mock_rh = mock_rh
        self.hat = HATInterface()

    @patch('storm_sense.hat_interface.rh')
    def test_show_temperature(self, mock_rh):
        hat = HATInterface()
        hat.show_temperature(23.5)
        mock_rh.display.print_str.assert_called_with('23.5')
        mock_rh.display.show.assert_called_once()

    @patch('storm_sense.hat_interface.rh')
    def test_show_pressure(self, mock_rh):
        hat = HATInterface()
        hat.show_pressure(1013.25)
        mock_rh.display.print_str.assert_called_with('1013')
        mock_rh.display.show.assert_called_once()

    @patch('storm_sense.hat_interface.rh')
    def test_show_storm_level_watch(self, mock_rh):
        hat = HATInterface()
        hat.show_storm_level(StormLevel.WATCH)
        mock_rh.display.print_str.assert_called_with('WTCH')
        mock_rh.display.show.assert_called_once()

    @patch('storm_sense.hat_interface.rh')
    def test_show_storm_level_all_labels(self, mock_rh):
        hat = HATInterface()
        for level, label in STORM_LABELS.items():
            mock_rh.reset_mock()
            hat.show_storm_level(level)
            mock_rh.display.print_str.assert_called_with(label)

    @patch('storm_sense.hat_interface.rh')
    def test_update_leds_clear(self, mock_rh):
        hat = HATInterface()
        hat.update_leds(StormLevel.CLEAR)

        # All 7 LEDs should be green
        calls = mock_rh.rainbow.set_pixel.call_args_list
        self.assertEqual(len(calls), 7)
        for i, c in enumerate(calls):
            self.assertEqual(c, call(i, 0, 80, 0))
        mock_rh.rainbow.show.assert_called_once()

    @patch('storm_sense.hat_interface.rh')
    def test_update_leds_severe(self, mock_rh):
        hat = HATInterface()
        hat.update_leds(StormLevel.SEVERE)

        calls = mock_rh.rainbow.set_pixel.call_args_list
        self.assertEqual(len(calls), 7)
        for i, c in enumerate(calls):
            self.assertEqual(c, call(i, 80, 0, 0))

    @patch('storm_sense.hat_interface.rh')
    def test_buzz_alert_watch(self, mock_rh):
        hat = HATInterface()
        hat.buzz_alert(StormLevel.WATCH)
        mock_rh.buzzer.midi_note.assert_called_once_with(60, 0.3)

    @patch('storm_sense.hat_interface.rh')
    @patch('storm_sense.hat_interface.time')
    def test_buzz_alert_warning(self, mock_time, mock_rh):
        hat = HATInterface()
        hat.buzz_alert(StormLevel.WARNING)
        self.assertEqual(mock_rh.buzzer.midi_note.call_count, 3)
        mock_rh.buzzer.midi_note.assert_called_with(69, 0.2)

    @patch('storm_sense.hat_interface.rh')
    def test_clear_all(self, mock_rh):
        hat = HATInterface()
        hat.clear_all()
        mock_rh.display.clear.assert_called_once()
        mock_rh.rainbow.clear.assert_called_once()
        mock_rh.rainbow.show.assert_called()
        mock_rh.buzzer.stop.assert_called_once()

    @patch('storm_sense.hat_interface.rh')
    def test_button_callback_fires(self, mock_rh):
        hat = HATInterface()
        callback = MagicMock()
        hat.on_button_a = callback

        hat._handle_button_a()
        callback.assert_called_once()

    @patch('storm_sense.hat_interface.rh')
    def test_button_callback_none_safe(self, mock_rh):
        hat = HATInterface()
        hat.on_button_a = None
        # Should not raise
        hat._handle_button_a()


if __name__ == '__main__':
    unittest.main()
```

**Step 3: Run tests**

```bash
cd stormsense-pi && python -m pytest tests/test_hat_interface.py -v
```

Expected: All tests PASS.

**Step 4: Commit**

```bash
git add stormsense-pi/storm_sense/hat_interface.py stormsense-pi/tests/test_hat_interface.py
git commit -m "feat(WU-2): HATInterface with display, LEDs, buzzer, and button callbacks"
```

---

### Task 3 (WU-5): Flutter — Project Scaffold + Models

**Agent:** `flutter-models`
**Files:**
- Modify: `storm_sense/pubspec.yaml`
- Create: `storm_sense/lib/core/storm/storm_level.dart`
- Create: `storm_sense/lib/core/api/models.dart`
- Create: `storm_sense/lib/core/theme/storm_theme.dart`
- Create: `storm_sense/test/core/api/models_test.dart`

**Context for agent:** You are setting up the Flutter project foundation — `pubspec.yaml` dependencies, shared models using `freezed`, the `StormLevel` enum, and the app theme. All other Flutter work units depend on your output. Use exact models from PRD §3.6.

**Step 1: Replace `storm_sense/pubspec.yaml`**

```yaml
name: storm_sense
description: StormSense — Flutter companion app for Raspberry Pi weather station.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
  dio: ^5.4.0
  fl_chart: ^0.68.0
  flutter_local_notifications: ^17.0.0
  freezed_annotation: ^2.4.0
  equatable: ^2.0.0
  json_annotation: ^4.8.0
  go_router: ^14.0.0
  shared_preferences: ^2.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  bloc_test: ^9.1.0
  mocktail: ^1.0.0

flutter:
  uses-material-design: true
```

**Step 2: Create `storm_sense/lib/core/storm/storm_level.dart`**

```dart
import 'dart:ui';

/// Storm severity levels matching Pi-side StormLevel IntEnum.
enum StormLevel {
  clear(0, 'Clear', Color(0xFF4CAF50)),
  watch(1, 'Watch', Color(0xFFFFC107)),
  warning(2, 'Warning', Color(0xFFFF9800)),
  severe(3, 'Severe', Color(0xFFF44336));

  const StormLevel(this.value, this.label, this.color);
  final int value;
  final String label;
  final Color color;

  static StormLevel fromInt(int v) =>
      StormLevel.values.firstWhere((e) => e.value == v,
          orElse: () => StormLevel.clear);
}
```

**Step 3: Create `storm_sense/lib/core/api/models.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

/// Maps to GET /api/status response.
@freezed
class StormStatus with _$StormStatus {
  const factory StormStatus({
    required double temperature,
    @JsonKey(name: 'raw_temperature') required double rawTemperature,
    required double pressure,
    @JsonKey(name: 'storm_level') required int stormLevel,
    @JsonKey(name: 'storm_label') required String stormLabel,
    @JsonKey(name: 'samples_collected') required int samplesCollected,
    @JsonKey(name: 'history_full') required bool historyFull,
    @JsonKey(name: 'display_mode') required String displayMode,
    @JsonKey(name: 'pressure_delta_3h') required double? pressureDelta3h,
  }) = _StormStatus;

  factory StormStatus.fromJson(Map<String, dynamic> json) =>
      _$StormStatusFromJson(json);
}

/// Maps to GET /api/history array entries.
@freezed
class Reading with _$Reading {
  const factory Reading({
    required double timestamp,
    required double temperature,
    @JsonKey(name: 'raw_temperature') required double rawTemperature,
    required double pressure,
    @JsonKey(name: 'storm_level') required int stormLevel,
  }) = _Reading;

  factory Reading.fromJson(Map<String, dynamic> json) =>
      _$ReadingFromJson(json);
}
```

**Step 4: Create `storm_sense/lib/core/theme/storm_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:storm_sense/core/storm/storm_level.dart';

class StormTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: StormLevel.clear.color,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: StormLevel.clear.color,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
```

**Step 5: Run pub get + build_runner**

```bash
cd storm_sense && flutter pub get
cd storm_sense && dart run build_runner build --delete-conflicting-outputs
```

Expected: Both commands succeed. `models.freezed.dart` and `models.g.dart` are generated.

**Step 6: Create `storm_sense/test/core/api/models_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storm_sense/core/api/models.dart';
import 'package:storm_sense/core/storm/storm_level.dart';

void main() {
  group('StormStatus', () {
    test('fromJson parses sample /api/status response', () {
      final json = {
        'temperature': 23.45,
        'raw_temperature': 28.12,
        'pressure': 1013.25,
        'storm_level': 0,
        'storm_label': 'CLEAR',
        'samples_collected': 42,
        'history_full': false,
        'display_mode': 'TEMPERATURE',
        'pressure_delta_3h': null,
      };

      final status = StormStatus.fromJson(json);

      expect(status.temperature, 23.45);
      expect(status.rawTemperature, 28.12);
      expect(status.pressure, 1013.25);
      expect(status.stormLevel, 0);
      expect(status.stormLabel, 'CLEAR');
      expect(status.samplesCollected, 42);
      expect(status.historyFull, false);
      expect(status.displayMode, 'TEMPERATURE');
      expect(status.pressureDelta3h, isNull);
    });

    test('fromJson parses non-null pressure_delta_3h', () {
      final json = {
        'temperature': 23.45,
        'raw_temperature': 28.12,
        'pressure': 1013.25,
        'storm_level': 1,
        'storm_label': 'WATCH',
        'samples_collected': 360,
        'history_full': true,
        'display_mode': 'PRESSURE',
        'pressure_delta_3h': -3.5,
      };

      final status = StormStatus.fromJson(json);
      expect(status.pressureDelta3h, -3.5);
      expect(status.historyFull, true);
    });
  });

  group('Reading', () {
    test('fromJson parses sample /api/history entry', () {
      final json = {
        'timestamp': 1708635600.0,
        'temperature': 23.45,
        'raw_temperature': 28.12,
        'pressure': 1013.25,
        'storm_level': 0,
      };

      final reading = Reading.fromJson(json);

      expect(reading.timestamp, 1708635600.0);
      expect(reading.temperature, 23.45);
      expect(reading.rawTemperature, 28.12);
      expect(reading.pressure, 1013.25);
      expect(reading.stormLevel, 0);
    });
  });

  group('StormLevel', () {
    test('fromInt returns correct level', () {
      expect(StormLevel.fromInt(0), StormLevel.clear);
      expect(StormLevel.fromInt(1), StormLevel.watch);
      expect(StormLevel.fromInt(2), StormLevel.warning);
      expect(StormLevel.fromInt(3), StormLevel.severe);
    });

    test('fromInt returns clear for unknown value', () {
      expect(StormLevel.fromInt(99), StormLevel.clear);
    });

    test('each level has a color', () {
      for (final level in StormLevel.values) {
        expect(level.color, isNotNull);
      }
    });
  });
}
```

**Step 7: Run tests**

```bash
cd storm_sense && flutter test test/core/api/models_test.dart
```

Expected: All tests PASS.

**Step 8: Commit**

```bash
git add storm_sense/pubspec.yaml storm_sense/lib/core/ storm_sense/test/core/
git commit -m "feat(WU-5): Flutter models, StormLevel enum, and app theme"
```

---

### Task 4 (WU-10): Flutter — Notification Service

**Agent:** `flutter-notifs`
**Files:**
- Create: `storm_sense/lib/notifications/storm_notification_service.dart`

**Context for agent:** You are building the local push notification service. It initializes Android/iOS notification channels and shows storm alerts. Only called on escalation (caller's responsibility). No external dependencies beyond `flutter_local_notifications`.

**Step 1: Write `storm_sense/lib/notifications/storm_notification_service.dart`**

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification content per storm level.
const _stormNotifications = {
  1: (title: 'Storm Watch', body: 'Pressure dropping moderately. Weather may change.'),
  2: (title: 'Storm Warning', body: 'Rapid pressure drop detected. Storm approaching.'),
  3: (title: 'Severe Storm Alert', body: 'Severe pressure drop! Take precautions.'),
};

class StormNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  StormNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'storm_alerts',
      'Storm Alerts',
      description: 'Notifications for storm level changes',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showStormAlert(int level) async {
    final content = _stormNotifications[level];
    if (content == null) return; // No notification for CLEAR (level 0)

    const androidDetails = AndroidNotificationDetails(
      'storm_alerts',
      'Storm Alerts',
      channelDescription: 'Notifications for storm level changes',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      level, // Use level as notification ID
      content.title,
      content.body,
      details,
    );
  }
}
```

**Step 2: Commit**

```bash
git add storm_sense/lib/notifications/storm_notification_service.dart
git commit -m "feat(WU-10): StormNotificationService with Android/iOS channels"
```

---

## Phase 1 Checkpoint

```bash
# Pi tests
cd stormsense-pi && python -m pytest tests/ -v

# Flutter tests
cd storm_sense && flutter test test/core/

# Import verification
cd stormsense-pi && python -c "from storm_sense.sensor_service import SensorService; print('WU-1 OK')"
cd stormsense-pi && python -c "from storm_sense.hat_interface import HATInterface; print('WU-2 OK')"
```

---

## Phase 2 — Group B (3 Parallel Agents)

> Depends on Phase 1 completion. All 3 agents spawn simultaneously.

---

### Task 5 (WU-3): Pi REST API — Flask Server

**Agent:** `pi-api`
**Files:**
- Create: `stormsense-pi/storm_sense/api_server.py`
- Create: `stormsense-pi/tests/test_api_server.py`

**Context for agent:** You are building a Flask REST API that exposes 3 endpoints: `/api/status`, `/api/history`, `/api/health`. It receives a `SensorService` instance via constructor injection. CORS must be enabled. Endpoints return JSON matching the contract in the PRD §3.4 exactly.

**Step 1: Write `stormsense-pi/storm_sense/api_server.py`**

```python
"""WU-3: Flask REST API server for StormSense."""

from flask import Flask, jsonify
from flask_cors import CORS

from storm_sense.config import API_HOST, API_PORT


class ApiServer:
    """REST API serving sensor data over HTTP."""

    def __init__(self, sensor_service) -> None:
        self._sensor_service = sensor_service
        self._app = Flask(__name__)
        CORS(self._app)
        self._register_routes()

    def _register_routes(self) -> None:
        @self._app.route('/api/status', methods=['GET'])
        def status():
            return jsonify(self._sensor_service.get_status())

        @self._app.route('/api/history', methods=['GET'])
        def history():
            return jsonify(self._sensor_service.get_history())

        @self._app.route('/api/health', methods=['GET'])
        def health():
            return jsonify({
                'status': 'ok',
                'uptime_samples': self._sensor_service._samples_collected,
            })

    def run(self, host: str = API_HOST, port: int = API_PORT) -> None:
        """Start Flask server (blocking)."""
        self._app.run(host=host, port=port)

    def get_app(self) -> Flask:
        """Return Flask app instance for testing."""
        return self._app
```

**Step 2: Write `stormsense-pi/tests/test_api_server.py`**

```python
"""Tests for WU-3: ApiServer."""

import json
import unittest
from unittest.mock import MagicMock

from storm_sense.api_server import ApiServer


class TestApiServer(unittest.TestCase):
    """Test suite for ApiServer."""

    def setUp(self):
        self.mock_sensor = MagicMock()
        self.mock_sensor.get_status.return_value = {
            'temperature': 23.45,
            'raw_temperature': 28.12,
            'pressure': 1013.25,
            'storm_level': 0,
            'storm_label': 'CLEAR',
            'samples_collected': 42,
            'history_full': False,
            'display_mode': 'TEMPERATURE',
            'pressure_delta_3h': None,
        }
        self.mock_sensor.get_history.return_value = [
            {
                'timestamp': 1708635600.0,
                'temperature': 23.45,
                'raw_temperature': 28.12,
                'pressure': 1013.25,
                'storm_level': 0,
            }
        ]
        self.mock_sensor._samples_collected = 42

        self.server = ApiServer(self.mock_sensor)
        self.app = self.server.get_app()
        self.client = self.app.test_client()

    def test_get_status_returns_json(self):
        response = self.client.get('/api/status')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)

        self.assertEqual(data['temperature'], 23.45)
        self.assertEqual(data['raw_temperature'], 28.12)
        self.assertEqual(data['pressure'], 1013.25)
        self.assertEqual(data['storm_level'], 0)
        self.assertEqual(data['storm_label'], 'CLEAR')
        self.assertEqual(data['samples_collected'], 42)
        self.assertFalse(data['history_full'])
        self.assertEqual(data['display_mode'], 'TEMPERATURE')
        self.assertIsNone(data['pressure_delta_3h'])

    def test_get_history_returns_json_array(self):
        response = self.client.get('/api/history')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)

        self.assertIsInstance(data, list)
        self.assertEqual(len(data), 1)
        entry = data[0]
        self.assertEqual(entry['timestamp'], 1708635600.0)
        self.assertEqual(entry['temperature'], 23.45)
        self.assertEqual(entry['pressure'], 1013.25)

    def test_get_health_returns_ok(self):
        response = self.client.get('/api/health')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)

        self.assertEqual(data['status'], 'ok')
        self.assertEqual(data['uptime_samples'], 42)

    def test_cors_headers(self):
        response = self.client.get('/api/status')
        # flask-cors adds Access-Control-Allow-Origin
        self.assertIn('Access-Control-Allow-Origin', response.headers)

    def test_get_app_returns_flask_instance(self):
        app = self.server.get_app()
        self.assertIsNotNone(app)


if __name__ == '__main__':
    unittest.main()
```

**Step 3: Run tests**

```bash
cd stormsense-pi && python -m pytest tests/test_api_server.py -v
```

**Step 4: Commit**

```bash
git add stormsense-pi/storm_sense/api_server.py stormsense-pi/tests/test_api_server.py
git commit -m "feat(WU-3): Flask REST API with /status, /history, /health endpoints"
```

---

### Task 6 (WU-6): Flutter — API Client

**Agent:** `flutter-client`
**Files:**
- Create: `storm_sense/lib/core/api/storm_sense_api.dart`
- Create: `storm_sense/test/core/api/storm_sense_api_test.dart`

**Context for agent:** You are building the Dio-based HTTP client that talks to the Pi REST API. Three methods: `getStatus()`, `getHistory()`, `isHealthy()`. Configurable base URL, 5-second timeouts. Models (`StormStatus`, `Reading`) already exist in `models.dart`.

**Step 1: Write `storm_sense/lib/core/api/storm_sense_api.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:storm_sense/core/api/models.dart';

class StormSenseApi {
  final Dio _dio;

  StormSenseApi({required String baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ));

  Future<StormStatus> getStatus() async {
    final response = await _dio.get('/api/status');
    return StormStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Reading>> getHistory() async {
    final response = await _dio.get('/api/history');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Reading.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isHealthy() async {
    try {
      final response = await _dio.get('/api/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
```

**Step 2: Write `storm_sense/test/core/api/storm_sense_api_test.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storm_sense/core/api/storm_sense_api.dart';
import 'package:storm_sense/core/api/models.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late StormSenseApi api;

  setUp(() {
    mockDio = MockDio();
    api = StormSenseApi(baseUrl: 'http://192.168.1.42:5000', dio: mockDio);
  });

  group('getStatus', () {
    test('returns parsed StormStatus on 200', () async {
      when(() => mockDio.get('/api/status')).thenAnswer((_) async => Response(
            data: {
              'temperature': 23.45,
              'raw_temperature': 28.12,
              'pressure': 1013.25,
              'storm_level': 0,
              'storm_label': 'CLEAR',
              'samples_collected': 42,
              'history_full': false,
              'display_mode': 'TEMPERATURE',
              'pressure_delta_3h': null,
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/status'),
          ));

      final status = await api.getStatus();
      expect(status.temperature, 23.45);
      expect(status.stormLevel, 0);
    });
  });

  group('getHistory', () {
    test('returns List<Reading> on 200', () async {
      when(() => mockDio.get('/api/history')).thenAnswer((_) async => Response(
            data: [
              {
                'timestamp': 1708635600.0,
                'temperature': 23.45,
                'raw_temperature': 28.12,
                'pressure': 1013.25,
                'storm_level': 0,
              }
            ],
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/history'),
          ));

      final history = await api.getHistory();
      expect(history.length, 1);
      expect(history.first.pressure, 1013.25);
    });
  });

  group('isHealthy', () {
    test('returns true on 200', () async {
      when(() => mockDio.get('/api/health')).thenAnswer((_) async => Response(
            data: {'status': 'ok', 'uptime_samples': 42},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/health'),
          ));

      expect(await api.isHealthy(), true);
    });

    test('returns false on error', () async {
      when(() => mockDio.get('/api/health')).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/api/health'),
        ),
      );

      expect(await api.isHealthy(), false);
    });
  });
}
```

**Step 3: Run tests**

```bash
cd storm_sense && flutter test test/core/api/storm_sense_api_test.dart
```

**Step 4: Commit**

```bash
git add storm_sense/lib/core/api/storm_sense_api.dart storm_sense/test/core/api/storm_sense_api_test.dart
git commit -m "feat(WU-6): Dio-based StormSenseApi client with getStatus, getHistory, isHealthy"
```

---

### Task 7 (WU-11): Flutter — Settings Feature

**Agent:** `flutter-settings`
**Files:**
- Create: `storm_sense/lib/features/settings/bloc/settings_event.dart`
- Create: `storm_sense/lib/features/settings/bloc/settings_state.dart`
- Create: `storm_sense/lib/features/settings/bloc/settings_bloc.dart`
- Create: `storm_sense/lib/features/settings/view/settings_page.dart`
- Create: `storm_sense/test/features/settings/settings_bloc_test.dart`

**Context for agent:** You are building the settings feature — temperature unit toggle (C/F), pressure unit toggle (hPa/inHg), poll interval (5/10/30s). All settings persist to `SharedPreferences`. Other BLoCs read the settings state for unit conversions and poll timing.

**Step 1: Write `storm_sense/lib/features/settings/bloc/settings_event.dart`**

```dart
import 'package:equatable/equatable.dart';

enum TemperatureUnit { celsius, fahrenheit }
enum PressureUnit { hpa, inhg }

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

final class TemperatureUnitChanged extends SettingsEvent {
  const TemperatureUnitChanged(this.unit);
  final TemperatureUnit unit;

  @override
  List<Object?> get props => [unit];
}

final class PressureUnitChanged extends SettingsEvent {
  const PressureUnitChanged(this.unit);
  final PressureUnit unit;

  @override
  List<Object?> get props => [unit];
}

final class PollIntervalChanged extends SettingsEvent {
  const PollIntervalChanged(this.seconds);
  final int seconds;

  @override
  List<Object?> get props => [seconds];
}
```

**Step 2: Write `storm_sense/lib/features/settings/bloc/settings_state.dart`**

```dart
import 'package:equatable/equatable.dart';
import 'package:storm_sense/features/settings/bloc/settings_event.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.tempUnit = TemperatureUnit.celsius,
    this.pressureUnit = PressureUnit.hpa,
    this.pollIntervalSeconds = 5,
  });

  final TemperatureUnit tempUnit;
  final PressureUnit pressureUnit;
  final int pollIntervalSeconds;

  SettingsState copyWith({
    TemperatureUnit? tempUnit,
    PressureUnit? pressureUnit,
    int? pollIntervalSeconds,
  }) {
    return SettingsState(
      tempUnit: tempUnit ?? this.tempUnit,
      pressureUnit: pressureUnit ?? this.pressureUnit,
      pollIntervalSeconds: pollIntervalSeconds ?? this.pollIntervalSeconds,
    );
  }

  /// Convert Celsius to the user's preferred unit.
  double convertTemperature(double celsius) {
    if (tempUnit == TemperatureUnit.fahrenheit) {
      return celsius * 9 / 5 + 32;
    }
    return celsius;
  }

  /// Convert hPa to the user's preferred unit.
  double convertPressure(double hpa) {
    if (pressureUnit == PressureUnit.inhg) {
      return hpa * 0.02953;
    }
    return hpa;
  }

  String get tempUnitLabel =>
      tempUnit == TemperatureUnit.celsius ? '\u00B0C' : '\u00B0F';

  String get pressureUnitLabel =>
      pressureUnit == PressureUnit.hpa ? 'hPa' : 'inHg';

  @override
  List<Object?> get props => [tempUnit, pressureUnit, pollIntervalSeconds];
}
```

**Step 3: Write `storm_sense/lib/features/settings/bloc/settings_bloc.dart`**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/features/settings/bloc/settings_event.dart';
import 'package:storm_sense/features/settings/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({SharedPreferences? prefs})
      : _prefs = prefs,
        super(const SettingsState()) {
    on<SettingsLoaded>(_onLoaded);
    on<TemperatureUnitChanged>(_onTempUnitChanged);
    on<PressureUnitChanged>(_onPressureUnitChanged);
    on<PollIntervalChanged>(_onPollIntervalChanged);
  }

  SharedPreferences? _prefs;

  Future<void> _onLoaded(
    SettingsLoaded event,
    Emitter<SettingsState> emit,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();

    final tempIndex = _prefs!.getInt('temp_unit') ?? 0;
    final pressIndex = _prefs!.getInt('pressure_unit') ?? 0;
    final poll = _prefs!.getInt('poll_interval') ?? 5;

    emit(SettingsState(
      tempUnit: TemperatureUnit.values[tempIndex],
      pressureUnit: PressureUnit.values[pressIndex],
      pollIntervalSeconds: poll,
    ));
  }

  Future<void> _onTempUnitChanged(
    TemperatureUnitChanged event,
    Emitter<SettingsState> emit,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt('temp_unit', event.unit.index);
    emit(state.copyWith(tempUnit: event.unit));
  }

  Future<void> _onPressureUnitChanged(
    PressureUnitChanged event,
    Emitter<SettingsState> emit,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt('pressure_unit', event.unit.index);
    emit(state.copyWith(pressureUnit: event.unit));
  }

  Future<void> _onPollIntervalChanged(
    PollIntervalChanged event,
    Emitter<SettingsState> emit,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt('poll_interval', event.seconds);
    emit(state.copyWith(pollIntervalSeconds: event.seconds));
  }
}
```

**Step 4: Write `storm_sense/lib/features/settings/view/settings_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_event.dart';
import 'package:storm_sense/features/settings/bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              _buildSectionHeader('Temperature Unit'),
              RadioListTile<TemperatureUnit>(
                title: const Text('\u00B0C (Celsius)'),
                value: TemperatureUnit.celsius,
                groupValue: state.tempUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(TemperatureUnitChanged(v!)),
              ),
              RadioListTile<TemperatureUnit>(
                title: const Text('\u00B0F (Fahrenheit)'),
                value: TemperatureUnit.fahrenheit,
                groupValue: state.tempUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(TemperatureUnitChanged(v!)),
              ),
              const Divider(),
              _buildSectionHeader('Pressure Unit'),
              RadioListTile<PressureUnit>(
                title: const Text('hPa (Hectopascals)'),
                value: PressureUnit.hpa,
                groupValue: state.pressureUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(PressureUnitChanged(v!)),
              ),
              RadioListTile<PressureUnit>(
                title: const Text('inHg (Inches of Mercury)'),
                value: PressureUnit.inhg,
                groupValue: state.pressureUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(PressureUnitChanged(v!)),
              ),
              const Divider(),
              _buildSectionHeader('Poll Interval'),
              for (final seconds in [5, 10, 30])
                RadioListTile<int>(
                  title: Text('${seconds}s'),
                  value: seconds,
                  groupValue: state.pollIntervalSeconds,
                  onChanged: (v) => context
                      .read<SettingsBloc>()
                      .add(PollIntervalChanged(v!)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}
```

**Step 5: Write `storm_sense/test/features/settings/settings_bloc_test.dart`**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/features/settings/bloc/settings_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_event.dart';
import 'package:storm_sense/features/settings/bloc/settings_state.dart';

void main() {
  group('SettingsBloc', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initial state is defaults', () {
      final bloc = SettingsBloc(prefs: prefs);
      expect(bloc.state.tempUnit, TemperatureUnit.celsius);
      expect(bloc.state.pressureUnit, PressureUnit.hpa);
      expect(bloc.state.pollIntervalSeconds, 5);
    });

    blocTest<SettingsBloc, SettingsState>(
      'emits updated temp unit on TemperatureUnitChanged',
      build: () => SettingsBloc(prefs: prefs),
      act: (bloc) =>
          bloc.add(const TemperatureUnitChanged(TemperatureUnit.fahrenheit)),
      expect: () => [
        const SettingsState(tempUnit: TemperatureUnit.fahrenheit),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits updated pressure unit on PressureUnitChanged',
      build: () => SettingsBloc(prefs: prefs),
      act: (bloc) =>
          bloc.add(const PressureUnitChanged(PressureUnit.inhg)),
      expect: () => [
        const SettingsState(pressureUnit: PressureUnit.inhg),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits updated poll interval on PollIntervalChanged',
      build: () => SettingsBloc(prefs: prefs),
      act: (bloc) => bloc.add(const PollIntervalChanged(30)),
      expect: () => [
        const SettingsState(pollIntervalSeconds: 30),
      ],
    );
  });

  group('SettingsState conversions', () {
    test('celsius returns same value', () {
      const state = SettingsState();
      expect(state.convertTemperature(25.0), 25.0);
    });

    test('fahrenheit conversion is correct', () {
      const state = SettingsState(tempUnit: TemperatureUnit.fahrenheit);
      expect(state.convertTemperature(0.0), 32.0);
      expect(state.convertTemperature(100.0), 212.0);
    });

    test('hpa returns same value', () {
      const state = SettingsState();
      expect(state.convertPressure(1013.25), 1013.25);
    });

    test('inhg conversion is correct', () {
      const state = SettingsState(pressureUnit: PressureUnit.inhg);
      final result = state.convertPressure(1013.25);
      expect(result, closeTo(29.92, 0.01));
    });
  });
}
```

**Step 6: Run tests**

```bash
cd storm_sense && flutter test test/features/settings/settings_bloc_test.dart
```

**Step 7: Commit**

```bash
git add storm_sense/lib/features/settings/ storm_sense/test/features/settings/
git commit -m "feat(WU-11): Settings BLoC with unit toggles and poll interval"
```

---

## Phase 2 Checkpoint

```bash
# All Pi tests
cd stormsense-pi && python -m pytest tests/ -v

# All Flutter tests
cd storm_sense && flutter test

# Import verifications
cd stormsense-pi && python -c "from storm_sense.api_server import ApiServer; print('WU-3 OK')"
```

---

## Phase 3 — Group C (4 Parallel Agents)

> Depends on Phase 2 completion. All 4 agents spawn simultaneously.

---

### Task 8 (WU-4): Pi Main Entry Point — Orchestration + Systemd

**Agent:** `pi-main`
**Files:**
- Create: `stormsense-pi/storm_sense/main.py`
- Create: `stormsense-pi/requirements.txt`
- Create: `stormsense-pi/stormsense.service`

**Context for agent:** You are building the main orchestrator that wires SensorService, HATInterface, and ApiServer together. Sensor loop runs in a daemon thread every 30s. Flask runs in main thread. Button callbacks switch display modes. SIGINT/SIGTERM trigger clean shutdown. Also provide systemd service file and requirements.txt.

**Step 1: Write `stormsense-pi/storm_sense/main.py`**

```python
"""WU-4: Main entry point — orchestrates all StormSense modules."""

import logging
import signal
import threading
import time

from storm_sense.config import (
    API_HOST,
    API_PORT,
    SAMPLE_INTERVAL_S,
    DisplayMode,
    StormLevel,
)
from storm_sense.sensor_service import SensorService
from storm_sense.hat_interface import HATInterface
from storm_sense.api_server import ApiServer

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
)
logger = logging.getLogger(__name__)


class StormSenseApp:
    """Main application orchestrator."""

    def __init__(self):
        self._sensor = SensorService()
        self._hat = HATInterface()
        self._api = ApiServer(self._sensor)
        self._shutdown_event = threading.Event()
        self._previous_storm_level = StormLevel.CLEAR

        self._wire_buttons()

    def _wire_buttons(self) -> None:
        """Connect button callbacks to display mode changes."""

        def on_button_a():
            self._sensor.display_mode = DisplayMode.TEMPERATURE
            self._hat.show_temperature(self._sensor.temperature)
            logger.info('Button A: Temperature mode')

        def on_button_b():
            self._sensor.display_mode = DisplayMode.PRESSURE
            self._hat.show_pressure(self._sensor.pressure)
            logger.info('Button B: Pressure mode')

        def on_button_c():
            self._sensor.reset_history()
            self._sensor.display_mode = DisplayMode.STORM_LEVEL
            self._hat.show_storm_level(self._sensor.storm_level)
            logger.info('Button C: Reset history, Storm Level mode')

        self._hat.on_button_a = on_button_a
        self._hat.on_button_b = on_button_b
        self._hat.on_button_c = on_button_c

    def _sensor_loop(self) -> None:
        """Background thread: read sensor and update display every SAMPLE_INTERVAL_S."""
        logger.info('Sensor loop started (interval: %ds)', SAMPLE_INTERVAL_S)
        while not self._shutdown_event.is_set():
            try:
                self._sensor.read()

                # Check for storm escalation
                current_level = self._sensor.storm_level
                if current_level > self._previous_storm_level:
                    logger.warning(
                        'Storm escalation: %s -> %s',
                        self._previous_storm_level.name,
                        current_level.name,
                    )
                    self._hat.buzz_alert(current_level)
                self._previous_storm_level = current_level

                # Update LEDs
                self._hat.update_leds(current_level)

                # Update display based on current mode
                mode = self._sensor.display_mode
                if mode == DisplayMode.TEMPERATURE:
                    self._hat.show_temperature(self._sensor.temperature)
                elif mode == DisplayMode.PRESSURE:
                    self._hat.show_pressure(self._sensor.pressure)
                elif mode == DisplayMode.STORM_LEVEL:
                    self._hat.show_storm_level(current_level)

                logger.info(
                    'Reading: %.1f°C, %.1f hPa, %s',
                    self._sensor.temperature,
                    self._sensor.pressure,
                    current_level.name,
                )

            except Exception:
                logger.exception('Error in sensor loop')
                self._hat.show_text('ERR ')

            self._shutdown_event.wait(SAMPLE_INTERVAL_S)

    def _handle_signal(self, signum, frame) -> None:
        """Handle SIGINT/SIGTERM for clean shutdown."""
        sig_name = signal.Signals(signum).name
        logger.info('Received %s, shutting down...', sig_name)
        self._shutdown_event.set()

    def run(self) -> None:
        """Start StormSense: sensor loop + Flask API."""
        signal.signal(signal.SIGINT, self._handle_signal)
        signal.signal(signal.SIGTERM, self._handle_signal)

        self._hat.show_text('INIT')
        logger.info('StormSense starting...')

        # Initial reading
        try:
            self._sensor.read()
            self._hat.update_leds(self._sensor.storm_level)
            self._hat.show_temperature(self._sensor.temperature)
        except Exception:
            logger.exception('Failed initial sensor read')
            self._hat.show_text('ERR ')

        # Start sensor loop in background
        sensor_thread = threading.Thread(
            target=self._sensor_loop, daemon=True
        )
        sensor_thread.start()

        # Run Flask in main thread
        logger.info('API server starting on %s:%d', API_HOST, API_PORT)
        try:
            self._api.run(host=API_HOST, port=API_PORT)
        except Exception:
            logger.exception('API server error')
        finally:
            self._shutdown_event.set()
            self._hat.clear_all()
            logger.info('StormSense shutdown complete')


def main():
    app = StormSenseApp()
    app.run()


if __name__ == '__main__':
    main()
```

**Step 2: Write `stormsense-pi/requirements.txt`**

```
rainbowhat
flask
flask-cors
```

**Step 3: Write `stormsense-pi/stormsense.service`**

```ini
[Unit]
Description=StormSense Weather Station
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m storm_sense.main
WorkingDirectory=/home/pi/stormsense-pi
Restart=always
RestartSec=10
User=pi

[Install]
WantedBy=multi-user.target
```

**Step 4: Commit**

```bash
git add stormsense-pi/storm_sense/main.py stormsense-pi/requirements.txt stormsense-pi/stormsense.service
git commit -m "feat(WU-4): Main orchestrator with sensor loop, button wiring, and systemd service"
```

---

### Task 9 (WU-7): Flutter — Connection Feature (BLoC)

**Agent:** `flutter-connect`
**Files:**
- Create: `storm_sense/lib/features/connection/bloc/connection_event.dart`
- Create: `storm_sense/lib/features/connection/bloc/connection_state.dart`
- Create: `storm_sense/lib/features/connection/bloc/connection_bloc.dart`
- Create: `storm_sense/lib/features/connection/view/connect_page.dart`
- Create: `storm_sense/test/features/connection/connection_bloc_test.dart`

**Context for agent:** You are building the connection page where users enter the Pi's IP address, run a health check, and navigate to the dashboard on success. Last-used IP persists in SharedPreferences. API client is `StormSenseApi` from `core/api/storm_sense_api.dart`.

**Step 1: Write `connection_event.dart`**

```dart
import 'package:equatable/equatable.dart';

sealed class ConnectionEvent extends Equatable {
  const ConnectionEvent();

  @override
  List<Object?> get props => [];
}

final class ConnectionStarted extends ConnectionEvent {
  const ConnectionStarted();
}

final class ConnectionSubmitted extends ConnectionEvent {
  const ConnectionSubmitted(this.ipAddress);
  final String ipAddress;

  @override
  List<Object?> get props => [ipAddress];
}
```

**Step 2: Write `connection_state.dart`**

```dart
import 'package:equatable/equatable.dart';

sealed class ConnectionState extends Equatable {
  const ConnectionState();

  @override
  List<Object?> get props => [];
}

final class ConnectionInitial extends ConnectionState {
  const ConnectionInitial({this.lastIp});
  final String? lastIp;

  @override
  List<Object?> get props => [lastIp];
}

final class ConnectionLoading extends ConnectionState {
  const ConnectionLoading();
}

final class ConnectionSuccess extends ConnectionState {
  const ConnectionSuccess(this.baseUrl);
  final String baseUrl;

  @override
  List<Object?> get props => [baseUrl];
}

final class ConnectionFailure extends ConnectionState {
  const ConnectionFailure(this.error);
  final String error;

  @override
  List<Object?> get props => [error];
}
```

**Step 3: Write `connection_bloc.dart`**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/core/api/storm_sense_api.dart';
import 'package:storm_sense/features/connection/bloc/connection_event.dart';
import 'package:storm_sense/features/connection/bloc/connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  ConnectionBloc({SharedPreferences? prefs})
      : _prefs = prefs,
        super(const ConnectionInitial()) {
    on<ConnectionStarted>(_onStarted);
    on<ConnectionSubmitted>(_onSubmitted);
  }

  SharedPreferences? _prefs;

  Future<void> _onStarted(
    ConnectionStarted event,
    Emitter<ConnectionState> emit,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    final lastIp = _prefs!.getString('last_ip');
    emit(ConnectionInitial(lastIp: lastIp));
  }

  Future<void> _onSubmitted(
    ConnectionSubmitted event,
    Emitter<ConnectionState> emit,
  ) async {
    emit(const ConnectionLoading());

    final baseUrl = 'http://${event.ipAddress}:5000';
    final api = StormSenseApi(baseUrl: baseUrl);

    try {
      final healthy = await api.isHealthy();
      if (healthy) {
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs!.setString('last_ip', event.ipAddress);
        emit(ConnectionSuccess(baseUrl));
      } else {
        emit(const ConnectionFailure('Pi is not responding. Check the IP address.'));
      }
    } catch (e) {
      emit(ConnectionFailure('Connection failed: ${e.toString()}'));
    }
  }
}
```

**Step 4: Write `connect_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/features/connection/bloc/connection_bloc.dart';
import 'package:storm_sense/features/connection/bloc/connection_event.dart';
import 'package:storm_sense/features/connection/bloc/connection_state.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ConnectionBloc>().add(const ConnectionStarted());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StormSense')),
      body: BlocConsumer<ConnectionBloc, ConnectionState>(
        listener: (context, state) {
          if (state is ConnectionInitial && state.lastIp != null) {
            _controller.text = state.lastIp!;
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Connect to your StormSense Pi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Pi IP Address',
                    hintText: '192.168.1.42',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wifi),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                if (state is ConnectionFailure)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      state.error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state is ConnectionLoading
                        ? null
                        : () {
                            final ip = _controller.text.trim();
                            if (ip.isNotEmpty) {
                              context
                                  .read<ConnectionBloc>()
                                  .add(ConnectionSubmitted(ip));
                            }
                          },
                    child: state is ConnectionLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Connect'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

**Step 5: Write `storm_sense/test/features/connection/connection_bloc_test.dart`**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/features/connection/bloc/connection_bloc.dart';
import 'package:storm_sense/features/connection/bloc/connection_event.dart';
import 'package:storm_sense/features/connection/bloc/connection_state.dart';

void main() {
  group('ConnectionBloc', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initial state is ConnectionInitial', () {
      final bloc = ConnectionBloc(prefs: prefs);
      expect(bloc.state, const ConnectionInitial());
    });

    blocTest<ConnectionBloc, ConnectionState>(
      'ConnectionStarted emits initial with lastIp when saved',
      setUp: () async {
        SharedPreferences.setMockInitialValues({'last_ip': '192.168.1.42'});
        prefs = await SharedPreferences.getInstance();
      },
      build: () => ConnectionBloc(prefs: prefs),
      act: (bloc) => bloc.add(const ConnectionStarted()),
      expect: () => [
        const ConnectionInitial(lastIp: '192.168.1.42'),
      ],
    );

    blocTest<ConnectionBloc, ConnectionState>(
      'ConnectionStarted emits initial with null when no saved IP',
      build: () => ConnectionBloc(prefs: prefs),
      act: (bloc) => bloc.add(const ConnectionStarted()),
      expect: () => [
        const ConnectionInitial(lastIp: null),
      ],
    );
  });
}
```

**Step 6: Run tests**

```bash
cd storm_sense && flutter test test/features/connection/connection_bloc_test.dart
```

**Step 7: Commit**

```bash
git add storm_sense/lib/features/connection/ storm_sense/test/features/connection/
git commit -m "feat(WU-7): Connection BLoC with IP input, health check, and persistence"
```

---

### Task 10 (WU-8): Flutter — Dashboard Feature (BLoC)

**Agent:** `flutter-dashboard`
**Files:**
- Create: `storm_sense/lib/features/dashboard/bloc/dashboard_event.dart`
- Create: `storm_sense/lib/features/dashboard/bloc/dashboard_state.dart`
- Create: `storm_sense/lib/features/dashboard/bloc/dashboard_bloc.dart`
- Create: `storm_sense/lib/features/dashboard/view/dashboard_page.dart`
- Create: `storm_sense/lib/features/dashboard/view/temperature_card.dart`
- Create: `storm_sense/lib/features/dashboard/view/pressure_card.dart`
- Create: `storm_sense/lib/features/dashboard/view/storm_alert_card.dart`
- Create: `storm_sense/test/features/dashboard/dashboard_bloc_test.dart`

**Context for agent:** You are building the main dashboard that polls `/api/status` every N seconds (from settings), displays temperature/pressure/storm cards, and triggers notifications on storm escalation. Uses `StormSenseApi` and `StormNotificationService`.

**Full code for all files provided to agent. Key implementation notes:**

- `DashboardBloc` uses `Timer.periodic` for polling
- Compares previous `stormLevel` to detect escalation
- Escalation to WARNING (2) or SEVERE (3) triggers notification
- `DashboardPage` uses `RefreshIndicator` for pull-to-refresh
- Cards read `SettingsState` from context for unit conversion

**Step 1-7: Write all files** (event, state, bloc, 4 views, test)

**Step 8: Run tests**

```bash
cd storm_sense && flutter test test/features/dashboard/dashboard_bloc_test.dart
```

**Step 9: Commit**

```bash
git add storm_sense/lib/features/dashboard/ storm_sense/test/features/dashboard/
git commit -m "feat(WU-8): Dashboard BLoC with polling, storm escalation, and weather cards"
```

---

### Task 11 (WU-9): Flutter — History Feature (BLoC + Chart)

**Agent:** `flutter-history`
**Files:**
- Create: `storm_sense/lib/features/history/bloc/history_event.dart`
- Create: `storm_sense/lib/features/history/bloc/history_state.dart`
- Create: `storm_sense/lib/features/history/bloc/history_bloc.dart`
- Create: `storm_sense/lib/features/history/view/history_page.dart`
- Create: `storm_sense/lib/features/history/view/pressure_chart.dart`
- Create: `storm_sense/test/features/history/history_bloc_test.dart`

**Context for agent:** You are building the history page with a pressure-over-time chart using `fl_chart`. Fetches `/api/history`, renders LineChart with gradient fill, 3-hour X-axis labels, auto-scaled Y-axis. Uses `StormSenseApi`.

**Key implementation:** `PressureChart` widget uses `LineChart` from `fl_chart` with pressure data points. X-axis shows time labels every 3 hours. Y-axis auto-scales with 2 hPa padding. Gradient fill under the line.

**Step 1-6: Write all files**

**Step 7: Run tests**

```bash
cd storm_sense && flutter test test/features/history/history_bloc_test.dart
```

**Step 8: Commit**

```bash
git add storm_sense/lib/features/history/ storm_sense/test/features/history/
git commit -m "feat(WU-9): History BLoC with pressure chart using fl_chart"
```

---

## Phase 3 Checkpoint

```bash
# All Pi tests
cd stormsense-pi && python -m pytest tests/ -v

# All Flutter tests
cd storm_sense && flutter test
```

---

## Phase 4 — Integration (1 Agent, Sequential)

### Task 12 (WU-12): Flutter — App Shell + Routing

**Agent:** `flutter-shell`
**Files:**
- Replace: `storm_sense/lib/main.dart`
- Create: `storm_sense/lib/app/storm_sense_app.dart`
- Create: `storm_sense/lib/app/router.dart`

**Context for agent:** You are wiring the entire Flutter app together. `main.dart` initializes notification service, creates `RepositoryProvider` for API, `MultiBlocProvider` for all BLoCs. `router.dart` uses `go_router` with `/connect`, `/dashboard`, `/history`, `/settings` routes. Bottom nav bar for dashboard/history/settings. App launches to `/connect` if no saved IP.

**Step 1: Write `storm_sense/lib/app/router.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storm_sense/features/connection/view/connect_page.dart';
import 'package:storm_sense/features/dashboard/view/dashboard_page.dart';
import 'package:storm_sense/features/history/view/history_page.dart';
import 'package:storm_sense/features/settings/view/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({String initialLocation = '/connect'}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/connect',
        builder: (context, state) => const ConnectPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateIndex(GoRouterState.of(context).uri.path),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
            case 1:
              context.go('/history');
            case 2:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateIndex(String path) {
    if (path.startsWith('/history')) return 1;
    if (path.startsWith('/settings')) return 2;
    return 0;
  }
}
```

**Step 2: Write `storm_sense/lib/app/storm_sense_app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/app/router.dart';
import 'package:storm_sense/core/api/storm_sense_api.dart';
import 'package:storm_sense/core/theme/storm_theme.dart';
import 'package:storm_sense/features/connection/bloc/connection_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_event.dart';
import 'package:storm_sense/notifications/storm_notification_service.dart';

class StormSenseApp extends StatelessWidget {
  const StormSenseApp({
    super.key,
    required this.notificationService,
  });

  final StormNotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    final router = createRouter();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ConnectionBloc(),
        ),
        BlocProvider(
          create: (_) => SettingsBloc()..add(const SettingsLoaded()),
        ),
      ],
      child: MaterialApp.router(
        title: 'StormSense',
        theme: StormTheme.lightTheme,
        darkTheme: StormTheme.darkTheme,
        routerConfig: router,
      ),
    );
  }
}
```

**Step 3: Write `storm_sense/lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:storm_sense/app/storm_sense_app.dart';
import 'package:storm_sense/notifications/storm_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = StormNotificationService();
  await notificationService.init();

  runApp(StormSenseApp(notificationService: notificationService));
}
```

**Step 4: Run all Flutter tests**

```bash
cd storm_sense && flutter test
```

**Step 5: Verify app builds**

```bash
cd storm_sense && flutter build apk --debug 2>&1 | tail -5
```

**Step 6: Commit**

```bash
git add storm_sense/lib/main.dart storm_sense/lib/app/
git commit -m "feat(WU-12): App shell with GoRouter, bottom nav, and BLoC wiring"
```

---

## Final Checkpoint

```bash
# Full Pi test suite
cd stormsense-pi && python -m pytest tests/ -v

# Full Flutter test suite
cd storm_sense && flutter test

# Import smoke tests
cd stormsense-pi && python -c "
from storm_sense.sensor_service import SensorService
from storm_sense.hat_interface import HATInterface
from storm_sense.api_server import ApiServer
from storm_sense.main import StormSenseApp
print('All Pi modules: OK')
"

# Flutter build verification
cd storm_sense && flutter build apk --debug 2>&1 | tail -3
```

---

## Summary

| Phase | Tasks | Agents | Parallel? |
|-------|-------|--------|-----------|
| 0 | 0.1, 0.2, 0.3 | Coordinator | Sequential |
| 1 | 1 (WU-1), 2 (WU-2), 3 (WU-5), 4 (WU-10) | 4 agents | Yes |
| 2 | 5 (WU-3), 6 (WU-6), 7 (WU-11) | 3 agents | Yes |
| 3 | 8 (WU-4), 9 (WU-7), 10 (WU-8), 11 (WU-9) | 4 agents | Yes |
| 4 | 12 (WU-12) | 1 agent | Sequential |
| **Total** | **15 tasks** | **12 agent launches** | |
