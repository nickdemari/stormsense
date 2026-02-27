import 'package:storm_sense/core/astro/aspects.dart';
import 'package:storm_sense/core/astro/birth_chart.dart';
import 'package:storm_sense/core/astro/planetary_positions.dart';
import 'package:storm_sense/core/astro/zodiac.dart';

/// Structured personal transit data derived from birth chart + current sky.
class PersonalTransit {
  const PersonalTransit({
    required this.natalSun,
    required this.natalMoon,
    required this.natalElementCounts,
    required this.weatherResonanceCount,
    required this.natalTotal,
    required this.weatherElement,
    required this.transitAspects,
    required this.natalPositions,
  });

  /// Natal Sun position.
  final CelestialPosition natalSun;

  /// Natal Moon position.
  final CelestialPosition natalMoon;

  /// Element distribution across natal placements.
  final Map<AstroElement, int> natalElementCounts;

  /// How many natal placements share today's weather element.
  final int weatherResonanceCount;

  /// Total number of natal bodies.
  final int natalTotal;

  /// Today's weather-derived element.
  final AstroElement weatherElement;

  /// Transit-to-natal aspects, sorted by tightest orb.
  final List<Aspect> transitAspects;

  /// All natal positions for detailed display.
  final List<CelestialPosition> natalPositions;
}

/// A complete oracle reading combining weather data with planetary positions.
class OracleReading {
  const OracleReading({
    required this.timestamp,
    required this.dominantElement,
    required this.elementalHarmony,
    required this.cosmicWeatherSummary,
    required this.planets,
    required this.aspects,
    this.weatherElement,
    this.personalTransit,
    this.birthData,
  });

  /// When the reading was generated.
  final DateTime timestamp;

  /// Human-readable label of the dominant element (e.g. "Water").
  final String dominantElement;

  /// Fraction of planetary bodies whose element matches the weather element.
  /// Range: [0.0, 1.0].
  final double elementalHarmony;

  /// Narrative summary of the cosmic-weather synthesis.
  final String cosmicWeatherSummary;

  /// Positions of all tracked celestial bodies at reading time.
  final List<CelestialPosition> planets;

  /// Detected aspects between celestial bodies.
  final List<Aspect> aspects;

  /// The weather-derived element, if available.
  final AstroElement? weatherElement;

  /// Structured personal transit data, if birth data present.
  final PersonalTransit? personalTransit;

  /// The birth data used for this reading, if any.
  final BirthData? birthData;
}

/// Maps current weather conditions to an astrological element.
///
/// Storm levels 3-4 (rain/stormy) map to Water.
/// Level 0 (dry) with high temp (>85F) maps to Fire.
/// Level 0 (dry) with normal temp maps to Earth.
/// Level 2 (change) maps to Air.
/// Level 1 (fair) maps to Earth.
AstroElement weatherElement({
  required int stormLevel,
  required double temperatureF,
}) {
  if (stormLevel >= 3) return AstroElement.water;
  if (stormLevel == 0 && temperatureF > 85) return AstroElement.fire;
  if (stormLevel == 2) return AstroElement.air;
  if (stormLevel == 0) return AstroElement.earth;
  return AstroElement.earth;
}

/// Computes the fraction of planetary positions whose element matches
/// the weather-derived element.
///
/// Returns 0.0 for an empty list.
double elementalHarmony(
  List<CelestialPosition> positions,
  AstroElement weather,
) {
  if (positions.isEmpty) return 0.0;
  final matches = positions.where((p) => p.element == weather).length;
  return matches / positions.length;
}

/// Combines real-time weather sensor data with planetary positions
/// to produce an [OracleReading].
class OracleEngine {
  OracleEngine._();

  /// Generates a complete oracle reading for the given conditions and time.
  static OracleReading generateReading({
    required double temperatureF,
    required double pressure,
    required int stormLevel,
    required DateTime dateTime,
    BirthData? birthData,
  }) {
    final planets = PlanetaryPositions.allPositions(dateTime);
    final weather = weatherElement(
      stormLevel: stormLevel,
      temperatureF: temperatureF,
    );
    final harmony = elementalHarmony(planets, weather);

    final elementCounts = <AstroElement, int>{};
    for (final p in planets) {
      elementCounts[p.element] = (elementCounts[p.element] ?? 0) + 1;
    }
    final dominantPlanetary = elementCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final longitudes = {for (final p in planets) p.name: p.longitude};
    final aspects = findAllAspects(longitudes);

    final summary = _generateSummary(
      planets: planets,
      weather: weather,
      harmony: harmony,
      stormLevel: stormLevel,
      temperatureF: temperatureF,
      pressure: pressure,
      dominantPlanetary: dominantPlanetary,
      aspects: aspects,
    );

    PersonalTransit? personalTransit;
    if (birthData != null) {
      personalTransit = _generatePersonalTransit(
        transitPlanets: planets,
        birthData: birthData,
        weather: weather,
      );
    }

    return OracleReading(
      timestamp: dateTime,
      dominantElement: weather.label,
      elementalHarmony: harmony,
      cosmicWeatherSummary: summary,
      planets: planets,
      aspects: aspects,
      weatherElement: weather,
      personalTransit: personalTransit,
      birthData: birthData,
    );
  }

  static String _generateSummary({
    required List<CelestialPosition> planets,
    required AstroElement weather,
    required double harmony,
    required int stormLevel,
    required double temperatureF,
    required double pressure,
    required AstroElement dominantPlanetary,
    required List<Aspect> aspects,
  }) {
    final sun = planets.firstWhere((p) => p.name == 'Sun');
    final moon = planets.firstWhere((p) => p.name == 'Moon');

    final buffer = StringBuffer();

    buffer.write(
      'Sun in ${sun.sign.label} ${sun.sign.glyph} ${sun.degreeInSign}\u00B0, '
      'Moon in ${moon.sign.label} ${moon.sign.glyph} '
      '${moon.degreeInSign}\u00B0. ',
    );

    if (harmony > 0.7) {
      buffer.write(
        '${weather.label} energy dominates both sky and atmosphere \u2014 '
        'celestial and terrestrial forces are aligned. ',
      );
    } else if (harmony > 0.3) {
      buffer.write(
        'Mixed elemental signatures: ${weather.label} conditions meet '
        '${dominantPlanetary.label} planetary energy. '
        'Expect nuanced, layered influences. ',
      );
    } else {
      buffer.write(
        'Cosmic tension: ${dominantPlanetary.label} planetary energy clashes '
        'with ${weather.label} atmospheric conditions. '
        'Contradictory forces create unpredictable dynamics. ',
      );
    }

    if (aspects.isNotEmpty) {
      final top = aspects.first;
      buffer.write(
        '${top.body1} ${top.type.glyph} ${top.body2} '
        '(${top.type.label}) signals ${top.type.keyword}.',
      );
    }

    return buffer.toString();
  }

  /// Builds structured personal transit data by comparing current transiting
  /// planets against natal chart positions.
  static PersonalTransit _generatePersonalTransit({
    required List<CelestialPosition> transitPlanets,
    required BirthData birthData,
    required AstroElement weather,
  }) {
    final natalPositions = birthData.natalPositions;

    // Find transits aspecting natal positions
    final natalLongitudes = {
      for (final p in natalPositions) 'Natal ${p.name}': p.longitude,
    };
    final transitLongitudes = {
      for (final p in transitPlanets) p.name: p.longitude,
    };

    final transitAspects = <Aspect>[];
    for (final tEntry in transitLongitudes.entries) {
      for (final nEntry in natalLongitudes.entries) {
        final aspect = findAspect(
          tEntry.value,
          nEntry.value,
          body1: tEntry.key,
          body2: nEntry.key,
        );
        if (aspect != null) {
          transitAspects.add(aspect);
        }
      }
    }

    transitAspects.sort((a, b) => a.orb.compareTo(b.orb));

    final natalSun = natalPositions.firstWhere((p) => p.name == 'Sun');
    final natalMoon = natalPositions.firstWhere((p) => p.name == 'Moon');

    final natalElementCounts = <AstroElement, int>{};
    for (final p in natalPositions) {
      natalElementCounts[p.element] =
          (natalElementCounts[p.element] ?? 0) + 1;
    }

    final resonanceCount =
        natalPositions.where((p) => p.element == weather).length;

    return PersonalTransit(
      natalSun: natalSun,
      natalMoon: natalMoon,
      natalElementCounts: natalElementCounts,
      weatherResonanceCount: resonanceCount,
      natalTotal: natalPositions.length,
      weatherElement: weather,
      transitAspects: transitAspects,
      natalPositions: natalPositions,
    );
  }
}
