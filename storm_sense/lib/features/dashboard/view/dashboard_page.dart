import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:storm_sense/features/dashboard/view/temperature_card.dart';
import 'package:storm_sense/features/dashboard/view/pressure_card.dart';
import 'package:storm_sense/features/dashboard/view/storm_alert_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<DashboardBloc>()
                        .add(const DashboardRefreshed()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is DashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<DashboardBloc>()
                    .add(const DashboardRefreshed());
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  StormAlertCard(stormLevel: state.status.stormLevel),
                  const SizedBox(height: 12),
                  TemperatureCard(temperature: state.status.temperature),
                  const SizedBox(height: 12),
                  PressureCard(
                    pressure: state.status.pressure,
                    delta: state.status.pressureDelta3h,
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
