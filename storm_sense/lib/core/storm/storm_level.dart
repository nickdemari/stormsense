import 'dart:ui';

enum StormLevel {
  clear(0, 'Clear', Color(0xFF4CAF50)),
  watch(1, 'Watch', Color(0xFFFFC107)),
  warning(2, 'Warning', Color(0xFFFF9800)),
  severe(3, 'Severe', Color(0xFFF44336));

  const StormLevel(this.value, this.label, this.color);
  final int value;
  final String label;
  final Color color;

  static StormLevel fromInt(int v) =>
      StormLevel.values.firstWhere((e) => e.value == v,
          orElse: () => StormLevel.clear);
}
