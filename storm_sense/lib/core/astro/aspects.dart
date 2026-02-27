/// Planetary aspect detection for astrological weather correlation.
///
/// Identifies geometric relationships between celestial bodies
/// based on angular separation along the ecliptic.

enum AspectType {
  conjunction(0, 8, 'Conjunction', '\u260C', 'unity'),
  sextile(60, 6, 'Sextile', '\u26B9', 'opportunity'),
  square(90, 7, 'Square', '\u25A1', 'tension'),
  trine(120, 8, 'Trine', '\u25B3', 'harmony'),
  opposition(180, 8, 'Opposition', '\u260D', 'polarity');

  const AspectType(this.angle, this.orb, this.label, this.glyph, this.keyword);

  /// The exact angle in degrees for this aspect.
  final double angle;

  /// Maximum allowed deviation from the exact angle (in degrees).
  final double orb;

  /// Human-readable name.
  final String label;

  /// Unicode glyph for display.
  final String glyph;

  /// Single-word descriptor of the aspect's quality.
  final String keyword;
}

/// A detected aspect between two celestial bodies.
class Aspect {
  const Aspect({
    required this.type,
    required this.body1,
    required this.body2,
    required this.orb,
  });

  /// The kind of aspect (conjunction, trine, etc.).
  final AspectType type;

  /// Name of the first body.
  final String body1;

  /// Name of the second body.
  final String body2;

  /// Actual deviation from the exact aspect angle, in degrees.
  final double orb;
}

/// Checks whether two ecliptic longitudes form a recognised aspect.
///
/// Returns the [Aspect] if the angular separation (shortest arc) falls
/// within the orb of any [AspectType], or `null` otherwise.
Aspect? findAspect(
  double lon1,
  double lon2, {
  String body1 = '',
  String body2 = '',
}) {
  final separation = _angularSeparation(lon1, lon2);

  for (final type in AspectType.values) {
    final diff = (separation - type.angle).abs();
    if (diff <= type.orb) {
      return Aspect(type: type, body1: body1, body2: body2, orb: diff);
    }
  }
  return null;
}

/// Finds every pairwise aspect among a map of body-name to ecliptic longitude.
///
/// Results are sorted by tightest orb first (most exact aspects on top).
List<Aspect> findAllAspects(Map<String, double> longitudes) {
  final aspects = <Aspect>[];
  final names = longitudes.keys.toList();

  for (var i = 0; i < names.length; i++) {
    for (var j = i + 1; j < names.length; j++) {
      final aspect = findAspect(
        longitudes[names[i]]!,
        longitudes[names[j]]!,
        body1: names[i],
        body2: names[j],
      );
      if (aspect != null) {
        aspects.add(aspect);
      }
    }
  }

  aspects.sort((a, b) => a.orb.compareTo(b.orb));
  return aspects;
}

/// Shortest-arc angular separation between two ecliptic longitudes.
double _angularSeparation(double lon1, double lon2) {
  final diff = (lon2 - lon1).abs() % 360;
  return diff > 180 ? 360 - diff : diff;
}
