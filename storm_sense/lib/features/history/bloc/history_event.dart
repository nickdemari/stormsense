import 'package:equatable/equatable.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

final class HistoryStarted extends HistoryEvent {
  const HistoryStarted(this.baseUrl);
  final String baseUrl;

  @override
  List<Object?> get props => [baseUrl];
}

final class HistoryRefreshed extends HistoryEvent {
  const HistoryRefreshed();
}
