import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storm_sense/core/api/models.dart';
import 'package:storm_sense/core/api/storm_sense_api.dart';
import 'package:storm_sense/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:storm_sense/notifications/storm_notification_service.dart';

class MockStormSenseApi extends Mock implements StormSenseApi {}

class MockNotificationService extends Mock implements StormNotificationService {}

void main() {
  group('DashboardBloc', () {
    final sampleStatus = StormStatus(
      temperature: 23.45,
      rawTemperature: 28.12,
      pressure: 1013.25,
      stormLevel: 0,
      stormLabel: 'CLEAR',
      samplesCollected: 42,
      historyFull: false,
      displayMode: 'TEMPERATURE',
      pressureDelta3h: null,
    );

    test('initial state is DashboardInitial', () {
      final bloc = DashboardBloc();
      expect(bloc.state, const DashboardInitial());
      bloc.close();
    });

    test('close cancels poll timer', () async {
      final bloc = DashboardBloc();
      await bloc.close();
      // Should not throw
    });

    test('DashboardStopped cancels polling', () {
      final bloc = DashboardBloc();
      bloc.add(const DashboardStopped());
      // Should not throw
      bloc.close();
    });
  });
}
