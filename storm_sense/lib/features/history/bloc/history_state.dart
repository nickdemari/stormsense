import 'package:equatable/equatable.dart';
import 'package:storm_sense/core/api/models.dart';

sealed class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

final class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

final class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

final class HistoryLoaded extends HistoryState {
  const HistoryLoaded({required this.readings});
  final List<Reading> readings;

  @override
  List<Object?> get props => [readings];
}

final class HistoryError extends HistoryState {
  const HistoryError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
