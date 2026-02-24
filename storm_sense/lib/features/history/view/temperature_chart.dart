import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:storm_sense/core/api/models.dart';

class TemperatureChart extends StatelessWidget {
  const TemperatureChart({
    super.key,
    required this.readings,
    this.unit = '\u00B0F',
    this.valueMapper,
  });

  final List<Reading> readings;
  final String unit;

  /// Extracts the converted temperature from a [Reading].
  /// Defaults to [Reading.temperatureF] when null.
  final double Function(Reading)? valueMapper;

  static const _color = Color(0xFFF59E0B);
  static const _maxPoints = 250;
  static const _leftReserved = 36.0;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final gridColor = cs.onSurface.withValues(alpha: 0.05);
    final labelColor = cs.onSurfaceVariant.withValues(alpha: 0.3);
    final labelStyle = TextStyle(
      fontSize: 9,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: labelColor,
    );

    final mapper = valueMapper ?? (Reading r) => r.temperatureF;
    final raw = readings.map(mapper).toList();

    // Smooth sensor noise with a moving average scaled to data density.
    final window = raw.length <= 30 ? 1 : (raw.length ~/ 80).clamp(3, 15);
    final smoothed = List<double>.generate(raw.length, (i) {
      final lo = math.max(0, i - window ~/ 2);
      final hi = math.min(raw.length, i + window ~/ 2 + 1);
      var sum = 0.0;
      for (var j = lo; j < hi; j++) {
        sum += raw[j];
      }
      return sum / (hi - lo);
    });

    // Downsample to _maxPoints for rendering perf + cleaner line.
    final List<FlSpot> spots;
    final List<double> timestamps;
    if (smoothed.length <= _maxPoints) {
      spots = [
        for (var i = 0; i < smoothed.length; i++)
          FlSpot(i.toDouble(), smoothed[i]),
      ];
      timestamps = [for (final r in readings) r.timestamp.toDouble()];
    } else {
      final step = (smoothed.length - 1) / (_maxPoints - 1);
      spots = [];
      timestamps = [];
      for (var i = 0; i < _maxPoints; i++) {
        final idx = (i * step).round().clamp(0, smoothed.length - 1);
        spots.add(FlSpot(i.toDouble(), smoothed[idx]));
        timestamps.add(readings[idx].timestamp.toDouble());
      }
    }

    final minT = smoothed.reduce(math.min) - 2;
    final maxT = smoothed.reduce(math.max) + 2;

    // Build 5 evenly-spaced time labels.
    final last = timestamps.length - 1;
    final labelIndices = [
      0,
      (last * 0.25).round(),
      (last * 0.50).round(),
      (last * 0.75).round(),
      last,
    ];

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              minY: minT,
              maxY: maxT,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: gridColor,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: _leftReserved,
                    interval: 2,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: labelStyle,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  preventCurveOverShooting: true,
                  color: _color,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _color.withValues(alpha: 0.22),
                        _color.withValues(alpha: 0.04),
                        _color.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) =>
                      cs.surfaceContainerHighest.withValues(alpha: 0.95),
                  tooltipRoundedRadius: 10,
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)}$unit',
                        TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontSize: 13,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: _leftReserved, top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final idx in labelIndices)
                Text(_formatTime(timestamps[idx]), style: labelStyle),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatTime(double ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch((ts * 1000).toInt());
    final h = dt.hour == 0 ? 12 : dt.hour > 12 ? dt.hour - 12 : dt.hour;
    return '$h:${dt.minute.toString().padLeft(2, '0')}${dt.hour < 12 ? 'a' : 'p'}';
  }
}
