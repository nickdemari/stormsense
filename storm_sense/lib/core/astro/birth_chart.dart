import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/core/astro/planetary_positions.dart';

class BirthData {
  const BirthData({
    required this.birthDate,
    this.birthTime,
    this.latitude,
    this.longitude,
  });

  final DateTime birthDate;
  final String? birthTime;
  final double? latitude;
  final double? longitude;

  DateTime get natalDateTime {
    if (birthTime == null) return birthDate;
    final parts = birthTime!.split(':');
    if (parts.length != 2) return birthDate;
    return DateTime(
      birthDate.year,
      birthDate.month,
      birthDate.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    );
  }

  List<CelestialPosition> get natalPositions =>
      PlanetaryPositions.allPositions(natalDateTime);
}

class BirthDataStore {
  static const _keyDate = 'oracle_birth_date';
  static const _keyTime = 'oracle_birth_time';
  static const _keyLat = 'oracle_birth_latitude';
  static const _keyLng = 'oracle_birth_longitude';

  static Future<BirthData?> load(SharedPreferences prefs) async {
    final dateStr = prefs.getString(_keyDate);
    if (dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;

    return BirthData(
      birthDate: date,
      birthTime: prefs.getString(_keyTime),
      latitude: prefs.getDouble(_keyLat),
      longitude: prefs.getDouble(_keyLng),
    );
  }

  static Future<void> save(SharedPreferences prefs, BirthData data) async {
    await prefs.setString(_keyDate, data.birthDate.toIso8601String());
    if (data.birthTime != null) {
      await prefs.setString(_keyTime, data.birthTime!);
    } else {
      await prefs.remove(_keyTime);
    }
    if (data.latitude != null) {
      await prefs.setDouble(_keyLat, data.latitude!);
    }
    if (data.longitude != null) {
      await prefs.setDouble(_keyLng, data.longitude!);
    }
  }

  static Future<void> clear(SharedPreferences prefs) async {
    await prefs.remove(_keyDate);
    await prefs.remove(_keyTime);
    await prefs.remove(_keyLat);
    await prefs.remove(_keyLng);
  }
}
