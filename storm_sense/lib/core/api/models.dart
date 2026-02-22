import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
sealed class StormStatus with _$StormStatus {
  const factory StormStatus({
    required double temperature,
    @JsonKey(name: 'raw_temperature') required double rawTemperature,
    required double pressure,
    @JsonKey(name: 'storm_level') required int stormLevel,
    @JsonKey(name: 'storm_label') required String stormLabel,
    @JsonKey(name: 'samples_collected') required int samplesCollected,
    @JsonKey(name: 'history_full') required bool historyFull,
    @JsonKey(name: 'display_mode') required String displayMode,
    @JsonKey(name: 'pressure_delta_3h') required double? pressureDelta3h,
  }) = _StormStatus;

  factory StormStatus.fromJson(Map<String, dynamic> json) =>
      _$StormStatusFromJson(json);
}

@freezed
sealed class Reading with _$Reading {
  const factory Reading({
    required double timestamp,
    required double temperature,
    @JsonKey(name: 'raw_temperature') required double rawTemperature,
    required double pressure,
    @JsonKey(name: 'storm_level') required int stormLevel,
  }) = _Reading;

  factory Reading.fromJson(Map<String, dynamic> json) =>
      _$ReadingFromJson(json);
}
