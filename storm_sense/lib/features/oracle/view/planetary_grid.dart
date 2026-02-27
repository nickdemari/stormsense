import 'package:flutter/material.dart';
import 'package:storm_sense/core/astro/planetary_positions.dart';
import 'package:storm_sense/core/astro/zodiac.dart';

class PlanetaryGrid extends StatelessWidget {
  const PlanetaryGrid({super.key, required this.planets});

  final List<CelestialPosition> planets;
  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                _color.withValues(alpha: 0.3),
                Colors.transparent,
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.blur_circular,
                        size: 18,
                        color: _color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Planetary Positions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...List.generate(
                  (planets.length / 2).ceil(),
                  (row) {
                    final left = planets[row * 2];
                    final right = row * 2 + 1 < planets.length
                        ? planets[row * 2 + 1]
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPlanetTile(left, theme, cs),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: right != null
                                ? _buildPlanetTile(right, theme, cs)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanetTile(
    CelestialPosition planet,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            _planetGlyph(planet.name),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planet.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${planet.sign.glyph} ${planet.degreeInSign}\u00B0 '
                  '${planet.sign.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              _zodiacAsset(planet.sign),
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                planet.sign.glyph,
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _zodiacAsset(ZodiacSign sign) =>
      'assets/oracle/zodiac_${sign.name}.png';

  String _planetGlyph(String name) {
    return switch (name) {
      'Sun' => '\u2609',
      'Moon' => '\u263D',
      'Mercury' => '\u263F',
      'Venus' => '\u2640',
      'Mars' => '\u2642',
      'Jupiter' => '\u2643',
      'Saturn' => '\u2644',
      'Rahu' => '\u260A',
      _ => '\u2731',
    };
  }
}
