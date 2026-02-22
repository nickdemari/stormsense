import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/features/connection/bloc/connection_bloc.dart';
import 'package:storm_sense/features/connection/bloc/connection_event.dart';
import 'package:storm_sense/features/connection/bloc/connection_state.dart';

void main() {
  group('ConnectionBloc', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initial state is ConnectionInitial', () {
      final bloc = ConnectionBloc(prefs: prefs);
      expect(bloc.state, const ConnectionInitial());
    });

    blocTest<ConnectionBloc, ConnectionState>(
      'ConnectionStarted emits initial with lastIp when saved',
      setUp: () async {
        SharedPreferences.setMockInitialValues({'last_ip': '192.168.1.42'});
        prefs = await SharedPreferences.getInstance();
      },
      build: () => ConnectionBloc(prefs: prefs),
      act: (bloc) => bloc.add(const ConnectionStarted()),
      expect: () => [
        const ConnectionInitial(lastIp: '192.168.1.42'),
      ],
    );

    blocTest<ConnectionBloc, ConnectionState>(
      'ConnectionStarted emits initial with null when no saved IP',
      build: () => ConnectionBloc(prefs: prefs),
      act: (bloc) => bloc.add(const ConnectionStarted()),
      expect: () => [
        const ConnectionInitial(lastIp: null),
      ],
    );
  });
}
