import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storm_sense/core/astro/aspects.dart';
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
                    const SizedBox(height: 12),
                    _BirthChartCTA(theme: theme),
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

class _BirthChartCTA extends StatelessWidget {
  const _BirthChartCTA({required this.theme});

  final ThemeData theme;
  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: () => BirthChartSheet.show(context),
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
                    child: const Icon(
                      Icons.person_outline,
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
                          'Personalize your readings',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Add your birth info for custom insights',
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
