# StormSense — Product Requirements Document

## Multi-Agent Development Guide

> **This PRD is structured for parallel execution by a swarm of coding agents.**
> Each work unit is self-contained with explicit interfaces, contracts, and
> acceptance criteria. Agents should read the Shared Contracts section first,
> then execute their assigned work unit independently.

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [System Architecture](#2-system-architecture)
3. [Shared Contracts](#3-shared-contracts)
4. [Dependency Graph](#4-dependency-graph)
5. [Work Units](#5-work-units)
   - [WU-1: Pi Core Service — Sensor + Storm Detection](#wu-1-pi-core-service)
   - [WU-2: Pi Rainbow HAT Interface — Display, LEDs, Buttons](#wu-2-pi-rainbow-hat-interface)
   - [WU-3: Pi REST API — Flask Server](#wu-3-pi-rest-api)
   - [WU-4: Pi Main Entry Point — Orchestration + Systemd](#wu-4-pi-main-entry-point)
   - [WU-5: Flutter — Project Scaffold + Models](#wu-5-flutter-project-scaffold)
   - [WU-6: Flutter — API Client](#wu-6-flutter-api-client)
   - [WU-7: Flutter — Connection Feature (BLoC)](#wu-7-flutter-connection-feature)
   - [WU-8: Flutter — Dashboard Feature (BLoC)](#wu-8-flutter-dashboard-feature)
   - [WU-9: Flutter — History Feature (BLoC + Chart)](#wu-9-flutter-history-feature)
   - [WU-10: Flutter — Notification Service](#wu-10-flutter-notification-service)
   - [WU-11: Flutter — Settings Feature](#wu-11-flutter-settings-feature)
   - [WU-12: Flutter — App Shell + Routing](#wu-12-flutter-app-shell)
   - [WU-13: Optional — nRF52840 Outdoor Sensor (Zephyr)](#wu-13-optional-outdoor-sensor)
   - [WU-14: Optional — Pi BLE Listener for Outdoor Sensor](#wu-14-optional-ble-listener)
6. [Integration Checkpoints](#6-integration-checkpoints)
7. [Tech Stack Summary](#7-tech-stack-summary)

---

## 1. Product Overview

**StormSense** is a self-contained weather station and storm predictor built on a Raspberry Pi 3B + Rainbow HAT. It uses the HAT's onboard BMP280 sensor for temperature and barometric pressure, tracks pressure trends over a 3-hour rolling window, and alerts when storms are approaching via display, LEDs, buzzer, and a Flutter companion app.

### Core User Stories

| ID   | Story                                                                                     |
|------|-------------------------------------------------------------------------------------------|
| US-1 | As a user, I can see the current temperature on the Rainbow HAT by pressing button A      |
| US-2 | As a user, I can see the current barometric pressure by pressing button B                 |
| US-3 | As a user, I can see the storm threat level by pressing button C                          |
| US-4 | As a user, I can reset the pressure history by pressing button C                          |
| US-5 | As a user, I can see storm severity on the Rainbow LEDs (green→yellow→orange→red)         |
| US-6 | As a user, I hear a buzzer alert when storm level escalates to WARNING or SEVERE          |
| US-7 | As a user, I can view live temp/pressure/storm data on my phone via the Flutter app       |
| US-8 | As a user, I can view a 24-hour pressure history chart in the Flutter app                 |
| US-9 | As a user, I receive a push notification on my phone when a storm warning is detected     |
| US-10| As a user, I can configure temperature units (°C/°F) and pressure units (hPa/inHg)       |

### Optional User Stories (Phase 4)

| ID    | Story                                                                                    |
|-------|------------------------------------------------------------------------------------------|
| US-11 | As a user, I can see outdoor temperature from a remote BLE sensor                        |
| US-12 | As a user, I can compare indoor vs outdoor readings in the Flutter app                   |

---

## 2. System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Raspberry Pi 3B                            │
│                    + Rainbow HAT                              │
│                                                               │
│  ┌────────────────┐   ┌──────────────────┐                   │
│  │  WU-1          │   │  WU-2            │                   │
│  │  SensorService │──►│  HATInterface    │                   │
│  │  + StormEngine │   │  Display/LEDs/   │                   │
│  │                │   │  Buttons/Buzzer  │                   │
│  └───────┬────────┘   └──────────────────┘                   │
│          │                                                    │
│  ┌───────▼────────┐   ┌──────────────────┐                   │
│  │  WU-3          │   │  WU-4            │                   │
│  │  Flask REST API │◄──│  Main Entry      │                   │
│  │  /api/*        │   │  Orchestrator    │                   │
│  └───────┬────────┘   └──────────────────┘                   │
│          │                                                    │
└──────────┼────────────────────────────────────────────────────┘
           │ WiFi (HTTP)
           ▼
┌──────────────────────────────────────────────────────────────┐
│                    Flutter App                                │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐ │
│  │  WU-5    │  │  WU-6    │  │  WU-10   │  │  WU-12      │ │
│  │  Models  │  │  API     │  │  Notifs  │  │  App Shell   │ │
│  └──────────┘  │  Client  │  └──────────┘  │  + Routing   │ │
│                └──────────┘                 └─────────────┘ │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐ │
│  │  WU-7    │  │  WU-8    │  │  WU-9    │  │  WU-11      │ │
│  │  Connect │  │  Dash    │  │  History │  │  Settings    │ │
│  │  BLoC    │  │  BLoC    │  │  BLoC    │  │  Feature     │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Shared Contracts

> **CRITICAL: All agents must read this section before starting work.**
> These contracts define the interfaces between work units. Do not deviate.

### 3.1 Pi File Structure

```
stormsense-pi/
├── storm_sense/
│   ├── __init__.py
│   ├── main.py              # WU-4: Entry point + orchestration
│   ├── sensor_service.py    # WU-1: BMP280 reading + storm detection
│   ├── hat_interface.py     # WU-2: Rainbow HAT display/LEDs/buttons
│   ├── api_server.py        # WU-3: Flask REST API
│   ├── ble_listener.py      # WU-14: Optional outdoor sensor listener
│   └── config.py            # Shared constants (below)
├── requirements.txt
├── stormsense.service       # WU-4: Systemd unit file
├── tests/
│   ├── test_sensor_service.py
│   ├── test_hat_interface.py
│   └── test_api_server.py
└── README.md
```

### 3.2 Flutter File Structure

```
storm_sense/
├── lib/
│   ├── main.dart                            # WU-12
│   ├── app/
│   │   ├── storm_sense_app.dart             # WU-12
│   │   └── router.dart                      # WU-12
│   ├── core/
│   │   ├── api/
│   │   │   ├── storm_sense_api.dart         # WU-6
│   │   │   └── models.dart                  # WU-5
│   │   ├── storm/
│   │   │   └── storm_level.dart             # WU-5
│   │   └── theme/
│   │       └── storm_theme.dart             # WU-5
│   ├── features/
│   │   ├── connection/
│   │   │   ├── bloc/
│   │   │   │   ├── connection_bloc.dart     # WU-7
│   │   │   │   ├── connection_event.dart    # WU-7
│   │   │   │   └── connection_state.dart    # WU-7
│   │   │   └── view/
│   │   │       └── connect_page.dart        # WU-7
│   │   ├── dashboard/
│   │   │   ├── bloc/
│   │   │   │   ├── dashboard_bloc.dart      # WU-8
│   │   │   │   ├── dashboard_event.dart     # WU-8
│   │   │   │   └── dashboard_state.dart     # WU-8
│   │   │   └── view/
│   │   │       ├── dashboard_page.dart      # WU-8
│   │   │       ├── temperature_card.dart    # WU-8
│   │   │       ├── pressure_card.dart       # WU-8
│   │   │       └── storm_alert_card.dart    # WU-8
│   │   ├── history/
│   │   │   ├── bloc/
│   │   │   │   ├── history_bloc.dart        # WU-9
│   │   │   │   ├── history_event.dart       # WU-9
│   │   │   │   └── history_state.dart       # WU-9
│   │   │   └── view/
│   │   │       ├── history_page.dart        # WU-9
│   │   │       └── pressure_chart.dart      # WU-9
│   │   └── settings/
│   │       ├── bloc/
│   │       │   ├── settings_bloc.dart       # WU-11
│   │       │   ├── settings_event.dart      # WU-11
│   │       │   └── settings_state.dart      # WU-11
│   │       └── view/
│   │           └── settings_page.dart       # WU-11
│   └── notifications/
│       └── storm_notification_service.dart  # WU-10
├── pubspec.yaml                             # WU-5
├── test/
│   ├── core/
│   │   └── api/
│   │       └── storm_sense_api_test.dart
│   └── features/
│       ├── dashboard/
│       │   └── dashboard_bloc_test.dart
│       └── history/
│           └── history_bloc_test.dart
└── README.md
```

### 3.3 Shared Constants — `config.py`

All Pi-side work units import from this file. **Do not duplicate these values.**

```python
# storm_sense/config.py

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

### 3.4 REST API Contract

All endpoints return JSON. The Flutter app depends on these exact response shapes.

#### `GET /api/status`

```json
{
  "temperature": 23.45,
  "raw_temperature": 28.12,
  "pressure": 1013.25,
  "storm_level": 0,
  "storm_label": "CLEAR",
  "samples_collected": 42,
  "history_full": false,
  "display_mode": "TEMPERATURE",
  "pressure_delta_3h": null
}
```

| Field                | Type     | Description                                      |
|----------------------|----------|--------------------------------------------------|
| `temperature`        | `float`  | CPU-heat-calibrated temperature in °C            |
| `raw_temperature`    | `float`  | Uncalibrated BMP280 reading in °C                |
| `pressure`           | `float`  | Barometric pressure in hPa                       |
| `storm_level`        | `int`    | 0=CLEAR, 1=WATCH, 2=WARNING, 3=SEVERE           |
| `storm_label`        | `string` | Human-readable storm level                       |
| `samples_collected`  | `int`    | Number of samples in 3hr rolling window          |
| `history_full`       | `bool`   | True when 3hr window is fully populated          |
| `display_mode`       | `string` | Current Rainbow HAT display mode                 |
| `pressure_delta_3h`  | `float?` | Pressure change over window (null if < 2 samples)|

#### `GET /api/history`

```json
[
  {
    "timestamp": 1708635600.0,
    "temperature": 23.45,
    "raw_temperature": 28.12,
    "pressure": 1013.25,
    "storm_level": 0
  }
]
```

Returns array of readings, last 24 hours, oldest first. Max 2880 entries.

| Field              | Type    | Description                              |
|--------------------|---------|------------------------------------------|
| `timestamp`        | `float` | Unix timestamp of reading                |
| `temperature`      | `float` | Calibrated temperature in °C             |
| `raw_temperature`  | `float` | Raw BMP280 temperature in °C             |
| `pressure`         | `float` | Barometric pressure in hPa               |
| `storm_level`      | `int`   | Storm level at time of reading           |

#### `GET /api/health`

```json
{
  "status": "ok",
  "uptime_samples": 42
}
```

### 3.5 Inter-Module Python Interfaces

These are the class interfaces that Pi work units must expose. Each WU owns its
class but must conform to this contract so WU-4 (orchestrator) can wire them together.

#### SensorService (WU-1 exposes → WU-3, WU-4 consume)

```python
class SensorService:
    temperature: float          # Calibrated °C
    raw_temperature: float      # Raw BMP280 °C
    pressure: float             # hPa
    storm_level: StormLevel
    pressure_delta_3h: float | None

    def read(self) -> None:
        """Take one BMP280 reading and update all state."""

    def get_status(self) -> dict:
        """Return status dict matching /api/status contract."""

    def get_history(self) -> list[dict]:
        """Return history list matching /api/history contract."""

    def reset_history(self) -> None:
        """Clear pressure history and reset storm level."""
```

#### HATInterface (WU-2 exposes → WU-4 consumes)

```python
class HATInterface:
    on_button_a: Callable | None   # Set by orchestrator
    on_button_b: Callable | None
    on_button_c: Callable | None

    def show_temperature(self, temp: float) -> None:
        """Display temperature on 14-segment (e.g. '23.5')."""

    def show_pressure(self, pressure: float) -> None:
        """Display pressure on 14-segment (e.g. '1013')."""

    def show_storm_level(self, level: StormLevel) -> None:
        """Display storm label on 14-segment (e.g. 'WTCH')."""

    def show_text(self, text: str) -> None:
        """Display arbitrary 4-char string."""

    def update_leds(self, level: StormLevel) -> None:
        """Set Rainbow LED colors based on storm severity."""

    def buzz_alert(self, level: StormLevel) -> None:
        """Sound buzzer for storm escalation."""

    def clear_all(self) -> None:
        """Turn off all display, LEDs, buzzer."""
```

#### ApiServer (WU-3 exposes → WU-4 consumes)

```python
class ApiServer:
    def __init__(self, sensor_service: SensorService) -> None:
        """Inject SensorService dependency."""

    def run(self, host: str, port: int) -> None:
        """Start Flask server (blocking)."""

    def get_app(self) -> Flask:
        """Return Flask app for testing."""
```

### 3.6 Flutter Shared Models (WU-5 defines → all Flutter WUs import)

```dart
// StormLevel enum — shared across all features
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

```dart
// StormStatus — maps to GET /api/status
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
```

```dart
// Reading — maps to GET /api/history entries
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

---

## 4. Dependency Graph

```
PARALLEL GROUP A (no dependencies — start immediately):
  ┌────────┐  ┌────────┐  ┌────────┐  ┌─────────┐
  │  WU-1  │  │  WU-2  │  │  WU-5  │  │  WU-10  │
  │ Sensor │  │  HAT   │  │ Models │  │ Notifs  │
  └───┬────┘  └───┬────┘  └───┬────┘  └─────────┘
      │           │           │
PARALLEL GROUP B (depends on Group A completions as marked):
      │           │           │
      ▼           │           ▼
  ┌────────┐      │      ┌────────┐  ┌────────┐
  │  WU-3  │      │      │  WU-6  │  │  WU-11 │
  │  API   │      │      │ Client │  │Settings│
  │(←WU-1) │      │      │(←WU-5) │  │(←WU-5) │
  └───┬────┘      │      └───┬────┘  └────────┘
      │           │           │
PARALLEL GROUP C (depends on Group B):
      ▼           ▼           ▼
  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
  │  WU-4  │  │  WU-7  │  │  WU-8  │  │  WU-9  │
  │  Main  │  │Connect │  │  Dash  │  │History │
  │(←1,2,3)│  │(←WU-6) │  │(←6,10)│  │(←WU-6) │
  └────────┘  └───┬────┘  └───┬────┘  └───┬────┘
                  │           │           │
INTEGRATION (depends on all above):
                  ▼           ▼           ▼
              ┌──────────────────────────────┐
              │           WU-12              │
              │    App Shell + Routing       │
              │    (← WU-7, 8, 9, 11)       │
              └──────────────────────────────┘

OPTIONAL (independent, start anytime):
  ┌────────┐  ┌────────┐
  │  WU-13 │  │  WU-14 │
  │nRF52840│  │BLE Lstn│
  └────────┘  └────────┘
```

### Parallelism Summary

| Phase       | Work Units              | Can Run In Parallel |
|-------------|-------------------------|---------------------|
| Group A     | WU-1, WU-2, WU-5, WU-10| Yes (all 4)         |
| Group B     | WU-3, WU-6, WU-11      | Yes (all 3)         |
| Group C     | WU-4, WU-7, WU-8, WU-9 | Yes (all 4)         |
| Integration | WU-12                   | Sequential          |
| Optional    | WU-13, WU-14            | Anytime             |

---

## 5. Work Units

---

### WU-1: Pi Core Service — Sensor + Storm Detection
<a id="wu-1-pi-core-service"></a>

**File:** `storm_sense/sensor_service.py`
**Dependencies:** `config.py` (provided)
**Consumed by:** WU-3 (API), WU-4 (Orchestrator)

#### Responsibilities

- Read BMP280 temperature and pressure from Rainbow HAT
- Apply CPU heat calibration to temperature
- Maintain 3-hour rolling pressure history (deque, maxlen from config)
- Maintain 24-hour session log for API history endpoint
- Run storm detection algorithm against rolling window
- Expose `get_status()` and `get_history()` matching API contract exactly
- Expose `reset_history()` for button C handler

#### Temperature Calibration Formula

```python
corrected = measured - (cpu_temp - measured) / 2.0
```

Read CPU temp from `/sys/class/thermal/thermal_zone0/temp` (divide by 1000).

#### Storm Detection Algorithm

```python
delta = current_pressure - oldest_pressure_in_window
if delta <= -10.0 → SEVERE
if delta <= -6.0  → WARNING
if delta <= -3.0  → WATCH
else              → CLEAR
```

Return `pressure_delta_3h = None` if fewer than 2 samples in window.

#### Interface Contract

Must expose the `SensorService` interface defined in Section 3.5.

#### Acceptance Criteria

- [ ] `read()` updates `temperature`, `raw_temperature`, `pressure`, `storm_level`
- [ ] Temperature is calibrated using CPU temp correction
- [ ] Pressure history is capped at `HISTORY_MAX_SAMPLES` (360)
- [ ] Session log is capped at `SESSION_LOG_MAX` (2880)
- [ ] `get_status()` returns dict matching `/api/status` JSON contract exactly
- [ ] `get_history()` returns list matching `/api/history` JSON contract exactly
- [ ] `reset_history()` clears pressure history and resets storm level to CLEAR
- [ ] Storm detection is correct at all threshold boundaries
- [ ] Unit tests cover: normal reading, storm escalation, storm de-escalation, history reset, calibration math

---

### WU-2: Pi Rainbow HAT Interface — Display, LEDs, Buttons
<a id="wu-2-pi-rainbow-hat-interface"></a>

**File:** `storm_sense/hat_interface.py`
**Dependencies:** `config.py` (provided), `rainbowhat` library
**Consumed by:** WU-4 (Orchestrator)

#### Responsibilities

- Drive the 14-segment alphanumeric display (4 characters)
- Drive the 7x APA102 RGB LED rainbow arc
- Register capacitive touch button callbacks (A, B, C)
- Drive piezo buzzer for storm alerts
- Flash individual button LEDs on press for tactile feedback

#### Display Modes

| Mode         | Format              | Example  |
|--------------|---------------------|----------|
| Temperature  | `{temp:4.1f}`       | `23.5`   |
| Pressure     | `{pres:4.0f}`       | `1013`   |
| Storm Level  | 4-char label        | `WTCH`   |
| Init         | Static text         | `INIT`   |
| Scanning     | Static text         | `SCAN`   |
| Error        | Static text         | `ERR `   |

#### Storm Level Labels

```python
{CLEAR: "CLR ", WATCH: "WTCH", WARNING: "WARN", SEVERE: "SEVR"}
```

#### LED Palettes (7 LEDs, RGB tuples)

```
CLEAR   → (0,80,0) × 7                                    — All green
WATCH   → (0,80,0) × 4 + (80,80,0) × 3                   — Green + Yellow
WARNING → (0,80,0) × 2 + (80,80,0) × 2 + (80,30,0) × 3  — Green + Yellow + Orange
SEVERE  → (80,0,0) × 7                                     — All red
```

#### Buzzer Behavior

- WATCH escalation: Single C4 note (midi 60), 0.3s
- WARNING/SEVERE escalation: Three A4 notes (midi 69), 0.2s each, 0.1s gap

#### Button Registration

Buttons A/B/C register callbacks via `rh.touch.{A,B,C}.press()`.
The HATInterface stores callable references (`on_button_a`, `on_button_b`, `on_button_c`)
that the orchestrator (WU-4) sets after construction.

#### Interface Contract

Must expose the `HATInterface` interface defined in Section 3.5.

#### Acceptance Criteria

- [ ] `show_temperature(23.5)` displays `23.5` on 14-segment
- [ ] `show_pressure(1013.25)` displays `1013` on 14-segment
- [ ] `show_storm_level(StormLevel.WATCH)` displays `WTCH`
- [ ] `update_leds(level)` sets correct RGB palette for all 4 storm levels
- [ ] `buzz_alert(level)` plays correct tone pattern per level
- [ ] Button press triggers registered callback + flashes corresponding LED
- [ ] `clear_all()` turns off display, all LEDs, buzzer

---

### WU-3: Pi REST API — Flask Server
<a id="wu-3-pi-rest-api"></a>

**File:** `storm_sense/api_server.py`
**Dependencies:** `config.py`, WU-1 (`SensorService`)
**Consumed by:** WU-4 (Orchestrator), WU-6 (Flutter API Client)

#### Responsibilities

- Serve three REST endpoints matching the contract in Section 3.4
- Accept `SensorService` as a constructor dependency (injected by WU-4)
- Run Flask on configurable host:port from config
- CORS enabled for local network Flutter access

#### Endpoints

| Route           | Method | Data Source                         |
|-----------------|--------|-------------------------------------|
| `/api/status`   | GET    | `sensor_service.get_status()`       |
| `/api/history`  | GET    | `sensor_service.get_history()`      |
| `/api/health`   | GET    | Static OK + sample count            |

#### Interface Contract

Must expose the `ApiServer` interface defined in Section 3.5.

#### Acceptance Criteria

- [ ] `GET /api/status` returns JSON matching contract exactly
- [ ] `GET /api/history` returns JSON array matching contract exactly
- [ ] `GET /api/health` returns `{"status": "ok", "uptime_samples": N}`
- [ ] CORS headers allow requests from any origin
- [ ] `get_app()` returns Flask app instance for testing
- [ ] Unit tests: mock `SensorService`, verify all 3 endpoint responses

---

### WU-4: Pi Main Entry Point — Orchestration + Systemd
<a id="wu-4-pi-main-entry-point"></a>

**Files:** `storm_sense/main.py`, `stormsense.service`, `requirements.txt`
**Dependencies:** WU-1, WU-2, WU-3

#### Responsibilities

- Instantiate `SensorService`, `HATInterface`, `ApiServer`
- Wire button callbacks:
  - Button A → set display mode to TEMPERATURE, call `show_temperature()`
  - Button B → set display mode to PRESSURE, call `show_pressure()`
  - Button C → call `sensor_service.reset_history()`, set mode to STORM_LEVEL, call `show_storm_level()`
- Run sensor reading loop in a background thread (every `SAMPLE_INTERVAL_S`)
- After each reading, update HAT display based on current mode
- Run Flask API in main thread (or vice versa)
- Handle SIGINT/SIGTERM for clean shutdown
- Provide systemd service file for boot-start

#### Sensor Loop Logic

```
every SAMPLE_INTERVAL_S:
  1. sensor_service.read()
  2. if storm_level escalated → hat.buzz_alert(new_level)
  3. hat.update_leds(storm_level)
  4. update display based on current mode:
     - TEMPERATURE → hat.show_temperature(sensor.temperature)
     - PRESSURE    → hat.show_pressure(sensor.pressure)
     - STORM_LEVEL → hat.show_storm_level(sensor.storm_level)
```

#### requirements.txt

```
rainbowhat
flask
flask-cors
```

#### Systemd Service

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

#### Acceptance Criteria

- [ ] All three modules instantiate and wire correctly
- [ ] Button A/B/C trigger correct display updates
- [ ] Sensor loop runs at configured interval
- [ ] Storm escalation triggers buzzer
- [ ] API server accessible on `:5000` from local network
- [ ] SIGINT/SIGTERM cleanly shuts down (clears display, LEDs)
- [ ] Systemd service starts on boot and auto-restarts on crash

---

### WU-5: Flutter — Project Scaffold + Models
<a id="wu-5-flutter-project-scaffold"></a>

**Files:** `pubspec.yaml`, `lib/core/api/models.dart`, `lib/core/storm/storm_level.dart`, `lib/core/theme/storm_theme.dart`
**Dependencies:** None
**Consumed by:** All Flutter WUs

#### Responsibilities

- Create Flutter project scaffold
- Define `pubspec.yaml` with all dependencies
- Implement `StormStatus` and `Reading` freezed models matching API contract
- Implement `StormLevel` enum with value, label, and color
- Define app theme

#### pubspec.yaml Dependencies

```yaml
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
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
```

#### Model Definitions

Use the exact freezed models from Section 3.6.

#### Acceptance Criteria

- [ ] `flutter pub get` succeeds
- [ ] `dart run build_runner build` generates freezed/json files without errors
- [ ] `StormStatus.fromJson(...)` correctly parses sample `/api/status` response
- [ ] `Reading.fromJson(...)` correctly parses sample `/api/history` entry
- [ ] `StormLevel.fromInt(2)` returns `StormLevel.warning`
- [ ] Theme defines colors consistent with StormLevel enum colors

---

### WU-6: Flutter — API Client
<a id="wu-6-flutter-api-client"></a>

**File:** `lib/core/api/storm_sense_api.dart`
**Dependencies:** WU-5 (models)
**Consumed by:** WU-7, WU-8, WU-9

#### Responsibilities

- Dio-based HTTP client targeting Pi REST API
- Methods: `getStatus()`, `getHistory()`, `isHealthy()`
- Configurable base URL (set at runtime from connection page)
- 5-second connect/receive timeouts
- Throw typed exceptions on failure

#### Interface

```dart
class StormSenseApi {
  StormSenseApi({required String baseUrl});

  Future<StormStatus> getStatus();
  Future<List<Reading>> getHistory();
  Future<bool> isHealthy();
}
```

#### Acceptance Criteria

- [ ] `getStatus()` returns parsed `StormStatus` on 200
- [ ] `getHistory()` returns `List<Reading>` on 200
- [ ] `isHealthy()` returns `true` on 200, `false` on any error
- [ ] Throws `DioException` on timeout or network error
- [ ] Unit tests with mocked Dio verify all three methods

---

### WU-7: Flutter — Connection Feature (BLoC)
<a id="wu-7-flutter-connection-feature"></a>

**Files:** `lib/features/connection/bloc/*`, `lib/features/connection/view/connect_page.dart`
**Dependencies:** WU-6 (API client)

#### Responsibilities

- UI: Text field for Pi IP address (e.g. `192.168.1.42`)
- "Connect" button runs health check against entered IP
- On success: emit connected state with base URL, navigate to dashboard
- On failure: show error message, allow retry
- Persist last-used IP in SharedPreferences

#### BLoC States

```
ConnectionInitial        → Show IP input field
ConnectionLoading        → Checking health endpoint
ConnectionSuccess(url)   → Navigate to dashboard
ConnectionFailure(error) → Show error, allow retry
```

#### Acceptance Criteria

- [ ] User can enter IP and press Connect
- [ ] Loading indicator shown during health check
- [ ] Successful health check navigates to dashboard
- [ ] Failed health check shows error message
- [ ] Last-used IP persisted and pre-filled on return
- [ ] BLoC test covers success and failure paths

---

### WU-8: Flutter — Dashboard Feature (BLoC)
<a id="wu-8-flutter-dashboard-feature"></a>

**Files:** `lib/features/dashboard/bloc/*`, `lib/features/dashboard/view/*`
**Dependencies:** WU-6 (API client), WU-10 (notification service)

#### Responsibilities

- Poll `/api/status` every 5 seconds
- Display three cards: Temperature, Pressure, Storm Alert
- Storm alert card shows colored banner matching StormLevel
- Trigger notification via WU-10 when storm level escalates to WARNING+
- Pull-to-refresh support

#### UI Layout

```
┌─────────────────────────┐
│  🌡️ Temperature         │
│  23.5°C                 │
│  (raw: 28.1°C)          │
├─────────────────────────┤
│  📊 Pressure            │
│  1013.2 hPa             │
│  Δ3h: -2.1 hPa          │
├─────────────────────────┤
│  ⛈️ Storm Level          │
│  ████ CLEAR ████        │  ← colored banner
│  42/360 samples         │
└─────────────────────────┘
```

#### BLoC States

```
DashboardLoading
DashboardLoaded(StormStatus status)
DashboardError(String message)
```

#### BLoC Events

```
DashboardStarted          → Start polling
DashboardRefreshed        → Single poll cycle
DashboardStopped          → Stop polling
```

#### Acceptance Criteria

- [ ] Polls every 5 seconds and updates UI
- [ ] Temperature card shows calibrated value with raw value subtitle
- [ ] Pressure card shows hPa value with 3h delta
- [ ] Storm card shows colored banner matching current level
- [ ] Notification fires on escalation to WARNING or SEVERE
- [ ] Pull-to-refresh triggers immediate poll
- [ ] Error state shown if Pi unreachable, auto-retries
- [ ] BLoC test covers polling, escalation detection, error handling

---

### WU-9: Flutter — History Feature (BLoC + Chart)
<a id="wu-9-flutter-history-feature"></a>

**Files:** `lib/features/history/bloc/*`, `lib/features/history/view/*`
**Dependencies:** WU-6 (API client)

#### Responsibilities

- Fetch `/api/history` and render pressure chart using `fl_chart`
- X-axis: time (last 24h)
- Y-axis: pressure in hPa
- Optional: overlay temperature as secondary line
- Refresh button to re-fetch

#### Chart Specifications

- Line chart with gradient fill under the pressure line
- Green/yellow/red zones based on storm thresholds
- X-axis labels: every 3 hours
- Y-axis labels: auto-scaled with 2 hPa padding

#### BLoC States

```
HistoryLoading
HistoryLoaded(List<Reading> readings)
HistoryError(String message)
```

#### Acceptance Criteria

- [ ] Chart renders pressure over time with correct axis labels
- [ ] Empty state shown when no history available
- [ ] Refresh button re-fetches data
- [ ] Chart is scrollable/zoomable for dense data
- [ ] BLoC test covers data loading and error states

---

### WU-10: Flutter — Notification Service
<a id="wu-10-flutter-notification-service"></a>

**File:** `lib/notifications/storm_notification_service.dart`
**Dependencies:** None (uses `flutter_local_notifications`)
**Consumed by:** WU-8 (Dashboard BLoC)

#### Responsibilities

- Initialize notification channels (Android + iOS)
- Show local push notification with storm level title and body
- Only notify on escalation (caller's responsibility to check)

#### Notification Content

| Level   | Title                  | Body                                              |
|---------|------------------------|----------------------------------------------------|
| WATCH   | ⚠️ Storm Watch         | Pressure dropping moderately. Weather may change.  |
| WARNING | 🌧️ Storm Warning      | Rapid pressure drop detected. Storm approaching.   |
| SEVERE  | 🌪️ Severe Storm Alert | Severe pressure drop! Take precautions.             |

#### Interface

```dart
class StormNotificationService {
  Future<void> init();
  Future<void> showStormAlert(int level);
}
```

#### Acceptance Criteria

- [ ] Android notification channel `storm_alerts` created with high importance
- [ ] iOS notification permissions requested
- [ ] `showStormAlert(0)` does nothing (no notification for CLEAR)
- [ ] `showStormAlert(2)` shows WARNING notification
- [ ] Notifications show correct title and body per level

---

### WU-11: Flutter — Settings Feature
<a id="wu-11-flutter-settings-feature"></a>

**Files:** `lib/features/settings/bloc/*`, `lib/features/settings/view/settings_page.dart`
**Dependencies:** WU-5 (models)

#### Responsibilities

- Temperature unit toggle: °C / °F
- Pressure unit toggle: hPa / inHg
- Poll interval adjustment: 5s / 10s / 30s
- Persist all settings in SharedPreferences
- Provide settings state to other BLoCs via repository pattern

#### Conversion Formulas

```
°F = °C × 9/5 + 32
inHg = hPa × 0.02953
```

#### Settings State

```dart
class SettingsState {
  final TemperatureUnit tempUnit;  // celsius, fahrenheit
  final PressureUnit pressureUnit; // hpa, inhg
  final int pollIntervalSeconds;   // 5, 10, or 30
}
```

#### Acceptance Criteria

- [ ] Toggle temperature unit updates display across app
- [ ] Toggle pressure unit updates display across app
- [ ] Poll interval change takes effect on next dashboard start
- [ ] All settings persist across app restarts
- [ ] Default: °C, hPa, 5s polling

---

### WU-12: Flutter — App Shell + Routing
<a id="wu-12-flutter-app-shell"></a>

**Files:** `lib/main.dart`, `lib/app/storm_sense_app.dart`, `lib/app/router.dart`
**Dependencies:** WU-7, WU-8, WU-9, WU-10, WU-11

#### Responsibilities

- App entry point with `RepositoryProvider` and `MultiBlocProvider` setup
- GoRouter routing configuration
- Bottom navigation bar (Dashboard, History, Settings)
- Initialize notification service on startup

#### Routes

| Route         | Page            | Nav Bar |
|---------------|-----------------|---------|
| `/connect`    | ConnectPage     | No      |
| `/dashboard`  | DashboardPage   | Yes     |
| `/history`    | HistoryPage     | Yes     |
| `/settings`   | SettingsPage    | Yes     |

#### Acceptance Criteria

- [ ] App launches to `/connect` if no saved IP
- [ ] App launches to `/dashboard` if saved IP exists and health check passes
- [ ] Bottom nav switches between Dashboard, History, Settings
- [ ] All BLoCs properly provided and disposed
- [ ] Notification service initialized before dashboard starts

---

### WU-13: Optional — nRF52840 Outdoor Sensor (Zephyr)
<a id="wu-13-optional-outdoor-sensor"></a>

**Dependencies:** None (standalone firmware)
**No soldering required** — use breadboard friction-fit for BMP280 + jumper wires.

#### Hardware Wiring

```
BMP280 VIN  → nRF52840 VDD (3.3V)
BMP280 GND  → nRF52840 GND
BMP280 SCK  → nRF52840 P0.27 (I2C Clock)
BMP280 SDI  → nRF52840 P0.26 (I2C Data)

Connection: Push header pins through BMP280 holes, friction-fit into
breadboard, run dupont jumper wires to nRF52840-DK headers.
```

#### Firmware Summary

- Zephyr RTOS via nRF Connect SDK
- Read BMP280 every 30s via I2C
- Advertise BLE GATT service (UUID: 0x1810)
- Notify: temperature (0x2A6E, int16 °C×100), pressure (0x2A6D, uint32 Pa)

#### Acceptance Criteria

- [ ] BMP280 reads successfully over I2C
- [ ] BLE advertising visible in nRF Connect mobile app
- [ ] Temperature and pressure characteristics readable and notify-able

---

### WU-14: Optional — Pi BLE Listener for Outdoor Sensor
<a id="wu-14-optional-ble-listener"></a>

**File:** `storm_sense/ble_listener.py`
**Dependencies:** WU-13 (outdoor sensor running), `bleak` library

#### Responsibilities

- Scan for outdoor sensor by service UUID
- Connect and subscribe to temperature + pressure notifications
- Expose `outdoor_temperature` and `outdoor_pressure` properties
- Add outdoor data to API responses (extend `/api/status`)

#### Acceptance Criteria

- [ ] Discovers and connects to nRF52840 outdoor sensor
- [ ] Parses BLE notification payloads correctly
- [ ] Reconnects automatically on disconnect
- [ ] Outdoor readings available in API status response

---

## 6. Integration Checkpoints

Run these checks at each phase boundary to verify cross-unit compatibility.

### Checkpoint 1: Pi Modules (after WU-1, WU-2, WU-3)

```bash
# In stormsense-pi/
python -m pytest tests/
python -c "from storm_sense.sensor_service import SensorService; print('WU-1 OK')"
python -c "from storm_sense.hat_interface import HATInterface; print('WU-2 OK')"
python -c "from storm_sense.api_server import ApiServer; print('WU-3 OK')"
```

### Checkpoint 2: Pi Integration (after WU-4)

```bash
# On Raspberry Pi with Rainbow HAT attached
python -m storm_sense.main &
curl http://localhost:5000/api/status  # Should return JSON
curl http://localhost:5000/api/health  # Should return {"status": "ok", ...}
# Press buttons A, B, C — verify display changes
```

### Checkpoint 3: Flutter Models (after WU-5, WU-6)

```bash
cd storm_sense
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/
```

### Checkpoint 4: Flutter Full Integration (after WU-12)

```bash
flutter test
flutter run  # Connect to Pi IP, verify dashboard updates
```

---

## 7. Tech Stack Summary

### Raspberry Pi

| Component       | Technology                        |
|-----------------|-----------------------------------|
| OS              | Raspberry Pi OS Lite              |
| Language        | Python 3.9+                       |
| Sensor          | BMP280 via `rainbowhat` library   |
| Display/LEDs    | Rainbow HAT via `rainbowhat`      |
| REST API        | Flask + flask-cors                |
| BLE (optional)  | bleak                             |
| Process Manager | systemd                           |

### Flutter App

| Component       | Technology                        |
|-----------------|-----------------------------------|
| State Mgmt     | flutter_bloc ^8.1.0               |
| HTTP Client     | dio ^5.4.0                        |
| Charts          | fl_chart ^0.68.0                  |
| Notifications   | flutter_local_notifications ^17.0 |
| Code Gen        | freezed + json_serializable       |
| Routing         | go_router ^14.0.0                 |
| Persistence     | shared_preferences ^2.2.0        |
| Testing         | bloc_test + mocktail               |

### Optional Outdoor Sensor

| Component       | Technology                        |
|-----------------|-----------------------------------|
| Board           | nRF52840-DK                       |
| Sensor          | BMP280 (breadboard, no solder)    |
| RTOS            | Zephyr via nRF Connect SDK        |
| Communication   | BLE GATT                          |