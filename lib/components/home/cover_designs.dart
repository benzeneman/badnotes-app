import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

typedef _CoverPaint = void Function(Canvas canvas, Size size);

/// A notebook cover, drawn in code so it stays crisp at any size and costs
/// nothing in the app's download size.
class CoverDesign {
  const CoverDesign._(
    this.id,
    this.name,
    this.section,
    this._paint, {
    this.label = false,
  });

  /// A plain colored cover, as covers were before there were designs.
  /// Its [id] is the color in ARGB hex, which older versions understand.
  factory CoverDesign.solid(Color color) => CoverDesign._(
    color.toARGB32().toRadixString(16),
    'Color',
    'Solid colors',
    (c, s) => _solid(c, s, color),
    label: true,
  );

  /// What is saved in `<note>.cover`.
  final String id;
  final String name;

  /// Which row of the cover picker it's in.
  final String section;

  /// Whether the notebook's name goes on a label on the cover.
  final bool label;

  final _CoverPaint _paint;

  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paint(canvas, size);
    _binding(canvas, size);
    canvas.restore();
  }

  /// Finds the cover saved as [id], or null if there's no such cover.
  static CoverDesign? fromId(String id) {
    for (final design in [...all, ..._retired]) {
      if (design.id == id) return design;
    }
    final color = int.tryParse(id, radix: 16);
    return color == null ? null : CoverDesign.solid(Color(color));
  }

  /// The plain covers the picker offers: four light, four dark.
  static const solidColors = <Color>[
    Color(0xFFE8E1FB), // lavender
    Color(0xFFFBE3DA), // blush
    Color(0xFFDCEFE9), // mint
    Color(0xFFDCE8FB), // sky
    Color(0xFF1E3A5F), // navy
    Color(0xFF3C3C43), // charcoal
    Color(0xFF2E5E4E), // forest
    Color(0xFF4B3B6E), // plum
  ];

  /// The design's soft cover colours (design/DESIGN.md §2): lavender, blush,
  /// mint, sand, sky, rose and paper white.
  static const pastelColors = <Color>[
    Color(0xFFE8E1FB),
    Color(0xFFFBE3DA),
    Color(0xFFDCEFE9),
    Color(0xFFF7ECCF),
    Color(0xFFDCE8FB),
    Color(0xFFF8DDE6),
    Color(0xFFFFFFFF),
  ];

  /// The covers the picker offers.
  static final List<CoverDesign> all = [
    const CoverDesign._('d:botanical', 'Botanical', 'Simple', _botanical, label: true),
    const CoverDesign._('d:arches', 'Arches', 'Colorful', _arches),
    const CoverDesign._('d:mountains', 'Mountains', 'Colorful', _mountains),
    const CoverDesign._('d:sunrise', 'Sunrise', 'Colorful', _sunrise),
    const CoverDesign._('d:waves2', 'Tide', 'Colorful', _tide),
    const CoverDesign._('d:rose', 'Rose Rings', 'Colorful', _roseRings),
    const CoverDesign._('d:terrazzo', 'Terrazzo', 'Patterns', _terrazzo),
    const CoverDesign._('d:confetti', 'Confetti', 'Patterns', _confetti),
    const CoverDesign._('d:leaves', 'Leaves', 'Patterns', _leaves),
    const CoverDesign._('d:graph', 'Mint Graph', 'Patterns', _graph),
    const CoverDesign._('d:terrazzo2', 'Pastel Terrazzo', 'Patterns', _pastelTerrazzo),
    const CoverDesign._('d:dunes', 'Dunes', 'Colorful', _dunes),
    const CoverDesign._('d:clouds', 'Clouds', 'Colorful', _clouds),
    const CoverDesign._('d:hills', 'Sage Hills', 'Colorful', _sageHills),
    const CoverDesign._('d:moonrise', 'Moonrise', 'Colorful', _moonrise),
    const CoverDesign._('d:window', 'Window', 'Colorful', _window),
    const CoverDesign._('d:pebbles', 'Pebbles', 'Colorful', _pebbles),
    const CoverDesign._('d:tulips', 'Tulips', 'Simple', _tulips),
    const CoverDesign._('d:blossom', 'Blossom', 'Patterns', _blossom),
    const CoverDesign._('d:ribbons', 'Ribbons', 'Patterns', _ribbons),
    for (final color in solidColors) CoverDesign.solid(color),
  ];

  /// Covers no longer offered, still drawn for notebooks that have them
  /// (their ids are saved in `<note>.cover`).
  static final List<CoverDesign> _retired = [
    const CoverDesign._('d:ocean', 'Ocean', 'Simple', _ocean, label: true),
    const CoverDesign._('d:forest', 'Forest', 'Simple', _forest, label: true),
    const CoverDesign._('d:kraft', 'Kraft', 'Simple', _kraft, label: true),
    const CoverDesign._('d:linen', 'Linen', 'Simple', _linen, label: true),
    const CoverDesign._('d:leather', 'Leather', 'Simple', _leather, label: true),
    const CoverDesign._('d:sunset', 'Sunset', 'Colorful', _sunset),
    const CoverDesign._('d:aurora', 'Aurora', 'Colorful', _aurora),
    const CoverDesign._('d:candy', 'Candy', 'Colorful', _candy),
    const CoverDesign._('d:mesh', 'Dream', 'Colorful', _mesh),
    const CoverDesign._('d:citrus', 'Citrus', 'Colorful', _citrus),
    const CoverDesign._('d:bloom', 'Bloom', 'Patterns', _bloom),
    const CoverDesign._('d:polka', 'Polka', 'Patterns', _polka),
    const CoverDesign._('d:waves', 'Waves', 'Patterns', _waves),
    const CoverDesign._('d:memphis', 'Memphis', 'Patterns', _memphis),
    const CoverDesign._('d:honey', 'Honey', 'Patterns', _honey),
    const CoverDesign._('d:galaxy', 'Galaxy', 'Dark', _galaxy),
    const CoverDesign._('d:midnight', 'Midnight Bloom', 'Dark', _midnight),
    const CoverDesign._('d:neon', 'Neon', 'Dark', _neon),
    const CoverDesign._('d:marble', 'Marble', 'Dark', _marble),
    const CoverDesign._('d:peaks', 'Night Peaks', 'Dark', _peaks),
    const CoverDesign._('d:linen2', 'Soft Linen', 'Simple', _softLinen, label: true),
    const CoverDesign._('d:grid', 'Sketch Grid', 'Simple', _sketchGrid, label: true),
    const CoverDesign._('d:bauhaus', 'Bauhaus', 'Colorful', _bauhaus),
    const CoverDesign._('d:blobs', 'Blobs', 'Colorful', _blobs),
    const CoverDesign._('d:charcoal', 'Charcoal', 'Dark', _charcoal, label: true),
    const CoverDesign._('d:night', 'Night', 'Dark', _night, label: true),
  ];

  /// [all], by [section], in order.
  static Map<String, List<CoverDesign>> get sections {
    final sections = <String, List<CoverDesign>>{};
    for (final design in all) {
      (sections[design.section] ??= []).add(design);
    }
    return sections;
  }

  static CoverDesign get standard => fromId('d:terrazzo2')!;

  @override
  bool operator ==(Object other) => other is CoverDesign && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// --- helpers ---------------------------------------------------------------

const _tau = math.pi * 2;

Paint _fillPaint(Color color) => Paint()
  ..color = color
  ..isAntiAlias = true;

Paint _strokePaint(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

void _gradient(
  Canvas c,
  Size s,
  List<Color> colors, {
  Alignment begin = Alignment.topCenter,
  Alignment end = Alignment.bottomCenter,
  List<double>? stops,
}) {
  final rect = Offset.zero & s;
  c.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
        stops: stops,
      ).createShader(rect),
  );
}

/// A soft round glow of [color] fading out to nothing.
void _glow(Canvas c, Offset center, double radius, Color color) {
  final rect = Rect.fromCircle(center: center, radius: radius);
  c.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(rect),
  );
}

/// The shade of the spine and a little sheen, so every cover reads as a book.
void _binding(Canvas c, Size s) {
  final w = s.width;
  final spine = Rect.fromLTWH(0, 0, w * 0.075, s.height);
  c.drawRect(
    spine,
    Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x47000000), Color(0x14000000), Color(0x00000000)],
      ).createShader(spine),
  );
  c.drawLine(
    Offset(w * 0.075, 0),
    Offset(w * 0.075, s.height),
    Paint()
      ..color = const Color(0x26FFFFFF)
      ..strokeWidth = math.max(1, w * 0.006),
  );
  final all = Offset.zero & s;
  c.drawRect(
    all,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF), Color(0x12000000)],
        stops: [0, 0.45, 1],
      ).createShader(all),
  );
}

/// An elastic band down the right side.
void _band(Canvas c, Size s, Color color) {
  final x = s.width * 0.82;
  c.drawRect(Rect.fromLTWH(x, 0, s.width * 0.045, s.height), _fillPaint(color));
  c.drawRect(
    Rect.fromLTWH(x, 0, s.width * 0.012, s.height),
    _fillPaint(const Color(0x33000000)),
  );
}

/// A dashed stitched border [inset] in from the edges.
void _stitches(Canvas c, Size s, double inset, Color color) {
  final u = s.width / 100;
  final paint = _strokePaint(color, u * 0.7);
  final dash = u * 2.4, gap = u * 1.6;
  void along(Offset from, Offset to) {
    final length = (to - from).distance;
    final step = (to - from) / length;
    for (var d = 0.0; d < length; d += dash + gap) {
      c.drawLine(from + step * d, from + step * math.min(d + dash, length), paint);
    }
  }

  final l = inset + s.width * 0.075, t = inset;
  final r = s.width - inset, b = s.height - inset;
  along(Offset(l, t), Offset(r, t));
  along(Offset(r, t), Offset(r, b));
  along(Offset(r, b), Offset(l, b));
  along(Offset(l, b), Offset(l, t));
}

/// A flower of [petals] round petals.
void _flower(
  Canvas c,
  Offset center,
  double r,
  Color petal,
  Color middle, {
  int petals = 5,
  double turn = 0,
}) {
  final paint = _fillPaint(petal);
  c.save();
  c.translate(center.dx, center.dy);
  c.rotate(turn);
  for (var i = 0; i < petals; i++) {
    c.save();
    c.rotate(i * _tau / petals);
    c.drawOval(
      Rect.fromCenter(center: Offset(0, -r * 0.52), width: r * 0.62, height: r * 1.04),
      paint,
    );
    c.restore();
  }
  c.drawCircle(Offset.zero, r * 0.3, _fillPaint(middle));
  c.drawCircle(
    Offset(-r * 0.08, -r * 0.08),
    r * 0.1,
    _fillPaint(Colors.white.withValues(alpha: 0.45)),
  );
  c.restore();
}

/// A pointed leaf [length] long, along [turn].
void _leaf(Canvas c, Offset base, double length, double turn, Color color) {
  c.save();
  c.translate(base.dx, base.dy);
  c.rotate(turn);
  final half = length * 0.28;
  final path = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(half, -length * 0.5, 0, -length)
    ..quadraticBezierTo(-half, -length * 0.5, 0, 0);
  c.drawPath(path, _fillPaint(color));
  c.drawLine(
    Offset.zero,
    Offset(0, -length * 0.9),
    _strokePaint(const Color(0x40FFFFFF), length * 0.03),
  );
  c.restore();
}

// --- simple ----------------------------------------------------------------

void _solid(Canvas c, Size s, Color color) {
  _gradient(
    c,
    s,
    [color, Color.lerp(color, Colors.black, 0.14)!],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

void _ocean(Canvas c, Size s) {
  _gradient(c, s, const [Color(0xFF45C3F7), Color(0xFF1A8BE0)]);
  _band(c, s, const Color(0xFF0D64AA));
}

void _forest(Canvas c, Size s) {
  _gradient(c, s, const [Color(0xFF34A06E), Color(0xFF1B6545)]);
  _band(c, s, const Color(0xFF0F4430));
}

void _kraft(Canvas c, Size s) {
  final u = s.width / 100;
  _gradient(c, s, const [Color(0xFFD2AE82), Color(0xFFB38657)]);
  // paper fibres
  final random = math.Random(7);
  final fibre = _strokePaint(const Color(0x1A5B3A1A), u * 0.35);
  for (var i = 0; i < 70; i++) {
    final x = random.nextDouble() * s.width, y = random.nextDouble() * s.height;
    final a = random.nextDouble() * math.pi;
    final l = u * (1 + random.nextDouble() * 3);
    c.drawLine(Offset(x, y), Offset(x + math.cos(a) * l, y + math.sin(a) * l), fibre);
  }
  _stitches(c, s, u * 6, const Color(0xCCFFF3E0));
}

void _linen(Canvas c, Size s) {
  final u = s.width / 100;
  c.drawRect(Offset.zero & s, _fillPaint(const Color(0xFFF4EFE6)));
  final thread = _strokePaint(const Color(0x10000000), u * 0.3);
  for (var y = 0.0; y < s.height; y += u * 1.6) {
    c.drawLine(Offset(0, y), Offset(s.width, y), thread);
  }
  for (var x = 0.0; x < s.width; x += u * 1.6) {
    c.drawLine(Offset(x, 0), Offset(x, s.height), thread);
  }
  // a ribbon bookmark hanging from the top
  final ribbon = Path()
    ..moveTo(u * 70, 0)
    ..lineTo(u * 77, 0)
    ..lineTo(u * 77, s.height * 0.2)
    ..lineTo(u * 73.5, s.height * 0.175)
    ..lineTo(u * 70, s.height * 0.2)
    ..close();
  c.drawPath(ribbon, _fillPaint(const Color(0xFFD64545)));
}

void _leather(Canvas c, Size s) {
  final u = s.width / 100;
  _gradient(c, s, const [Color(0xFF3B3B41), Color(0xFF232327)]);
  final random = math.Random(3);
  final grain = _fillPaint(const Color(0x0DFFFFFF));
  for (var i = 0; i < 260; i++) {
    c.drawCircle(
      Offset(random.nextDouble() * s.width, random.nextDouble() * s.height),
      u * (0.2 + random.nextDouble() * 0.5),
      grain,
    );
  }
  _stitches(c, s, u * 5, const Color(0x66FFFFFF));
  // brass corners
  final brass = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFFE9C46A), Color(0xFFA67C2E)],
    ).createShader(Offset.zero & s);
  final k = u * 16;
  c.drawPath(
    Path()
      ..moveTo(s.width - k, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width, k)
      ..close(),
    brass,
  );
  c.drawPath(
    Path()
      ..moveTo(s.width - k, s.height)
      ..lineTo(s.width, s.height)
      ..lineTo(s.width, s.height - k)
      ..close(),
    brass,
  );
}

// --- colorful --------------------------------------------------------------

void _sunset(Canvas c, Size s) {
  final u = s.width / 100, h = s.height;
  _gradient(
    c,
    s,
    const [Color(0xFF2B1055), Color(0xFFB0357F), Color(0xFFFF8E53)],
    stops: const [0, 0.5, 0.78],
  );
  final sun = Offset(u * 54, h * 0.6);
  final sunRadius = u * 30;
  c.saveLayer(Offset.zero & s, Paint());
  c.drawCircle(
    sun,
    sunRadius,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE66D), Color(0xFFFF6B6B)],
      ).createShader(Rect.fromCircle(center: sun, radius: sunRadius)),
  );
  // retro cuts across the lower half of the sun
  final cut = Paint()..blendMode = BlendMode.dstOut;
  var y = sun.dy;
  for (var i = 1; i <= 6; i++) {
    final thickness = u * 0.7 * i;
    c.drawRect(Rect.fromLTWH(0, y, s.width, thickness), cut);
    y += thickness + u * 3.2;
  }
  c.restore();
  // the sea
  final sea = Rect.fromLTWH(0, h * 0.8, s.width, h * 0.2);
  c.drawRect(
    sea,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3A1462), Color(0xFF14062B)],
      ).createShader(sea),
  );
  final shine = _strokePaint(const Color(0x88FFB37B), u * 0.9);
  for (var i = 0; i < 5; i++) {
    final yy = h * 0.83 + i * u * 4;
    final half = u * (22 - i * 3.5);
    c.drawLine(Offset(sun.dx - half, yy), Offset(sun.dx + half, yy), shine);
  }
}

void _aurora(Canvas c, Size s) {
  final u = s.width / 100, h = s.height;
  _gradient(c, s, const [Color(0xFF07152E), Color(0xFF0C3346)]);
  final random = math.Random(11);
  final star = _fillPaint(const Color(0xAAFFFFFF));
  for (var i = 0; i < 40; i++) {
    c.drawCircle(
      Offset(random.nextDouble() * s.width, random.nextDouble() * h * 0.6),
      u * (0.25 + random.nextDouble() * 0.45),
      star,
    );
  }
  void ribbon(double y, double sway, Color color) {
    final path = Path()
      ..moveTo(-u * 10, y)
      ..cubicTo(u * 25, y - sway, u * 60, y + sway, u * 110, y - sway * 0.6)
      ..lineTo(u * 110, y - sway * 0.6 + u * 14)
      ..cubicTo(u * 60, y + sway + u * 14, u * 25, y - sway + u * 18, -u * 10, y + u * 16)
      ..close();
    c.drawPath(
      path,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 4),
    );
  }

  ribbon(h * 0.22, u * 14, const Color(0x8833C9FF));
  ribbon(h * 0.36, u * 18, const Color(0x993CF2A5));
  ribbon(h * 0.5, u * 12, const Color(0x77B06CFF));
  // a hill line at the bottom
  c.drawPath(
    Path()
      ..moveTo(0, h * 0.86)
      ..quadraticBezierTo(u * 40, h * 0.78, s.width, h * 0.88)
      ..lineTo(s.width, h)
      ..lineTo(0, h)
      ..close(),
    _fillPaint(const Color(0xFF041019)),
  );
}

void _candy(Canvas c, Size s) {
  final u = s.width / 100;
  const colors = [
    Color(0xFFFF6F91),
    Color(0xFFFFC75F),
    Color(0xFFF9F871),
    Color(0xFF00C9A7),
    Color(0xFF4D8AF0),
    Color(0xFF9B5DE5),
  ];
  c.save();
  c.translate(s.width / 2, s.height / 2);
  c.rotate(-math.pi / 4);
  final reach = s.height * 1.2;
  var i = 0;
  for (var x = -reach; x < reach; x += u * 9) {
    c.drawRect(
      Rect.fromLTWH(x, -reach, u * 9, reach * 2),
      _fillPaint(colors[i++ % colors.length]),
    );
  }
  c.restore();
}

void _mesh(Canvas c, Size s) {
  final u = s.width / 100, h = s.height;
  c.drawRect(Offset.zero & s, _fillPaint(const Color(0xFFFFE6F2)));
  _glow(c, Offset(u * 15, h * 0.18), u * 75, const Color(0xFFFF6FB5));
  _glow(c, Offset(u * 95, h * 0.32), u * 70, const Color(0xFF6FA8FF));
  _glow(c, Offset(u * 35, h * 0.78), u * 80, const Color(0xFFFFD36F));
  _glow(c, Offset(u * 95, h * 0.95), u * 60, const Color(0xFF9B6FFF));
  // a few sparkles
  final sparkle = _fillPaint(const Color(0xCCFFFFFF));
  for (final (x, y, r) in const [(70.0, 0.15, 2.4), (25.0, 0.5, 1.6), (80.0, 0.68, 2.0)]) {
    final center = Offset(u * x, h * y);
    final k = u * r;
    c.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - k * 2)
        ..quadraticBezierTo(center.dx, center.dy, center.dx + k * 2, center.dy)
        ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + k * 2)
        ..quadraticBezierTo(center.dx, center.dy, center.dx - k * 2, center.dy)
        ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - k * 2),
      sparkle,
    );
  }
}

void _citrus(Canvas c, Size s) {
  final u = s.width / 100, h = s.height;
  _gradient(c, s, const [Color(0xFFFFE680), Color(0xFFFFC93C)]);
  void slice(Offset center, double r, Color rind, Color flesh) {
    c.drawCircle(center, r, _fillPaint(rind));
    c.drawCircle(center, r * 0.88, _fillPaint(const Color(0xFFFFFBEA)));
    c.drawCircle(center, r * 0.8, _fillPaint(flesh));
    final pith = _strokePaint(const Color(0xFFFFFBEA), r * 0.06);
    for (var i = 0; i < 9; i++) {
      final a = i * _tau / 9;
      c.drawLine(center, center + Offset(math.cos(a), math.sin(a)) * r * 0.8, pith);
    }
    c.drawCircle(center, r * 0.1, _fillPaint(const Color(0xFFFFFBEA)));
  }

  const orange = (Color(0xFFFF8C1A), Color(0xFFFFB04A));
  const lime = (Color(0xFF4FA83A), Color(0xFFA8E063));
  const grapefruit = (Color(0xFFE8505B), Color(0xFFFF8A80));
  for (final (x, y, r, kind) in [
    (18.0, 0.12, 20.0, orange),
    (82.0, 0.26, 16.0, lime),
    (40.0, 0.44, 13.0, grapefruit),
    (90.0, 0.6, 22.0, orange),
    (16.0, 0.72, 17.0, lime),
    (58.0, 0.9, 19.0, grapefruit),
  ]) {
    final center = Offset(u * x, h * y);
    _leaf(c, center + Offset(u * r * 0.3, -u * r * 0.7), u * r * 0.9, 0.7, const Color(0xFF3E8E41));
    slice(center, u * r, kind.$1, kind.$2);
  }
}

void _arches(Canvas c, Size s) {
  final u = s.width / 100, h = s.height;
  c.drawRect(Offset.zero & s, _fillPaint(const Color(0xFFF7DCCB)));
  c.drawCircle(Offset(u * 76, h * 0.2), u * 10, _fillPaint(const Color(0xFFF28F3B)));
  const colors = [
    Color(0xFFC8553D),
    Color(0xFFF28F3B),
    Color(0xFFF6BD60),
    Color(0xFF84A98C),
    Color(0xFF52796F),
  ];
  final center = Offset(u * 50, h * 0.96);
  for (var i = 0; i < colors.length; i++) {
    final r = u * (46 - i * 8.5);
    c.drawArc(
      Rect.fromCircle(center: center, radius: r),
      math.pi,
      math.pi,
      false,
      _strokePaint(colors[i], u * 7)..strokeCap = StrokeCap.butt,
    );
  }
  final dot = _fillPaint(const Color(0x66C8553D));
  final random = math.Random(5);
  for (var i = 0; i < 24; i++) {
    c.drawCircle(
      Offset(u * (10 + random.nextDouble() * 85), h * (0.05 + random.nextDouble() * 0.38)),
      u * 0.9,
      dot,
    );
  }
}

// --- patterns --------------------------------------------------------------

void _bloom(Canvas c, Size s) {
  final u = s.width / 100, h = s.height;
  c.drawRect(Offset.zero & s, _fillPaint(const Color(0xFFFFF7EA)));
  const petals = [
    Color(0xFFFF7A90),
    Color(0xFFFFB347),
    Color(0xFF7EC8E3),
    Color(0xFFB388EB),
    Color(0xFFFF6F61),
    Color(0xFFFFD23F),
  ];
  final random = math.Random(42);
  final rows = (h / (u * 22)).ceil() + 1;
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < 5; col++) {
      final x = u * (col * 24 + (row.isOdd ? 12 : 0) + random.nextDouble() * 8 - 4);
      final y = row * u * 22 + random.nextDouble() * u * 8 - u * 4;
      final r = u * (7 + random.nextDouble() * 5);
      final turn = random.nextDouble() * _tau;
      final base = Offset(x, y);
      _leaf(c, base, r * 1.5, turn, const Color(0xFF4CAF7A));
      _leaf(c, base, r * 1.3, turn + 2.4, const Color(0xFF2E8B57));
      final petal = petals[random.nextInt(petals.length)];
      _flower(
        c,
        base,
        r,
        petal,
        petal == const Color(0xFFFFD23F) ? const Color(0xFFE85D04) : const Color(0xFFFFD23F),
        petals: 5 + random.nextInt(3),
        turn: turn,
      );
    }
  }
}

void _terrazzo(Canvas c, Size s) {
  final u = s.width / 100;
  c.drawRect(Offset.zero & s, _fillPaint(const Color(0xFFF3EDE5)));
  const colors = [
    Color(0xFFE76F51),
    Color(0xFF2A9D8F),
    Color(0xFFF4A261),
    Color(0xFF264653),
    Color(0xFFE9C46A),
    Color(0xFFD8A7B1),
  ];
  final random = math.Random(9);
  final count = (s.height / s.width * 55).round();
  for (var i = 0; i < count; i++) {
    final center = Offset(random.nextDouble() * s.width, random.nextDouble() * s.height);
    final sides = 4 + random.nextInt(3);
    final r = u * (1.4 + random.nextDouble() * 3.6);
    final path = Path();
    for (var k = 0; k < sides; k++) {
      final a = k * _tau / sides + random.nextDouble() * 0.8;
      final d = r * (0.6 + random.nextDouble() * 0.5);
      final p = center + Offset(math.cos(a), math.sin(a)) * d;
      if (k == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    c.drawPath(path, _fillPaint(colors[random.nextInt(colors.length)]));
  }
}

void _confetti(Canvas c, Size s) {
  final u = s.width / 100;
  c.drawRect(Offset.zero & s, _fillPaint(const Color(0xFFF6F8FF)));
  const colors = [
    Color(0xFF5B8DEF),
    Color(0xFFFF7EB6),
    Color(0xFFFFC542),
    Color(0xFF3DD9B3),
    Color(0xFFA78BFA),
  ];
  final random = math.Random(21);
  final count = (s.height / s.width * 42).round();
  for (var i = 0; i < count; i++) {
    final p = Offset(random.nextDouble() * s.width, random.nextDouble() * s.height);
    final a = random.nextDouble() * math.pi;
    final l = u * (5 + random.nextDouble() * 6);
    final paint = _strokePaint(colors[random.nextInt(colors.length)], u * 2.2);
    if (random.nextInt(4) == 0) {
      c.drawCircle(p, u * 1.6, paint..style = PaintingStyle.fill);
    } else {
      c.drawLine(p, p + Offset(math.cos(a), math.sin(a)) * l, paint);
    }
  }
}

void _polka(Canvas c, Size s) {
  final u = s.width / 100;
  _gradient(c, s, const [Color(0xFFF2557A), Color(0xFFD62850)]);
  final dot = _fillPaint(const Color(0xF2FFF4F6));
  var row = 0;
  for (var y = u * 4; y < s.height + u * 6; y += u * 10, row++) {
    for (var x = row.isOdd ? u * 10 : u * 4; x < s.width + u * 6; x += u * 12) {
      c.drawCircle(Offset(x, y), u * 2.6, dot);
    }
  }
}

void _waves(Canvas c, Size s) {
  final u = s.width / 100;
  final r = u * 11;
  const bg = Color(0xFF15325E);
  c.drawRect(Offset.zero & s, _fillPaint(bg));
  final fill = _fillPaint(bg);
  final lines = [
    _strokePaint(const Color(0xFFFFFFFF), u * 0.9),
    _strokePaint(const Color(0xFF7FB3E6), u * 0.9),
    _strokePaint(const Color(0xFF4B86C5), u * 0.9),
  ];
  var row = 0;
  for (var y = 0.0; y < s.height + r * 2; y += r * 0.5, row++) {
    for (var x = row.isOdd ? r : 0.0; x < s.width + r * 2; x += r * 2) {
      final center = Offset(x, y);
      c.drawCircle(center, r, fill);
      for (var k = 0; k < 3; k++) {
        c.drawCircle(center, r * (0.95 - k * 0.28), lines[k]);
      }
    }
  }
}

void _memphis(Canvas c, Size s) {
  final u = s.width / 100;
  c.drawRect(Offset.zero & s, _fillPaint(const Color(0xFFFFD93D)));
  const ink = Color(0xFF2D3047);
  final random = math.Random(13);
  final count = (s.height / s.width * 18).round();
  for (var i = 0; i < count; i++) {
    final p = Offset(random.nextDouble() * s.width, random.nextDouble() * s.height);
    final size = u * (4 + random.nextDouble() * 5);
    switch (i % 5) {
      case 0: // zigzag
        final path = Path()..moveTo(p.dx, p.dy);
        for (var k = 1; k <= 4; k++) {
          path.lineTo(p.dx + k * size * 0.5, p.dy + (k.isOdd ? -size * 0.5 : 0));
        }
        c.drawPath(path, _strokePaint(ink, u * 1.4));
      case 1:
        c.drawCircle(p, size * 0.6, _fillPaint(const Color(0xFFFF6B6B)));
      case 2:
        c.drawCircle(p, size * 0.55, _strokePaint(const Color(0xFF2BB5A8), u * 1.4));
      case 3:
        c.drawPath(
          Path()
            ..moveTo(p.dx, p.dy - size * 0.6)
            ..lineTo(p.dx + size * 0.6, p.dy + size * 0.5)
            ..lineTo(p.dx - size * 0.6, p.dy + size * 0.5)
            ..close(),
          _fillPaint(const Color(0xFF6A4C93)),
        );
      default: // squiggle
        final path = Path()..moveTo(p.dx, p.dy);
        path.cubicTo(
          p.dx + size * 0.4, p.dy - size * 0.6,
          p.dx + size * 0.8, p.dy + size * 0.6,
          p.dx + size * 1.4, p.dy,
        );
        c.drawPath(path, _strokePaint(const Color(0xFF3A86FF), u * 1.4));
    }
  }
  final dot = _fillPaint(ink);
  for (var i = 0; i < count * 2; i++) {
    c.drawCircle(
      Offset(random.nextDouble() * s.width, random.nextDouble() * s.height),
      u * 0.8,
      dot,
    );
  }
}

void _honey(Canvas c, Size s) {
  final u = s.width / 100;
  _gradient(c, s, const [Color(0xFFFFBF3C), Color(0xFFFF8F00)]);
  final r = u * 8;
  final w = math.sqrt(3) * r;
  final line = _strokePaint(const Color(0x66FFFFFF), u * 0.9);
  final filled = _fillPaint(const Color(0x33FFFFFF));
  final random = math.Random(17);
  var row = 0;
  for (var y = 0.0; y < s.height + r; y += r * 1.5, row++) {
    for (var x = row.isOdd ? w / 2 : 0.0; x < s.width + w; x += w) {
      final path = Path();
      for (var k = 0; k < 6; k++) {
        final a = math.pi / 6 + k * math.pi / 3;
        final p = Offset(x + math.cos(a) * r, y + math.sin(a) * r);
        if (k == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      }
      path.close();
      if (random.nextInt(5) == 0) c.drawPath(path, filled);
      c.drawPath(path, line);
    }
  }
}

void _leaves(Canvas c, Size s) {
  final u = s.width / 100;
  c.drawRect(Offset.zero & s, _fillPaint(const Color(0xFF1C4A37)));
  const colors = [
    Color(0xFF2E7D57),
    Color(0xFF3FA66B),
    Color(0xFF7BC67E),
    Color(0xFFB5E48C),
    Color(0xFF145C3F),
  ];
  final random = math.Random(31);
  final count = (s.height / s.width * 30).round();
  for (var i = 0; i < count; i++) {
    _leaf(
      c,
      Offset(random.nextDouble() * s.width, random.nextDouble() * s.height * 1.1),
      u * (14 + random.nextDouble() * 14),
      random.nextDouble() * _tau,
      colors[random.nextInt(colors.length)],
    );
  }
}

void _graph(Canvas c, Size s) {
  final u = s.width / 100;
  c.drawRect(Offset.zero & s, _fillPaint(const Color(0xFFB9F0D3)));
  final line = _strokePaint(const Color(0x8CFFFFFF), u * 0.4);
  for (var x = u * 6; x < s.width; x += u * 6) {
    c.drawLine(Offset(x, 0), Offset(x, s.height), line);
  }
  for (var y = u * 6; y < s.height; y += u * 6) {
    c.drawLine(Offset(0, y), Offset(s.width, y), line);
  }
  const ink = Color(0xFF1B4D3E);
  final pen = _strokePaint(ink, u * 1.2);
  // a star
  final star = Path();
  final sc = Offset(u * 30, s.height * 0.2);
  for (var k = 0; k < 10; k++) {
    final a = -math.pi / 2 + k * math.pi / 5;
    final d = k.isEven ? u * 9 : u * 4;
    final p = sc + Offset(math.cos(a), math.sin(a)) * d;
    if (k == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
  }
  c.drawPath(star..close(), pen);
  // a heart
  final hc = Offset(u * 72, s.height * 0.46);
  c.drawPath(
    Path()
      ..moveTo(hc.dx, hc.dy + u * 8)
      ..cubicTo(hc.dx - u * 14, hc.dy - u * 2, hc.dx - u * 6, hc.dy - u * 12, hc.dx, hc.dy - u * 4)
      ..cubicTo(hc.dx + u * 6, hc.dy - u * 12, hc.dx + u * 14, hc.dy - u * 2, hc.dx, hc.dy + u * 8),
    _fillPaint(const Color(0xFFFF7B9C)),
  );
  // a spiral
  final spiral = Path();
  final pc = Offset(u * 34, s.height * 0.74);
  for (var a = 0.0; a < _tau * 2.6; a += 0.2) {
    final p = pc + Offset(math.cos(a), math.sin(a)) * (u * 0.9 * a);
    if (a == 0) {
        spiral.moveTo(p.dx, p.dy);
      } else {
        spiral.lineTo(p.dx, p.dy);
      }
  }
  c.drawPath(spiral, pen);
  // an underline squiggle
  final squiggle = Path()..moveTo(u * 60, s.height * 0.86);
  for (var k = 0; k < 4; k++) {
    final x = u * (60 + k * 7);
    squiggle.quadraticBezierTo(x + u * 3.5, s.height * 0.86 + (k.isEven ? -u * 3 : u * 3), x + u * 7, s.height * 0.86);
  }
  c.drawPath(squiggle, pen);
}

// --- dark ------------------------------------------------------------------

void _galaxy(Canvas c, Size s) {
  final u = s.width / 100, h = s.height;
  _gradient(c, s, const [Color(0xFF0B0A2A), Color(0xFF2A1458), Color(0xFF4B1D6B)]);
  _glow(c, Offset(u * 20, h * 0.7), u * 55, const Color(0x55FF4FA3));
  _glow(c, Offset(u * 85, h * 0.55), u * 45, const Color(0x4433D6FF));
  final random = math.Random(2);
  for (var i = 0; i < 110; i++) {
    c.drawCircle(
      Offset(random.nextDouble() * s.width, random.nextDouble() * h),
      u * (0.15 + random.nextDouble() * 0.55),
      _fillPaint(Colors.white.withValues(alpha: 0.3 + random.nextDouble() * 0.7)),
    );
  }
  final planet = Offset(u * 64, h * 0.3);
  final r = u * 14;
  final ring = _strokePaint(const Color(0xCCFFE1B0), u * 1.6);
  final ringRect = Rect.fromCenter(center: Offset.zero, width: r * 3.4, height: r * 0.9);
  c.save();
  c.translate(planet.dx, planet.dy);
  c.rotate(-0.35);
  c.drawArc(ringRect, math.pi, math.pi, false, ring);
  c.restore();
  c.drawCircle(
    planet,
    r,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFC27A), Color(0xFFE8577E), Color(0xFF6B2A7A)],
      ).createShader(Rect.fromCircle(center: planet, radius: r)),
  );
  c.save();
  c.translate(planet.dx, planet.dy);
  c.rotate(-0.35);
  c.drawArc(ringRect, 0, math.pi, false, ring);
  c.restore();
}

void _midnight(Canvas c, Size s) {
  final u = s.width / 100, h = s.height;
  c.drawRect(Offset.zero & s, _fillPaint(const Color(0xFF141416)));
  final random = math.Random(8);
  for (var i = 0; i < 9; i++) {
    final center = Offset(
      u * (i * 13 + random.nextDouble() * 6),
      h * (0.68 + random.nextDouble() * 0.3),
    );
    _flower(
      c,
      center,
      u * (10 + random.nextDouble() * 6),
      const Color(0xFFF4F4F6),
      const Color(0xFF3AB0FF),
      petals: 6,
      turn: random.nextDouble(),
    );
  }
  final dot = _fillPaint(const Color(0xFF3AB0FF));
  for (var i = 0; i < 14; i++) {
    c.drawCircle(
      Offset(random.nextDouble() * s.width, h * (0.55 + random.nextDouble() * 0.12)),
      u * 0.9,
      dot,
    );
  }
}

void _neon(Canvas c, Size s) {
  final u = s.width / 100, h = s.height;
  _gradient(c, s, const [Color(0xFF0D0221), Color(0xFF1B0B45)]);
  void neon(Path path, Color color) {
    c.drawPath(
      path,
      _strokePaint(color.withValues(alpha: 0.6), u * 3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 1.6),
    );
    c.drawPath(path, _strokePaint(Color.lerp(color, Colors.white, 0.35)!, u * 0.9));
  }

  // a synthwave floor
  final horizon = h * 0.66;
  final floor = _strokePaint(const Color(0x99B14CFF), u * 0.5);
  for (var k = -6; k <= 6; k++) {
    c.drawLine(Offset(u * 50 + k * u * 4, horizon), Offset(u * 50 + k * u * 26, h), floor);
  }
  for (var k = 0; k < 7; k++) {
    final y = horizon + (h - horizon) * math.pow(k / 6, 1.7);
    c.drawLine(Offset(0, y), Offset(s.width, y), floor);
  }
  neon(
    Path()..addOval(Rect.fromCircle(center: Offset(u * 50, h * 0.42), radius: u * 22)),
    const Color(0xFFFF2E97),
  );
  neon(
    Path()
      ..moveTo(u * 26, h * 0.3)
      ..lineTo(u * 40, h * 0.12)
      ..lineTo(u * 54, h * 0.3)
      ..close(),
    const Color(0xFF00F0FF),
  );
  final zig = Path()..moveTo(u * 58, h * 0.16);
  for (var k = 1; k <= 5; k++) {
    zig.lineTo(u * (58 + k * 6), h * 0.16 + (k.isOdd ? u * 6 : 0));
  }
  neon(zig, const Color(0xFFFFE600));
}

void _marble(Canvas c, Size s) {
  final u = s.width / 100, h = s.height;
  _gradient(
    c,
    s,
    const [Color(0xFF222225), Color(0xFF0E0E10)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  final random = math.Random(4);
  for (var i = 0; i < 7; i++) {
    final y = h * random.nextDouble();
    final path = Path()..moveTo(-u * 5, y);
    var x = -u * 5, yy = y;
    while (x < s.width + u * 10) {
      final nx = x + u * (12 + random.nextDouble() * 16);
      final ny = yy + u * (random.nextDouble() * 26 - 10);
      path.quadraticBezierTo((x + nx) / 2 + u * 4, yy + u * (random.nextDouble() * 12 - 6), nx, ny);
      x = nx;
      yy = ny;
    }
    final gold = i.isEven;
    if (gold) {
      c.drawPath(
        path,
        _strokePaint(const Color(0x55D4AF37), u * 2.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 1.2),
      );
    }
    c.drawPath(
      path,
      _strokePaint(
        gold ? const Color(0xFFE6C463) : const Color(0x40FFFFFF),
        u * (gold ? 0.7 : 0.4) + u * random.nextDouble() * 0.5,
      ),
    );
  }
}

void _peaks(Canvas c, Size s) {
  final u = s.width / 100, h = s.height;
  _gradient(c, s, const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]);
  final random = math.Random(6);
  for (var i = 0; i < 50; i++) {
    c.drawCircle(
      Offset(random.nextDouble() * s.width, random.nextDouble() * h * 0.5),
      u * (0.2 + random.nextDouble() * 0.4),
      _fillPaint(const Color(0xBBFFFFFF)),
    );
  }
  final moon = Offset(u * 72, h * 0.2);
  _glow(c, moon, u * 22, const Color(0x55FFF4D6));
  c.drawCircle(moon, u * 8, _fillPaint(const Color(0xFFFFF4D6)));
  void range(double base, double jag, Color color, int seed) {
    final random = math.Random(seed);
    final path = Path()..moveTo(0, h);
    path.lineTo(0, base);
    var x = 0.0;
    while (x < s.width) {
      final peak = x + u * (8 + random.nextDouble() * 10);
      final next = peak + u * (8 + random.nextDouble() * 10);
      path.lineTo(peak, base - u * jag * (0.4 + random.nextDouble() * 0.8));
      path.lineTo(next, base - u * random.nextDouble() * 4);
      x = next;
    }
    path
      ..lineTo(s.width, h)
      ..close();
    c.drawPath(path, _fillPaint(color));
  }

  range(h * 0.58, 22, const Color(0xFF3E5C76), 1);
  range(h * 0.7, 18, const Color(0xFF2B4257), 2);
  range(h * 0.84, 14, const Color(0xFF16232F), 3);
}

// --- pastel (the "Minimal" design's extra covers, design/covers/*.svg) ------
// Drawn on a 300 × 400 board scaled to cover the size, like the SVGs'
// "xMidYMid slice".

/// Runs [draw] on the 300 × 400 board, scaled and centred to fill [s].
void _board(Canvas c, Size s, Color background, void Function(Canvas) draw) {
  c.drawRect(Offset.zero & s, _fillPaint(background));
  final scale = math.max(s.width / 300, s.height / 400);
  c.save();
  c.translate((s.width - 300 * scale) / 2, (s.height - 400 * scale) / 2);
  c.scale(scale);
  draw(c);
  c.restore();
}

final _svgPaths = <String, Path>{};
Path _svg(String data) => _svgPaths[data] ??= parseSvgPathData(data);

void _mountains(Canvas c, Size s) =>
    _board(c, s, const Color(0xFFE8E1FB), (c) {
      c.drawCircle(
        const Offset(210, 120),
        34,
        _fillPaint(const Color(0xFFFFF1C9)),
      );
      c.drawPath(
        _svg('M0 300l80-110 60 70 50-60 110 130v70H0z'),
        _fillPaint(const Color(0xFFB9A8F2)),
      );
      c.drawPath(
        _svg('M0 330l70-60 70 50 60-40 100 70v50H0z'),
        _fillPaint(const Color(0xFF8F79E0)),
      );
    });

void _tide(Canvas c, Size s) => _board(c, s, const Color(0xFFE3EDFB), (c) {
  const colors = [
    Color(0xFFBFD9F4),
    Color(0xFF99C2EC),
    Color(0xFF6FA6DE),
    Color(0xFF4C88C9),
  ];
  for (var i = 0; i < colors.length; i++) {
    final y = 200 + i * 50;
    c.drawPath(
      _svg('M0 ${y}c50-24 100 24 150 0s100-24 150 0V400H0z'),
      _fillPaint(colors[i]),
    );
  }
});

void _sunrise(Canvas c, Size s) => _board(c, s, const Color(0xFFFDF1EC), (c) {
  const bands = [
    Color(0xFFFBE3DA),
    Color(0xFFF7CDBE),
    Color(0xFFF2B7A2),
    Color(0xFFEC9F86),
    Color(0xFFE58A6E),
  ];
  for (var i = 0; i < bands.length; i++) {
    c.drawRect(
      Rect.fromLTWH(0, 200.0 + i * 40, 300, 40),
      _fillPaint(bands[i]),
    );
  }
  c.drawCircle(const Offset(150, 200), 60, _fillPaint(const Color(0xFFFFF1C9)));
});

void _bauhaus(Canvas c, Size s) => _board(c, s, const Color(0xFFFAF7F2), (c) {
  c.drawCircle(const Offset(90, 110), 60, _fillPaint(const Color(0xFFF2C2B1)));
  c.drawRect(
    const Rect.fromLTWH(150, 160, 110, 110),
    _fillPaint(const Color(0xFFCFC2F5)),
  );
  c.drawPath(
    _svg('M40 360l80-140 80 140z'),
    _fillPaint(const Color(0xFFEBD69F)),
  );
  c.drawCircle(const Offset(215, 215), 28, _fillPaint(const Color(0xFFFBE3DA)));
});

void _blobs(Canvas c, Size s) => _board(c, s, const Color(0xFFFFFFFF), (c) {
  c.drawPath(
    _svg('M40 120c0-60 80-90 120-50s100 10 100 70-60 80-110 60S40 180 40 120z'),
    _fillPaint(const Color(0xFFE6DEFB)),
  );
  c.drawPath(
    _svg('M60 300c10-50 80-60 120-40s80 20 70 70-90 60-130 50-70-30-60-80z'),
    _fillPaint(const Color(0xFFDCEFE9)),
  );
});

void _roseRings(Canvas c, Size s) =>
    _board(c, s, const Color(0xFFF8DDE6), (c) {
      const ring = Color(0xFFEFC1D0);
      c.drawCircle(const Offset(150, 200), 110, _strokePaint(ring, 2));
      c.drawCircle(const Offset(150, 200), 80, _strokePaint(ring, 2));
      c.drawCircle(const Offset(150, 200), 50, _fillPaint(ring));
    });

void _botanical(Canvas c, Size s) =>
    _board(c, s, const Color(0xFFDCEFE9), (c) {
      final leaves = _svg(
        'M150 330c-40-10-70-40-80-80 40 5 70 35 80 80zM150 270c40-10 70-40 '
        '80-80-40 5-70 35-80 80zM150 210c-30-10-50-35-55-65 30 5 50 30 55 '
        '65zM150 160c25-12 40-35 40-60-25 8-38 30-40 60z',
      );
      c.drawPath(leaves, _fillPaint(const Color(0xFFA8D5C4)));
      final stroke = _strokePaint(const Color(0xFF2F7D65), 3);
      c.drawLine(const Offset(150, 400), const Offset(150, 150), stroke);
      c.drawPath(leaves, stroke);
    });

void _softLinen(Canvas c, Size s) =>
    _board(c, s, const Color(0xFFF4EEDF), (c) {
      final paint = _strokePaint(const Color(0xFFE6DDC8), 0.8)
        ..strokeCap = StrokeCap.butt;
      for (double x = 3; x < 300; x += 6) {
        c.drawLine(Offset(x, 0), Offset(x, 400), paint);
      }
      for (double y = 3; y < 400; y += 6) {
        c.drawLine(Offset(0, y), Offset(300, y), paint);
      }
    });

void _sketchGrid(Canvas c, Size s) =>
    _board(c, s, const Color(0xFFF7F8FB), (c) {
      final paint = _strokePaint(const Color(0xFFD8DCE8), 1)
        ..strokeCap = StrokeCap.butt;
      for (double x = 0; x <= 300; x += 20) {
        c.drawLine(Offset(x, 0), Offset(x, 400), paint);
      }
      for (double y = 0; y <= 400; y += 20) {
        c.drawLine(Offset(0, y), Offset(300, y), paint);
      }
    });

void _pastelTerrazzo(Canvas c, Size s) =>
    _board(c, s, const Color(0xFFF6F3EE), (c) {
      const chips = [
        (50.0, 60.0, 14.0, 8.0, 20.0, Color(0xFFF2C2B1)),
        (140.0, 40.0, 10.0, 6.0, -30.0, Color(0xFFB5DDD0)),
        (230.0, 90.0, 16.0, 9.0, 45.0, Color(0xFFCFC2F5)),
        (80.0, 160.0, 9.0, 6.0, 10.0, Color(0xFFEBD69F)),
        (190.0, 190.0, 13.0, 7.0, -15.0, Color(0xFFF2C2B1)),
        (40.0, 260.0, 12.0, 8.0, 60.0, Color(0xFFCFC2F5)),
        (140.0, 300.0, 15.0, 8.0, -40.0, Color(0xFFB5DDD0)),
        (250.0, 290.0, 9.0, 6.0, 25.0, Color(0xFFEBD69F)),
        (100.0, 370.0, 13.0, 7.0, 5.0, Color(0xFFCFC2F5)),
        (220.0, 370.0, 10.0, 6.0, -60.0, Color(0xFFF2C2B1)),
      ];
      for (final (x, y, rx, ry, turn, color) in chips) {
        c.save();
        c.translate(x, y);
        c.rotate(turn * math.pi / 180);
        c.drawOval(
          Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
          _fillPaint(color),
        );
        c.restore();
      }
    });

void _charcoal(Canvas c, Size s) => _board(c, s, const Color(0xFF2B2B30), (c) {
  c.drawLine(
    const Offset(0, 340),
    const Offset(300, 340),
    _strokePaint(const Color(0xFF3A3A40), 2),
  );
  c.drawCircle(const Offset(240, 70), 6, _fillPaint(const Color(0xFF6E56CF)));
});

void _night(Canvas c, Size s) => _board(c, s, const Color(0xFF24305E), (c) {
  const moon = Color(0xFFF3EBD2);
  c.drawCircle(const Offset(200, 110), 40, _fillPaint(moon));
  c.drawCircle(const Offset(216, 98), 36, _fillPaint(const Color(0xFF24305E)));
  const stars = [
    (60.0, 80.0, 2.0),
    (110.0, 150.0, 1.5),
    (40.0, 220.0, 2.2),
    (240.0, 240.0, 1.6),
    (150.0, 60.0, 1.4),
    (90.0, 300.0, 2.0),
    (220.0, 330.0, 1.8),
    (260.0, 180.0, 1.2),
    (170.0, 260.0, 1.5),
  ];
  for (final (x, y, r) in stars) {
    c.drawCircle(Offset(x, y), r, _fillPaint(moon));
  }
});

// --- more pastel covers (2026-11-24), same 300 × 400 board ------------------

void _dunes(Canvas c, Size s) => _board(c, s, const Color(0xFFFDF1EC), (c) {
  c.drawCircle(const Offset(210, 120), 30, _fillPaint(const Color(0xFFFFF1C9)));
  c.drawPath(
    _svg('M0 250C80 200 170 230 300 210V400H0z'),
    _fillPaint(const Color(0xFFF7D9C4)),
  );
  c.drawPath(
    _svg('M0 300C90 260 200 300 300 270V400H0z'),
    _fillPaint(const Color(0xFFEFBFA3)),
  );
  c.drawPath(
    _svg('M0 350C100 320 190 360 300 330V400H0z'),
    _fillPaint(const Color(0xFFE3A283)),
  );
});

void _clouds(Canvas c, Size s) => _board(c, s, const Color(0xFFDCE8FB), (c) {
  c.drawCircle(const Offset(225, 80), 26, _fillPaint(const Color(0xFFFFF1C9)));
  void cloud(List<(double, double, double)> puffs, Rect base, Color color) {
    final paint = _fillPaint(color);
    for (final (x, y, r) in puffs) {
      c.drawCircle(Offset(x, y), r, paint);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(base, Radius.circular(base.height / 2)),
      paint,
    );
  }

  const white = Color(0xFFFFFFFF);
  cloud(
    const [(70, 160, 26), (100, 148, 32), (132, 162, 24)],
    const Rect.fromLTWH(60, 160, 84, 26),
    white,
  );
  cloud(
    const [(180, 270, 30), (216, 256, 36), (252, 274, 26)],
    const Rect.fromLTWH(166, 270, 104, 30),
    white,
  );
  cloud(
    const [(50, 340, 18), (74, 332, 22)],
    const Rect.fromLTWH(40, 340, 56, 18),
    const Color(0xFFF4F8FE),
  );
});

void _sageHills(Canvas c, Size s) =>
    _board(c, s, const Color(0xFFEEF6F1), (c) {
      c.drawCircle(
        const Offset(90, 130),
        32,
        _fillPaint(const Color(0xFFFFF1C9)),
      );
      c.drawPath(
        _svg('M0 260C60 220 120 230 170 255S260 270 300 240V400H0z'),
        _fillPaint(const Color(0xFFCDE8DC)),
      );
      c.drawPath(
        _svg('M0 310C70 280 140 300 200 290S270 280 300 295V400H0z'),
        _fillPaint(const Color(0xFFA8D5C4)),
      );
      c.drawPath(
        _svg('M0 355C80 335 160 360 220 345S280 335 300 345V400H0z'),
        _fillPaint(const Color(0xFF7FBFA8)),
      );
    });

void _blossom(Canvas c, Size s) => _board(c, s, const Color(0xFFF8DDE6), (c) {
  final petal = _fillPaint(const Color(0xFFFFFFFF));
  final middle = _fillPaint(const Color(0xFFF6D365));
  const petals = [(0.0, -13.0), (12.4, -4.0), (7.6, 10.5), (-7.6, 10.5), (-12.4, -4.0)];
  const flowers = [(70.0, 80.0), (220.0, 120.0), (140.0, 200.0), (60.0, 300.0), (230.0, 320.0)];
  for (final (x, y) in flowers) {
    for (final (dx, dy) in petals) {
      c.drawCircle(Offset(x + dx, y + dy), 11, petal);
    }
    c.drawCircle(Offset(x, y), 6, middle);
  }
  final dot = _fillPaint(const Color(0xFFF2B7C7));
  for (final (x, y) in const [(180.0, 50.0), (40.0, 190.0), (250.0, 220.0), (140.0, 360.0)]) {
    c.drawCircle(Offset(x, y), 5, dot);
  }
});

void _moonrise(Canvas c, Size s) =>
    _board(c, s, const Color(0xFFE8E1FB), (c) {
      c.drawCircle(
        const Offset(190, 120),
        44,
        _fillPaint(const Color(0xFFFFF1C9)),
      );
      c.drawCircle(
        const Offset(210, 106),
        40,
        _fillPaint(const Color(0xFFE8E1FB)),
      );
      final star = _fillPaint(const Color(0xFFFFFFFF));
      const stars = [
        (70.0, 80.0, 3.0),
        (110.0, 160.0, 2.4),
        (250.0, 200.0, 2.6),
        (60.0, 210.0, 2.0),
        (150.0, 60.0, 2.2),
      ];
      for (final (x, y, r) in stars) {
        c.drawCircle(Offset(x, y), r, star);
      }
      c.drawPath(
        _svg('M0 320C70 290 150 300 210 315S280 320 300 310V400H0z'),
        _fillPaint(const Color(0xFFCFC2F5)),
      );
      c.drawPath(
        _svg('M0 360C90 340 170 355 300 345V400H0z'),
        _fillPaint(const Color(0xFFB9A8F2)),
      );
    });

void _ribbons(Canvas c, Size s) => _board(c, s, const Color(0xFFF6F3EE), (c) {
  const colors = [
    Color(0xFFCFC2F5),
    Color(0xFFF2C2B1),
    Color(0xFFB5DDD0),
    Color(0xFFEBD69F),
    Color(0xFFCFC2F5),
  ];
  for (var i = 0; i < colors.length; i++) {
    final y = 80 + i * 70;
    c.drawPath(
      _svg('M-10 ${y}c40-30 80 30 120 0s80-30 120 0 80 30 120 0'),
      _strokePaint(colors[i], 8),
    );
  }
});

void _window(Canvas c, Size s) => _board(c, s, const Color(0xFFFBE3DA), (c) {
  final arch = _svg('M70 360V180a80 80 0 0 1 160 0v180z');
  c.drawPath(arch, _fillPaint(const Color(0xFFF7CDBE)));
  c.save();
  c.clipPath(arch);
  c.drawCircle(const Offset(150, 220), 36, _fillPaint(const Color(0xFFFFF1C9)));
  c.drawPath(
    _svg('M60 300c40-30 80-20 100 0s60 20 90-10v80H60z'),
    _fillPaint(const Color(0xFFEC9F86)),
  );
  c.restore();
});

void _pebbles(Canvas c, Size s) => _board(c, s, const Color(0xFFE3EDFB), (c) {
  const stones = [
    (330.0, 80.0, 30.0, Color(0xFF99C2EC)),
    (275.0, 62.0, 26.0, Color(0xFFB5DDD0)),
    (226.0, 46.0, 22.0, Color(0xFFEBD69F)),
    (186.0, 32.0, 18.0, Color(0xFFF2C2B1)),
    (154.0, 20.0, 13.0, Color(0xFFCFC2F5)),
  ];
  for (final (y, rx, ry, color) in stones) {
    c.drawOval(
      Rect.fromCenter(center: Offset(150, y), width: rx * 2, height: ry * 2),
      _fillPaint(color),
    );
  }
});

void _tulips(Canvas c, Size s) => _board(c, s, const Color(0xFFDCEFE9), (c) {
  final leaves = [
    _svg('M150 320c-20-10-35-30-38-50 20 5 34 25 38 50z'),
    _svg('M210 340c18-10 30-28 32-46-18 5-30 22-32 46z'),
  ];
  final stem = _strokePaint(const Color(0xFF2F7D65), 3)
    ..strokeCap = StrokeCap.butt;
  c.drawLine(const Offset(90, 400), const Offset(90, 230), stem);
  c.drawLine(const Offset(150, 400), const Offset(150, 180), stem);
  c.drawLine(const Offset(210, 400), const Offset(210, 250), stem);
  for (final leaf in leaves) {
    c.drawPath(leaf, stem);
    c.drawPath(leaf, _fillPaint(const Color(0xFFA8D5C4)));
  }
  const heads = [
    ('M70 230q0-40 20-40t20 40q-20 14-40 0z', Color(0xFFF2B7C7)),
    ('M130 180q0-40 20-40t20 40q-20 14-40 0z', Color(0xFFCFC2F5)),
    ('M190 250q0-40 20-40t20 40q-20 14-40 0z', Color(0xFFF2C27B)),
  ];
  for (final (data, color) in heads) {
    c.drawPath(_svg(data), _fillPaint(color));
  }
});
