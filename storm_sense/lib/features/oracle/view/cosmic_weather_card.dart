import 'package:flutter/material.dart';
import 'package:storm_sense/core/astro/oracle_engine.dart';

class CosmicWeatherCard extends StatelessWidget {
  const CosmicWeatherCard({super.key, required this.reading});

  final OracleReading reading;

  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final harmonyPercent = (reading.elementalHarmony * 100).round();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                _color.withValues(alpha: 0.8),
                Colors.transparent,
              ]),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _elementIcon(reading.dominantElement),
                        color: _color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${reading.dominantElement} Dominant',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _color,
                            ),
                          ),
                          Text(
                            'Elemental harmony: $harmonyPercent%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: reading.elementalHarmony,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: _color,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  reading.cosmicWeatherSummary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _timeAgo(reading.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _elementIcon(String element) {
    return switch (element) {
      'Fire' => Icons.local_fire_department_outlined,
      'Water' => Icons.water_drop_outlined,
      'Air' => Icons.air_outlined,
      'Earth' => Icons.landscape_outlined,
      _ => Icons.auto_awesome,
    };
  }

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} min ago';
    return 'Updated ${diff.inHours}h ago';
  }
}
