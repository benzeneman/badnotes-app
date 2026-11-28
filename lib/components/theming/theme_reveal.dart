import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Light and dark trade places like in the feature tour: the new theme
/// fills the screen in a circle growing from the last tap.
///
/// [builder] gets the brightness to show. When [brightness] changes, the
/// screen is kept as a picture first, the app is built once in the new
/// theme, and the picture is drawn over it with a growing hole. Only that
/// picture is drawn again while the circle grows; nothing is rebuilt.
/// Instant with "reduce motion".
class ThemeReveal extends StatefulWidget {
  const new({super.key, required this.brightness, required this.builder});

  final Brightness brightness;
  final Widget Function(BuildContext context, Brightness shown) builder;

  static const duration = Duration(milliseconds: 550);

  @override
  State<ThemeReveal> createState() => _ThemeRevealState();
}

class _ThemeRevealState extends State<ThemeReveal>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late var _shown = widget.brightness;
  late final _controller =
      AnimationController(vsync: this, duration: ThemeReveal.duration)
        ..addStatusListener((status) {
          if (status.isCompleted) _clear();
        });
  late final _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );
  ui.Image? _old;
  Offset? _tap;
  var _pending = false;

  @override
  void didUpdateWidget(ThemeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.brightness == _shown || _pending) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      // built right after this, no setState needed
      _shown = widget.brightness;
      _controller.stop();
      final old = _old;
      _old = null;
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
      return;
    }
    // the picture is taken after this frame, still in the old theme
    _pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _switch());
  }

  void _switch() {
    _pending = false;
    if (!mounted || widget.brightness == _shown) return;
    ui.Image? picture;
    final box = _boundary.currentContext?.findRenderObject();
    if (box is RenderRepaintBoundary && box.hasSize) {
      try {
        picture = box.toImageSync(
          pixelRatio: math.min(MediaQuery.devicePixelRatioOf(context), 2),
        );
      } catch (_) {
        // no picture: the theme just changes
      }
    }
    _old?.dispose();
    setState(() {
      _shown = widget.brightness;
      _old = picture;
    });
    if (picture != null) _controller.forward(from: 0);
  }

  void _clear() {
    final old = _old;
    if (old == null) return;
    setState(() => _old = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    _old?.dispose();
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final old = _old;
    final size = MediaQuery.sizeOf(context);
    return Listener(
      onPointerDown: (event) => _tap = event.position,
      child: CustomPaint(
        foregroundPainter: old == null
            ? null
            : RevealPainter(
                image: old,
                center: _tap ?? Offset(size.width - 40, 40),
                progress: _progress,
              ),
        child: RepaintBoundary(
          key: _boundary,
          child: widget.builder(context, _shown),
        ),
      ),
    );
  }
}

/// [image] over the whole size, but for a hole around [center] that grows
/// with [progress] until it reaches the farthest corner.
@visibleForTesting
class RevealPainter extends CustomPainter {
  new({required this.image, required this.center, required this.progress})
    : super(repaint: progress);

  final ui.Image image;
  final Offset center;
  final Animation<double> progress;

  /// From [center] to the farthest corner of [size].
  static double reach(Offset center, Size size) => [
    Offset.zero,
    size.topRight(Offset.zero),
    size.bottomLeft(Offset.zero),
    size.bottomRight(Offset.zero),
  ].map((corner) => (corner - center).distance).reduce(math.max);

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final radius = reach(center, size) * progress.value;
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(screen)
          ..addOval(Rect.fromCircle(center: center, radius: radius)),
      )
      ..drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        screen,
        Paint()..filterQuality = FilterQuality.low,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(RevealPainter old) =>
      old.image != image || old.center != center;
}
