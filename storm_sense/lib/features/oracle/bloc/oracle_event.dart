part of 'oracle_bloc.dart';

sealed class OracleEvent extends Equatable {
  const OracleEvent();

  @override
  List<Object?> get props => [];
}

final class OracleStarted extends OracleEvent {
  const OracleStarted();
}

final class OracleWeatherUpdated extends OracleEvent {
  const OracleWeatherUpdated(this.temperatureF, this.pressure, this.stormLevel);

  final double temperatureF;
  final double pressure;
  final int stormLevel;

  @override
  List<Object?> get props => [temperatureF, pressure, stormLevel];
}

final class OracleRefreshed extends OracleEvent {
  const OracleRefreshed();
}

final class OracleBirthDataChanged extends OracleEvent {
  const OracleBirthDataChanged();
}

final class OracleStopped extends OracleEvent {
  const OracleStopped();
}
