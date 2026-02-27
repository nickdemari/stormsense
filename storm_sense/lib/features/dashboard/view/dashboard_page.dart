import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:storm_sense/core/api/models.dart';
import 'package:storm_sense/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:storm_sense/features/dashboard/view/temperature_card.dart';
import 'package:storm_sense/features/dashboard/view/pressure_card.dart';
import 'package:storm_sense/features/dashboard/view/storm_alert_card.dart';
import 'package:storm_sense/features/history/bloc/history_bloc.dart';
import 'package:storm_sense/features/history/bloc/history_event.dart';
import 'package:storm_sense/features/oracle/bloc/oracle_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<DashboardBloc, DashboardState>(
          listener: (context, state) {
            if (state is DashboardError && state.previousStatus != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Connection lost. Showing last data.'),
                    backgroundColor: cs.error,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: cs.onError,
                      onPressed: () => context
                          .read<DashboardBloc>()
                          .add(const DashboardRefreshed()),
                    ),
                  ),
                );
            }
          },
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DashboardError && state.previousStatus != null) {
              return _buildDashboardContent(
                context,
                theme,
                state.previousStatus!,
                isStale: true,
              );
            }

            if (state is DashboardError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: cs.error),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context
                            .read<DashboardBloc>()
                            .add(const DashboardRefreshed()),
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _disconnect(context),
                        icon: const Icon(Icons.link_off),
                        label: const Text('Disconnect'),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is DashboardLoaded) {
              return _buildDashboardContent(
                context,
                theme,
                state.status,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    ThemeData theme,
    StormStatus status, {
    bool isStale = false,
  }) {
    final cs = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(const DashboardRefreshed());
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Dashboard',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: -0.5,
            ),
          ),
          if (isStale) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline — showing last known data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context
                        .read<DashboardBloc>()
                        .add(const DashboardRefreshed()),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Retry',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          StormAlertCard(stormLevel: status.stormLevel),
          const SizedBox(height: 12),
          TemperatureCard(temperature: status.temperature),
          const SizedBox(height: 12),
          PressureCard(
            pressure: status.pressure,
            delta: status.pressureDelta3h,
          ),
        ],
      ),
    );
  }

  void _disconnect(BuildContext context) {
    context.read<DashboardBloc>().add(const DashboardStopped());
    context.read<HistoryBloc>().add(const HistoryStopped());
    context.read<OracleBloc>().add(const OracleStopped());
    context.go('/connect');
  }
}
