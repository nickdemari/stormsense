import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/core/api/models.dart';
import 'package:storm_sense/features/history/bloc/history_bloc.dart';
import 'package:storm_sense/features/history/bloc/history_event.dart';
import 'package:storm_sense/features/history/bloc/history_state.dart';
import 'package:storm_sense/features/history/view/metric_card.dart';
import 'package:storm_sense/features/history/view/pressure_chart.dart';
import 'package:storm_sense/features/history/view/temperature_chart.dart';
import 'package:storm_sense/features/settings/bloc/settings_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_state.dart';

const _kTempColor = Color(0xFFF59E0B);
const _kPresColor = Color(0xFF38BDF8);

enum _TimeRange {
  oneHour('1H', 'hour', Duration(hours: 1)),
  twoHours('2H', '2 hours', Duration(hours: 2)),
  sixHours('6H', '6 hours', Duration(hours: 6)),
  twelveHours('12H', '12 hours', Duration(hours: 12)),
  oneDay('1D', '24 hours', Duration(days: 1)),
  oneWeek('1W', '7 days', Duration(days: 7));

  const _TimeRange(this.label, this.description, this.duration);
  final String label;
  final String description;
  final Duration duration;
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  _TimeRange _selectedRange = _TimeRange.twoHours;

  List<Reading> _filterReadings(List<Reading> readings) {
    if (readings.isEmpty) return readings;
    final latest = readings.last.timestamp;
    final cutoff = latest - _selectedRange.duration.inSeconds;
    final filtered = readings.where((r) => r.timestamp >= cutoff).toList();
    return filtered.length >= 2 ? filtered : readings;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<HistoryBloc, HistoryState>(
          listener: (context, state) {
            if (state is HistoryError && state.previousReadings != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content:
                        const Text('Connection lost. Showing last data.'),
                    backgroundColor: cs.error,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: cs.onError,
                      onPressed: () => context
                          .read<HistoryBloc>()
                          .add(const HistoryRefreshed()),
                    ),
                  ),
                );
            }
          },
          builder: (context, state) {
            if (state is HistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is HistoryError &&
                state.previousReadings != null &&
                state.previousReadings!.isNotEmpty) {
              final readings = _filterReadings(state.previousReadings!);
              return BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, settings) {
                  return _buildContent(readings, theme, cs, settings);
                },
              );
            }

            if (state is HistoryError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: cs.error),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context
                          .read<HistoryBloc>()
                          .add(const HistoryRefreshed()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is HistoryLoaded) {
              if (state.readings.isEmpty) {
                return const Center(
                  child: Text(
                    'No history data yet.\nWait for readings to accumulate.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final readings = _filterReadings(state.readings);
              return BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, settings) {
                  return _buildContent(readings, theme, cs, settings);
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    List<Reading> readings,
    ThemeData theme,
    ColorScheme cs,
    SettingsState settings,
  ) {
    final temps =
        readings.map((r) => settings.convertTemperature(r.temperature)).toList();
    final pres =
        readings.map((r) => settings.convertPressure(r.pressure)).toList();

    final tempMin = temps.reduce(math.min);
    final tempMax = temps.reduce(math.max);
    final tempAvg = temps.reduce((a, b) => a + b) / temps.length;
    final tempTrend = temps.last - temps.first;

    final presMin = pres.reduce(math.min);
    final presMax = pres.reduce(math.max);
    final presAvg = pres.reduce((a, b) => a + b) / pres.length;
    final presTrend = pres.last - pres.first;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<HistoryBloc>().add(const HistoryRefreshed());
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Header
          Row(
            children: [
              Text(
                'History',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time range selector
          _TimeRangeSelector(
            selected: _selectedRange,
            onChanged: (range) => setState(() => _selectedRange = range),
          ),
          const SizedBox(height: 16),

          // Temperature card
          MetricCard(
            icon: Icons.thermostat_outlined,
            title: 'Temperature',
            subtitle: 'Last ${_selectedRange.description}',
            accentColor: _kTempColor,
            currentValue: temps.last,
            unit: settings.tempUnitLabel,
            minValue: '${tempMin.toStringAsFixed(1)}\u00B0',
            avgValue: '${tempAvg.toStringAsFixed(1)}\u00B0',
            maxValue: '${tempMax.toStringAsFixed(1)}\u00B0',
            trendDelta: tempTrend,
            trendUnit: '\u00B0',
            chart: TemperatureChart(
              readings: readings,
              unit: settings.tempUnitLabel,
              valueMapper: (r) => settings.convertTemperature(r.temperature),
            ),
          ),
          const SizedBox(height: 16),

          // Pressure card
          MetricCard(
            icon: Icons.speed_outlined,
            title: 'Pressure',
            subtitle: 'Last ${_selectedRange.description}',
            accentColor: _kPresColor,
            currentValue: pres.last,
            unit: settings.pressureUnitLabel,
            minValue: presMin.toStringAsFixed(1),
            avgValue: presAvg.toStringAsFixed(1),
            maxValue: presMax.toStringAsFixed(1),
            trendDelta: presTrend,
            trendUnit: '',
            chart: PressureChart(
              readings: readings,
              unit: settings.pressureUnitLabel,
              valueMapper: (r) => settings.convertPressure(r.pressure),
            ),
          ),
          const SizedBox(height: 16),

          // Reading count
          Text(
            '${readings.length} readings',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha:0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TimeRangeSelector extends StatelessWidget {
  const _TimeRangeSelector({
    required this.selected,
    required this.onChanged,
  });

  final _TimeRange selected;
  final ValueChanged<_TimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha:0.2)),
      ),
      child: Row(
        children: _TimeRange.values.map((range) {
          final isActive = range == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? cs.surfaceContainerHighest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    range.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? cs.onSurface
                          : cs.onSurfaceVariant.withValues(alpha:0.4),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
