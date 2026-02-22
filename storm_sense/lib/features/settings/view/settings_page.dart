import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              _SectionHeader(title: 'Temperature Unit'),
              RadioListTile<TemperatureUnit>(
                title: const Text('\u00B0C (Celsius)'),
                value: TemperatureUnit.celsius,
                groupValue: state.tempUnit,
                onChanged: (value) {
                  if (value != null) {
                    context
                        .read<SettingsBloc>()
                        .add(TemperatureUnitChanged(value));
                  }
                },
              ),
              RadioListTile<TemperatureUnit>(
                title: const Text('\u00B0F (Fahrenheit)'),
                value: TemperatureUnit.fahrenheit,
                groupValue: state.tempUnit,
                onChanged: (value) {
                  if (value != null) {
                    context
                        .read<SettingsBloc>()
                        .add(TemperatureUnitChanged(value));
                  }
                },
              ),
              const Divider(),
              _SectionHeader(title: 'Pressure Unit'),
              RadioListTile<PressureUnit>(
                title: const Text('hPa (Hectopascal)'),
                value: PressureUnit.hpa,
                groupValue: state.pressureUnit,
                onChanged: (value) {
                  if (value != null) {
                    context
                        .read<SettingsBloc>()
                        .add(PressureUnitChanged(value));
                  }
                },
              ),
              RadioListTile<PressureUnit>(
                title: const Text('inHg (Inches of Mercury)'),
                value: PressureUnit.inhg,
                groupValue: state.pressureUnit,
                onChanged: (value) {
                  if (value != null) {
                    context
                        .read<SettingsBloc>()
                        .add(PressureUnitChanged(value));
                  }
                },
              ),
              const Divider(),
              _SectionHeader(title: 'Poll Interval'),
              for (final seconds in [5, 10, 30])
                RadioListTile<int>(
                  title: Text('${seconds}s'),
                  value: seconds,
                  groupValue: state.pollIntervalSeconds,
                  onChanged: (value) {
                    if (value != null) {
                      context
                          .read<SettingsBloc>()
                          .add(PollIntervalChanged(value));
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
