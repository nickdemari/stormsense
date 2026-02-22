import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/core/api/storm_sense_api.dart';
import 'package:storm_sense/features/connection/bloc/connection_event.dart';
import 'package:storm_sense/features/connection/bloc/connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  ConnectionBloc({SharedPreferences? prefs})
      : _prefs = prefs,
        super(const ConnectionInitial()) {
    on<ConnectionStarted>(_onStarted);
    on<ConnectionSubmitted>(_onSubmitted);
  }

  SharedPreferences? _prefs;

  Future<void> _onStarted(
    ConnectionStarted event,
    Emitter<ConnectionState> emit,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    final lastIp = _prefs!.getString('last_ip');
    emit(ConnectionInitial(lastIp: lastIp));
  }

  Future<void> _onSubmitted(
    ConnectionSubmitted event,
    Emitter<ConnectionState> emit,
  ) async {
    emit(const ConnectionLoading());

    final baseUrl = 'http://${event.ipAddress}:5000';
    final api = StormSenseApi(baseUrl: baseUrl);

    try {
      final healthy = await api.isHealthy();
      if (healthy) {
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs!.setString('last_ip', event.ipAddress);
        emit(ConnectionSuccess(baseUrl));
      } else {
        emit(const ConnectionFailure(
          'Pi is not responding. Check the IP address.',
        ));
      }
    } catch (e) {
      emit(ConnectionFailure('Connection failed: ${e.toString()}'));
    }
  }
}
