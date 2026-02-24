import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/features/connection/bloc/connection_bloc.dart';
import 'package:storm_sense/features/connection/bloc/connection_event.dart';
import 'package:storm_sense/features/connection/bloc/connection_state.dart'
    as conn;

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ConnectionBloc>().add(const ConnectionStarted());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ConnectionBloc, conn.ConnectionState>(
          listener: (context, state) {
            if (state is conn.ConnectionInitial && state.lastIp != null) {
              _controller.text = state.lastIp!;
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // App icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.thunderstorm_rounded,
                      size: 40,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'StormSense',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect to your weather station',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),

                  // IP input
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Pi IP Address',
                      hintText: '192.168.1.42',
                      filled: true,
                      fillColor: cs.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.primary, width: 2),
                      ),
                      prefixIcon: Icon(
                        Icons.wifi_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Error message
                  if (state is conn.ConnectionFailure)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: cs.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.error,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Connect button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: state is conn.ConnectionLoading
                          ? null
                          : () {
                              final ip = _controller.text.trim();
                              if (ip.isNotEmpty) {
                                context
                                    .read<ConnectionBloc>()
                                    .add(ConnectionSubmitted(ip));
                              }
                            },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: state is conn.ConnectionLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Connect',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
