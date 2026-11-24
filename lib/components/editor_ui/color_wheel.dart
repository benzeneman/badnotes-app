import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Any color: drag round the ring for its hue, and in the square inside for
/// how strong and how light it is.
class ColorWheel extends StatefulWidget {
  const ColorWheel({
    super.key,
    required this.color,
    required this.onChanged,
    this.onChangeEnd,
  });

  final Color color;

  /// Live, on every move of the finger.
  final ValueChanged<Color> onChanged;

  /// Once, when the finger lifts: the color that was chosen.
  final ValueChanged<Color>? onChangeEnd;

  @override
  State<ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<ColorWheel> {
  late HSVColor _hsv = HSVColor.fromColor(widget.color);

  /// What the drag is on: the ring, the square, or nothing.
  bool? _onRing;

  static const _ring = 24.0;

  /// Between the ring and the square.
  static const _gap = 12.0;

  @override
  void didUpdateWidget(ColorWheel old) {
    super.didUpdateWidget(old);
    // a color from elsewhere (the hex, the note); not the one just dragged
    if (widget.color.toARGB32() != _hsv.toColor().toARGB32()) {
      _hsv = HSVColor.fromColor(widget.color);
    }
  }

  void _touch(Offset p, Size size, {bool start = false}) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final d = p - center;
    if (start) {
      _onRing = d.distance > radius - _ring - _gap / 2;
      HapticFeedback.selectionClick();
    }
    if (_onRing == true) {
      final hue = (atan2(d.dy, d.dx) * 180 / pi + 360) % 360;
      _hsv = _hsv.withHue(hue);
    } else {
      final half = (radius - _ring - _gap) / sqrt2;
      final x = ((d.dx + half) / (2 * half)).clamp(0.0, 1.0);
      final y = ((d.dy + half) / (2 * half)).clamp(0.0, 1.0);
      _hsv = _hsv.withSaturation(x).withValue(1 - y);
    }
    setState(() {});
    widget.onChanged(_hsv.toColor());
  }

  void _end() {
    setState(() => _onRing = null);
    widget.onChangeEnd?.call(_hsv.toColor());
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
            onPanStart: (d) => _touch(d.localPosition, size, start: true),
            onPanUpdate: (d) => _touch(d.localPosition, size),
            onPanEnd: (_) => _end(),
            onTapDown: (d) => _touch(d.localPosition, size, start: true),
            onTapUp: (_) => _end(),
            child: RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: _WheelPainter(_hsv, _onRing),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.hsv, this.dragging);

  final HSVColor hsv;

  /// Which knob is held: the ring's (true), the square's (false), or none.
  final bool? dragging;

  static final _shadow = Paint()
    ..color = Colors.black38
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  /// A knob: the color, a white rim and a soft shadow; bigger while held.
  static void _knob(Canvas canvas, Offset at, double r, Color color, bool held) {
    final radius = held ? r * 1.3 : r;
    canvas.drawCircle(at + const Offset(0, 1.5), radius + 1, _shadow);
    canvas.drawCircle(at, radius, Paint()..color = color);
    canvas.drawCircle(
      at,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    const ring = _ColorWheelState._ring;
    final ringRadius = radius - ring / 2;
    final ringRect = Rect.fromCircle(center: center, radius: ringRadius);

    // the ring, softly shadowed, every 10° so the hues blend evenly
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..shader = SweepGradient(
          colors: [
            for (int h = 0; h <= 360; h += 10)
              HSVColor.fromAHSV(1, h % 360 * 1.0, 1, 1).toColor(),
          ],
        ).createShader(ringRect),
    );

    final half = (radius - ring - _ColorWheelState._gap) / sqrt2;
    final square = Rect.fromCenter(
      center: center,
      width: half * 2,
      height: half * 2,
    );
    final rrect = RRect.fromRectAndRadius(square, const Radius.circular(12));
    canvas.drawRRect(rrect.shift(const Offset(0, 2)), _shadow);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      square,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor()],
        ).createShader(square),
    );
    canvas.drawRect(
      square,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(square),
    );
    canvas.restore();

    final angle = hsv.hue * pi / 180;
    _knob(
      canvas,
      center + Offset(cos(angle), sin(angle)) * ringRadius,
      ring / 2 - 2,
      HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
      dragging == true,
    );
    _knob(
      canvas,
      Offset(
        square.left + hsv.saturation * square.width,
        square.top + (1 - hsv.value) * square.height,
      ),
      10,
      hsv.toColor(),
      dragging == false,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.hsv != hsv || old.dragging != dragging;
}
