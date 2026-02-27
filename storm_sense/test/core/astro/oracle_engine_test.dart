import 'package:flutter_test/flutter_test.dart';
import 'package:storm_sense/core/astro/oracle_engine.dart';
import 'package:storm_sense/core/astro/planetary_positions.dart';
import 'package:storm_sense/core/astro/zodiac.dart';

void main() {
  group('weatherElement', () {
    test('stormy level returns water', () {
      expect(
        weatherElement(stormLevel: 4, temperatureF: 70),
        AstroElement.water,
      );
    });

    test('rain level returns water', () {
      expect(
        weatherElement(stormLevel: 3, temperatureF: 70),
        AstroElement.water,
      );
    });

    test('dry level with high temp returns fire', () {
      expect(
        weatherElement(stormLevel: 0, temperatureF: 90),
        AstroElement.fire,
      );
    });

    test('dry level with low temp returns earth', () {
      expect(
        weatherElement(stormLevel: 0, temperatureF: 70),
        AstroElement.earth,
      );
    });

    test('fair level returns earth', () {
      expect(
        weatherElement(stormLevel: 1, temperatureF: 70),
        AstroElement.earth,
      );
    });

    test('change level returns air', () {
      expect(
        weatherElement(stormLevel: 2, temperatureF: 70),
        AstroElement.air,
      );
    });

    test('high temp with dry overrides to fire', () {
      expect(
        weatherElement(stormLevel: 0, temperatureF: 95),
        AstroElement.fire,
      );
    });
  });

  group('elementalHarmony', () {
    test('returns 1.0 when all planets match weather element', () {
      final positions = List.generate(
        8,
        (i) => CelestialPosition(
          name: 'Body$i',
          longitude: 0.0,
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
          longitude: 30.0,
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
        CelestialPosition(
          name: 'Sun',
          longitude: 0,
          sign: ZodiacSign.aries,
          degreeInSign: 0,
          element: AstroElement.fire,
        ),
        CelestialPosition(
          name: 'Moon',
          longitude: 30,
          sign: ZodiacSign.taurus,
          degreeInSign: 0,
          element: AstroElement.earth,
        ),
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
