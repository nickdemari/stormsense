import 'package:equatable/equatable.dart';

sealed class ConnectionState extends Equatable {
  const ConnectionState();

  @override
  List<Object?> get props => [];
}

final class ConnectionInitial extends ConnectionState {
  const ConnectionInitial({this.lastIp});
  final String? lastIp;

  @override
  List<Object?> get props => [lastIp];
}

final class ConnectionLoading extends ConnectionState {
  const ConnectionLoading();
}

final class ConnectionSuccess extends ConnectionState {
  const ConnectionSuccess(this.baseUrl);
  final String baseUrl;

  @override
  List<Object?> get props => [baseUrl];
}

final class ConnectionFailure extends ConnectionState {
  const ConnectionFailure(this.error);
  final String error;

  @override
  List<Object?> get props => [error];
}
