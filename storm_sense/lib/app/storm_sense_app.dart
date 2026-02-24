import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:storm_sense/app/router.dart';
import 'package:storm_sense/core/theme/storm_theme.dart';
import 'package:storm_sense/features/connection/bloc/connection_bloc.dart';
import 'package:storm_sense/features/connection/bloc/connection_state.dart'
    as conn;
import 'package:storm_sense/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:storm_sense/features/history/bloc/history_bloc.dart';
import 'package:storm_sense/features/history/bloc/history_event.dart';
import 'package:storm_sense/features/settings/bloc/settings_bloc.dart';
import 'package:storm_sense/features/settings/bloc/settings_event.dart';
import 'package:storm_sense/features/settings/bloc/settings_state.dart';
import 'package:storm_sense/notifications/storm_notification_service.dart';

class StormSenseApp extends StatefulWidget {
  const StormSenseApp({
    super.key,
    required this.notificationService,
  });

  final StormNotificationService notificationService;

  @override
  State<StormSenseApp> createState() => _StormSenseAppState();
}

class _StormSenseAppState extends State<StormSenseApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<StormNotificationService>.value(
      value: widget.notificationService,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ConnectionBloc(),
          ),
          BlocProvider(
            create: (_) => SettingsBloc()..add(const SettingsLoaded()),
          ),
          BlocProvider(
            create: (_) => DashboardBloc(
              notificationService: widget.notificationService,
            ),
          ),
          BlocProvider(
            create: (_) => HistoryBloc(),
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<ConnectionBloc, conn.ConnectionState>(
              listener: (context, state) {
                if (state is conn.ConnectionSuccess) {
                  final pollInterval =
                      context.read<SettingsBloc>().state.pollIntervalSeconds;
                  context.read<DashboardBloc>().add(DashboardStarted(
                        state.baseUrl,
                        pollIntervalSeconds: pollInterval,
                      ));
                  context.read<HistoryBloc>().add(HistoryStarted(
                        state.baseUrl,
                        pollIntervalSeconds: pollInterval,
                      ));
                  _router.go('/dashboard');
                }
              },
            ),
            BlocListener<SettingsBloc, SettingsState>(
              listenWhen: (previous, current) =>
                  previous.pollIntervalSeconds !=
                  current.pollIntervalSeconds,
              listener: (context, state) {
                context.read<DashboardBloc>().add(
                      DashboardPollIntervalChanged(
                        state.pollIntervalSeconds,
                      ),
                    );
                context.read<HistoryBloc>().add(
                      HistoryPollIntervalChanged(
                        state.pollIntervalSeconds,
                      ),
                    );
              },
            ),
          ],
          child: MaterialApp.router(
            title: 'StormSense',
            theme: StormTheme.light,
            darkTheme: StormTheme.dark,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
