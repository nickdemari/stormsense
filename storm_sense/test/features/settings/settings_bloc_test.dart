import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/features/settings/bloc/settings_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_event.dart';
import 'package:storm_sense/features/settings/bloc/settings_state.dart';

void main() {
  group('SettingsState', () {
    test('initial state has correct defaults', () {
      const state = SettingsState();
      expect(state.tempUnit, TemperatureUnit.fahrenheit);
      expect(state.pressureUnit, PressureUnit.hpa);
      expect(state.pollIntervalSeconds, 5);
    });

    group('convertTemperature', () {
      test('celsius returns same value', () {
        const state = SettingsState(tempUnit: TemperatureUnit.celsius);
        expect(state.convertTemperature(25.0), 25.0);
      });

      test('fahrenheit converts 0C to 32F', () {
        const state = SettingsState(tempUnit: TemperatureUnit.fahrenheit);
        expect(state.convertTemperature(0.0), 32.0);
      });

      test('fahrenheit converts 100C to 212F', () {
        const state = SettingsState(tempUnit: TemperatureUnit.fahrenheit);
        expect(state.convertTemperature(100.0), 212.0);
      });
    });

    group('convertPressure', () {
      test('hpa returns same value', () {
        const state = SettingsState(pressureUnit: PressureUnit.hpa);
        expect(state.convertPressure(1013.25), 1013.25);
      });

      test('inhg converts 1013.25 hPa to approximately 29.92 inHg', () {
        const state = SettingsState(pressureUnit: PressureUnit.inhg);
        final result = state.convertPressure(1013.25);
        expect(result, closeTo(29.92, 0.01));
      });
    });

    test('tempUnitLabel returns correct labels', () {
      expect(
        const SettingsState(tempUnit: TemperatureUnit.celsius).tempUnitLabel,
        '\u00B0C',
      );
      expect(
        const SettingsState(tempUnit: TemperatureUnit.fahrenheit).tempUnitLabel,
        '\u00B0F',
      );
    });

    test('pressureUnitLabel returns correct labels', () {
      expect(
        const SettingsState(pressureUnit: PressureUnit.hpa).pressureUnitLabel,
        'hPa',
      );
      expect(
        const SettingsState(pressureUnit: PressureUnit.inhg).pressureUnitLabel,
        'inHg',
      );
    });
  });

  group('SettingsBloc', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initial state is default SettingsState', () {
      final bloc = SettingsBloc(prefs: prefs);
      expect(bloc.state, const SettingsState());
      bloc.close();
    });

    blocTest<SettingsBloc, SettingsState>(
      'SettingsLoaded with empty prefs emits default state',
      setUp: () async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      },
      build: () => SettingsBloc(prefs: prefs),
      act: (bloc) => bloc.add(const SettingsLoaded()),
      expect: () => [const SettingsState()],
    );

    blocTest<SettingsBloc, SettingsState>(
      'TemperatureUnitChanged emits state with celsius',
      setUp: () async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      },
      build: () => SettingsBloc(prefs: prefs),
      act: (bloc) =>
          bloc.add(const TemperatureUnitChanged(TemperatureUnit.celsius)),
      expect: () => [
        const SettingsState(tempUnit: TemperatureUnit.celsius),
      ],
      verify: (_) {
        expect(prefs.getString('temp_unit'), 'celsius');
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'PressureUnitChanged emits state with inhg',
      setUp: () async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      },
      build: () => SettingsBloc(prefs: prefs),
      act: (bloc) =>
          bloc.add(const PressureUnitChanged(PressureUnit.inhg)),
      expect: () => [
        const SettingsState(pressureUnit: PressureUnit.inhg),
      ],
      verify: (_) {
        expect(prefs.getString('pressure_unit'), 'inhg');
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'PollIntervalChanged emits state with 30',
      setUp: () async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      },
      build: () => SettingsBloc(prefs: prefs),
      act: (bloc) => bloc.add(const PollIntervalChanged(30)),
      expect: () => [
        const SettingsState(pollIntervalSeconds: 30),
      ],
      verify: (_) {
        expect(prefs.getInt('poll_interval'), 30);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'SettingsLoaded reads saved preferences',
      setUp: () async {
        SharedPreferences.setMockInitialValues({
          'temp_unit': 'fahrenheit',
          'pressure_unit': 'inhg',
          'poll_interval': 10,
        });
        prefs = await SharedPreferences.getInstance();
      },
      build: () => SettingsBloc(prefs: prefs),
      act: (bloc) => bloc.add(const SettingsLoaded()),
      expect: () => [
        const SettingsState(
          tempUnit: TemperatureUnit.fahrenheit,
          pressureUnit: PressureUnit.inhg,
          pollIntervalSeconds: 10,
        ),
      ],
    );
  });
}
