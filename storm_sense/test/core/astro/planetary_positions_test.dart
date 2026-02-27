import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:storm_sense/core/astro/planetary_positions.dart';
import 'package:storm_sense/core/astro/zodiac.dart';

/// Circular distance between two angles on a 360-degree circle.
double _circularDistance(double a, double b) {
  final diff = (a - b).abs() % 360;
  return math.min(diff, 360 - diff);
}

void main() {
  group('PlanetaryPositions', () {
    final equinox2026 = DateTime.utc(2026, 3, 20, 10, 0);
    final newYear2026 = DateTime.utc(2026, 1, 1);

    group('sunLongitude', () {
      test('sun near 0 degrees at vernal equinox', () {
        final lon = PlanetaryPositions.sunLongitude(equinox2026);
        // Use circular distance to handle the 359.x vs 0 wrap-around.
        expect(_circularDistance(lon, 0.0), lessThanOrEqualTo(2.0));
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
        final delta = (day2 - day1 + 360) % 360;
        expect(delta, closeTo(13.2, 3.0));
      });
    });

    group('allPositions', () {
      test('returns positions for 8 bodies (Sun through Saturn)', () {
        final positions = PlanetaryPositions.allPositions(newYear2026);
        expect(positions.length, 8);
        expect(
          positions.map((p) => p.name),
          containsAll([
            'Sun',
            'Moon',
            'Mercury',
            'Venus',
            'Mars',
            'Jupiter',
            'Saturn',
          ]),
        );
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
