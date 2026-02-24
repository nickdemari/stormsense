import 'package:flutter/material.dart';
import 'package:storm_sense/core/storm/storm_level.dart';

class StormAlertCard extends StatelessWidget {
  const StormAlertCard({super.key, required this.stormLevel});

  final int stormLevel;

  @override
  Widget build(BuildContext context) {
    final level = StormLevel.fromInt(stormLevel);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
        children: [
          // Top glow in storm color
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  level.color.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: level.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconForLevel(level),
                    color: level.color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.label,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: level.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _descriptionForLevel(level),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForLevel(StormLevel level) {
    return switch (level) {
      StormLevel.dry => Icons.wb_sunny,
      StormLevel.fair => Icons.wb_sunny_outlined,
      StormLevel.change => Icons.cloud,
      StormLevel.rain => Icons.thunderstorm,
      StormLevel.stormy => Icons.warning,
    };
  }

  String _descriptionForLevel(StormLevel level) {
    return switch (level) {
      StormLevel.dry => 'High pressure. Clear and dry.',
      StormLevel.fair => 'Conditions are stable.',
      StormLevel.change => 'Moderate pressure drop detected.',
      StormLevel.rain => 'Rapid pressure drop. Rain likely.',
      StormLevel.stormy => 'Severe pressure drop! Storm approaching.',
    };
  }
}
