# StormSense — Design Document

**Date:** 2026-02-22
**Status:** Approved
**PRD:** `docs/mvp.md`
**Scope:** Full MVP (WU-1 through WU-12)

---

## 1. Project Structure

Two top-level directories at project root:

```
stormsense/
├── stormsense-pi/              # Python — Raspberry Pi backend
│   ├── storm_sense/
│   │   ├── __init__.py
│   │   ├── config.py           # Shared constants (PRD §3.3)
│   │   ├── sensor_service.py   # WU-1
│   │   ├── hat_interface.py    # WU-2
│   │   ├── api_server.py       # WU-3
│   │   ├── main.py             # WU-4
│   │   └── mocks/
│   │       ├── __init__.py
│   │       └── mock_rainbowhat.py
│   ├── tests/
│   │   ├── test_sensor_service.py
│   │   ├── test_hat_interface.py
│   │   └── test_api_server.py
│   ├── requirements.txt
│   └── stormsense.service
│
├── storm_sense/                # Flutter — companion mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   │   ├── storm_sense_app.dart
│   │   │   └── router.dart
│   │   ├── core/
│   │   │   ├── api/
│   │   │   │   ├── storm_sense_api.dart
│   │   │   │   └── models.dart
│   │   │   ├── storm/
│   │   │   │   └── storm_level.dart
│   │   │   └── theme/
│   │   │       └── storm_theme.dart
│   │   ├── features/
│   │   │   ├── connection/
│   │   │   │   ├── bloc/
│   │   │   │   └── view/
│   │   │   ├── dashboard/
│   │   │   │   ├── bloc/
│   │   │   │   └── view/
│   │   │   ├── history/
│   │   │   │   ├── bloc/
│   │   │   │   └── view/
│   │   │   └── settings/
│   │   │       ├── bloc/
│   │   │       └── view/
│   │   └── notifications/
│   │       └── storm_notification_service.dart
│   ├── test/
│   ├── pubspec.yaml
│   └── ...
│
├── docs/
│   ├── mvp.md
│   └── plans/
└── CLAUDE.md
```

---

## 2. Hardware Mocking Strategy

Development is on macOS — no Raspberry Pi hardware available.

### Mock module: `storm_sense/mocks/mock_rainbowhat.py`

Drop-in stub for the `rainbowhat` library API surface:

- `weather.temperature()` / `weather.pressure()` → configurable floats
- `display.print_str()` / `display.show()` → no-op
- `rainbow.set_pixel()` / `rainbow.show()` → no-op
- `buzzer.midi_note()` → no-op
- `touch.A/B/C.press()` → stores callback reference

### Import strategy (all Pi modules):

```python
try:
    import rainbowhat as rh
except ImportError:
    from storm_sense.mocks import mock_rainbowhat as rh
```

### CPU temperature fallback:

`SensorService._read_cpu_temp()` returns `45.0` when `/sys/class/thermal/thermal_zone0/temp` is absent.

### Tests:

All tests use `unittest.mock.patch` to inject controlled values. No hardware dependency, even on a real Pi.

---

## 3. Pi Backend — Data Flow

```
BMP280 (via rainbowhat)
       │
       ▼
SensorService (WU-1)
  - read() → updates temperature, pressure, storm_level
  - 3hr deque (360 samples) → storm detection
  - 24hr session log (2880) → history API
  - get_status() → dict (matches /api/status)
  - get_history() → list[dict] (matches /api/history)
  - reset_history() → clears + CLEAR level
       │
       ├──────────────────► ApiServer (WU-3)
       │                    Flask, 3 endpoints, CORS
       │
       └──► Main Orchestrator (WU-4)
            - wires SensorService + HATInterface + ApiServer
            - button callbacks (A=temp, B=pressure, C=reset+storm)
            - sensor loop every 30s in daemon thread
            - escalation detection → buzzer
            - Flask in main thread
            - SIGINT/SIGTERM → clean shutdown
                    │
                    ▼
            HATInterface (WU-2)
            - 14-segment display
            - 7x APA102 RGB LEDs
            - piezo buzzer
            - capacitive button registration
```

### Storm detection algorithm:

```
delta = current_pressure - oldest_pressure_in_window
SEVERE  if delta <= -10.0
WARNING if delta <= -6.0
WATCH   if delta <= -3.0
CLEAR   otherwise
pressure_delta_3h = None if < 2 samples
```

### Temperature calibration:

```
corrected = measured - (cpu_temp - measured) / 2.0
```

### Threading model:

- Sensor loop: `threading.Thread(daemon=True)`
- Flask: main thread via `api_server.run()`
- Shutdown: `threading.Event` + SIGINT/SIGTERM handler → `hat.clear_all()`

---

## 4. Flutter App — Architecture

### State management: BLoC pattern

```
main.dart
  └─ RepositoryProvider(StormSenseApi)
     └─ MultiBlocProvider
        ├─ SettingsBloc (SharedPreferences)
        ├─ ConnectionBloc (StormSenseApi.isHealthy)
        ├─ DashboardBloc (StormSenseApi.getStatus + NotificationService)
        └─ HistoryBloc (StormSenseApi.getHistory)
```

### Navigation (go_router):

```
App Launch
    │
Has saved IP? ──no──► /connect
    │                    │
   yes                success
    │                    │
    ▼                    ▼
Health check ──fail──► /connect
    │
  pass
    │
    ▼
/dashboard ◄──┐
/history   ◄──┤ Bottom Nav Bar
/settings  ◄──┘
```

### Polling (DashboardBloc):

- `DashboardStarted` → `Timer.periodic` at configured poll interval
- Each tick → `api.getStatus()` → `DashboardLoaded(status)`
- Storm escalation to WARNING+ → `notificationService.showStormAlert(level)`
- `DashboardStopped` → cancel timer
- Error → `DashboardError`, timer continues for auto-retry

### Settings propagation:

- `SettingsBloc` persists to `SharedPreferences`
- Unit conversions applied at display layer only (raw data stays metric)
- Poll interval change takes effect on next `DashboardStarted`

### Code generation:

- `freezed` + `json_serializable` for `StormStatus` and `Reading`
- `dart run build_runner build --delete-conflicting-outputs`

---

## 5. Swarm Execution Strategy

Hierarchical swarm, 4 phases per PRD dependency graph.

### Phase 0: Scaffolding (coordinator, before swarm)

- `git init` at project root
- Create `config.py`, `__init__.py`, `mocks/mock_rainbowhat.py`
- `flutter create storm_sense`, restructure to PRD §3.2
- Commit scaffold

### Phase 1 — Group A (4 parallel agents)

| Agent | WU | Delivers |
|-------|----|----------|
| pi-sensor | WU-1 | `sensor_service.py` + test |
| pi-hat | WU-2 | `hat_interface.py` + test |
| flutter-models | WU-5 | models, enums, theme, pubspec, build_runner |
| flutter-notifs | WU-10 | `storm_notification_service.dart` |

### Phase 2 — Group B (3 parallel agents)

| Agent | WU | Depends On | Delivers |
|-------|----|------------|----------|
| pi-api | WU-3 | WU-1 | `api_server.py` + test |
| flutter-client | WU-6 | WU-5 | `storm_sense_api.dart` + test |
| flutter-settings | WU-11 | WU-5 | settings bloc + view + test |

### Phase 3 — Group C (4 parallel agents)

| Agent | WU | Depends On | Delivers |
|-------|----|------------|----------|
| pi-main | WU-4 | WU-1,2,3 | `main.py` + service file + requirements.txt |
| flutter-connect | WU-7 | WU-6 | connection bloc + view + test |
| flutter-dashboard | WU-8 | WU-6, WU-10 | dashboard bloc + views + test |
| flutter-history | WU-9 | WU-6 | history bloc + views + test |

### Phase 4 — Integration (1 agent)

| Agent | WU | Depends On | Delivers |
|-------|----|------------|----------|
| flutter-shell | WU-12 | WU-7,8,9,10,11 | main.dart, router.dart, storm_sense_app.dart |

### Between phases:

1. Review all agent outputs
2. Merge worktrees into main
3. Run tests to verify integration
4. Spawn next phase

### Agent context (each agent receives):

1. Full shared contracts section (PRD §3)
2. Its specific WU section with acceptance criteria
3. Instruction: follow PRD exactly, no deviations
4. Instruction: write tests alongside code

---

## 6. Decisions Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Scope | Full MVP WU 1-12 | User selected |
| Swarm topology | Hierarchical, 4 phases | Matches PRD dependency graph exactly |
| Hardware mocking | Full mock module + try/except import | Enables macOS development + testing |
| PRD fidelity | Exact — no deviations | User selected |
| Flutter SDK | Available locally | Can run pub get, build_runner, tests |
| Unit conversions | Display layer only | Raw metric data preserved throughout |
| Threading | Sensor=daemon thread, Flask=main | Simple, clean shutdown semantics |
