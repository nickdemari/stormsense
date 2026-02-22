import 'package:equatable/equatable.dart';

sealed class ConnectionEvent extends Equatable {
  const ConnectionEvent();

  @override
  List<Object?> get props => [];
}

final class ConnectionStarted extends ConnectionEvent {
  const ConnectionStarted();
}

final class ConnectionSubmitted extends ConnectionEvent {
  const ConnectionSubmitted(this.ipAddress);
  final String ipAddress;

  @override
  List<Object?> get props => [ipAddress];
}
