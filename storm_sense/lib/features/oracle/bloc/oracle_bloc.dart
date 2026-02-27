import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/core/astro/birth_chart.dart';
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
    on<OracleBirthDataChanged>(_onBirthDataChanged);
    on<OracleStopped>(_onStopped);
  }

  final DashboardBloc _dashboardBloc;
  StreamSubscription<DashboardState>? _dashboardSub;

  double _lastTempF = 72.0;
  double _lastPressure = 1013.25;
  int _lastStormLevel = 1;
  BirthData? _birthData;

  Future<void> _onStarted(
    OracleStarted event,
    Emitter<OracleState> emit,
  ) async {
    emit(const OracleLoading());

    // Load saved birth data
    final prefs = await SharedPreferences.getInstance();
    _birthData = await BirthDataStore.load(prefs);

    final currentDashState = _dashboardBloc.state;
    if (currentDashState is DashboardLoaded) {
      final status = currentDashState.status;
      _lastTempF = status.temperatureF;
      _lastPressure = status.pressure;
      _lastStormLevel = status.stormLevel;
      _generateAndEmit(emit);
    }

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

  Future<void> _onBirthDataChanged(
    OracleBirthDataChanged event,
    Emitter<OracleState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    _birthData = await BirthDataStore.load(prefs);
    _generateAndEmit(emit);
  }

  void _onStopped(OracleStopped event, Emitter<OracleState> emit) {
    _dashboardSub?.cancel();
    _dashboardSub = null;
    _birthData = null;
    emit(const OracleInitial());
  }

  void _generateAndEmit(Emitter<OracleState> emit) {
    try {
      final reading = OracleEngine.generateReading(
        temperatureF: _lastTempF,
        pressure: _lastPressure,
        stormLevel: _lastStormLevel,
        dateTime: DateTime.now(),
        birthData: _birthData,
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
