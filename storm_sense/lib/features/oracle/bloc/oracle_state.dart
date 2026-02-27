part of 'oracle_bloc.dart';

sealed class OracleState extends Equatable {
  const OracleState();

  @override
  List<Object?> get props => [];
}

final class OracleInitial extends OracleState {
  const OracleInitial();
}

final class OracleLoading extends OracleState {
  const OracleLoading();
}

final class OracleLoaded extends OracleState {
  const OracleLoaded({required this.reading});
  final OracleReading reading;

  @override
  List<Object?> get props => [
        reading.timestamp,
        reading.elementalHarmony,
        reading.dominantElement,
        reading.cosmicWeatherSummary,
      ];
}

final class OracleError extends OracleState {
  const OracleError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
