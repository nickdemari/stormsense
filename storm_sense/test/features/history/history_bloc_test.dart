import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storm_sense/features/history/bloc/history_bloc.dart';
import 'package:storm_sense/features/history/bloc/history_event.dart';
import 'package:storm_sense/features/history/bloc/history_state.dart';

void main() {
  group('HistoryBloc', () {
    test('initial state is HistoryInitial', () {
      final bloc = HistoryBloc();
      expect(bloc.state, const HistoryInitial());
      bloc.close();
    });

    test('close completes cleanly', () async {
      final bloc = HistoryBloc();
      await bloc.close();
      // Should not throw
    });

    test('HistoryRefreshed with no API is a no-op', () async {
      final bloc = HistoryBloc();
      bloc.add(const HistoryRefreshed());
      await Future.delayed(const Duration(milliseconds: 100));
      expect(bloc.state, const HistoryInitial());
      await bloc.close();
    });
  });
}
