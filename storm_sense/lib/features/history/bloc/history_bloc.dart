import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/core/api/storm_sense_api.dart';
import 'package:storm_sense/features/history/bloc/history_event.dart';
import 'package:storm_sense/features/history/bloc/history_state.dart';

const _kDefaultRangeSeconds = 2 * 3600; // 2 hours
const _kMaxReadings = 5000;

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc() : super(const HistoryInitial()) {
    on<HistoryStarted>(_onStarted);
    on<HistoryRefreshed>(_onRefreshed);
    on<HistoryPollIntervalChanged>(_onPollIntervalChanged);
    on<HistoryStopped>(_onStopped);
    on<HistoryPolled>(_onPolled);
    on<HistoryRangeChanged>(_onRangeChanged);
  }

  StormSenseApi? _api;
  Timer? _pollTimer;
  int _rangeSeconds = _kDefaultRangeSeconds;

  double get _sinceCutoff =>
      DateTime.now().millisecondsSinceEpoch / 1000.0 - _rangeSeconds;

  /// Full fetch for the current time range.
  Future<void> _fetchHistory(Emitter<HistoryState> emit) async {
    try {
      final readings =
          await _api!.getHistory(since: _sinceCutoff, limit: _kMaxReadings);
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

  /// Incremental fetch — appends new readings and trims to the time window.
  Future<void> _fetchIncremental(Emitter<HistoryState> emit) async {
    final current = state;
    if (current is! HistoryLoaded || current.readings.isEmpty) {
      return _fetchHistory(emit);
    }
    try {
      final lastTs = current.readings.last.timestamp.toDouble();
      final newReadings = await _api!.getHistory(since: lastTs);
      if (newReadings.isEmpty) return;
      var merged = [...current.readings, ...newReadings];
      // Trim readings outside the current time window.
      final cutoff = _sinceCutoff;
      merged = merged.where((r) => r.timestamp >= cutoff).toList();
      if (merged.length > _kMaxReadings) {
        merged = merged.sublist(merged.length - _kMaxReadings);
      }
      emit(HistoryLoaded(readings: merged));
    } catch (e) {
      emit(HistoryError(
        'Failed to load history: ${e.toString()}',
        previousReadings: current.readings,
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

  Future<void> _onRangeChanged(
    HistoryRangeChanged event,
    Emitter<HistoryState> emit,
  ) async {
    _rangeSeconds = event.rangeSeconds;
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
    await _fetchIncremental(emit);
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
