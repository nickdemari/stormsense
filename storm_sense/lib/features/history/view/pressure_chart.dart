import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:storm_sense/core/api/models.dart';

class PressureChart extends StatelessWidget {
  const PressureChart({super.key, required this.readings});

  final List<Reading> readings;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) return const SizedBox.shrink();

    final spots = readings.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.pressure);
    }).toList();

    final pressures = readings.map((r) => r.pressure).toList();
    final minP = pressures.reduce((a, b) => a < b ? a : b) - 2;
    final maxP = pressures.reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        minY: minP,
        maxY: maxP,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (readings.length / 4)
                  .ceilToDouble()
                  .clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= readings.length) {
                  return const SizedBox.shrink();
                }
                final timestamp = readings[index].timestamp;
                final dt = DateTime.fromMillisecondsSinceEpoch(
                  (timestamp * 1000).toInt(),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
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
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withOpacity(0.3),
                  Colors.blue.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} hPa',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
