import 'package:dio/dio.dart';

import 'models.dart';

class StormSenseApi {
  StormSenseApi({required String baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ));

  final Dio _dio;

  Future<StormStatus> getStatus() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/status');
    return StormStatus.fromJson(response.data!);
  }

  Future<List<Reading>> getHistory() async {
    final response = await _dio.get<List<dynamic>>('/api/history');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(Reading.fromJson)
        .toList();
  }

  Future<bool> isHealthy() async {
    try {
      final response = await _dio.get<dynamic>('/api/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
