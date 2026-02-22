import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_state.dart';

class TemperatureCard extends StatelessWidget {
  const TemperatureCard({super.key, required this.temperature});

  final double temperature;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        final converted = settings.convertTemperature(temperature);
        final unit = settings.tempUnitLabel;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.thermostat, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Temperature',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${converted.toStringAsFixed(1)}$unit',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
