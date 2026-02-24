import 'package:flutter_test/flutter_test.dart';
import 'package:storm_sense/core/api/models.dart';
import 'package:storm_sense/core/storm/storm_level.dart';

void main() {
  group('StormStatus', () {
    test('fromJson with null pressure_delta_3h', () {
      final json = {
        'temperature': 22.5,
        'temperature_f': 72.5,
        'raw_temperature': 22.48,
        'pressure': 1013.25,
        'storm_level': 0,
        'storm_label': 'Clear',
        'samples_collected': 42,
        'history_full': false,
        'display_mode': 'temp',
        'pressure_delta_3h': null,
      };

      final status = StormStatus.fromJson(json);

      expect(status.temperature, 22.5);
      expect(status.rawTemperature, 22.48);
      expect(status.pressure, 1013.25);
      expect(status.stormLevel, 0);
      expect(status.stormLabel, 'Clear');
      expect(status.samplesCollected, 42);
      expect(status.historyFull, false);
      expect(status.displayMode, 'temp');
      expect(status.pressureDelta3h, isNull);
    });

    test('fromJson with non-null pressure_delta_3h', () {
      final json = {
        'temperature': 18.3,
        'temperature_f': 64.94,
        'raw_temperature': 18.27,
        'pressure': 1008.50,
        'storm_level': 2,
        'storm_label': 'Warning',
        'samples_collected': 150,
        'history_full': true,
        'display_mode': 'pressure',
        'pressure_delta_3h': -3.75,
      };

      final status = StormStatus.fromJson(json);

      expect(status.temperature, 18.3);
      expect(status.rawTemperature, 18.27);
      expect(status.pressure, 1008.50);
      expect(status.stormLevel, 2);
      expect(status.stormLabel, 'Warning');
      expect(status.samplesCollected, 150);
      expect(status.historyFull, true);
      expect(status.displayMode, 'pressure');
      expect(status.pressureDelta3h, -3.75);
    });
  });

  group('Reading', () {
    test('fromJson with sample history entry', () {
      final json = {
        'timestamp': 1700000000.0,
        'temperature': 21.0,
        'temperature_f': 69.8,
        'raw_temperature': 20.95,
        'pressure': 1012.0,
        'storm_level': 1,
      };

      final reading = Reading.fromJson(json);

      expect(reading.timestamp, 1700000000.0);
      expect(reading.temperature, 21.0);
      expect(reading.rawTemperature, 20.95);
      expect(reading.pressure, 1012.0);
      expect(reading.stormLevel, 1);
    });
  });

  group('StormLevel', () {
    test('fromInt(0) returns dry', () {
      expect(StormLevel.fromInt(0), StormLevel.dry);
    });

    test('fromInt(2) returns change', () {
      expect(StormLevel.fromInt(2), StormLevel.change);
    });

    test('fromInt(99) returns fair as fallback', () {
      expect(StormLevel.fromInt(99), StormLevel.fair);
    });

    test('each StormLevel has a non-null color', () {
      for (final level in StormLevel.values) {
        expect(level.color, isNotNull);
      }
    });
  });
}
