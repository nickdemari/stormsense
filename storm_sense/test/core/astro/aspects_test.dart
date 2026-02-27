import 'package:flutter_test/flutter_test.dart';
import 'package:storm_sense/core/astro/aspects.dart';

void main() {
  group('AspectType', () {
    test('has 5 major aspects', () {
      expect(AspectType.values.length, 5);
    });
  });

  group('findAspect', () {
    test('0 degree separation is conjunction', () {
      final aspect = findAspect(10.0, 10.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.conjunction);
    });

    test('180 degree separation is opposition', () {
      final aspect = findAspect(0.0, 180.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.opposition);
    });

    test('120 degree separation is trine', () {
      final aspect = findAspect(0.0, 120.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.trine);
    });

    test('90 degree separation is square', () {
      final aspect = findAspect(45.0, 135.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.square);
    });

    test('60 degree separation is sextile', () {
      final aspect = findAspect(0.0, 60.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.sextile);
    });

    test('within orb detects aspect', () {
      final aspect = findAspect(0.0, 7.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.conjunction);
    });

    test('outside orb returns null', () {
      final aspect = findAspect(0.0, 45.0);
      expect(aspect, isNull);
    });

    test('wrapping around 360 degrees works', () {
      final aspect = findAspect(355.0, 2.0);
      expect(aspect, isNotNull);
      expect(aspect!.type, AspectType.conjunction);
    });

    test('aspect has orb value', () {
      final aspect = findAspect(10.0, 13.0);
      expect(aspect, isNotNull);
      expect(aspect!.orb, closeTo(3.0, 0.01));
    });
  });

  group('findAllAspects', () {
    test('finds multiple aspects in a list of longitudes', () {
      final longitudes = {
        'Sun': 0.0,
        'Moon': 120.0,
        'Mars': 180.0,
      };
      final aspects = findAllAspects(longitudes);
      expect(aspects.length, greaterThanOrEqualTo(2));
    });
  });
}
