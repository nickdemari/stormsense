import 'package:flutter/material.dart';

/// A numeric text widget that smoothly animates between value changes.
///
/// Uses [TweenAnimationBuilder] so the transition runs automatically whenever
/// [value] changes (including the initial render, which animates from 0).
class AnimatedValue extends StatelessWidget {
  const AnimatedValue({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.fractionDigits = 1,
    this.suffix = '',
    this.curve = Curves.easeOutCubic,
  });

  /// The target numeric value to display.
  final double value;

  /// Text style applied to the formatted number.
  /// [FontFeature.tabularFigures] is always merged in so digits keep
  /// constant width during animation.
  final TextStyle? style;

  /// How long the value-to-value transition takes.
  final Duration duration;

  /// Decimal places shown (e.g. 1 -> "72.3").
  final int fractionDigits;

  /// Optional trailing text rendered as part of the animated string
  /// (e.g. '\u00B0F', ' hPa').
  final String suffix;

  /// Easing curve for the animation.
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, _) {
        final formatted =
            '${animatedValue.toStringAsFixed(fractionDigits)}$suffix';

        // Merge tabular figures into whatever style the caller provides so
        // digit widths stay constant and the text doesn't jitter.
        final baseStyle = style ?? DefaultTextStyle.of(context).style;
        final mergedStyle = baseStyle.copyWith(
          fontFeatures: [
            const FontFeature.tabularFigures(),
            ...?baseStyle.fontFeatures,
          ],
        );

        return Text(formatted, style: mergedStyle);
      },
    );
  }
}
