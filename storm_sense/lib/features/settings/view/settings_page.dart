import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:storm_sense/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:storm_sense/features/history/bloc/history_bloc.dart';
import 'package:storm_sense/features/history/bloc/history_event.dart';
import 'package:storm_sense/features/oracle/bloc/oracle_bloc.dart';
import 'package:storm_sense/notifications/storm_notification_service.dart';

import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  'Settings',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Temperature Unit
                _SettingsCard(
                  title: 'Temperature Unit',
                  icon: Icons.thermostat_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  child: SegmentedButton<TemperatureUnit>(
                    expandedInsets: EdgeInsets.zero,
                    segments: const [
                      ButtonSegment(
                        value: TemperatureUnit.celsius,
                        label: Text('Celsius'),
                      ),
                      ButtonSegment(
                        value: TemperatureUnit.fahrenheit,
                        label: Text('Fahrenheit'),
                      ),
                    ],
                    selected: {state.tempUnit},
                    onSelectionChanged: (selected) {
                      context
                          .read<SettingsBloc>()
                          .add(TemperatureUnitChanged(selected.first));
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Pressure Unit
                _SettingsCard(
                  title: 'Pressure Unit',
                  icon: Icons.speed_outlined,
                  iconColor: const Color(0xFF38BDF8),
                  child: SegmentedButton<PressureUnit>(
                    expandedInsets: EdgeInsets.zero,
                    segments: const [
                      ButtonSegment(
                        value: PressureUnit.hpa,
                        label: Text('hPa'),
                      ),
                      ButtonSegment(
                        value: PressureUnit.inhg,
                        label: Text('inHg'),
                      ),
                    ],
                    selected: {state.pressureUnit},
                    onSelectionChanged: (selected) {
                      context
                          .read<SettingsBloc>()
                          .add(PressureUnitChanged(selected.first));
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Poll Interval
                _SettingsCard(
                  title: 'Poll Interval',
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFF34D399),
                  child: SegmentedButton<int>(
                    expandedInsets: EdgeInsets.zero,
                    segments: const [
                      ButtonSegment(value: 5, label: Text('5s')),
                      ButtonSegment(value: 10, label: Text('10s')),
                      ButtonSegment(value: 30, label: Text('30s')),
                    ],
                    selected: {state.pollIntervalSeconds},
                    onSelectionChanged: (selected) {
                      context
                          .read<SettingsBloc>()
                          .add(PollIntervalChanged(selected.first));
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Notifications
                _NotificationCard(
                  service: context.read<StormNotificationService>(),
                ),
                const SizedBox(height: 24),

                // Disconnect
                _DisconnectCard(
                  onDisconnect: () {
                    context
                        .read<DashboardBloc>()
                        .add(const DashboardStopped());
                    context
                        .read<HistoryBloc>()
                        .add(const HistoryStopped());
                    context
                        .read<OracleBloc>()
                        .add(const OracleStopped());
                    context.go('/connect');
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  iconColor.withValues(alpha: 0.3),
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
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  const _NotificationCard({required this.service});

  final StormNotificationService service;

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with WidgetsBindingObserver {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final enabled = await widget.service.areNotificationsEnabled();
    if (mounted) setState(() => _enabled = enabled);
  }

  Future<void> _requestPermission() async {
    final granted = await widget.service.requestNotificationPermission();
    if (mounted) setState(() => _enabled = granted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const accent = Color(0xFFA78BFA);

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
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accent.withValues(alpha: 0.3),
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    _enabled == true
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        _enabled == true
                            ? 'Storm alerts enabled'
                            : Platform.isAndroid
                                ? 'Required for storm alerts'
                                : 'Enable in Settings > StormSense',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_enabled == null)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_enabled!)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF34D399),
                  )
                else
                  FilledButton(
                    onPressed: _requestPermission,
                    child: const Text('Enable'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisconnectCard extends StatelessWidget {
  const _DisconnectCard({required this.onDisconnect});

  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = cs.error;

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
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accent.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onDisconnect,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.link_off, size: 18, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disconnect',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Return to connection screen',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
