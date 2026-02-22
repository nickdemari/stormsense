import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storm_sense/features/connection/view/connect_page.dart';
import 'package:storm_sense/features/dashboard/view/dashboard_page.dart';
import 'package:storm_sense/features/history/view/history_page.dart';
import 'package:storm_sense/features/settings/view/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({String initialLocation = '/connect'}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/connect',
        builder: (context, state) => const ConnectPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateIndex(GoRouterState.of(context).uri.path),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
            case 1:
              context.go('/history');
            case 2:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateIndex(String path) {
    if (path.startsWith('/history')) return 1;
    if (path.startsWith('/settings')) return 2;
    return 0;
  }
}
