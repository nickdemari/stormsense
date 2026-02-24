part of 'dashboard_bloc.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  const DashboardLoaded({required this.status});
  final StormStatus status;

  @override
  List<Object?> get props => [status];
}

final class DashboardError extends DashboardState {
  const DashboardError(this.message, {this.previousStatus});
  final String message;
  final StormStatus? previousStatus;

  @override
  List<Object?> get props => [message, previousStatus];
}
