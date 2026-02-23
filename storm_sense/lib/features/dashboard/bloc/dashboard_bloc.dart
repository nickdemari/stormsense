import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/core/api/models.dart';
import 'package:storm_sense/core/api/storm_sense_api.dart';
import 'package:storm_sense/notifications/storm_notification_service.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    StormNotificationService? notificationService,
  })  : _notificationService = notificationService,
        super(const DashboardInitial()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshed>(_onRefreshed);
    on<DashboardStopped>(_onStopped);
    on<_DashboardPolled>(_onPolled);
  }

  StormSenseApi? _api;
  Timer? _pollTimer;
  int _previousStormLevel = 0;
  final StormNotificationService? _notificationService;

  void _startPolling(int intervalSeconds) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => add(const _DashboardPolled()),
    );
  }

  Future<void> _fetchStatus(Emitter<DashboardState> emit) async {
    try {
      final status = await _api!.getStatus();

      // Check for storm escalation
      if (status.stormLevel > _previousStormLevel && status.stormLevel >= 3) {
        _notificationService?.showStormAlert(status.stormLevel);
      }
      _previousStormLevel = status.stormLevel;

      emit(DashboardLoaded(status: status));
    } catch (e) {
      emit(DashboardError('Failed to fetch status: ${e.toString()}'));
    }
  }

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    _api = StormSenseApi(baseUrl: event.baseUrl);
    await _fetchStatus(emit);
    _startPolling(event.pollIntervalSeconds);
  }

  Future<void> _onRefreshed(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    if (_api == null) return;
    await _fetchStatus(emit);
  }

  Future<void> _onPolled(
    _DashboardPolled event,
    Emitter<DashboardState> emit,
  ) async {
    if (_api == null) return;
    await _fetchStatus(emit);
  }

  void _onStopped(
    DashboardStopped event,
    Emitter<DashboardState> emit,
  ) {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
