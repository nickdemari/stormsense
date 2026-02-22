import 'package:equatable/equatable.dart';

enum TemperatureUnit { celsius, fahrenheit }

enum PressureUnit { hpa, inhg }

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

final class TemperatureUnitChanged extends SettingsEvent {
  const TemperatureUnitChanged(this.unit);

  final TemperatureUnit unit;

  @override
  List<Object?> get props => [unit];
}

final class PressureUnitChanged extends SettingsEvent {
  const PressureUnitChanged(this.unit);

  final PressureUnit unit;

  @override
  List<Object?> get props => [unit];
}

final class PollIntervalChanged extends SettingsEvent {
  const PollIntervalChanged(this.seconds);

  final int seconds;

  @override
  List<Object?> get props => [seconds];
}
