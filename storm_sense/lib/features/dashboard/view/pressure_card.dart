import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_state.dart';

class PressureCard extends StatelessWidget {
  const PressureCard({
    super.key,
    required this.pressure,
    this.delta,
  });

  final double pressure;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        final converted = settings.convertPressure(pressure);
        final unit = settings.pressureUnitLabel;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.speed, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Pressure',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${converted.toStringAsFixed(1)} $unit',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (delta != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '3h trend: ${delta! >= 0 ? "+" : ""}${delta!.toStringAsFixed(1)} hPa',
                    style: TextStyle(
                      fontSize: 14,
                      color: delta! < -3.0 ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
