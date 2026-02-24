import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storm_sense/core/api/models.dart';
import 'package:storm_sense/core/api/storm_sense_api.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late StormSenseApi api;

  setUp(() {
    mockDio = MockDio();
    api = StormSenseApi(baseUrl: 'http://localhost', dio: mockDio);
  });

  group('getStatus', () {
    test('returns parsed StormStatus on 200', () async {
      final data = <String, dynamic>{
        'temperature': 23.45,
        'temperature_f': 74.21,
        'raw_temperature': 28.12,
        'pressure': 1013.25,
        'storm_level': 0,
        'storm_label': 'CLEAR',
        'samples_collected': 42,
        'history_full': false,
        'display_mode': 'TEMPERATURE',
        'pressure_delta_3h': null,
      };

      when(() => mockDio.get<Map<String, dynamic>>('/api/status')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: data,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/status'),
        ),
      );

      final status = await api.getStatus();

      expect(status.temperature, 23.45);
      expect(status.stormLevel, 0);
      expect(status.stormLabel, 'CLEAR');
      expect(status.pressureDelta3h, isNull);
    });
  });

  group('getHistory', () {
    test('returns List<Reading> on 200', () async {
      final data = <dynamic>[
        <String, dynamic>{
          'timestamp': 1708635600.0,
          'temperature': 23.45,
          'temperature_f': 74.21,
          'raw_temperature': 28.12,
          'pressure': 1013.25,
          'storm_level': 0,
        },
      ];

      when(() => mockDio.get<List<dynamic>>('/api/history')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          data: data,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/history'),
        ),
      );

      final history = await api.getHistory();

      expect(history, hasLength(1));
      expect(history.first.pressure, 1013.25);
    });
  });

  group('isHealthy', () {
    test('returns true on 200', () async {
      when(() => mockDio.get<dynamic>('/api/health')).thenAnswer(
        (_) async => Response<dynamic>(
          data: 'ok',
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/health'),
        ),
      );

      final healthy = await api.isHealthy();

      expect(healthy, isTrue);
    });

    test('returns false on DioException connectionTimeout', () async {
      when(() => mockDio.get<dynamic>('/api/health')).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/api/health'),
        ),
      );

      final healthy = await api.isHealthy();

      expect(healthy, isFalse);
    });
  });
}
