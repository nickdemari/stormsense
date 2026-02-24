import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_state.dart';
import 'package:storm_sense/shared/widgets/animated_value.dart';

class PressureCard extends StatelessWidget {
  const PressureCard({
    super.key,
    required this.pressure,
    this.delta,
  });

  final double pressure;
  final double? delta;

  static const _color = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        final converted = settings.convertPressure(pressure);
        final unit = settings.pressureUnitLabel;

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
                            Icons.speed_outlined,
                            size: 18,
                            color: _color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pressure',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        if (delta != null) _buildTrendBadge(delta!),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedValue(
                          value: converted,
                          suffix: ' $unit',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: _color,
                            letterSpacing: -1.5,
                            height: 1,
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

  Widget _buildTrendBadge(double delta) {
    final isUp = delta > 0;
    final isStable = delta.abs() < 0.5;

    final Color color;
    final IconData icon;
    if (isStable) {
      color = const Color(0xFFFBBF24);
      icon = Icons.remove;
    } else if (isUp) {
      color = const Color(0xFF34D399);
      icon = Icons.arrow_upward_rounded;
    } else {
      color = const Color(0xFFF87171);
      icon = Icons.arrow_downward_rounded;
    }

    final prefix = isStable ? '' : (isUp ? '+' : '');
    final text = '$prefix${delta.toStringAsFixed(1)} hPa/3h';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
