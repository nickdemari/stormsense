import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/core/astro/aspects.dart';
import 'package:storm_sense/core/astro/birth_chart.dart';
import 'package:storm_sense/core/astro/oracle_engine.dart';
import 'package:storm_sense/core/astro/zodiac.dart';
import 'package:storm_sense/features/oracle/bloc/oracle_bloc.dart';
import 'package:storm_sense/features/oracle/view/birth_chart_sheet.dart';
import 'package:storm_sense/features/oracle/view/cosmic_weather_card.dart';
import 'package:storm_sense/features/oracle/view/planetary_grid.dart';

class OraclePage extends StatelessWidget {
  const OraclePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<OracleBloc, OracleState>(
          builder: (context, state) {
            if (state is OracleLoading || state is OracleInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is OracleError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context
                            .read<OracleBloc>()
                            .add(const OracleRefreshed()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is OracleLoaded) {
              final reading = state.reading;
              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<OracleBloc>()
                      .add(const OracleRefreshed());
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(
                      'Oracle',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CosmicBanner(theme: theme),
                    const SizedBox(height: 12),
                    CosmicWeatherCard(reading: reading),
                    const SizedBox(height: 12),
                    PlanetaryGrid(planets: reading.planets),
                    if (reading.aspects.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _AspectCard(
                        aspect: reading.aspects.first,
                        theme: theme,
                      ),
                    ],
                    if (reading.personalTransit != null) ...[
                      const SizedBox(height: 12),
                      _PersonalTransitCard(
                        transit: reading.personalTransit!,
                        theme: theme,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _BirthChartCTA(
                      theme: theme,
                      hasBirthData: reading.birthData != null,
                    ),
                    const SizedBox(height: 12),
                    _MethodologyCard(reading: reading, theme: theme),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _AspectCard extends StatelessWidget {
  const _AspectCard({required this.aspect, required this.theme});

  final Aspect aspect;
  final ThemeData theme;
  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
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
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    size: 18,
                    color: _color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${aspect.body1} ${aspect.type.glyph} ${aspect.body2}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _color,
                        ),
                      ),
                      Text(
                        '${aspect.type.label} \u2014 ${aspect.type.keyword}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodologyCard extends StatelessWidget {
  const _MethodologyCard({required this.reading, required this.theme});

  final OracleReading reading;
  final ThemeData theme;
  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final dimText = cs.onSurfaceVariant.withValues(alpha: 0.7);
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(color: dimText);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    // Compute element breakdown from planets
    final elementCounts = <AstroElement, int>{};
    for (final p in reading.planets) {
      elementCounts[p.element] = (elementCounts[p.element] ?? 0) + 1;
    }
    final total = reading.planets.length;
    final weatherEl = reading.weatherElement;
    final matchCount =
        weatherEl != null ? (elementCounts[weatherEl] ?? 0) : 0;
    final harmonyPct = (reading.elementalHarmony * 100).round();

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
                        Icons.info_outline,
                        size: 18,
                        color: _color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'How It Works',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Step 1
                Text('1. Weather \u2192 Element', style: labelStyle),
                const SizedBox(height: 4),
                Text(
                  'Your sensor data (temperature, pressure, storm level) '
                  'maps to a classical element:',
                  style: bodyStyle,
                ),
                const SizedBox(height: 6),
                _MappingRow(
                  label: 'Stormy / Rain (level 3\u20134)',
                  value: 'Water',
                  style: bodyStyle!,
                  highlight: weatherEl == AstroElement.water,
                ),
                _MappingRow(
                  label: 'Dry + hot >85\u00B0F (level 0)',
                  value: 'Fire',
                  style: bodyStyle,
                  highlight: weatherEl == AstroElement.fire,
                ),
                _MappingRow(
                  label: 'Pressure change (level 2)',
                  value: 'Air',
                  style: bodyStyle,
                  highlight: weatherEl == AstroElement.air,
                ),
                _MappingRow(
                  label: 'Fair / Dry + cool (level 0\u20131)',
                  value: 'Earth',
                  style: bodyStyle,
                  highlight: weatherEl == AstroElement.earth,
                ),
                if (weatherEl != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Current conditions \u2192 ${weatherEl.label}',
                    style: bodyStyle.copyWith(
                      color: _color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Step 2
                Text('2. Planetary Elements', style: labelStyle),
                const SizedBox(height: 4),
                Text(
                  'Each celestial body occupies a zodiac sign, and each '
                  'sign belongs to an element.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 6),
                ...elementCounts.entries.map((e) {
                  final pct = (e.value / total * 100).round();
                  final isMatch = e.key == weatherEl;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            e.key.label,
                            style: bodyStyle.copyWith(
                              color: isMatch ? _color : dimText,
                              fontWeight: isMatch
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: e.value / total,
                              backgroundColor: cs.surfaceContainerHighest,
                              color: isMatch
                                  ? _color
                                  : cs.onSurfaceVariant
                                      .withValues(alpha: 0.3),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${e.value}/$total ($pct%)',
                          style: bodyStyle.copyWith(
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 14),

                // Step 3
                Text('3. Elemental Harmony', style: labelStyle),
                const SizedBox(height: 4),
                Text(
                  'Harmony = fraction of planets sharing your weather '
                  'element. Higher means sky and atmosphere agree.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$matchCount of $total planets in '
                    '${weatherEl?.label ?? "?"} signs = $harmonyPct% harmony',
                    style: bodyStyle.copyWith(
                      color: _color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Step 4
                Text('4. Planetary Aspects', style: labelStyle),
                const SizedBox(height: 4),
                Text(
                  'Angular relationships between planets add nuance:',
                  style: bodyStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  '\u260C Conjunction (0\u00B0) \u00B7 '
                  '\u26B9 Sextile (60\u00B0) \u00B7 '
                  '\u25A1 Square (90\u00B0)\n'
                  '\u25B3 Trine (120\u00B0) \u00B7 '
                  '\u260D Opposition (180\u00B0)',
                  style: bodyStyle.copyWith(letterSpacing: 0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MappingRow extends StatelessWidget {
  const _MappingRow({
    required this.label,
    required this.value,
    required this.style,
    this.highlight = false,
  });

  final String label;
  final String value;
  final TextStyle style;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final activeColor = highlight ? const Color(0xFF818CF8) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlight
                  ? const Color(0xFF818CF8)
                  : Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: style.copyWith(
                color: activeColor ?? style.color,
                fontWeight: highlight ? FontWeight.w500 : null,
              ),
            ),
          ),
          Text(
            value,
            style: style.copyWith(
              color: activeColor ?? style.color,
              fontWeight: highlight ? FontWeight.w500 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalTransitCard extends StatelessWidget {
  const _PersonalTransitCard({
    required this.transit,
    required this.theme,
  });

  final PersonalTransit transit;
  final ThemeData theme;
  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final dimText = cs.onSurfaceVariant.withValues(alpha: 0.7);
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(color: dimText);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final resonance = transit.weatherResonanceCount;
    final total = transit.natalTotal;

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
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                _color.withValues(alpha: 0.6),
                Colors.transparent,
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                        Icons.auto_awesome,
                        size: 18,
                        color: _color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Personal Transit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _color,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Natal Sun & Moon
                Row(
                  children: [
                    _NatalBodyChip(
                      label: 'Sun',
                      sign: transit.natalSun.sign,
                      degree: transit.natalSun.degreeInSign,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _NatalBodyChip(
                      label: 'Moon',
                      sign: transit.natalMoon.sign,
                      degree: transit.natalMoon.degreeInSign,
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Natal element breakdown
                Text('Natal Element Balance', style: labelStyle),
                const SizedBox(height: 6),
                ...transit.natalElementCounts.entries.map((e) {
                  final pct = (e.value / total * 100).round();
                  final isMatch = e.key == transit.weatherElement;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            e.key.label,
                            style: bodyStyle?.copyWith(
                              color: isMatch ? _color : dimText,
                              fontWeight: isMatch
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: e.value / total,
                              backgroundColor: cs.surfaceContainerHighest,
                              color: isMatch
                                  ? _color
                                  : cs.onSurfaceVariant
                                      .withValues(alpha: 0.3),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${e.value}/$total ($pct%)',
                          style: bodyStyle?.copyWith(
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 14),

                // Weather resonance
                Text('Weather Resonance', style: labelStyle),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    resonance >= 3
                        ? 'Strong resonance \u2014 $resonance of $total '
                            'natal placements in '
                            '${transit.weatherElement.label} signs. '
                            'Today\u2019s atmosphere amplifies your chart.'
                        : resonance == 0
                            ? 'No natal placements in '
                                '${transit.weatherElement.label} signs. '
                                'Today\u2019s energy challenges your chart '
                                '\u2014 growth from unfamiliar territory.'
                            : '$resonance of $total natal placements in '
                                '${transit.weatherElement.label} signs. '
                                'Moderate atmospheric alignment.',
                    style: bodyStyle?.copyWith(
                      color: resonance >= 3 ? _color : dimText,
                      height: 1.4,
                    ),
                  ),
                ),

                // Active transits
                if (transit.transitAspects.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('Active Transits', style: labelStyle),
                  const SizedBox(height: 6),
                  ...transit.transitAspects.take(5).map((a) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              a.type.glyph,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${a.body1} \u2192 ${a.body2}',
                                  style: bodyStyle?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Text(
                                  '${a.type.label} '
                                  '(${a.orb.toStringAsFixed(1)}\u00B0 orb) '
                                  '\u2014 ${a.type.keyword}',
                                  style: bodyStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                // Natal placements detail
                const SizedBox(height: 14),
                Text('Natal Placements', style: labelStyle),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: transit.natalPositions.map((p) {
                    final isMatch = p.element == transit.weatherElement;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isMatch
                            ? _color.withValues(alpha: 0.12)
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                        border: isMatch
                            ? Border.all(
                                color: _color.withValues(alpha: 0.3),
                              )
                            : null,
                      ),
                      child: Text(
                        '${p.name} ${p.sign.glyph} ${p.degreeInSign}\u00B0',
                        style: bodyStyle?.copyWith(
                          color: isMatch ? _color : dimText,
                          fontWeight: isMatch
                              ? FontWeight.w500
                              : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NatalBodyChip extends StatelessWidget {
  const _NatalBodyChip({
    required this.label,
    required this.sign,
    required this.degree,
    required this.theme,
  });

  final String label;
  final ZodiacSign sign;
  final int degree;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/oracle/zodiac_${sign.name}.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  sign.glyph,
                  style: TextStyle(fontSize: 20, color: cs.onSurface),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label in ${sign.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$degree\u00B0 ${sign.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthChartCTA extends StatelessWidget {
  const _BirthChartCTA({required this.theme, this.hasBirthData = false});

  final ThemeData theme;
  final bool hasBirthData;
  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: () async {
        // Load existing birth data to pass to sheet
        BirthData? existing;
        if (hasBirthData) {
          final prefs = await SharedPreferences.getInstance();
          existing = await BirthDataStore.load(prefs);
        }
        if (!context.mounted) return;
        await BirthChartSheet.show(context, existingData: existing);
        if (context.mounted) {
          context.read<OracleBloc>().add(const OracleBirthDataChanged());
        }
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
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
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      hasBirthData
                          ? Icons.person
                          : Icons.person_outline,
                      size: 18,
                      color: _color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasBirthData
                              ? 'Edit birth chart'
                              : 'Personalize your readings',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          hasBirthData
                              ? 'Tap to update or clear your birth info'
                              : 'Add your birth info for custom insights',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CosmicBanner extends StatelessWidget {
  const _CosmicBanner({required this.theme});

  final ThemeData theme;
  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Container(
      height: 100,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/oracle/bg_zodiac_wheel.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: cs.surfaceContainer,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  cs.surface.withValues(alpha: 0.85),
                  cs.surface.withValues(alpha: 0.4),
                  cs.surface.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: _color.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Atmospheric Astrology',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _color,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: _color.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
