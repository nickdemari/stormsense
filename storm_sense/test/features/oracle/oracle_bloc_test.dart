import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/core/astro/oracle_engine.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
      wait: const Duration(milliseconds: 300),
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
        reading: OracleEngine.generateReading(
          temperatureF: 72.0,
          pressure: 1013.25,
          stormLevel: 1,
          dateTime: DateTime.utc(2026, 3, 1),
        ),
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
