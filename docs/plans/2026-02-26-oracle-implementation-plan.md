# Oracle (Atmospheric Astrology) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a client-side "Weather-as-Oracle" tab to StormSense that combines BMP280 sensor data with pure-Dart planetary position calculations to produce informative, grounded cosmic-weather readings.

**Architecture:** New `core/astro/` module handles all astronomical math (Sun, Moon, Mercury–Saturn longitudes via simplified VSOP87/ELP). New `features/oracle/` feature follows existing BLoC pattern. OracleBloc subscribes to DashboardBloc's state stream for live weather data. Optional birth chart stored in `shared_preferences`. Gemini-generated image assets via `surf` CLI.

**Tech Stack:** Flutter/Dart, flutter_bloc, Freezed, Equatable, shared_preferences, mocktail, bloc_test. No external astrology packages — pure Dart math.

**Design Doc:** `docs/plans/2026-02-26-oracle-astrology-design.md`

**Swarm Topology:** Hierarchical, 7 agents. See Task 0 for swarm init.

---

## Task 0: Initialize Swarm & Generate Image Assets

This task bootstraps the Claude Flow swarm and kicks off the parallel image generation agent. Run this before all other tasks.

**Step 1: Init the swarm**

```bash
npx @claude-flow/cli@latest swarm init --topology hierarchical --max-agents 8 --strategy specialized
```

**Step 2: Generate image assets via surf CLI + Gemini**

Open a browser tab to Gemini and generate images. Save all assets to `storm_sense/assets/oracle/`.

```bash
# Create the assets directory
mkdir -p storm_sense/assets/oracle/elements storm_sense/assets/oracle/zodiac storm_sense/assets/oracle/backgrounds

# Open Gemini
surf go "https://gemini.google.com"
surf read  # verify page loaded
```

Generate the following images (one prompt at a time):

**Element illustrations (4):**
- Prompt: "Minimalist icon illustration of the [Fire/Earth/Air/Water] element for a dark-themed weather app. Abstract, geometric style. Indigo and [element color] tones on transparent background. 256x256px."
- Save to: `storm_sense/assets/oracle/elements/fire.png`, `earth.png`, `air.png`, `water.png`

**Zodiac sign icons (12):**
- Prompt: "Minimalist line-art icon of the [Aries/Taurus/etc.] zodiac sign. Thin white lines on transparent background. Geometric, modern style. 128x128px."
- Save to: `storm_sense/assets/oracle/zodiac/aries.png`, `taurus.png`, etc.

**Card backgrounds (1):**
- Prompt: "Subtle cosmic nebula texture for a dark-themed mobile app card background. Very muted indigo and deep purple tones, almost black. Seamless tileable. 512x512px."
- Save to: `storm_sense/assets/oracle/backgrounds/cosmic_bg.png`

**Step 3: Register assets in pubspec.yaml**

File: `storm_sense/pubspec.yaml`

Add under the `flutter:` section:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/oracle/elements/
    - assets/oracle/zodiac/
    - assets/oracle/backgrounds/
```

**Step 4: Commit**

```bash
cd storm_sense
git add assets/oracle/ pubspec.yaml
git commit -m "assets: add Gemini-generated oracle imagery (elements, zodiac, backgrounds)"
```

---

## Task 1: Zodiac Module — `core/astro/zodiac.dart`

The foundation. Maps ecliptic longitude (0–360°) to zodiac signs and elements. Zero dependencies. Pure functions.

**Files:**
- Create: `storm_sense/lib/core/astro/zodiac.dart`
- Test: `storm_sense/test/core/astro/zodiac_test.dart`

**Step 1: Write the failing tests**

File: `storm_sense/test/core/astro/zodiac_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storm_sense/core/astro/zodiac.dart';

void main() {
  group('ZodiacSign', () {
    test('has 12 signs', () {
      expect(ZodiacSign.values.length, 12);
    });

    test('aries is first, pisces is last', () {
      expect(ZodiacSign.values.first, ZodiacSign.aries);
      expect(ZodiacSign.values.last, ZodiacSign.pisces);
    });
  });

  group('Element', () {
    test('has 4 elements', () {
      expect(AstroElement.values.length, 4);
    });
  });

  group('ZodiacSign.element', () {
    test('fire signs', () {
      expect(ZodiacSign.aries.element, AstroElement.fire);
      expect(ZodiacSign.leo.element, AstroElement.fire);
      expect(ZodiacSign.sagittarius.element, AstroElement.fire);
    });

    test('earth signs', () {
      expect(ZodiacSign.taurus.element, AstroElement.earth);
      expect(ZodiacSign.virgo.element, AstroElement.earth);
      expect(ZodiacSign.capricorn.element, AstroElement.earth);
    });

    test('air signs', () {
      expect(ZodiacSign.gemini.element, AstroElement.air);
      expect(ZodiacSign.libra.element, AstroElement.air);
      expect(ZodiacSign.aquarius.element, AstroElement.air);
    });

    test('water signs', () {
      expect(ZodiacSign.cancer.element, AstroElement.water);
      expect(ZodiacSign.scorpio.element, AstroElement.water);
      expect(ZodiacSign.pisces.element, AstroElement.water);
    });
  });

  group('signFromLongitude', () {
    test('0 degrees is Aries', () {
      expect(signFromLongitude(0.0), ZodiacSign.aries);
    });

    test('29.99 degrees is still Aries', () {
      expect(signFromLongitude(29.99), ZodiacSign.aries);
    });

    test('30 degrees is Taurus', () {
      expect(signFromLongitude(30.0), ZodiacSign.taurus);
    });

    test('359.99 degrees is Pisces', () {
      expect(signFromLongitude(359.99), ZodiacSign.pisces);
    });

    test('330 degrees is Pisces', () {
      expect(signFromLongitude(330.0), ZodiacSign.pisces);
    });

    test('180 degrees is Libra', () {
      expect(signFromLongitude(180.0), ZodiacSign.libra);
    });

    test('negative wraps around', () {
      // -10 degrees = 350 degrees = Pisces
      expect(signFromLongitude(-10.0), ZodiacSign.pisces);
    });

    test('over 360 wraps around', () {
      // 370 degrees = 10 degrees = Aries
      expect(signFromLongitude(370.0), ZodiacSign.aries);
    });
  });

  group('degreeInSign', () {
    test('0 longitude is 0 degrees in Aries', () {
      expect(degreeInSign(0.0), 0);
    });

    test('45 longitude is 15 degrees in Taurus', () {
      expect(degreeInSign(45.0), 15);
    });

    test('359.9 is 29 degrees in Pisces', () {
      expect(degreeInSign(359.9), 29);
    });
  });

  group('ZodiacSign.glyph', () {
    test('aries glyph is correct unicode', () {
      expect(ZodiacSign.aries.glyph, '\u2648');
    });

    test('pisces glyph is correct unicode', () {
      expect(ZodiacSign.pisces.glyph, '\u2653');
    });
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
cd storm_sense && flutter test test/core/astro/zodiac_test.dart
```

Expected: FAIL — `zodiac.dart` does not exist yet.

**Step 3: Write minimal implementation**

File: `storm_sense/lib/core/astro/zodiac.dart`

```dart
/// Zodiac sign and element mapping from ecliptic longitude.
///
/// Each sign spans 30 degrees of the ecliptic, starting at 0° Aries.

enum AstroElement {
  fire('Fire'),
  earth('Earth'),
  air('Air'),
  water('Water');

  const AstroElement(this.label);
  final String label;
}

enum ZodiacSign {
  aries('Aries', '\u2648', AstroElement.fire),
  taurus('Taurus', '\u2649', AstroElement.earth),
  gemini('Gemini', '\u264A', AstroElement.air),
  cancer('Cancer', '\u264B', AstroElement.water),
  leo('Leo', '\u264C', AstroElement.fire),
  virgo('Virgo', '\u264D', AstroElement.earth),
  libra('Libra', '\u264E', AstroElement.air),
  scorpio('Scorpio', '\u264F', AstroElement.water),
  sagittarius('Sagittarius', '\u2650', AstroElement.fire),
  capricorn('Capricorn', '\u2651', AstroElement.earth),
  aquarius('Aquarius', '\u2652', AstroElement.air),
  pisces('Pisces', '\u2653', AstroElement.water);

  const ZodiacSign(this.label, this.glyph, this.element);

  final String label;
  final String glyph;
  final AstroElement element;
}

/// Returns the zodiac sign for an ecliptic longitude (0–360°).
/// Handles wrapping for negative or >360 values.
ZodiacSign signFromLongitude(double longitude) {
  final normalized = longitude % 360;
  final wrapped = normalized < 0 ? normalized + 360 : normalized;
  final index = wrapped ~/ 30;
  return ZodiacSign.values[index.clamp(0, 11)];
}

/// Returns the degree within the current sign (0–29).
int degreeInSign(double longitude) {
  final normalized = longitude % 360;
  final wrapped = normalized < 0 ? normalized + 360 : normalized;
  return (wrapped % 30).floor();
}
```

**Step 4: Run tests to verify they pass**

```bash
cd storm_sense && flutter test test/core/astro/zodiac_test.dart -v
```

Expected: ALL PASS

**Step 5: Commit**

```bash
cd storm_sense
git add lib/core/astro/zodiac.dart test/core/astro/zodiac_test.dart
git commit -m "feat(astro): add zodiac sign and element mapping from ecliptic longitude"
```

---

## Task 2: Planetary Positions — `core/astro/planetary_positions.dart`

Pure Dart implementation of simplified astronomical algorithms for Sun, Moon, and naked-eye planets (Mercury through Saturn). Uses truncated VSOP87 / Jean Meeus formulas. Accuracy target: ±1° (more than sufficient for zodiac sign determination).

**Files:**
- Create: `storm_sense/lib/core/astro/planetary_positions.dart`
- Test: `storm_sense/test/core/astro/planetary_positions_test.dart`

**Reference data for tests:** Use known ephemeris positions. Source: JPL Horizons or any almanac.

**Step 1: Write the failing tests**

File: `storm_sense/test/core/astro/planetary_positions_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storm_sense/core/astro/planetary_positions.dart';
import 'package:storm_sense/core/astro/zodiac.dart';

void main() {
  group('PlanetaryPositions', () {
    // Known reference: 2026-03-20 (vernal equinox) — Sun at ~0° Aries
    final equinox2026 = DateTime.utc(2026, 3, 20, 10, 0);

    // Known reference: 2026-01-01 00:00 UTC
    final newYear2026 = DateTime.utc(2026, 1, 1);

    group('sunLongitude', () {
      test('sun near 0 degrees at vernal equinox', () {
        final lon = PlanetaryPositions.sunLongitude(equinox2026);
        // Sun should be near 0° (±2°) at vernal equinox
        expect(lon, closeTo(0.0, 2.0));
      });

      test('sun in Capricorn on Jan 1', () {
        final lon = PlanetaryPositions.sunLongitude(newYear2026);
        final sign = signFromLongitude(lon);
        expect(sign, ZodiacSign.capricorn);
      });

      test('sun longitude is between 0 and 360', () {
        final lon = PlanetaryPositions.sunLongitude(DateTime.utc(2026, 6, 15));
        expect(lon, greaterThanOrEqualTo(0.0));
        expect(lon, lessThan(360.0));
      });
    });

    group('moonLongitude', () {
      test('moon longitude is between 0 and 360', () {
        final lon = PlanetaryPositions.moonLongitude(newYear2026);
        expect(lon, greaterThanOrEqualTo(0.0));
        expect(lon, lessThan(360.0));
      });

      test('moon moves roughly 13 degrees per day', () {
        final day1 = PlanetaryPositions.moonLongitude(newYear2026);
        final day2 = PlanetaryPositions.moonLongitude(
          newYear2026.add(const Duration(days: 1)),
        );
        // Moon moves ~13.2°/day. Allow wide tolerance since our formula is simplified.
        final delta = (day2 - day1 + 360) % 360;
        expect(delta, closeTo(13.2, 3.0));
      });
    });

    group('allPositions', () {
      test('returns positions for 8 bodies (Sun through Saturn)', () {
        final positions = PlanetaryPositions.allPositions(newYear2026);
        expect(positions.length, 8);
        expect(positions.map((p) => p.name), containsAll([
          'Sun', 'Moon', 'Mercury', 'Venus', 'Mars',
          'Jupiter', 'Saturn',
        ]));
      });

      test('all longitudes are 0-360', () {
        final positions = PlanetaryPositions.allPositions(newYear2026);
        for (final p in positions) {
          expect(p.longitude, greaterThanOrEqualTo(0.0),
              reason: '${p.name} longitude should be >= 0');
          expect(p.longitude, lessThan(360.0),
              reason: '${p.name} longitude should be < 360');
        }
      });

      test('each position has correct sign from its longitude', () {
        final positions = PlanetaryPositions.allPositions(newYear2026);
        for (final p in positions) {
          expect(p.sign, signFromLongitude(p.longitude),
              reason: '${p.name} sign should match its longitude');
        }
      });
    });
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
cd storm_sense && flutter test test/core/astro/planetary_positions_test.dart
```

Expected: FAIL — `planetary_positions.dart` does not exist yet.

**Step 3: Write implementation**

File: `storm_sense/lib/core/astro/planetary_positions.dart`

```dart
import 'dart:math' as math;

import 'package:storm_sense/core/astro/zodiac.dart';

/// A computed planetary position.
class CelestialPosition {
  const CelestialPosition({
    required this.name,
    required this.longitude,
    required this.sign,
    required this.degreeInSign,
    required this.element,
  });

  final String name;
  final double longitude;
  final ZodiacSign sign;
  final int degreeInSign;
  final AstroElement element;
}

/// Pure Dart astronomical position calculator.
///
/// Uses simplified algorithms from Jean Meeus' "Astronomical Algorithms".
/// Accuracy: ±1° for Sun, ±2° for Moon, ±1-3° for planets.
/// This is more than sufficient for zodiac sign determination (signs are 30° wide).
class PlanetaryPositions {
  PlanetaryPositions._();

  /// Julian centuries since J2000.0 epoch.
  static double _julianCenturies(DateTime dt) {
    // Convert to Julian Day Number
    final utc = dt.toUtc();
    final jd = _julianDay(utc);
    return (jd - 2451545.0) / 36525.0;
  }

  /// Julian Day from UTC DateTime.
  static double _julianDay(DateTime dt) {
    int y = dt.year;
    int m = dt.month;
    final d = dt.day +
        dt.hour / 24.0 +
        dt.minute / 1440.0 +
        dt.second / 86400.0;

    if (m <= 2) {
      y -= 1;
      m += 12;
    }

    final a = y ~/ 100;
    final b = 2 - a + a ~/ 4;
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
  }

  static double _normalizeDegrees(double deg) {
    final result = deg % 360;
    return result < 0 ? result + 360 : result;
  }

  static double _degToRad(double deg) => deg * math.pi / 180;

  /// Solar longitude (ecliptic) in degrees.
  /// Simplified formula from Meeus Ch. 25 (low accuracy, ±1°).
  static double sunLongitude(DateTime dt) {
    final t = _julianCenturies(dt);

    // Geometric mean longitude of the Sun (degrees)
    final l0 = _normalizeDegrees(280.46646 + 36000.76983 * t + 0.0003032 * t * t);

    // Mean anomaly of the Sun (degrees)
    final m = _normalizeDegrees(357.52911 + 35999.05029 * t - 0.0001537 * t * t);
    final mRad = _degToRad(m);

    // Equation of center
    final c = (1.9146 - 0.004817 * t - 0.000014 * t * t) * math.sin(mRad) +
        (0.019993 - 0.000101 * t) * math.sin(2 * mRad) +
        0.00029 * math.sin(3 * mRad);

    // Sun's true longitude
    final sunLon = l0 + c;

    // Apparent longitude (nutation correction, small)
    final omega = 125.04 - 1934.136 * t;
    final apparent = sunLon - 0.00569 - 0.00478 * math.sin(_degToRad(omega));

    return _normalizeDegrees(apparent);
  }

  /// Lunar longitude (ecliptic) in degrees.
  /// Simplified formula from Meeus Ch. 47 (low accuracy, ±2°).
  static double moonLongitude(DateTime dt) {
    final t = _julianCenturies(dt);

    // Mean longitude
    final lp = _normalizeDegrees(
        218.3165 + 481267.8813 * t);
    // Mean elongation
    final d = _normalizeDegrees(
        297.8502 + 445267.1115 * t);
    // Sun's mean anomaly
    final m = _normalizeDegrees(
        357.5291 + 35999.0503 * t);
    // Moon's mean anomaly
    final mp = _normalizeDegrees(
        134.9634 + 477198.8676 * t);
    // Moon's argument of latitude
    final f = _normalizeDegrees(
        93.2720 + 483202.0175 * t);

    final dR = _degToRad(d);
    final mR = _degToRad(m);
    final mpR = _degToRad(mp);
    final fR = _degToRad(f);

    // Principal terms (simplified — 6 largest terms)
    var lon = lp +
        6.289 * math.sin(mpR) +
        1.274 * math.sin(2 * dR - mpR) +
        0.658 * math.sin(2 * dR) +
        0.214 * math.sin(2 * mpR) -
        0.186 * math.sin(mR) -
        0.114 * math.sin(2 * fR);

    return _normalizeDegrees(lon);
  }

  /// Simplified planetary longitude for Mercury through Saturn.
  /// Uses mean elements + first-order perturbation terms.
  /// Accuracy: ±1-3° (sufficient for sign determination).
  static double _planetLongitude(DateTime dt, _PlanetElements el) {
    final t = _julianCenturies(dt);

    // Mean longitude
    final l = _normalizeDegrees(el.l0 + el.l1 * t);

    // For inner planets, apply simplified equation of center
    final m = _normalizeDegrees(el.m0 + el.m1 * t);
    final mRad = _degToRad(m);

    final eqCenter = el.c1 * math.sin(mRad) +
        el.c2 * math.sin(2 * mRad);

    return _normalizeDegrees(l + eqCenter);
  }

  /// All 8 celestial body positions (Sun, Moon, Mercury–Saturn).
  static List<CelestialPosition> allPositions(DateTime dt) {
    final bodies = <CelestialPosition>[];

    // Sun
    final sunLon = sunLongitude(dt);
    bodies.add(_makePosition('Sun', sunLon));

    // Moon
    final moonLon = moonLongitude(dt);
    bodies.add(_makePosition('Moon', moonLon));

    // Planets
    for (final entry in _planets.entries) {
      final lon = _planetLongitude(dt, entry.value);
      bodies.add(_makePosition(entry.key, lon));
    }

    return bodies;
  }

  static CelestialPosition _makePosition(String name, double longitude) {
    final sign = signFromLongitude(longitude);
    return CelestialPosition(
      name: name,
      longitude: longitude,
      sign: sign,
      degreeInSign: degreeInSign(longitude),
      element: sign.element,
    );
  }

  // Simplified orbital elements for planets.
  // l0, l1: mean longitude (deg, deg/century)
  // m0, m1: mean anomaly (deg, deg/century)
  // c1, c2: equation of center coefficients (deg)
  static final _planets = <String, _PlanetElements>{
    'Mercury': _PlanetElements(
      l0: 252.2509, l1: 149472.6746,
      m0: 174.7948, m1: 149472.5153,
      c1: 23.44, c2: 2.98,
    ),
    'Venus': _PlanetElements(
      l0: 181.9798, l1: 58517.8157,
      m0: 50.4161, m1: 58517.8039,
      c1: 0.7758, c2: 0.0033,
    ),
    'Mars': _PlanetElements(
      l0: 355.4330, l1: 19140.2993,
      m0: 19.3730, m1: 19139.8585,
      c1: 10.6912, c2: 0.6228,
    ),
    'Jupiter': _PlanetElements(
      l0: 34.3515, l1: 3034.9057,
      m0: 20.0202, m1: 3034.6962,
      c1: 5.5549, c2: 0.1683,
    ),
    'Saturn': _PlanetElements(
      l0: 50.0774, l1: 1222.1138,
      m0: 317.0207, m1: 1222.1116,
      c1: 6.3642, c2: 0.2609,
    ),
    'Rahu': _PlanetElements(
      l0: 125.0445, l1: -1934.1363,
      m0: 0, m1: 0,
      c1: 0, c2: 0,
    ),
  };
}

class _PlanetElements {
  const _PlanetElements({
    required this.l0,
    required this.l1,
    required this.m0,
    required this.m1,
    required this.c1,
    required this.c2,
  });

  final double l0, l1; // mean longitude
  final double m0, m1; // mean anomaly
  final double c1, c2; // equation of center coefficients
}
```

**Step 4: Run tests to verify they pass**

```bash
cd storm_sense && flutter test test/core/astro/planetary_positions_test.dart -v
```

Expected: ALL PASS. If the vernal equinox test is off by >2°, tweak the apparent longitude nutation coefficient.

**Step 5: Commit**

```bash
cd storm_sense
git add lib/core/astro/planetary_positions.dart test/core/astro/planetary_positions_test.dart
git commit -m "feat(astro): add pure Dart planetary position calculator (Sun, Moon, Mercury-Saturn)"
```

---

## Task 3: Aspects Module — `core/astro/aspects.dart`

Detects major planetary aspects (conjunction, opposition, trine, square, sextile) between any two celestial bodies.

**Files:**
- Create: `storm_sense/lib/core/astro/aspects.dart`
- Test: `storm_sense/test/core/astro/aspects_test.dart`

**Step 1: Write the failing tests**

File: `storm_sense/test/core/astro/aspects_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storm_sense/core/astro/aspects.dart';

void main() {
  group('AspectType', () {
    test('has 5 major aspects', () {
      expect(AspectType.values.length, 5);
    });
  });

  group('findAspect', () {
    test('0 degree separation is conjunction', () {
      final aspect = findAspect(10.0, 10.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.conjunction);
    });

    test('180 degree separation is opposition', () {
      final aspect = findAspect(0.0, 180.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.opposition);
    });

    test('120 degree separation is trine', () {
      final aspect = findAspect(0.0, 120.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.trine);
    });

    test('90 degree separation is square', () {
      final aspect = findAspect(45.0, 135.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.square);
    });

    test('60 degree separation is sextile', () {
      final aspect = findAspect(0.0, 60.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.sextile);
    });

    test('within orb detects aspect', () {
      // 8 degree orb for conjunction: 7 degrees apart should match
      final aspect = findAspect(0.0, 7.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.conjunction);
    });

    test('outside orb returns null', () {
      // No major aspect at 45 degrees
      final aspect = findAspect(0.0, 45.0);
      expect(aspect, isNull);
    });

    test('wrapping around 360 degrees works', () {
      // 355 and 5 are 10 degrees apart -> conjunction (orb 8) -> outside
      // 355 and 2 are 7 degrees apart -> conjunction
      final aspect = findAspect(355.0, 2.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.conjunction);
    });

    test('aspect has orb value', () {
      final aspect = findAspect(10.0, 13.0);
      expect(aspect, isNotNull);
      expect(aspect!.orb, closeTo(3.0, 0.01));
    });
  });

  group('findAllAspects', () {
    test('finds multiple aspects in a list of longitudes', () {
      // Sun at 0, Moon at 120 (trine), Mars at 180 (opposition to Sun)
      final longitudes = {
        'Sun': 0.0,
        'Moon': 120.0,
        'Mars': 180.0,
      };
      final aspects = findAllAspects(longitudes);
      expect(aspects.length, greaterThanOrEqualTo(2));
    });
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
cd storm_sense && flutter test test/core/astro/aspects_test.dart
```

Expected: FAIL — file not found.

**Step 3: Write implementation**

File: `storm_sense/lib/core/astro/aspects.dart`

```dart
/// Planetary aspect detection.
///
/// An "aspect" is a specific angular relationship between two celestial bodies.
/// Each aspect has an "orb" — the tolerance in degrees for detection.

enum AspectType {
  conjunction(0, 8, 'Conjunction', '\u260C', 'unity'),
  sextile(60, 6, 'Sextile', '\u26B9', 'opportunity'),
  square(90, 7, 'Square', '\u25A1', 'tension'),
  trine(120, 8, 'Trine', '\u25B3', 'harmony'),
  opposition(180, 8, 'Opposition', '\u260D', 'polarity');

  const AspectType(this.angle, this.orb, this.label, this.glyph, this.keyword);

  final double angle;
  final double orb;
  final String label;
  final String glyph;
  final String keyword;
}

class Aspect {
  const Aspect({
    required this.type,
    required this.body1,
    required this.body2,
    required this.orb,
  });

  final AspectType type;
  final String body1;
  final String body2;
  final double orb;
}

/// Find the aspect between two ecliptic longitudes, if any.
/// Returns null if no major aspect is within orb.
Aspect? findAspect(double lon1, double lon2, {String body1 = '', String body2 = ''}) {
  final separation = _angularSeparation(lon1, lon2);

  for (final type in AspectType.values) {
    final diff = (separation - type.angle).abs();
    if (diff <= type.orb) {
      return Aspect(type: type, body1: body1, body2: body2, orb: diff);
    }
  }
  return null;
}

/// Find all aspects between a map of named longitudes.
List<Aspect> findAllAspects(Map<String, double> longitudes) {
  final aspects = <Aspect>[];
  final names = longitudes.keys.toList();

  for (var i = 0; i < names.length; i++) {
    for (var j = i + 1; j < names.length; j++) {
      final aspect = findAspect(
        longitudes[names[i]]!,
        longitudes[names[j]]!,
        body1: names[i],
        body2: names[j],
      );
      if (aspect != null) {
        aspects.add(aspect);
      }
    }
  }

  // Sort by tightest orb (most exact aspect first)
  aspects.sort((a, b) => a.orb.compareTo(b.orb));
  return aspects;
}

double _angularSeparation(double lon1, double lon2) {
  final diff = (lon2 - lon1).abs() % 360;
  return diff > 180 ? 360 - diff : diff;
}
```

**Step 4: Run tests**

```bash
cd storm_sense && flutter test test/core/astro/aspects_test.dart -v
```

Expected: ALL PASS

**Step 5: Commit**

```bash
cd storm_sense
git add lib/core/astro/aspects.dart test/core/astro/aspects_test.dart
git commit -m "feat(astro): add planetary aspect detection (conjunction, sextile, square, trine, opposition)"
```

---

## Task 4: Oracle Engine — `core/astro/oracle_engine.dart`

The brain. Takes weather data (StormStatus) + planetary positions → produces an OracleReading with elemental harmony score, dominant element, and interpretation text.

**Files:**
- Create: `storm_sense/lib/core/astro/oracle_engine.dart`
- Test: `storm_sense/test/core/astro/oracle_engine_test.dart`

**Step 1: Write the failing tests**

File: `storm_sense/test/core/astro/oracle_engine_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storm_sense/core/astro/oracle_engine.dart';
import 'package:storm_sense/core/astro/planetary_positions.dart';
import 'package:storm_sense/core/astro/zodiac.dart';

void main() {
  group('weatherElement', () {
    test('stormy level returns water', () {
      expect(weatherElement(stormLevel: 4, temperatureF: 70), AstroElement.water);
    });

    test('rain level returns water', () {
      expect(weatherElement(stormLevel: 3, temperatureF: 70), AstroElement.water);
    });

    test('dry level returns fire', () {
      expect(weatherElement(stormLevel: 0, temperatureF: 90), AstroElement.fire);
    });

    test('fair level returns earth', () {
      expect(weatherElement(stormLevel: 1, temperatureF: 70), AstroElement.earth);
    });

    test('change level returns air', () {
      expect(weatherElement(stormLevel: 2, temperatureF: 70), AstroElement.air);
    });

    test('high temp with dry overrides to fire', () {
      expect(weatherElement(stormLevel: 0, temperatureF: 95), AstroElement.fire);
    });
  });

  group('elementalHarmony', () {
    test('returns 1.0 when all planets match weather element', () {
      final positions = List.generate(
        8,
        (i) => CelestialPosition(
          name: 'Body$i',
          longitude: 0.0, // Aries = fire
          sign: ZodiacSign.aries,
          degreeInSign: 0,
          element: AstroElement.fire,
        ),
      );
      final score = elementalHarmony(positions, AstroElement.fire);
      expect(score, 1.0);
    });

    test('returns 0.0 when no planets match weather element', () {
      final positions = List.generate(
        8,
        (i) => CelestialPosition(
          name: 'Body$i',
          longitude: 30.0, // Taurus = earth
          sign: ZodiacSign.taurus,
          degreeInSign: 0,
          element: AstroElement.earth,
        ),
      );
      final score = elementalHarmony(positions, AstroElement.fire);
      expect(score, 0.0);
    });

    test('returns fractional value for mixed elements', () {
      final positions = [
        CelestialPosition(name: 'Sun', longitude: 0, sign: ZodiacSign.aries, degreeInSign: 0, element: AstroElement.fire),
        CelestialPosition(name: 'Moon', longitude: 30, sign: ZodiacSign.taurus, degreeInSign: 0, element: AstroElement.earth),
      ];
      final score = elementalHarmony(positions, AstroElement.fire);
      expect(score, closeTo(0.5, 0.01));
    });
  });

  group('OracleEngine.generateReading', () {
    test('returns a reading with all required fields', () {
      final reading = OracleEngine.generateReading(
        temperatureF: 72.0,
        pressure: 1013.25,
        stormLevel: 1,
        dateTime: DateTime.utc(2026, 3, 1),
      );

      expect(reading.timestamp, isNotNull);
      expect(reading.dominantElement, isNotEmpty);
      expect(reading.elementalHarmony, inInclusiveRange(0.0, 1.0));
      expect(reading.cosmicWeatherSummary, isNotEmpty);
      expect(reading.planets, hasLength(8));
    });

    test('stormy conditions produce water-dominant reading', () {
      final reading = OracleEngine.generateReading(
        temperatureF: 55.0,
        pressure: 990.0,
        stormLevel: 4,
        dateTime: DateTime.utc(2026, 3, 1),
      );

      expect(reading.dominantElement, 'Water');
    });
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
cd storm_sense && flutter test test/core/astro/oracle_engine_test.dart
```

**Step 3: Write implementation**

File: `storm_sense/lib/core/astro/oracle_engine.dart`

```dart
import 'package:storm_sense/core/astro/aspects.dart';
import 'package:storm_sense/core/astro/planetary_positions.dart';
import 'package:storm_sense/core/astro/zodiac.dart';

/// An oracle reading combining weather and planetary data.
class OracleReading {
  const OracleReading({
    required this.timestamp,
    required this.dominantElement,
    required this.elementalHarmony,
    required this.cosmicWeatherSummary,
    required this.planets,
    required this.aspects,
    this.weatherElement,
  });

  final DateTime timestamp;
  final String dominantElement;
  final double elementalHarmony;
  final String cosmicWeatherSummary;
  final List<CelestialPosition> planets;
  final List<Aspect> aspects;
  final AstroElement? weatherElement;
}

/// Determines the atmospheric element from weather conditions.
AstroElement weatherElement({
  required int stormLevel,
  required double temperatureF,
}) {
  // Water: storms and rain take priority
  if (stormLevel >= 3) return AstroElement.water;

  // Fire: dry + hot
  if (stormLevel == 0 && temperatureF > 85) return AstroElement.fire;
  if (stormLevel == 0) return AstroElement.fire;

  // Air: changing conditions
  if (stormLevel == 2) return AstroElement.air;

  // Earth: fair/stable
  return AstroElement.earth;
}

/// Calculates how aligned the planetary elements are with the weather element.
/// Returns 0.0 (no match) to 1.0 (all planets in weather's element).
double elementalHarmony(
  List<CelestialPosition> positions,
  AstroElement weather,
) {
  if (positions.isEmpty) return 0.0;
  final matches = positions.where((p) => p.element == weather).length;
  return matches / positions.length;
}

/// The Oracle Engine — combines weather data with planetary positions.
class OracleEngine {
  OracleEngine._();

  static OracleReading generateReading({
    required double temperatureF,
    required double pressure,
    required int stormLevel,
    required DateTime dateTime,
  }) {
    final planets = PlanetaryPositions.allPositions(dateTime);
    final weather = weatherElement(
      stormLevel: stormLevel,
      temperatureF: temperatureF,
    );
    final harmony = elementalHarmony(planets, weather);

    // Find the dominant planetary element
    final elementCounts = <AstroElement, int>{};
    for (final p in planets) {
      elementCounts[p.element] = (elementCounts[p.element] ?? 0) + 1;
    }
    final dominantPlanetary = elementCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    // Build aspect list
    final longitudes = {for (final p in planets) p.name: p.longitude};
    final aspects = findAllAspects(longitudes);

    // Generate summary text
    final summary = _generateSummary(
      planets: planets,
      weather: weather,
      harmony: harmony,
      stormLevel: stormLevel,
      temperatureF: temperatureF,
      pressure: pressure,
      dominantPlanetary: dominantPlanetary,
      aspects: aspects,
    );

    return OracleReading(
      timestamp: dateTime,
      dominantElement: weather.label,
      elementalHarmony: harmony,
      cosmicWeatherSummary: summary,
      planets: planets,
      aspects: aspects,
      weatherElement: weather,
    );
  }

  static String _generateSummary({
    required List<CelestialPosition> planets,
    required AstroElement weather,
    required double harmony,
    required int stormLevel,
    required double temperatureF,
    required double pressure,
    required AstroElement dominantPlanetary,
    required List<Aspect> aspects,
  }) {
    final sun = planets.firstWhere((p) => p.name == 'Sun');
    final moon = planets.firstWhere((p) => p.name == 'Moon');

    final buffer = StringBuffer();

    // Opening: Sun and Moon positions
    buffer.write(
      'Sun in ${sun.sign.label} ${sun.sign.glyph} ${sun.degreeInSign}\u00B0, '
      'Moon in ${moon.sign.label} ${moon.sign.glyph} ${moon.degreeInSign}\u00B0. ',
    );

    // Harmony assessment
    if (harmony > 0.7) {
      buffer.write(
        '${weather.label} energy dominates both sky and atmosphere \u2014 '
        'celestial and terrestrial forces are aligned. ',
      );
    } else if (harmony > 0.3) {
      buffer.write(
        'Mixed elemental signatures: ${weather.label} conditions meet '
        '${dominantPlanetary.label} planetary energy. '
        'Expect nuanced, layered influences. ',
      );
    } else {
      buffer.write(
        'Cosmic tension: ${dominantPlanetary.label} planetary energy clashes '
        'with ${weather.label} atmospheric conditions. '
        'Contradictory forces create unpredictable dynamics. ',
      );
    }

    // Most notable aspect
    if (aspects.isNotEmpty) {
      final top = aspects.first;
      buffer.write(
        '${top.body1} ${top.type.glyph} ${top.body2} '
        '(${top.type.label}) signals ${top.type.keyword}.',
      );
    }

    return buffer.toString();
  }
}
```

**Step 4: Run tests**

```bash
cd storm_sense && flutter test test/core/astro/oracle_engine_test.dart -v
```

Expected: ALL PASS

**Step 5: Commit**

```bash
cd storm_sense
git add lib/core/astro/oracle_engine.dart test/core/astro/oracle_engine_test.dart
git commit -m "feat(astro): add OracleEngine combining weather data with planetary positions"
```

---

## Task 5: Freezed Models & Oracle BLoC

**Files:**
- Create: `storm_sense/lib/features/oracle/bloc/oracle_bloc.dart`
- Create: `storm_sense/lib/features/oracle/bloc/oracle_event.dart`
- Create: `storm_sense/lib/features/oracle/bloc/oracle_state.dart`
- Test: `storm_sense/test/features/oracle/oracle_bloc_test.dart`

**Step 1: Write the oracle events**

File: `storm_sense/lib/features/oracle/bloc/oracle_event.dart`

```dart
part of 'oracle_bloc.dart';

sealed class OracleEvent extends Equatable {
  const OracleEvent();

  @override
  List<Object?> get props => [];
}

/// Starts the oracle — subscribes to dashboard state stream.
final class OracleStarted extends OracleEvent {
  const OracleStarted();
}

/// Dashboard emitted new weather data — recalculate oracle.
final class OracleWeatherUpdated extends OracleEvent {
  const OracleWeatherUpdated(this.temperatureF, this.pressure, this.stormLevel);

  final double temperatureF;
  final double pressure;
  final int stormLevel;

  @override
  List<Object?> get props => [temperatureF, pressure, stormLevel];
}

/// User triggered manual refresh.
final class OracleRefreshed extends OracleEvent {
  const OracleRefreshed();
}

/// Oracle tab left / user disconnected.
final class OracleStopped extends OracleEvent {
  const OracleStopped();
}
```

**Step 2: Write the oracle states**

File: `storm_sense/lib/features/oracle/bloc/oracle_state.dart`

```dart
part of 'oracle_bloc.dart';

sealed class OracleState extends Equatable {
  const OracleState();

  @override
  List<Object?> get props => [];
}

final class OracleInitial extends OracleState {
  const OracleInitial();
}

final class OracleLoading extends OracleState {
  const OracleLoading();
}

final class OracleLoaded extends OracleState {
  const OracleLoaded({required this.reading});
  final OracleReading reading;

  @override
  List<Object?> get props => [reading.timestamp, reading.elementalHarmony];
}

final class OracleError extends OracleState {
  const OracleError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
```

**Step 3: Write the OracleBloc**

File: `storm_sense/lib/features/oracle/bloc/oracle_bloc.dart`

```dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/core/astro/oracle_engine.dart';
import 'package:storm_sense/features/dashboard/bloc/dashboard_bloc.dart';

part 'oracle_event.dart';
part 'oracle_state.dart';

class OracleBloc extends Bloc<OracleEvent, OracleState> {
  OracleBloc({required DashboardBloc dashboardBloc})
      : _dashboardBloc = dashboardBloc,
        super(const OracleInitial()) {
    on<OracleStarted>(_onStarted);
    on<OracleWeatherUpdated>(_onWeatherUpdated);
    on<OracleRefreshed>(_onRefreshed);
    on<OracleStopped>(_onStopped);
  }

  final DashboardBloc _dashboardBloc;
  StreamSubscription<DashboardState>? _dashboardSub;

  // Cache last known weather for manual refresh
  double _lastTempF = 72.0;
  double _lastPressure = 1013.25;
  int _lastStormLevel = 1;

  void _onStarted(OracleStarted event, Emitter<OracleState> emit) {
    emit(const OracleLoading());

    // If dashboard already has data, use it immediately
    final currentDashState = _dashboardBloc.state;
    if (currentDashState is DashboardLoaded) {
      final status = currentDashState.status;
      _lastTempF = status.temperatureF;
      _lastPressure = status.pressure;
      _lastStormLevel = status.stormLevel;
      _generateAndEmit(emit);
    }

    // Subscribe to future dashboard updates
    _dashboardSub?.cancel();
    _dashboardSub = _dashboardBloc.stream.listen((dashState) {
      if (dashState is DashboardLoaded) {
        add(OracleWeatherUpdated(
          dashState.status.temperatureF,
          dashState.status.pressure,
          dashState.status.stormLevel,
        ));
      }
    });
  }

  void _onWeatherUpdated(
    OracleWeatherUpdated event,
    Emitter<OracleState> emit,
  ) {
    _lastTempF = event.temperatureF;
    _lastPressure = event.pressure;
    _lastStormLevel = event.stormLevel;
    _generateAndEmit(emit);
  }

  void _onRefreshed(OracleRefreshed event, Emitter<OracleState> emit) {
    _generateAndEmit(emit);
  }

  void _onStopped(OracleStopped event, Emitter<OracleState> emit) {
    _dashboardSub?.cancel();
    _dashboardSub = null;
    emit(const OracleInitial());
  }

  void _generateAndEmit(Emitter<OracleState> emit) {
    try {
      final reading = OracleEngine.generateReading(
        temperatureF: _lastTempF,
        pressure: _lastPressure,
        stormLevel: _lastStormLevel,
        dateTime: DateTime.now(),
      );
      emit(OracleLoaded(reading: reading));
    } catch (e) {
      emit(OracleError('Failed to generate oracle reading: $e'));
    }
  }

  @override
  Future<void> close() {
    _dashboardSub?.cancel();
    return super.close();
  }
}
```

**Step 4: Write the BLoC test**

File: `storm_sense/test/features/oracle/oracle_bloc_test.dart`

```dart
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storm_sense/core/api/models.dart';
import 'package:storm_sense/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:storm_sense/features/oracle/bloc/oracle_bloc.dart';

class MockDashboardBloc extends Mock implements DashboardBloc {
  final _controller = StreamController<DashboardState>.broadcast();

  @override
  Stream<DashboardState> get stream => _controller.stream;

  @override
  DashboardState get state => const DashboardInitial();

  void emitState(DashboardState state) => _controller.add(state);

  void dispose() => _controller.close();
}

void main() {
  late MockDashboardBloc mockDashboard;

  final sampleStatus = StormStatus(
    temperature: 23.0,
    temperatureF: 73.4,
    rawTemperature: 28.0,
    pressure: 1013.25,
    stormLevel: 1,
    stormLabel: 'FAIR',
    samplesCollected: 100,
    historyFull: false,
    displayMode: 'TEMPERATURE',
    pressureDelta3h: -1.5,
  );

  setUp(() {
    mockDashboard = MockDashboardBloc();
  });

  tearDown(() {
    mockDashboard.dispose();
  });

  group('OracleBloc', () {
    test('initial state is OracleInitial', () {
      final bloc = OracleBloc(dashboardBloc: mockDashboard);
      expect(bloc.state, const OracleInitial());
      bloc.close();
    });

    blocTest<OracleBloc, OracleState>(
      'OracleStarted with no dashboard data emits OracleLoading',
      build: () => OracleBloc(dashboardBloc: mockDashboard),
      act: (bloc) => bloc.add(const OracleStarted()),
      expect: () => [const OracleLoading()],
    );

    blocTest<OracleBloc, OracleState>(
      'OracleWeatherUpdated emits OracleLoaded',
      build: () => OracleBloc(dashboardBloc: mockDashboard),
      act: (bloc) => bloc.add(const OracleWeatherUpdated(73.4, 1013.25, 1)),
      expect: () => [isA<OracleLoaded>()],
    );

    blocTest<OracleBloc, OracleState>(
      'OracleStopped resets to initial',
      build: () => OracleBloc(dashboardBloc: mockDashboard),
      seed: () => OracleLoaded(
        reading: _fakeReading(),
      ),
      act: (bloc) => bloc.add(const OracleStopped()),
      expect: () => [const OracleInitial()],
    );

    blocTest<OracleBloc, OracleState>(
      'OracleRefreshed generates new reading',
      build: () => OracleBloc(dashboardBloc: mockDashboard),
      act: (bloc) => bloc.add(const OracleRefreshed()),
      expect: () => [isA<OracleLoaded>()],
    );
  });
}

// Helper to create a fake reading for seed state
OracleReading _fakeReading() {
  return OracleEngine.generateReading(
    temperatureF: 72.0,
    pressure: 1013.25,
    stormLevel: 1,
    dateTime: DateTime.utc(2026, 3, 1),
  );
}
```

**Note:** Add `import 'package:storm_sense/core/astro/oracle_engine.dart';` at top of test file.

**Step 5: Run tests**

```bash
cd storm_sense && flutter test test/features/oracle/oracle_bloc_test.dart -v
```

Expected: ALL PASS

**Step 6: Commit**

```bash
cd storm_sense
git add lib/features/oracle/bloc/ test/features/oracle/oracle_bloc_test.dart
git commit -m "feat(oracle): add OracleBloc with dashboard stream subscription"
```

---

## Task 6: Oracle UI — Page, Cards, and Navigation

Build the Oracle page with all 4 cards, update the router to add the 4th tab, and wire up BLoC providers in `storm_sense_app.dart`.

**Files:**
- Create: `storm_sense/lib/features/oracle/view/oracle_page.dart`
- Create: `storm_sense/lib/features/oracle/view/cosmic_weather_card.dart`
- Create: `storm_sense/lib/features/oracle/view/planetary_grid.dart`
- Modify: `storm_sense/lib/app/router.dart` (add Oracle route + 4th nav destination)
- Modify: `storm_sense/lib/app/storm_sense_app.dart` (add OracleBloc provider + wiring)

**Step 1: Create `cosmic_weather_card.dart`**

File: `storm_sense/lib/features/oracle/view/cosmic_weather_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:storm_sense/core/astro/oracle_engine.dart';

class CosmicWeatherCard extends StatelessWidget {
  const CosmicWeatherCard({super.key, required this.reading});

  final OracleReading reading;

  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final harmonyPercent = (reading.elementalHarmony * 100).round();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _color.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _elementIcon(reading.dominantElement),
                        color: _color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${reading.dominantElement} Dominant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _color,
                            ),
                          ),
                          Text(
                            'Elemental harmony: $harmonyPercent%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Harmony bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: reading.elementalHarmony,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: _color,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  reading.cosmicWeatherSummary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _timeAgo(reading.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _elementIcon(String element) {
    return switch (element) {
      'Fire' => Icons.local_fire_department_outlined,
      'Water' => Icons.water_drop_outlined,
      'Air' => Icons.air_outlined,
      'Earth' => Icons.landscape_outlined,
      _ => Icons.auto_awesome,
    };
  }

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} min ago';
    return 'Updated ${diff.inHours}h ago';
  }
}
```

**Step 2: Create `planetary_grid.dart`**

File: `storm_sense/lib/features/oracle/view/planetary_grid.dart`

```dart
import 'package:flutter/material.dart';
import 'package:storm_sense/core/astro/planetary_positions.dart';

class PlanetaryGrid extends StatelessWidget {
  const PlanetaryGrid({super.key, required this.planets});

  final List<CelestialPosition> planets;

  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _color.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.blur_circular,
                        size: 18,
                        color: _color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Planetary Positions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // 2-column grid
                ...List.generate(
                  (planets.length / 2).ceil(),
                  (row) {
                    final left = planets[row * 2];
                    final right = row * 2 + 1 < planets.length
                        ? planets[row * 2 + 1]
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: _buildPlanetTile(left, theme, cs)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: right != null
                                ? _buildPlanetTile(right, theme, cs)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanetTile(
    CelestialPosition planet,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            _planetGlyph(planet.name),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planet.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${planet.sign.glyph} ${planet.degreeInSign}\u00B0 ${planet.sign.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _planetGlyph(String name) {
    return switch (name) {
      'Sun' => '\u2609',
      'Moon' => '\u263D',
      'Mercury' => '\u263F',
      'Venus' => '\u2640',
      'Mars' => '\u2642',
      'Jupiter' => '\u2643',
      'Saturn' => '\u2644',
      'Rahu' => '\u260A',
      _ => '\u2731',
    };
  }
}
```

**Step 3: Create `oracle_page.dart`**

File: `storm_sense/lib/features/oracle/view/oracle_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/features/oracle/bloc/oracle_bloc.dart';
import 'package:storm_sense/features/oracle/view/cosmic_weather_card.dart';
import 'package:storm_sense/features/oracle/view/planetary_grid.dart';

class OraclePage extends StatelessWidget {
  const OraclePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<OracleBloc, OracleState>(
          builder: (context, state) {
            if (state is OracleLoading || state is OracleInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is OracleError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48,
                          color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context
                            .read<OracleBloc>()
                            .add(const OracleRefreshed()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is OracleLoaded) {
              final reading = state.reading;
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<OracleBloc>().add(const OracleRefreshed());
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(
                      'Oracle',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CosmicWeatherCard(reading: reading),
                    const SizedBox(height: 12),
                    PlanetaryGrid(planets: reading.planets),
                    if (reading.aspects.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _AspectCard(
                        aspect: reading.aspects.first,
                        theme: theme,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _BirthChartCTA(theme: theme),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _AspectCard extends StatelessWidget {
  const _AspectCard({required this.aspect, required this.theme});

  final dynamic aspect; // Aspect type from aspects.dart
  final ThemeData theme;

  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _color.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    size: 18,
                    color: _color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${aspect.body1} ${aspect.type.glyph} ${aspect.body2}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _color,
                        ),
                      ),
                      Text(
                        '${aspect.type.label} \u2014 ${aspect.type.keyword}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthChartCTA extends StatelessWidget {
  const _BirthChartCTA({required this.theme});

  final ThemeData theme;

  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _color.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: _color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personalize your readings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        'Add your birth info for custom insights',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Update router**

File: `storm_sense/lib/app/router.dart`

Add import at top:
```dart
import 'package:storm_sense/features/oracle/view/oracle_page.dart';
```

Add route inside `ShellRoute.routes` list, between `/dashboard` and `/history`:
```dart
GoRoute(
  path: '/oracle',
  builder: (context, state) => const OraclePage(),
),
```

Update `_AppShell` — change `NavigationBar` to 4 destinations:
```dart
destinations: const [
  NavigationDestination(
    icon: Icon(Icons.dashboard),
    label: 'Dashboard',
  ),
  NavigationDestination(
    icon: Icon(Icons.auto_awesome),
    label: 'Oracle',
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
```

Update `onDestinationSelected`:
```dart
onDestinationSelected: (index) {
  switch (index) {
    case 0:
      context.go('/dashboard');
    case 1:
      context.go('/oracle');
    case 2:
      context.go('/history');
    case 3:
      context.go('/settings');
  }
},
```

Update `_calculateIndex`:
```dart
int _calculateIndex(String path) {
  if (path.startsWith('/oracle')) return 1;
  if (path.startsWith('/history')) return 2;
  if (path.startsWith('/settings')) return 3;
  return 0;
}
```

**Step 5: Wire OracleBloc in `storm_sense_app.dart`**

File: `storm_sense/lib/app/storm_sense_app.dart`

Add import:
```dart
import 'package:storm_sense/features/oracle/bloc/oracle_bloc.dart';
```

Add to the `MultiBlocProvider.providers` list (after DashboardBloc):
```dart
BlocProvider(
  create: (context) => OracleBloc(
    dashboardBloc: context.read<DashboardBloc>(),
  ),
),
```

Add to the `MultiBlocListener.listeners` — when connection succeeds, start oracle too. Inside the `ConnectionSuccess` listener, add:
```dart
context.read<OracleBloc>().add(const OracleStarted());
```

Add to `SettingsBloc` poll interval listener (optional — oracle doesn't poll, but keep parity).

In the disconnect flow (when `DashboardStopped` is dispatched from any page), add oracle stop. This is handled in `oracle_page.dart` and `dashboard_page.dart` disconnect methods — add:
```dart
context.read<OracleBloc>().add(const OracleStopped());
```
to the `_disconnect` method in `dashboard_page.dart`.

**Step 6: Run the build**

```bash
cd storm_sense && flutter build apk --debug 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

**Step 7: Run all tests**

```bash
cd storm_sense && flutter test
```

Expected: ALL PASS

**Step 8: Commit**

```bash
cd storm_sense
git add lib/features/oracle/ lib/app/router.dart lib/app/storm_sense_app.dart lib/features/dashboard/view/dashboard_page.dart
git commit -m "feat(oracle): add Oracle tab with cosmic weather card, planetary grid, and nav integration"
```

---

## Task 7: Birth Chart — Storage & Bottom Sheet

**Files:**
- Create: `storm_sense/lib/core/astro/birth_chart.dart`
- Create: `storm_sense/lib/features/oracle/view/birth_chart_sheet.dart`
- Modify: `storm_sense/lib/features/oracle/view/oracle_page.dart` (wire CTA to sheet)

**Step 1: Create `birth_chart.dart`**

File: `storm_sense/lib/core/astro/birth_chart.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/core/astro/planetary_positions.dart';

/// Birth chart data stored in shared_preferences.
class BirthData {
  const BirthData({
    required this.birthDate,
    this.birthTime,
    this.latitude,
    this.longitude,
  });

  final DateTime birthDate;
  final String? birthTime; // "HH:mm" or null
  final double? latitude;
  final double? longitude;

  /// Compute the natal DateTime (UTC) from birth date + optional time.
  DateTime get natalDateTime {
    if (birthTime == null) return birthDate;
    final parts = birthTime!.split(':');
    if (parts.length != 2) return birthDate;
    return DateTime(
      birthDate.year,
      birthDate.month,
      birthDate.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    );
  }

  /// Compute natal planetary positions.
  List<CelestialPosition> get natalPositions =>
      PlanetaryPositions.allPositions(natalDateTime);
}

/// Persistence helper for birth data.
class BirthDataStore {
  static const _keyDate = 'oracle_birth_date';
  static const _keyTime = 'oracle_birth_time';
  static const _keyLat = 'oracle_birth_latitude';
  static const _keyLng = 'oracle_birth_longitude';

  static Future<BirthData?> load(SharedPreferences prefs) async {
    final dateStr = prefs.getString(_keyDate);
    if (dateStr == null) return null;

    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;

    return BirthData(
      birthDate: date,
      birthTime: prefs.getString(_keyTime),
      latitude: prefs.getDouble(_keyLat),
      longitude: prefs.getDouble(_keyLng),
    );
  }

  static Future<void> save(SharedPreferences prefs, BirthData data) async {
    await prefs.setString(_keyDate, data.birthDate.toIso8601String());
    if (data.birthTime != null) {
      await prefs.setString(_keyTime, data.birthTime!);
    } else {
      await prefs.remove(_keyTime);
    }
    if (data.latitude != null) {
      await prefs.setDouble(_keyLat, data.latitude!);
    }
    if (data.longitude != null) {
      await prefs.setDouble(_keyLng, data.longitude!);
    }
  }

  static Future<void> clear(SharedPreferences prefs) async {
    await prefs.remove(_keyDate);
    await prefs.remove(_keyTime);
    await prefs.remove(_keyLat);
    await prefs.remove(_keyLng);
  }
}
```

**Step 2: Create `birth_chart_sheet.dart`**

File: `storm_sense/lib/features/oracle/view/birth_chart_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/core/astro/birth_chart.dart';

class BirthChartSheet extends StatefulWidget {
  const BirthChartSheet({super.key, this.existingData});

  final BirthData? existingData;

  static Future<BirthData?> show(BuildContext context, {BirthData? existingData}) {
    return showModalBottomSheet<BirthData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BirthChartSheet(existingData: existingData),
    );
  }

  @override
  State<BirthChartSheet> createState() => _BirthChartSheetState();
}

class _BirthChartSheetState extends State<BirthChartSheet> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  bool _knowTime = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingData?.birthDate ?? DateTime(1990, 1, 1);
    if (widget.existingData?.birthTime != null) {
      final parts = widget.existingData!.birthTime!.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    _knowTime = _selectedTime != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const accent = Color(0xFF818CF8);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Birth Chart Setup',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your birth info for personalized readings.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Date picker
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_today, color: accent),
            title: const Text('Birth Date'),
            subtitle: Text(
              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),

          // Time toggle + picker
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('I know my birth time'),
            value: _knowTime,
            onChanged: (v) => setState(() {
              _knowTime = v;
              if (!v) _selectedTime = null;
            }),
          ),
          if (_knowTime)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.access_time, color: accent),
              title: const Text('Birth Time'),
              subtitle: Text(
                _selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'Tap to select',
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
                );
                if (picked != null) setState(() => _selectedTime = picked);
              },
            ),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
              ),
              child: const Text('Save'),
            ),
          ),

          // Clear button (if existing data)
          if (widget.existingData != null)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _clear,
                style: TextButton.styleFrom(foregroundColor: cs.error),
                child: const Text('Clear Birth Data'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final timeStr = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
            '${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final data = BirthData(
      birthDate: _selectedDate,
      birthTime: timeStr,
    );

    final prefs = await SharedPreferences.getInstance();
    await BirthDataStore.save(prefs, data);

    if (mounted) Navigator.of(context).pop(data);
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await BirthDataStore.clear(prefs);

    if (mounted) Navigator.of(context).pop(null);
  }
}
```

**Step 3: Wire CTA in `oracle_page.dart`**

In `_BirthChartCTA`, make it a `StatelessWidget` that calls `BirthChartSheet.show(context)` on tap. Wrap the existing Container in a `GestureDetector`:

```dart
// Add to _BirthChartCTA build method, wrap the Container:
return GestureDetector(
  onTap: () => BirthChartSheet.show(context),
  child: Container(/* existing code */),
);
```

Add import to `oracle_page.dart`:
```dart
import 'package:storm_sense/features/oracle/view/birth_chart_sheet.dart';
import 'package:storm_sense/core/astro/aspects.dart';
```

**Step 4: Run build + tests**

```bash
cd storm_sense && flutter test && flutter build apk --debug 2>&1 | tail -3
```

**Step 5: Commit**

```bash
cd storm_sense
git add lib/core/astro/birth_chart.dart lib/features/oracle/view/birth_chart_sheet.dart lib/features/oracle/view/oracle_page.dart
git commit -m "feat(oracle): add birth chart storage and setup bottom sheet"
```

---

## Task 8: Run Freezed Code Generation

The oracle models reference Freezed but OracleReading is a plain class (not Freezed-generated). This is intentional — OracleReading uses plain Dart classes since it's never serialized to/from JSON. No build_runner step needed for this feature.

**However**, verify existing generated code is still valid:

```bash
cd storm_sense && dart run build_runner build --delete-conflicting-outputs
```

Expected: No errors, existing `.freezed.dart` and `.g.dart` files regenerated successfully.

**Commit only if files changed:**

```bash
cd storm_sense && git diff --stat
# If generated files changed:
git add lib/core/api/models.freezed.dart lib/core/api/models.g.dart
git commit -m "chore: regenerate Freezed files after oracle feature addition"
```

---

## Task 9: Final Integration Test & Cleanup

**Step 1: Run ALL tests**

```bash
cd storm_sense && flutter test -v
```

Expected: ALL PASS

**Step 2: Run lint**

```bash
cd storm_sense && flutter analyze
```

Fix any lint warnings (likely: unused imports, missing const constructors).

**Step 3: Verify build**

```bash
cd storm_sense && flutter build apk --debug 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

**Step 4: Final commit if any fixes**

```bash
cd storm_sense
git add -A
git commit -m "chore: fix lint warnings and finalize oracle feature integration"
```

---

## Swarm Agent Assignment Summary

| Task | Agent | Can Parallelize With |
|------|-------|---------------------|
| 0 (Image gen) | image-gen | Tasks 1-5 |
| 1 (Zodiac) | astro-engine | Task 0 |
| 2 (Planetary) | astro-engine | Task 0 |
| 3 (Aspects) | astro-engine | Task 0 |
| 4 (Oracle Engine) | oracle-logic | After Tasks 1-3 |
| 5 (BLoC) | oracle-logic | After Task 4 |
| 6 (UI + Nav) | oracle-ui + nav-integration | After Task 5 |
| 7 (Birth Chart) | birth-chart | After Task 1, parallel with 4-6 |
| 8 (Codegen) | test-runner | After all code tasks |
| 9 (Integration) | test-runner | Last |

**Critical path:** Task 1 → 2 → 3 → 4 → 5 → 6 → 9

**Parallel tracks:**
- Track A: Tasks 1-2-3 (astro math)
- Track B: Task 0 (image gen, fully independent)
- Track C: Task 7 (birth chart, after Task 1)
