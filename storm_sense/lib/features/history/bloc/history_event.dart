import 'package:equatable/equatable.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

final class HistoryStarted extends HistoryEvent {
  const HistoryStarted(this.baseUrl, {this.pollIntervalSeconds = 5});
  final String baseUrl;
  final int pollIntervalSeconds;

  @override
  List<Object?> get props => [baseUrl, pollIntervalSeconds];
}

final class HistoryRefreshed extends HistoryEvent {
  const HistoryRefreshed();
}

final class HistoryPollIntervalChanged extends HistoryEvent {
  const HistoryPollIntervalChanged(this.seconds);
  final int seconds;

  @override
  List<Object?> get props => [seconds];
}

final class HistoryStopped extends HistoryEvent {
  const HistoryStopped();
}

final class HistoryPolled extends HistoryEvent {
  const HistoryPolled();
}
