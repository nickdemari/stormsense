import 'package:flutter_test/flutter_test.dart';
import 'package:storm_sense/core/astro/zodiac.dart';

void main() {
  group('ZodiacSign', () {
    test('has 12 signs', () {
      expect(ZodiacSign.values.length, 12);
    });

    test('aries is first, pisces is last', () {
      expect(ZodiacSign.values.first, ZodiacSign.aries);
      expect(ZodiacSign.values.last, ZodiacSign.pisces);
    });
  });

  group('Element', () {
    test('has 4 elements', () {
      expect(AstroElement.values.length, 4);
    });
  });

  group('ZodiacSign.element', () {
    test('fire signs', () {
      expect(ZodiacSign.aries.element, AstroElement.fire);
      expect(ZodiacSign.leo.element, AstroElement.fire);
      expect(ZodiacSign.sagittarius.element, AstroElement.fire);
    });

    test('earth signs', () {
      expect(ZodiacSign.taurus.element, AstroElement.earth);
      expect(ZodiacSign.virgo.element, AstroElement.earth);
      expect(ZodiacSign.capricorn.element, AstroElement.earth);
    });

    test('air signs', () {
      expect(ZodiacSign.gemini.element, AstroElement.air);
      expect(ZodiacSign.libra.element, AstroElement.air);
      expect(ZodiacSign.aquarius.element, AstroElement.air);
    });

    test('water signs', () {
      expect(ZodiacSign.cancer.element, AstroElement.water);
      expect(ZodiacSign.scorpio.element, AstroElement.water);
      expect(ZodiacSign.pisces.element, AstroElement.water);
    });
  });

  group('signFromLongitude', () {
    test('0 degrees is Aries', () {
      expect(signFromLongitude(0.0), ZodiacSign.aries);
    });

    test('29.99 degrees is still Aries', () {
      expect(signFromLongitude(29.99), ZodiacSign.aries);
    });

    test('30 degrees is Taurus', () {
      expect(signFromLongitude(30.0), ZodiacSign.taurus);
    });

    test('359.99 degrees is Pisces', () {
      expect(signFromLongitude(359.99), ZodiacSign.pisces);
    });

    test('330 degrees is Pisces', () {
      expect(signFromLongitude(330.0), ZodiacSign.pisces);
    });

    test('180 degrees is Libra', () {
      expect(signFromLongitude(180.0), ZodiacSign.libra);
    });

    test('negative wraps around', () {
      expect(signFromLongitude(-10.0), ZodiacSign.pisces);
    });

    test('over 360 wraps around', () {
      expect(signFromLongitude(370.0), ZodiacSign.aries);
    });
  });

  group('degreeInSign', () {
    test('0 longitude is 0 degrees in Aries', () {
      expect(degreeInSign(0.0), 0);
    });

    test('45 longitude is 15 degrees in Taurus', () {
      expect(degreeInSign(45.0), 15);
    });

    test('359.9 is 29 degrees in Pisces', () {
      expect(degreeInSign(359.9), 29);
    });
  });

  group('ZodiacSign.glyph', () {
    test('aries glyph is correct unicode', () {
      expect(ZodiacSign.aries.glyph, '\u2648');
    });

    test('pisces glyph is correct unicode', () {
      expect(ZodiacSign.pisces.glyph, '\u2653');
    });
  });
}
