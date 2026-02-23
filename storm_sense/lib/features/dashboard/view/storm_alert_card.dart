import 'package:flutter/material.dart';
import 'package:storm_sense/core/storm/storm_level.dart';

class StormAlertCard extends StatelessWidget {
  const StormAlertCard({super.key, required this.stormLevel});

  final int stormLevel;

  @override
  Widget build(BuildContext context) {
    final level = StormLevel.fromInt(stormLevel);

    return Card(
      color: level.color.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              _iconForLevel(level),
              color: level.color,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: level.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _descriptionForLevel(level),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
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
