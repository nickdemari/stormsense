import 'package:flutter/material.dart';
import 'package:storm_sense/shared/widgets/animated_value.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.currentValue,
    required this.unit,
    required this.minValue,
    required this.avgValue,
    required this.maxValue,
    required this.trendDelta,
    required this.trendUnit,
    required this.chart,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final double currentValue;
  final String unit;
  final String minValue;
  final String avgValue;
  final String maxValue;
  final double trendDelta;
  final String trendUnit;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top glow accent line
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                accentColor.withValues(alpha:0.5),
                Colors.transparent,
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, cs),
                const SizedBox(height: 14),
                _buildLiveValue(cs),
                const SizedBox(height: 14),
                _buildStatsRow(cs),
                const SizedBox(height: 14),
                SizedBox(height: 150, child: chart),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha:0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: accentColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha:0.5),
                ),
              ),
            ],
          ),
        ),
        _buildTrendBadge(),
      ],
    );
  }

  Widget _buildTrendBadge() {
    final isStable = trendDelta.abs() < 0.1;
    final isUp = trendDelta > 0;

    final Color color;
    final IconData badgeIcon;
    if (isStable) {
      color = const Color(0xFFFBBF24);
      badgeIcon = Icons.remove;
    } else if (isUp) {
      color = const Color(0xFF34D399);
      badgeIcon = Icons.arrow_upward_rounded;
    } else {
      color = const Color(0xFFF87171);
      badgeIcon = Icons.arrow_downward_rounded;
    }

    final prefix = isStable ? '' : (isUp ? '+' : '');
    final text = '$prefix${trendDelta.toStringAsFixed(1)}$trendUnit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveValue(ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        AnimatedValue(
          value: currentValue,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: accentColor,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unit,
          style: TextStyle(
            fontSize: 16,
            color: cs.onSurfaceVariant.withValues(alpha:0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _statCell('MIN', minValue, cs),
          Container(
            width: 1,
            height: 28,
            color: cs.outlineVariant.withValues(alpha:0.2),
          ),
          _statCell('AVG', avgValue, cs),
          Container(
            width: 1,
            height: 28,
            color: cs.outlineVariant.withValues(alpha:0.2),
          ),
          _statCell('MAX', maxValue, cs),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value, ColorScheme cs) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant.withValues(alpha:0.4),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
