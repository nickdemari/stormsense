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
    return Scaffold(
      appBar: AppBar(title: const Text('StormSense')),
      body: BlocConsumer<ConnectionBloc, conn.ConnectionState>(
        listener: (context, state) {
          if (state is conn.ConnectionInitial && state.lastIp != null) {
            _controller.text = state.lastIp!;
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Connect to your StormSense Pi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Pi IP Address',
                    hintText: '192.168.1.42',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wifi),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                if (state is conn.ConnectionFailure)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      state.error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                    child: state is conn.ConnectionLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Connect'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
