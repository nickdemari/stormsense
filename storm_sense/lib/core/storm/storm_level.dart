import 'dart:ui';

enum StormLevel {
  dry(0, 'Dry', Color(0xFF0288D1)),
  fair(1, 'Fair', Color(0xFF4CAF50)),
  change(2, 'Change', Color(0xFFFFC107)),
  rain(3, 'Rain', Color(0xFFFF9800)),
  stormy(4, 'Stormy', Color(0xFFF44336));

  const StormLevel(this.value, this.label, this.color);
  final int value;
  final String label;
  final Color color;

  static StormLevel fromInt(int v) =>
      StormLevel.values.firstWhere((e) => e.value == v,
          orElse: () => StormLevel.fair);
}
