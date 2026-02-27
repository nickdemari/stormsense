enum AstroElement {
  fire('Fire'),
  earth('Earth'),
  air('Air'),
  water('Water');

  const AstroElement(this.label);
  final String label;
}

enum ZodiacSign {
  aries('Aries', '\u2648', AstroElement.fire),
  taurus('Taurus', '\u2649', AstroElement.earth),
  gemini('Gemini', '\u264A', AstroElement.air),
  cancer('Cancer', '\u264B', AstroElement.water),
  leo('Leo', '\u264C', AstroElement.fire),
  virgo('Virgo', '\u264D', AstroElement.earth),
  libra('Libra', '\u264E', AstroElement.air),
  scorpio('Scorpio', '\u264F', AstroElement.water),
  sagittarius('Sagittarius', '\u2650', AstroElement.fire),
  capricorn('Capricorn', '\u2651', AstroElement.earth),
  aquarius('Aquarius', '\u2652', AstroElement.air),
  pisces('Pisces', '\u2653', AstroElement.water);

  const ZodiacSign(this.label, this.glyph, this.element);

  final String label;
  final String glyph;
  final AstroElement element;
}

ZodiacSign signFromLongitude(double longitude) {
  final normalized = longitude % 360;
  final wrapped = normalized < 0 ? normalized + 360 : normalized;
  final index = wrapped ~/ 30;
  return ZodiacSign.values[index.clamp(0, 11)];
}

int degreeInSign(double longitude) {
  final normalized = longitude % 360;
  final wrapped = normalized < 0 ? normalized + 360 : normalized;
  return (wrapped % 30).floor();
}
