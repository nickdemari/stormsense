import 'dart:math' as math;

import 'package:storm_sense/core/astro/zodiac.dart';

/// Position of a celestial body at a given moment.
class CelestialPosition {
  const CelestialPosition({
    required this.name,
    required this.longitude,
    required this.sign,
    required this.degreeInSign,
    required this.element,
  });

  final String name;

  /// Ecliptic longitude in degrees [0, 360).
  final double longitude;

  final ZodiacSign sign;

  /// Degree within the sign [0, 29].
  final int degreeInSign;

  final AstroElement element;
}

/// Pure-Dart astronomical calculator for the Sun, Moon, and classical planets
/// (Mercury through Saturn) plus Rahu (lunar north node).
///
/// Uses simplified VSOP / Meeus-style mean elements -- accurate to roughly
/// 1-2 degrees for dates within a few decades of J2000.
class PlanetaryPositions {
  PlanetaryPositions._();

  // ---------------------------------------------------------------------------
  // Julian date helpers
  // ---------------------------------------------------------------------------

  static double _julianCenturies(DateTime dt) {
    final utc = dt.toUtc();
    final jd = _julianDay(utc);
    return (jd - 2451545.0) / 36525.0;
  }

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

  // ---------------------------------------------------------------------------
  // Angle utilities
  // ---------------------------------------------------------------------------

  static double _normalizeDegrees(double deg) {
    final result = deg % 360;
    return result < 0 ? result + 360 : result;
  }

  static double _degToRad(double deg) => deg * math.pi / 180;

  // ---------------------------------------------------------------------------
  // Sun (Meeus Ch. 25)
  // ---------------------------------------------------------------------------

  /// Apparent ecliptic longitude of the Sun for [dt].
  static double sunLongitude(DateTime dt) {
    final t = _julianCenturies(dt);

    // Geometric mean longitude.
    final l0 =
        _normalizeDegrees(280.46646 + 36000.76983 * t + 0.0003032 * t * t);

    // Mean anomaly.
    final m =
        _normalizeDegrees(357.52911 + 35999.05029 * t - 0.0001537 * t * t);
    final mRad = _degToRad(m);

    // Equation of center.
    final c = (1.9146 - 0.004817 * t - 0.000014 * t * t) * math.sin(mRad) +
        (0.019993 - 0.000101 * t) * math.sin(2 * mRad) +
        0.00029 * math.sin(3 * mRad);

    final sunLon = l0 + c;

    // Apparent longitude (nutation + aberration).
    final omega = 125.04 - 1934.136 * t;
    final apparent =
        sunLon - 0.00569 - 0.00478 * math.sin(_degToRad(omega));

    return _normalizeDegrees(apparent);
  }

  // ---------------------------------------------------------------------------
  // Moon (simplified Brown / Meeus Ch. 47)
  // ---------------------------------------------------------------------------

  /// Ecliptic longitude of the Moon for [dt].
  static double moonLongitude(DateTime dt) {
    final t = _julianCenturies(dt);

    final lp = _normalizeDegrees(218.3165 + 481267.8813 * t);
    final d = _normalizeDegrees(297.8502 + 445267.1115 * t);
    final m = _normalizeDegrees(357.5291 + 35999.0503 * t);
    final mp = _normalizeDegrees(134.9634 + 477198.8676 * t);
    final f = _normalizeDegrees(93.2720 + 483202.0175 * t);

    final dR = _degToRad(d);
    final mR = _degToRad(m);
    final mpR = _degToRad(mp);
    final fR = _degToRad(f);

    final lon = lp +
        6.289 * math.sin(mpR) +
        1.274 * math.sin(2 * dR - mpR) +
        0.658 * math.sin(2 * dR) +
        0.214 * math.sin(2 * mpR) -
        0.186 * math.sin(mR) -
        0.114 * math.sin(2 * fR);

    return _normalizeDegrees(lon);
  }

  // ---------------------------------------------------------------------------
  // Classical planets (simplified mean elements + equation of center)
  // ---------------------------------------------------------------------------

  static double _planetLongitude(DateTime dt, _PlanetElements el) {
    final t = _julianCenturies(dt);
    final l = _normalizeDegrees(el.l0 + el.l1 * t);
    final m = _normalizeDegrees(el.m0 + el.m1 * t);
    final mRad = _degToRad(m);

    final eqCenter = el.c1 * math.sin(mRad) + el.c2 * math.sin(2 * mRad);

    return _normalizeDegrees(l + eqCenter);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Computes positions for all tracked celestial bodies at [dt].
  ///
  /// Returns Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, and Rahu
  /// (8 bodies total).
  static List<CelestialPosition> allPositions(DateTime dt) {
    final bodies = <CelestialPosition>[
      _makePosition('Sun', sunLongitude(dt)),
      _makePosition('Moon', moonLongitude(dt)),
    ];

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

  // ---------------------------------------------------------------------------
  // Orbital element tables
  // ---------------------------------------------------------------------------

  static final _planets = <String, _PlanetElements>{
    'Mercury': _PlanetElements(
      l0: 252.2509,
      l1: 149472.6746,
      m0: 174.7948,
      m1: 149472.5153,
      c1: 23.44,
      c2: 2.98,
    ),
    'Venus': _PlanetElements(
      l0: 181.9798,
      l1: 58517.8157,
      m0: 50.4161,
      m1: 58517.8039,
      c1: 0.7758,
      c2: 0.0033,
    ),
    'Mars': _PlanetElements(
      l0: 355.4330,
      l1: 19140.2993,
      m0: 19.3730,
      m1: 19139.8585,
      c1: 10.6912,
      c2: 0.6228,
    ),
    'Jupiter': _PlanetElements(
      l0: 34.3515,
      l1: 3034.9057,
      m0: 20.0202,
      m1: 3034.6962,
      c1: 5.5549,
      c2: 0.1683,
    ),
    'Saturn': _PlanetElements(
      l0: 50.0774,
      l1: 1222.1138,
      m0: 317.0207,
      m1: 1222.1116,
      c1: 6.3642,
      c2: 0.2609,
    ),
    'Rahu': _PlanetElements(
      l0: 125.0445,
      l1: -1934.1363,
      m0: 0,
      m1: 0,
      c1: 0,
      c2: 0,
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

  /// Mean longitude at epoch (degrees).
  final double l0;

  /// Mean longitude rate (degrees per Julian century).
  final double l1;

  /// Mean anomaly at epoch (degrees).
  final double m0;

  /// Mean anomaly rate (degrees per Julian century).
  final double m1;

  /// First-order equation of center coefficient.
  final double c1;

  /// Second-order equation of center coefficient.
  final double c2;
}
