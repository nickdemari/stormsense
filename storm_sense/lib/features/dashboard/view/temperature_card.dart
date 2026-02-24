import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_state.dart';
import 'package:storm_sense/shared/widgets/animated_value.dart';

class TemperatureCard extends StatelessWidget {
  const TemperatureCard({super.key, required this.temperature});

  final double temperature;

  static const _color = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        final converted = settings.convertTemperature(temperature);
        final unit = settings.tempUnitLabel;

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _color.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.thermostat_outlined,
                            size: 18,
                            color: _color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Temperature',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedValue(
                          value: converted,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: _color,
                            letterSpacing: -1.5,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 16,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
