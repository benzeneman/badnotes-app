import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Picks a color off the note: the note shows still, a loupe follows the
/// finger, and the color under it when the finger lifts is the one picked.
abstract final class ScreenColorPicker {
  /// The note in front, which the editor sets.
  static GlobalKey? source;

  /// The color picked, or null if closed without one.
  static Future<Color?> pick(BuildContext context) async {
    final boundary = source?.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || !boundary.attached) return null;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData();
    if (bytes == null || !context.mounted) return null;
    final rect = boundary.localToGlobal(Offset.zero) & boundary.size;
    HapticFeedback.selectionClick();
    return Navigator.of(context, rootNavigator: true).push<Color>(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: _Picker(image: image, bytes: bytes, rect: rect, ratio: ratio),
        ),
      ),
    );
  }
}

class _Picker extends StatefulWidget {
  const _Picker({
    required this.image,
    required this.bytes,
    required this.rect,
    required this.ratio,
  });

  final ui.Image image;
  final ByteData bytes;

  /// Where the note is on the screen.
  final Rect rect;
  final double ratio;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late Offset _at = widget.rect.center;
  late Color _color = _colorAt(_at);

  Color _colorAt(Offset global) {
    final p = (global - widget.rect.topLeft) * widget.ratio;
    final x = p.dx.round().clamp(0, widget.image.width - 1);
    final y = p.dy.round().clamp(0, widget.image.height - 1);
    final i = (y * widget.image.width + x) * 4;
    final b = widget.bytes;
    return Color.fromARGB(
      255,
      b.getUint8(i),
      b.getUint8(i + 1),
      b.getUint8(i + 2),
    );
  }

  void _move(Offset global) {
    final next = _colorAt(global);
    if (next != _color) HapticFeedback.selectionClick();
    setState(() {
      _at = global;
      _color = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    const loupe = 112.0;
    final screen = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    // above the finger, so the finger doesn't hide it; under it at the top
    final above = _at.dy - loupe - 36 > top;
    final loupeCenter = Offset(
      _at.dx.clamp(loupe / 2, screen.width - loupe / 2),
      above ? _at.dy - loupe / 2 - 36 : _at.dy + loupe / 2 + 36,
    );
    return Material(
      color: Colors.black54,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _move(e.position),
        onPointerMove: (e) => _move(e.position),
        onPointerUp: (e) => Navigator.pop(context, _colorAt(e.position)),
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: widget.rect,
              child: RawImage(
                image: widget.image,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            Positioned(
              left: loupeCenter.dx - loupe / 2,
              top: loupeCenter.dy - loupe / 2,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size.square(loupe),
                  painter: _LoupePainter(
                    image: widget.image,
                    center: (_at - widget.rect.topLeft) * widget.ratio,
                    ratio: widget.ratio,
                    color: _color,
                  ),
                ),
              ),
            ),
            Positioned(
              top: top + 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                      const Text(
                        'Drag to a color, then lift',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      IconButton(
                        tooltip: 'Cancel',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The note under the finger, made big, with the color it's on as a ring.
class _LoupePainter extends CustomPainter {
  _LoupePainter({
    required this.image,
    required this.center,
    required this.ratio,
    required this.color,
  });

  final ui.Image image;

  /// The finger, in the image's pixels.
  final Offset center;
  final double ratio;
  final Color color;

  static const _zoom = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final mid = rect.center;
    canvas.drawCircle(
      mid,
      size.width / 2,
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawColor(Colors.white, BlendMode.src);
    canvas.drawImageRect(
      image,
      Rect.fromCenter(
        center: center,
        width: size.width * ratio / _zoom,
        height: size.height * ratio / _zoom,
      ),
      rect,
      Paint()..filterQuality = FilterQuality.none,
    );
    canvas.restore();
    // the pixel picked
    final cell = Rect.fromCenter(center: mid, width: _zoom + 4, height: _zoom + 4);
    canvas.drawRect(
      cell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
    );
    canvas.drawCircle(
      mid,
      size.width / 2 - 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = color,
    );
    canvas.drawCircle(
      mid,
      size.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_LoupePainter old) =>
      old.center != center || old.color != color;
}
