import 'package:equatable/equatable.dart';

import 'settings_event.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.tempUnit = TemperatureUnit.celsius,
    this.pressureUnit = PressureUnit.hpa,
    this.pollIntervalSeconds = 5,
  });

  final TemperatureUnit tempUnit;
  final PressureUnit pressureUnit;
  final int pollIntervalSeconds;

  /// Converts a temperature value from Celsius to the currently selected unit.
  /// If [tempUnit] is celsius, returns the value unchanged.
  /// If [tempUnit] is fahrenheit, applies: F = C * 9/5 + 32.
  double convertTemperature(double celsius) {
    return switch (tempUnit) {
      TemperatureUnit.celsius => celsius,
      TemperatureUnit.fahrenheit => celsius * 9.0 / 5.0 + 32.0,
    };
  }

  /// Converts a pressure value from hPa to the currently selected unit.
  /// If [pressureUnit] is hpa, returns the value unchanged.
  /// If [pressureUnit] is inhg, applies: inHg = hPa * 0.02953.
  double convertPressure(double hpa) {
    return switch (pressureUnit) {
      PressureUnit.hpa => hpa,
      PressureUnit.inhg => hpa * 0.02953,
    };
  }

  String get tempUnitLabel => switch (tempUnit) {
    TemperatureUnit.celsius => '\u00B0C',
    TemperatureUnit.fahrenheit => '\u00B0F',
  };

  String get pressureUnitLabel => switch (pressureUnit) {
    PressureUnit.hpa => 'hPa',
    PressureUnit.inhg => 'inHg',
  };

  SettingsState copyWith({
    TemperatureUnit? tempUnit,
    PressureUnit? pressureUnit,
    int? pollIntervalSeconds,
  }) {
    return SettingsState(
      tempUnit: tempUnit ?? this.tempUnit,
      pressureUnit: pressureUnit ?? this.pressureUnit,
      pollIntervalSeconds: pollIntervalSeconds ?? this.pollIntervalSeconds,
    );
  }

  @override
  List<Object?> get props => [tempUnit, pressureUnit, pollIntervalSeconds];
}
