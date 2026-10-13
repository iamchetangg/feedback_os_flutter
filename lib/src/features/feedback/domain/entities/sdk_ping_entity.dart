import 'package:equatable/equatable.dart';

class SdkPingResult extends Equatable {
  final bool ok;
  final String appId;

  const SdkPingResult({
    required this.ok,
    required this.appId,
  });

  @override
  List<Object?> get props => [ok, appId];
}
