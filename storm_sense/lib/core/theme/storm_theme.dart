import 'package:flutter/material.dart';
import 'package:storm_sense/core/storm/storm_level.dart';

class StormTheme {
  StormTheme._();

  static final Color _seedColor = StormLevel.fair.color;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seedColor,
        brightness: Brightness.light,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seedColor,
        brightness: Brightness.dark,
      );
}
