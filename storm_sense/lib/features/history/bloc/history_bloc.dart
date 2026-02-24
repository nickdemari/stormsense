import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/core/api/storm_sense_api.dart';
import 'package:storm_sense/features/history/bloc/history_event.dart';
import 'package:storm_sense/features/history/bloc/history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc() : super(const HistoryInitial()) {
    on<HistoryStarted>(_onStarted);
    on<HistoryRefreshed>(_onRefreshed);
    on<HistoryPollIntervalChanged>(_onPollIntervalChanged);
    on<HistoryStopped>(_onStopped);
    on<HistoryPolled>(_onPolled);
  }

  StormSenseApi? _api;
  Timer? _pollTimer;

  Future<void> _fetchHistory(Emitter<HistoryState> emit) async {
    try {
      final readings = await _api!.getHistory();
      emit(HistoryLoaded(readings: readings));
    } catch (e) {
      final previousReadings =
          state is HistoryLoaded ? (state as HistoryLoaded).readings : null;
      emit(HistoryError(
        'Failed to load history: ${e.toString()}',
        previousReadings: previousReadings,
      ));
    }
  }

  Future<void> _onStarted(
    HistoryStarted event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());
    _api = StormSenseApi(baseUrl: event.baseUrl);
    await _fetchHistory(emit);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(seconds: event.pollIntervalSeconds),
      (_) => add(const HistoryPolled()),
    );
  }

  Future<void> _onRefreshed(
    HistoryRefreshed event,
    Emitter<HistoryState> emit,
  ) async {
    if (_api == null) return;
    await _fetchHistory(emit);
  }

  void _onPollIntervalChanged(
    HistoryPollIntervalChanged event,
    Emitter<HistoryState> emit,
  ) {
    if (_api == null) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(seconds: event.seconds),
      (_) => add(const HistoryPolled()),
    );
  }

  void _onStopped(
    HistoryStopped event,
    Emitter<HistoryState> emit,
  ) {
    _pollTimer?.cancel();
    _pollTimer = null;
    _api = null;
    emit(const HistoryInitial());
  }

  Future<void> _onPolled(
    HistoryPolled event,
    Emitter<HistoryState> emit,
  ) async {
    if (_api == null) return;
    await _fetchHistory(emit);
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
