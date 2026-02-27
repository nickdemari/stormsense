# Oracle Feature Design — Atmospheric Astrology

**Date**: 2026-02-26
**Status**: Approved
**Author**: Claude Code + nickdemari

## Overview

Add a "Weather-as-Oracle" feature to StormSense that interprets current temperature, pressure, and storm level through an astrological lens. Real-time sensor data from the BMP280 is combined with computed planetary positions to generate informative, grounded cosmic-weather readings.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Core concept | Weather-as-oracle | Current conditions interpreted through astrological context |
| Placement | New 4th tab ("Oracle") | Dedicated experience, clean separation from weather data |
| Personalization | Optional birth chart | Works without it, enhanced with birth data |
| Compute layer | Flutter app (client-side) | No new Pi endpoints, works offline |
| Ephemeris approach | Pure Dart calculations | No external deps, no AGPL license issues, arcminute precision is sufficient |
| Tone | Informative & grounded | Factual positions + atmospheric interpretation, not mystical fluff |
| Image assets | Gemini-generated via surf CLI | Card backgrounds, zodiac icons, element illustrations |

## Architecture

### New Feature: `features/oracle/`

```
lib/features/oracle/
├── bloc/
│   ├── oracle_bloc.dart
│   ├── oracle_event.dart
│   └── oracle_state.dart
├── view/
│   ├── oracle_page.dart          # Main Oracle tab
│   ├── cosmic_weather_card.dart  # Current oracle reading (hero card)
│   ├── planetary_grid.dart       # Planet positions in zodiac
│   └── birth_chart_sheet.dart    # Bottom sheet for birth info input
└── models/
    └── oracle_reading.dart       # Freezed model for oracle data
```

### New Core Module: `core/astro/`

Pure Dart astronomical engine — no UI, fully testable:

```
lib/core/astro/
├── planetary_positions.dart   # Sun, Moon, Mercury-Saturn longitude calculations
├── zodiac.dart                # Sign determination, degree-to-sign mapping
├── aspects.dart               # Conjunction, opposition, trine, square detection
├── oracle_engine.dart         # Combines weather data + planetary data -> reading
└── birth_chart.dart           # Optional natal chart calculations
```

### Data Flow

```
BMP280 sensor data (temp, pressure, storm_level)
         |
         v
   DashboardBloc (existing -- already has StormStatus)
         |
         v
   OracleBloc <-- reads current StormStatus via BlocProvider
         |
         |-> PlanetaryPositions.calculate(DateTime.now())
         |     -> {sun: Aries 15deg, moon: Cancer 22deg, ...}
         |
         |-> OracleEngine.interpret(weather + planets + birthChart?)
         |     -> OracleReading (summary, element, harmony, etc.)
         |
         +-> OracleState.loaded(reading)
                  -> UI renders
```

No new Pi API endpoints needed. OracleBloc subscribes to DashboardBloc's stream for live weather data.

## Oracle Engine — Interpretation Logic

### Elemental Mapping

| Element | Zodiac Signs | Weather Condition |
|---------|-------------|-------------------|
| Fire | Aries, Leo, Sagittarius | High temp (>85F), Dry |
| Earth | Taurus, Virgo, Capricorn | Stable pressure, Fair |
| Air | Gemini, Libra, Aquarius | Pressure Change, moderate temp |
| Water | Cancer, Scorpio, Pisces | Rain, Stormy, low pressure |

### Oracle Reading Model (Freezed)

```dart
@freezed
class OracleReading with _$OracleReading {
  const factory OracleReading({
    required DateTime timestamp,
    required String dominantElement,         // "Fire", "Water", etc.
    required double elementalHarmony,        // 0.0-1.0
    required String cosmicWeatherSummary,    // 2-3 sentence interpretation
    required List<PlanetPosition> planets,   // All planet positions
    required WeatherAstroAspect? activeAspect,
    BirthChartOverlay? personalOverlay,      // null if no birth info
  }) = _OracleReading;
}

@freezed
class PlanetPosition with _$PlanetPosition {
  const factory PlanetPosition({
    required String planet,        // "Sun", "Moon", "Mars", etc.
    required String sign,          // "Aries", "Taurus", etc.
    required double longitude,     // 0-360 degrees
    required int degree,           // 0-29 within sign
    required String element,       // "Fire", "Earth", "Air", "Water"
  }) = _PlanetPosition;
}
```

### Interpretation Rules

**Elemental Harmony Score** (0.0 - 1.0): Measures alignment between atmospheric element and planetary element distribution.

- **High (>0.7)**: Weather and sky agree. "Mars conjunct Sun in Aries, barometric pressure rising sharply -- fire energy dominant. High-energy day with clear, dry conditions."
- **Moderate (0.3-0.7)**: Mixed signals. "Moon in Cancer (Water) while pressure holds steady (Earth). Emotional undercurrents beneath calm conditions."
- **Low (<0.3)**: Sky and weather at odds. "Jupiter in Sagittarius (Fire) but pressure dropping rapidly (Water). Cosmic tension -- expect the unexpected."

### Personalization (Optional Birth Chart)

When birth data is present, add a `BirthChartOverlay`:
- Transiting planets aspecting natal positions
- Which natal houses are activated
- Personal interpretation: "With your natal Moon at 15deg Scorpio, today's lunar transit through Cancer trines your emotional core."

Birth info stored locally via `shared_preferences`:
- `oracle_birth_date` (ISO 8601)
- `oracle_birth_time` (HH:mm, optional)
- `oracle_birth_latitude` / `oracle_birth_longitude` (optional)

## UI Design

### Navigation

Bottom nav: Dashboard | **Oracle** | History | Settings
Oracle icon: `Icons.auto_awesome`

### Accent Color

Deep indigo `#818CF8` (indigo-400) — distinct from existing amber/blue/green/violet.

### Card Stack (top to bottom)

1. **Cosmic Weather Card** (hero)
   - Indigo top glow line
   - Elemental harmony indicator (0-100%)
   - Dominant element icon + label
   - `cosmicWeatherSummary` text (2-3 sentences)
   - "Updated 2 min ago" timestamp

2. **Planetary Grid Card**
   - 2-column grid: Planet icon | Name | Sign glyph + degree
   - Highlight planets that changed signs today

3. **Active Aspect Card** (conditional)
   - Notable planetary aspect tied to weather interpretation
   - Only shown when a significant aspect is active

4. **Personal Insight Card** (conditional)
   - Shows transits to natal chart when birth info present
   - "Set up birth chart" CTA if no birth info -> opens bottom sheet

### Birth Chart Bottom Sheet

- Date picker (required)
- Time picker (optional, "I don't know" toggle)
- Location (optional, "I don't know" toggle)
- Save -> shared_preferences

### Design System Compliance

All cards follow existing patterns:
- `surfaceContainer` background
- 20px border radius
- `outlineVariant` border at 0.2 alpha
- Accent glow line at top
- `headlineMedium` for page header
- Tabular figures for numeric values

## Image Assets (Gemini-generated via surf CLI)

Generate the following using Google Gemini image generation:

1. **Card backgrounds** — Subtle cosmic/zodiac textures, dark theme compatible, muted tones
2. **Zodiac sign icons** (12) — Custom artwork for each sign, consistent style
3. **Element illustrations** (4) — Fire, Earth, Air, Water artwork for dominant element display

Assets saved to `storm_sense/assets/oracle/`.

## Testing Strategy

### Unit Tests (`test/core/astro/`)

- `planetary_positions_test.dart` — Given known dates, assert longitudes within +-1deg of published ephemeris
- `zodiac_test.dart` — Boundary tests at 0deg, 29.99deg for all signs
- `aspects_test.dart` — Conjunction, opposition, trine, square detection
- `oracle_engine_test.dart` — Interpretation rules, elemental harmony scoring

### BLoC Tests (`test/features/oracle/`)

- `oracle_bloc_test.dart` — Mock DashboardBloc stream, verify state emissions

### Widget Tests

- Verify cards render with test data
- Birth chart sheet opens and saves correctly

## Swarm Implementation Strategy

Hierarchical topology, 7 agents total:

| # | Agent | Role | Key Files | Dependencies |
|---|-------|------|-----------|-------------|
| 1 | astro-engine | Planetary math + zodiac mapping | `core/astro/planetary_positions.dart`, `zodiac.dart`, `aspects.dart` + tests | None |
| 2 | oracle-logic | Interpretation engine + Freezed models | `core/astro/oracle_engine.dart`, `features/oracle/models/`, `features/oracle/bloc/` | #1 |
| 3 | oracle-ui | Oracle page + all view cards | `features/oracle/view/oracle_page.dart`, `cosmic_weather_card.dart`, `planetary_grid.dart` | #2 |
| 4 | nav-integration | Router, bottom nav, BLoC wiring | `app/router.dart`, `app/storm_sense_app.dart` | None (parallel) |
| 5 | birth-chart | Birth info storage + calculations | `core/astro/birth_chart.dart`, `birth_chart_sheet.dart` | #1 |
| 6 | image-gen | Generate assets via surf CLI + Gemini | `assets/oracle/` | None (parallel) |
| 7 | test-runner | Run all tests, validate integration | All test files | #1-#5 |

```bash
npx @claude-flow/cli@latest swarm init --topology hierarchical --max-agents 8 --strategy specialized
```

## Out of Scope

- No new Pi API endpoints
- No server-side astrology computation
- No real-time planetary transit notifications (future enhancement)
- No social sharing of readings
- No horoscope text from external APIs
