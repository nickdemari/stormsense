import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({SharedPreferences? prefs})
      : _prefs = prefs,
        super(const SettingsState()) {
    on<SettingsLoaded>(_onLoaded);
    on<TemperatureUnitChanged>(_onTempUnitChanged);
    on<PressureUnitChanged>(_onPressureUnitChanged);
    on<PollIntervalChanged>(_onPollIntervalChanged);
  }

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> _onLoaded(
    SettingsLoaded event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await _preferences;

    final tempUnitName = prefs.getString('temp_unit');
    final pressureUnitName = prefs.getString('pressure_unit');
    final pollInterval = prefs.getInt('poll_interval');

    emit(
      SettingsState(
        tempUnit: TemperatureUnit.values.firstWhere(
          (e) => e.name == tempUnitName,
          orElse: () => TemperatureUnit.fahrenheit,
        ),
        pressureUnit: PressureUnit.values.firstWhere(
          (e) => e.name == pressureUnitName,
          orElse: () => PressureUnit.hpa,
        ),
        pollIntervalSeconds: pollInterval ?? 5,
      ),
    );
  }

  Future<void> _onTempUnitChanged(
    TemperatureUnitChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await _preferences;
    await prefs.setString('temp_unit', event.unit.name);
    emit(state.copyWith(tempUnit: event.unit));
  }

  Future<void> _onPressureUnitChanged(
    PressureUnitChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await _preferences;
    await prefs.setString('pressure_unit', event.unit.name);
    emit(state.copyWith(pressureUnit: event.unit));
  }

  Future<void> _onPollIntervalChanged(
    PollIntervalChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await _preferences;
    await prefs.setInt('poll_interval', event.seconds);
    emit(state.copyWith(pollIntervalSeconds: event.seconds));
  }
}
