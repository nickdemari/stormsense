part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

final class DashboardStarted extends DashboardEvent {
  const DashboardStarted(this.baseUrl, {this.pollIntervalSeconds = 5});
  final String baseUrl;
  final int pollIntervalSeconds;

  @override
  List<Object?> get props => [baseUrl, pollIntervalSeconds];
}

final class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}

final class DashboardStopped extends DashboardEvent {
  const DashboardStopped();
}

final class _DashboardPolled extends DashboardEvent {
  const _DashboardPolled();
}
