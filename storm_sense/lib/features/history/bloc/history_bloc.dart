import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/core/api/storm_sense_api.dart';
import 'package:storm_sense/features/history/bloc/history_event.dart';
import 'package:storm_sense/features/history/bloc/history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc() : super(const HistoryInitial()) {
    on<HistoryStarted>(_onStarted);
    on<HistoryRefreshed>(_onRefreshed);
  }

  StormSenseApi? _api;

  Future<void> _fetchHistory(Emitter<HistoryState> emit) async {
    try {
      final readings = await _api!.getHistory();
      emit(HistoryLoaded(readings: readings));
    } catch (e) {
      emit(HistoryError('Failed to load history: ${e.toString()}'));
    }
  }

  Future<void> _onStarted(
    HistoryStarted event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());
    _api = StormSenseApi(baseUrl: event.baseUrl);
    await _fetchHistory(emit);
  }

  Future<void> _onRefreshed(
    HistoryRefreshed event,
    Emitter<HistoryState> emit,
  ) async {
    if (_api == null) return;
    await _fetchHistory(emit);
  }
}
