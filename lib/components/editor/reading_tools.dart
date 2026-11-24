import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/canvas_gesture_detector.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/extensions/matrix4_extensions.dart';

/// Reading mode's extras: the pages scroll by themselves, like a teleprompter,
/// and a strip of light keeps the eye on one part of the page. Touches pass
/// through to the pages everywhere except on the controls.
class ReadingTools extends StatefulWidget {
  const ReadingTools({
    super.key,
    required this.pages,
    required this.transformationController,
    required this.isTouching,
  });

  final List<EditorPage> pages;
  final TransformationController transformationController;

  /// Scrolling waits while a finger is on the page.
  final bool Function() isTouching;

  @override
  State<ReadingTools> createState() => _ReadingToolsState();
}

class _ReadingToolsState extends State<ReadingTools> {
  static const _frame = Duration(milliseconds: 16);
  static const _stripHeight = 140.0;

  Timer? _ticker;
  Size _size = Size.zero;

  /// From 0 to 1, see [_pixelsPerSecond].
  var _speed = 0.25;
  var _stripOn = false;
  double? _stripCenter;

  double get _pixelsPerSecond => lerpDouble(10, 200, _speed)!;

  void _toggleScrolling() => setState(() {
    if (_ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    } else {
      _ticker = Timer.periodic(_frame, (_) => _scrollOneFrame());
    }
  });

  void _scrollOneFrame() {
    if (widget.isTouching()) return;
    final controller = widget.transformationController;
    final horizontal = CanvasGestureDetector.horizontal;
    final translation = controller.value.getTranslation();
    final scrollable =
        CanvasGestureDetector.getTopOfPage(
          pageIndex: widget.pages.length,
          pages: widget.pages,
          screenWidth: _size.width,
        ) *
        controller.value.approxScale -
        (horizontal ? _size.width : _size.height);
    final position = -(horizontal ? translation.x : translation.y);
    if (position >= scrollable) {
      // the end of the note
      setState(() {
        _ticker?.cancel();
        _ticker = null;
      });
      return;
    }
    final next =
        position + _pixelsPerSecond * _frame.inMilliseconds / 1000;
    controller.value = controller.value.clone()
      ..setTranslationRaw(
        horizontal ? -next : translation.x,
        horizontal ? translation.y : -next,
        translation.z,
      );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final center = (_stripCenter ?? _size.height * 0.4).clamp(
          0.0,
          _size.height,
        );
        return Stack(
          children: [
            if (_stripOn) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _StripPainter(center, _stripHeight),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: center - 20,
                child: GestureDetector(
                  onPanUpdate: (details) => setState(() {
                    _stripCenter = center + details.delta.dy;
                  }),
                  child: Material(
                    shape: const CircleBorder(),
                    color: colorScheme.surface,
                    elevation: 3,
                    child: const SizedBox.square(
                      dimension: 40,
                      child: Icon(Icons.unfold_more),
                    ),
                  ),
                ),
              ),
            ],
            Positioned(
              left: 8,
              bottom: 8,
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(24),
                color: colorScheme.surface,
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    IconButton(
                      tooltip: _ticker != null
                          ? 'Stop scrolling'
                          : 'Scroll by itself',
                      icon: Icon(
                        _ticker != null ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: _toggleScrolling,
                    ),
                    if (_ticker != null)
                      SizedBox(
                        width: 120,
                        child: Slider(
                          value: _speed,
                          onChanged: (value) => setState(() => _speed = value),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Focus strip',
                      isSelected: _stripOn,
                      icon: const Icon(Icons.highlight_alt),
                      onPressed: () => setState(() => _stripOn = !_stripOn),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StripPainter extends CustomPainter {
  const _StripPainter(this.center, this.height);

  final double center, height;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0x99000000);
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, center - height / 2),
      dim,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, center + height / 2, size.width, size.height),
      dim,
    );
  }

  @override
  bool shouldRepaint(_StripPainter oldDelegate) =>
      center != oldDelegate.center || height != oldDelegate.height;
}
