import 'dart:async';
import 'dart:math';
import 'dart:ui' show FontFeature;

import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_controls.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:badnotes/components/canvas/canvas_gesture_detector.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/extensions/matrix4_extensions.dart';
import 'package:badnotes/data/tools/pen.dart';

/// A ruler lying on top of the canvas, in the coordinates of the canvas area.
/// Fixed to the screen, not the page, so it stays put while the page scrolls.
class Ruler extends ChangeNotifier {
  Ruler(this.center);

  static const thickness = 90.0;

  /// A stroke starting this close to an edge follows that edge.
  static const snapReach = 40.0;

  /// Flutter's nominal sizes. ponytail: a screen's real size can differ a bit,
  /// and a page's zoom isn't taken into account; the ruler measures the screen.
  static const pixelsPerInch = 160.0;
  static const pixelsPerCm = pixelsPerInch / 2.54;

  static const knobRadius = 18.0;
  static const _knobDistance = 130.0;

  /// The length of the line last drawn along an edge, in pixels.
  double? measured;
  Offset _measureStart = .zero;

  void startMeasuring(Offset point) {
    _measureStart = point;
    measured = 0;
    notifyListeners();
  }

  void updateMeasuring(Offset point) {
    measured = (point - _measureStart).distance;
    notifyListeners();
  }

  Offset get knobCenter => center + _direction * _knobDistance;

  bool knobContains(Offset point) =>
      (point - knobCenter).distance <= knobRadius + 8;

  Offset center;
  double _rawAngle = 0;

  /// Sticks to multiples of 45 degrees when within a degree of one.
  double get angle {
    const step = pi / 4;
    final nearest = (_rawAngle / step).round() * step;
    return (_rawAngle - nearest).abs() < 1.1 * pi / 180 ? nearest : _rawAngle;
  }

  Offset get _direction => Offset(cos(angle), sin(angle));
  Offset get _normal => Offset(-sin(angle), cos(angle));

  double _signedDistance(Offset point) {
    final d = point - center;
    return d.dx * _normal.dx + d.dy * _normal.dy;
  }

  bool contains(Offset point) =>
      _signedDistance(point).abs() <= thickness / 2;

  /// The edge (1 or -1) that a stroke starting at [point] should follow,
  /// or null if it's too far away from the ruler.
  int? edgeNear(Offset point) {
    final distance = _signedDistance(point);
    final gap = distance.abs() - thickness / 2;
    if (gap < 0 || gap > snapReach) return null;
    return distance > 0 ? 1 : -1;
  }

  /// The point on [edge] closest to [point].
  Offset project(Offset point, int edge) {
    final d = point - center;
    final along = d.dx * _direction.dx + d.dy * _direction.dy;
    return center + _direction * along + _normal * (edge * thickness / 2);
  }

  void move(Offset delta, double rotation) {
    center += delta;
    _rawAngle += rotation;
    measured = null;
    notifyListeners();
  }
}

/// Drag with one finger to move the ruler, twist with two fingers or drag the
/// round knob to rotate. Touches outside the ruler reach the canvas underneath.
class RulerOverlay extends StatefulWidget {
  const RulerOverlay({super.key, required this.ruler});

  final Ruler ruler;

  @override
  State<RulerOverlay> createState() => _RulerOverlayState();
}

class _RulerOverlayState extends State<RulerOverlay> {
  double _lastRotation = 0;
  var _turningKnob = false;
  double _knobGrab = 0;

  double _directionFromCenter(Offset point) =>
      (point - widget.ruler.center).direction;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // the page underneath doesn't repaint as the ruler moves
      child: GestureDetector(
        onScaleStart: (details) {
          _lastRotation = 0;
          _turningKnob = widget.ruler.knobContains(details.localFocalPoint);
          _knobGrab = _directionFromCenter(details.localFocalPoint);
        },
        onScaleUpdate: (details) {
          if (_turningKnob && details.pointerCount == 1) {
            final direction = _directionFromCenter(details.localFocalPoint);
            widget.ruler.move(.zero, _wrapAngle(direction - _knobGrab));
            _knobGrab = direction;
            return;
          }
          widget.ruler.move(
            details.focalPointDelta,
            details.rotation - _lastRotation,
          );
          _lastRotation = details.rotation;
        },
        child: CustomPaint(
          painter: _RulerPainter(widget.ruler),
          size: Size.infinite,
        ),
      ),
    );
  }

  static double _wrapAngle(double angle) => atan2(sin(angle), cos(angle));
}

class _RulerPainter extends CustomPainter {
  _RulerPainter(this.ruler) : super(repaint: ruler);

  final Ruler ruler;

  /// Laid out once: making these on every frame of a rotation is what stutters.
  static final _labels = <String, TextPainter>{};

  static TextPainter _label(
    String text, {
    double fontSize = 11,
    Color color = BnColors.text,
  }) => _labels['$fontSize/$color/$text'] ??= TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: color == BnColors.text ? null : FontWeight.w600,
      ),
    ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  bool hitTest(Offset position) =>
      ruler.contains(position) || ruler.knobContains(position);

  void _drawMarks(
    Canvas canvas,
    Paint line,
    double half,
    double reach, {
    required double unit,
    required int perUnit,
    required double edge,
    required String suffix,
  }) {
    final spacing = unit / perUnit;
    final count = (reach / spacing).ceil();
    for (var i = -count; i <= count; i++) {
      final x = i * spacing;
      final long = i % perUnit == 0;
      final tick = long
          ? 16.0
          : i % (perUnit ~/ 2) == 0
          ? 11.0
          : 6.0;
      canvas.drawLine(
        Offset(x, edge * half),
        Offset(x, edge * (half - tick)),
        line,
      );
      if (long && i != 0) {
        final label = _label('${i.abs() ~/ perUnit}');
        label.paint(
          canvas,
          Offset(
            x - label.width / 2,
            edge > 0 ? half - tick - label.height : -half + tick,
          ),
        );
      }
    }
    final name = _label(suffix);
    name.paint(
      canvas,
      Offset(4, edge > 0 ? half - 16 - name.height : -half + 16),
    );
  }

  void _drawPill(Canvas canvas, Offset center, TextPainter label) {
    final box = Rect.fromCenter(
      center: center,
      width: label.width + 14,
      height: label.height + 6,
    );
    final chip = RRect.fromRectAndRadius(box, const Radius.circular(10));
    canvas.drawRRect(
      chip.shift(const Offset(0, 1)),
      Paint()
        ..color = const Color(0x29000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(chip, Paint()..color = Colors.white);
    label.paint(canvas, box.topLeft + const Offset(7, 3));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const half = Ruler.thickness / 2;
    final reach = size.longestSide * 1.5;
    canvas.save();
    canvas.translate(ruler.center.dx, ruler.center.dy);
    canvas.rotate(ruler.angle);

    // Clear glass lifted off the page: a soft shadow below that stays off
    // the writing under the ruler, a white frost, a bright top edge.
    final body = Rect.fromLTRB(-reach, -half, reach, half);
    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(body.inflate(40))
        ..addRect(body),
    );
    canvas.drawRect(
      body.shift(const Offset(0, 6)),
      Paint()
        ..color = const Color(0x4D000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.restore();
    canvas.drawRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x8CFFFFFF), Color(0x5CEFF4FF)],
        ).createShader(body),
    );
    canvas.drawLine(
      Offset(-reach, -half + 0.5),
      Offset(reach, -half + 0.5),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(-reach, half - 0.5),
      Offset(reach, half - 0.5),
      Paint()
        ..color = const Color(0x40000000)
        ..strokeWidth = 1,
    );
    final line = Paint()
      ..color = BnColors.text
      ..strokeWidth = 1;
    _drawMarks(
      canvas,
      line,
      half,
      reach,
      unit: Ruler.pixelsPerCm,
      perUnit: 10,
      edge: -1,
      suffix: 'cm',
    );
    _drawMarks(
      canvas,
      line,
      half,
      reach,
      unit: Ruler.pixelsPerInch,
      perUnit: 8,
      edge: 1,
      suffix: 'in',
    );
    canvas.restore();

    // the readings stay upright so they're always readable
    final degrees = (ruler.angle * 180 / pi).round() % 180;
    _drawPill(
      canvas,
      ruler.center,
      _label('$degrees°', fontSize: 15, color: BnColors.accent),
    );
    final measured = ruler.measured;
    if (measured != null) {
      _drawPill(
        canvas,
        ruler.center + const Offset(0, 26),
        _label(
          '${(measured / Ruler.pixelsPerCm).toStringAsFixed(1)} cm',
          fontSize: 13,
        ),
      );
    }

    final knob = ruler.knobCenter;
    canvas.drawCircle(knob, Ruler.knobRadius, Paint()..color = Colors.white);
    canvas.drawCircle(
      knob,
      Ruler.knobRadius,
      Paint()
        ..color = Colors.black54
        ..style = .stroke
        ..strokeWidth = 1.5,
    );
    final arrows = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.sync.codePoint),
        style: TextStyle(
          fontFamily: Icons.sync.fontFamily,
          package: Icons.sync.fontPackage,
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    arrows.paint(canvas, knob - Offset(arrows.width / 2, arrows.height / 2));
    arrows.dispose();
  }

  @override
  bool shouldRepaint(_RulerPainter oldDelegate) => ruler != oldDelegate.ruler;
}

/// A panel at the bottom of the canvas showing part of a page, enlarged, to
/// write small and neat. The ink lands on the page at normal size. A box on
/// the page marks the part shown: drag the box, use the buttons, or drag and
/// pinch with two fingers in the panel to move and zoom it.
/// ponytail: no auto-advance while writing, add if the buttons feel slow.
class ZoomWindow extends StatefulWidget {
  const ZoomWindow({
    super.key,
    required this.pages,
    required this.initialPageIndex,
    required this.initialOrigin,
    required this.transformationController,
    required this.canvasBuilder,
    required this.canDraw,
    required this.updatePointerData,
    required this.onDrawStart,
    required this.onDrawUpdate,
    required this.onDrawEnd,
    required this.onClose,
  });

  final List<EditorPage> pages;
  final int initialPageIndex;

  /// The top left of the marked part, in page coordinates.
  final Offset initialOrigin;
  final TransformationController transformationController;

  /// Builds the page at its full size, without any scaling.
  final Widget Function(int pageIndex, double zoom) canvasBuilder;

  /// Whether this kind of pointer writes. Otherwise it moves the marked part.
  final bool Function(PointerDeviceKind kind) canDraw;
  final void Function(PointerDeviceKind kind, double? pressure)
  updatePointerData;

  /// Points are in page coordinates.
  final void Function(int pageIndex, Offset point) onDrawStart;
  final ValueChanged<Offset> onDrawUpdate;
  final VoidCallback onDrawEnd;
  final VoidCallback onClose;

  @override
  State<ZoomWindow> createState() => _ZoomWindowState();
}

class _ZoomWindowState extends State<ZoomWindow> {
  static const _barHeight = 44.0;
  static const _minWidthFraction = 0.15;
  static const _maxWidthFraction = 1.0;

  final _stackKey = GlobalKey();
  late int _pageIndex = widget.initialPageIndex;
  late Offset _origin = widget.initialOrigin;

  /// How much of the page's width the panel shows.
  double _widthFraction = 0.45;

  PointerDeviceKind _pointerKind = PointerDeviceKind.touch;
  var _drawing = false;
  var _drawnWithFinger = false;
  var _panning = false;

  /// Fingers on the writing area. Two or more move and zoom the shown part
  /// until all of them lift; a stroke the first one started is dropped.
  final _touches = <int, Offset>{};
  var _twoFingers = false;
  Offset? _pinchFocal;
  double? _pinchSpan;

  /// The panel's zoom at the last build.
  double _zoom = 1;

  void _onTouchDown(PointerDownEvent event) {
    _onPointer(event);
    if (event.kind != PointerDeviceKind.touch) return;
    _touches[event.pointer] = event.localPosition;
    _pinchFocal = null;
    // a palm on the glass doesn't stop the pen
    if (_touches.length < 2 || _twoFingers || (_drawing && !_drawnWithFinger)) {
      return;
    }
    _twoFingers = true;
    _panning = false;
    if (_drawing) {
      // the first finger's stroke goes, without leaving a dot
      final stroke = Pen.currentStroke;
      if (stroke != null) {
        Pen.currentStroke = null;
        final page = stroke.page;
        if (page is EditorPage) page.currentStrokeTick.value++;
      }
      _drawing = false;
      widget.onDrawEnd();
    }
  }

  void _onTouchMove(PointerMoveEvent event) {
    _onPointer(event);
    if (!_touches.containsKey(event.pointer)) return;
    _touches[event.pointer] = event.localPosition;
    if (!_twoFingers || _touches.length < 2) return;
    final points = _touches.values.take(2).toList();
    final focal = (points[0] + points[1]) / 2;
    final span = max((points[0] - points[1]).distance, 1.0);
    final lastFocal = _pinchFocal, lastSpan = _pinchSpan;
    _pinchFocal = focal;
    _pinchSpan = span;
    if (lastFocal == null || lastSpan == null) return;
    setState(() {
      // the page point under the fingers stays under them
      final pagePoint = _origin + lastFocal / _zoom;
      final before = _widthFraction;
      _widthFraction = (_widthFraction * lastSpan / span).clamp(
        _minWidthFraction,
        _maxWidthFraction,
      );
      _zoom *= before / _widthFraction;
      _origin = pagePoint - focal / _zoom;
    });
  }

  void _onTouchUp(PointerEvent event) {
    if (_touches.remove(event.pointer) == null) return;
    _pinchFocal = null;
    if (_touches.isEmpty) _twoFingers = false;
  }

  void _onPointer(PointerEvent event) {
    _pointerKind = event.kind;
    final isStylus =
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;
    // some pens come in as touch, with real pressure
    final hasPressure =
        (isStylus || event.kind == PointerDeviceKind.touch) &&
        event.pressureMin != event.pressureMax;
    widget.updatePointerData(
      event.kind,
      hasPressure
          ? (event.pressure - event.pressureMin) /
                (event.pressureMax - event.pressureMin)
          : null,
    );
  }

  void _nextLine(Size pageSize, Size target) {
    setState(() {
      final y = _origin.dy + target.height;
      if (y < pageSize.height - 1) {
        _origin = Offset(0, y);
      } else if (_pageIndex < widget.pages.length - 1) {
        _pageIndex++;
        _origin = Offset.zero;
      }
    });
  }

  /// Steps sideways, keeping some overlap. Past the end, goes to the next line.
  void _step(int direction, Size pageSize, Size target) {
    final atEnd = _origin.dx >= pageSize.width - target.width - 1;
    if (direction > 0 && atEnd) return _nextLine(pageSize, target);
    setState(() {
      _origin += Offset(direction * target.width * 0.75, 0);
    });
  }

  void _setWidthFraction(double value) => setState(() {
    _widthFraction = value.clamp(_minWidthFraction, _maxWidthFraction);
  });

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        _pageIndex = min(_pageIndex, widget.pages.length - 1);
        final page = widget.pages[_pageIndex];
        final panelHeight = min(300.0, constraints.maxHeight * 0.42);
        final areaHeight = panelHeight - _barHeight;
        final zoom = _zoom =
            constraints.maxWidth / (page.size.width * _widthFraction);
        final target = Size(constraints.maxWidth, areaHeight) / zoom;
        _origin = Offset(
          _origin.dx.clamp(0.0, max(0.0, page.size.width - target.width)),
          _origin.dy.clamp(0.0, max(0.0, page.size.height - target.height)),
        );

        return Stack(
          key: _stackKey,
          children: [
            _buildMarker(page, target),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: panelHeight,
              child: Material(
                elevation: 12,
                color: ColorScheme.of(context).surfaceContainerHighest,
                child: Column(
                  children: [
                    SizedBox(
                      height: _barHeight,
                      child: _buildBar(page.size, target, zoom),
                    ),
                    Expanded(child: _buildWritingArea(page, zoom)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarker(EditorPage page, Size target) {
    return AnimatedBuilder(
      animation: widget.transformationController,
      builder: (context, _) {
        final pageBox = page.renderBox;
        final stackBox =
            _stackKey.currentContext?.findRenderObject() as RenderBox?;
        if (pageBox == null || stackBox == null || !pageBox.attached) {
          // no size yet on the first frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && stackBox == null) setState(() {});
          });
          return const SizedBox.shrink();
        }
        Offset toStack(Offset point) =>
            stackBox.globalToLocal(pageBox.localToGlobal(point));
        final rect = Rect.fromPoints(
          toStack(_origin),
          toStack(_origin + target.bottomRight(Offset.zero)),
        );
        final colorScheme = ColorScheme.of(context);
        return Positioned.fromRect(
          rect: rect,
          child: GestureDetector(
            onPanUpdate: (details) => setState(() {
              _origin += details.delta * target.width / rect.width;
            }),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                border: Border.all(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBar(Size pageSize, Size target, double zoom) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Move left',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _step(-1, pageSize, target),
        ),
        IconButton(
          tooltip: 'Move right',
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _step(1, pageSize, target),
        ),
        IconButton(
          tooltip: 'Next line',
          icon: const Icon(Icons.keyboard_return),
          onPressed: () => _nextLine(pageSize, target),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Zoom out',
          icon: const Icon(Icons.remove),
          onPressed: () => _setWidthFraction(_widthFraction * 1.25),
        ),
        Text('${(zoom * 100).round()}%'),
        IconButton(
          tooltip: 'Zoom in',
          icon: const Icon(Icons.add),
          onPressed: () => _setWidthFraction(_widthFraction / 1.25),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ],
    );
  }

  Widget _buildWritingArea(EditorPage page, double zoom) {
    Offset toPage(Offset local) => _origin + local / zoom;
    return Listener(
      onPointerDown: _onTouchDown,
      onPointerMove: _onTouchMove,
      onPointerUp: (event) {
        _onTouchUp(event);
        widget.updatePointerData(event.kind, null);
      },
      onPointerCancel: _onTouchUp,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (details) {
          if (details.pointerCount > 1 || _twoFingers) return;
          if (widget.canDraw(_pointerKind)) {
            _drawing = true;
            _drawnWithFinger = _pointerKind == PointerDeviceKind.touch;
            widget.onDrawStart(_pageIndex, toPage(details.localFocalPoint));
          } else {
            _panning = true;
          }
        },
        onScaleUpdate: (details) {
          if (_twoFingers) return;
          if (_drawing) {
            widget.onDrawUpdate(toPage(details.localFocalPoint));
          } else if (_panning) {
            setState(() => _origin -= details.focalPointDelta / zoom);
          }
        },
        onScaleEnd: (_) {
          if (_drawing) widget.onDrawEnd();
          _drawing = false;
          _panning = false;
        },
        child: IgnorePointer(
          child: ClipRect(
            child: Transform.scale(
              scale: zoom,
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: -_origin,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: page.size.width,
                  maxWidth: page.size.width,
                  minHeight: page.size.height,
                  maxHeight: page.size.height,
                  child: widget.canvasBuilder(_pageIndex, zoom),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What to count down, from the timer's dialog.
class TimerSetup {
  const TimerSetup(this.duration, {this.isBreak = false})
    : isStopwatch = false;

  /// Counts up instead of down, next to any running timer.
  const TimerSetup.stopwatch()
    : duration = Duration.zero,
      isBreak = false,
      isStopwatch = true;

  final Duration duration;
  final bool isBreak;
  final bool isStopwatch;
}

const _tabular = [FontFeature.tabularFigures()];

/// A countdown's pill and ring in its last minute.
const _lastMinuteColor = Color(0xFFF08C00);

/// A running timer's pill in the nav bar.
const _pillColor = Color(0xFF17171A);

String _two(int n) => n.toString().padLeft(2, '0');

/// 05:00, or 1:05:00 past an hour.
String _hms(int seconds) {
  final h = seconds ~/ 3600, m = seconds ~/ 60 % 60, s = seconds % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '${_two(m)}:${_two(s)}';
}

String _hundredths(Duration time) => _two(time.inMilliseconds ~/ 10 % 100);

/// Pick a length to count down, or start the stopwatch.
Future<TimerSetup?> showTimerDialog(BuildContext context) {
  return showAppleDialog<TimerSetup>(
    context: context,
    builder: (context) => const _TimerDialog(),
  );
}

/// The white card the timer's and stopwatch's controls sit on.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: popoverDecoration(context),
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: .min, children: children),
          ),
        ),
      ),
    );
  }
}

class _TimerDialog extends StatefulWidget {
  const _TimerDialog();

  @override
  State<_TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<_TimerDialog> {
  var _stopwatch = false;
  var _isBreak = false;
  var _minutes = 25;

  /// A length typed in by the user, which can have hours and seconds.
  Duration? _custom;

  Duration get _length => _custom ?? Duration(minutes: _minutes);

  void _set(int minutes) {
    final next = minutes.clamp(1, _TimerDial.maxMinutes);
    if (next == _minutes && _custom == null) return;
    if (next % 5 == 0) HapticFeedback.selectionClick();
    setState(() {
      _minutes = next;
      _custom = null;
    });
  }

  void _reset() => setState(() {
    _minutes = _isBreak ? 5 : 25;
    _custom = null;
  });

  /// Any length: hours, minutes and seconds.
  Future<void> _typeMinutes() async {
    final fields = [
      for (final _ in const ['Hours', 'Minutes', 'Seconds'])
        TextEditingController(),
    ];
    final ok = await showAppleDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom time'),
        content: Row(
          spacing: 8,
          children: [
            for (final (i, label) in const [
              'Hours',
              'Minutes',
              'Seconds',
            ].indexed)
              Expanded(
                child: TextField(
                  controller: fields[i],
                  autofocus: i == 1,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: label, hintText: '0'),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    int value(int i) => int.tryParse(fields[i].text) ?? 0;
    final duration = Duration(
      hours: value(0),
      minutes: value(1),
      seconds: value(2),
    );
    for (final field in fields) field.dispose();
    if (ok != true || duration <= Duration.zero || !mounted) return;
    setState(() {
      _custom = duration;
      _minutes = max(duration.inMinutes, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return _Card(
      children: [
        BnSegmented<bool>(
          segments: const [
            BnSegment(false, 'Timer'),
            BnSegment(true, 'Stopwatch'),
          ],
          selected: _stopwatch,
          onChanged: (value) => setState(() => _stopwatch = value),
        ),
        const SizedBox(height: 20),
        if (_stopwatch) ...[
          const _StopwatchReading(Duration.zero),
          const SizedBox(height: 8),
          Text(
            'Counts your focus time, with laps and breaks.',
            textAlign: TextAlign.center,
            style: BnType.caption.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 20),
          BnButton.primary(
            label: 'Start',
            icon: Icons.play_arrow,
            onPressed: () =>
                Navigator.pop(context, const TimerSetup.stopwatch()),
          ),
        ] else ...[
          _TimerDial(
            minutes: _minutes,
            reading: _hms(_length.inSeconds),
            caption: 'tap to type',
            color: _isBreak ? colors.success : colors.accent,
            onChanged: _set,
            onTapCenter: _typeMinutes,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final minutes in const [5, 10, 25, 45])
                BnChip(
                  label: minutes == 5 ? '5 min' : '$minutes',
                  selected: _custom == null && _minutes == minutes,
                  onTap: () => _set(minutes),
                ),
              BnChip(
                label: '+ custom',
                selected: _custom != null,
                onTap: _typeMinutes,
              ),
              BnChip(
                label: 'Break',
                icon: Icons.free_breakfast_outlined,
                selected: _isBreak,
                onTap: () => setState(() {
                  _isBreak = !_isBreak;
                  _minutes = _isBreak ? 5 : 25;
                  _custom = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: .center,
            spacing: 8,
            children: [
              BnButton(label: 'Reset', onPressed: _reset),
              BnButton.primary(
                label: 'Start',
                icon: Icons.play_arrow,
                onPressed: () => Navigator.pop(
                  context,
                  TimerSetup(_length, isBreak: _isBreak),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Big digits in the middle of a ring, with a line under them.
class _DialReading extends StatelessWidget {
  const _DialReading(this.reading, this.caption);

  final String reading, caption;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Column(
      mainAxisSize: .min,
      children: [
        Text(
          reading,
          style: TextStyle(
            fontSize: reading.length > 5 ? 34 : 44,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -1,
            color: colors.text,
            fontFeatures: _tabular,
          ),
        ),
        const SizedBox(height: 4),
        Text(caption, style: BnType.caption.copyWith(color: colors.muted)),
      ],
    );
  }
}

/// A ring to drag around, once around being [maxMinutes]. The reading in the
/// middle can be tapped to type any length.
class _TimerDial extends StatelessWidget {
  const _TimerDial({
    required this.minutes,
    required this.reading,
    required this.caption,
    required this.color,
    required this.onChanged,
    required this.onTapCenter,
  });

  /// 12 hours, each mark on the ring being an hour.
  static const maxMinutes = 720;

  /// What dragging moves by: single minutes can't be aimed at on a ring this
  /// long. A custom length can be typed in.
  static const _dragStep = 5;
  static const _size = 210.0;

  final int minutes;
  final String reading, caption;
  final Color color;
  final ValueChanged<int> onChanged;
  final VoidCallback onTapCenter;

  void _drag(Offset position) {
    final d = position - const Offset(_size / 2, _size / 2);
    final turn = (d.direction + pi / 2) % (2 * pi) / (2 * pi);
    final next = (turn * maxMinutes / _dragStep).round() * _dragStep;
    // no jumping across the top, from the longest time to the shortest
    if ((next - minutes).abs() > maxMinutes / 2) return;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return SizedBox.square(
      dimension: _size,
      child: GestureDetector(
        onPanDown: (details) => _drag(details.localPosition),
        onPanUpdate: (details) => _drag(details.localPosition),
        child: CustomPaint(
          painter: _TimerDialPainter(
            turn: min(minutes, maxMinutes) / maxMinutes,
            color: color,
            track: colors.accentTint,
            ticks: colors.faint,
          ),
          child: Center(
            child: GestureDetector(
              onTap: onTapCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _DialReading(reading, caption),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerDialPainter extends CustomPainter {
  _TimerDialPainter({
    required this.turn,
    required this.color,
    required this.track,
    required this.ticks,
  });

  final double turn;
  final Color color, track, ticks;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke;
    final ring = Paint()
      ..style = .stroke
      ..strokeWidth = stroke
      ..strokeCap = .round;
    canvas.drawCircle(center, radius, ring..color = track);
    final box = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(box, -pi / 2, turn * 2 * pi, false, ring..color = color);

    final tick = Paint()
      ..color = ticks
      ..strokeWidth = 2
      ..strokeCap = .round;
    for (var i = 0; i < 12; i++) {
      final direction = Offset.fromDirection(-pi / 2 + i * pi / 6);
      canvas.drawLine(
        center + direction * (radius - stroke),
        center + direction * (radius - stroke - (i % 3 == 0 ? 8 : 4)),
        tick,
      );
    }

    final knob = center + Offset.fromDirection(-pi / 2 + turn * 2 * pi, radius);
    canvas.drawCircle(knob, stroke * 0.85, Paint()..color = Colors.white);
    canvas.drawCircle(knob, stroke * 0.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TimerDialPainter oldDelegate) =>
      turn != oldDelegate.turn ||
      color != oldDelegate.color ||
      track != oldDelegate.track;
}

/// What's left of a running timer, as a ring around the time.
class _Ring extends StatelessWidget {
  const _Ring({
    required this.value,
    required this.color,
    required this.reading,
    required this.caption,
  });

  final double value;
  final Color color;
  final String reading, caption;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return SizedBox.square(
      dimension: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: const Duration(milliseconds: 250),
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: colors.accentTint,
              ),
            ),
          ),
          _DialReading(reading, caption),
        ],
      ),
    );
  }
}

/// A running timer or stopwatch in the nav bar: a dark pill with the time
/// and a pause button. Tap it for its card, drag it anywhere.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.color,
    required this.paused,
    required this.onPause,
    required this.onTap,
    required this.onDrag,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool paused;
  final VoidCallback onPause, onTap;
  final GestureDragUpdateCallback onDrag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanUpdate: onDrag,
      child: AnimatedContainer(
        duration: BnMotion.normal,
        height: 34,
        padding: const EdgeInsets.only(left: 12, right: 2),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: color,
          shadows: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: _tabular,
                ),
              ),
              IconButton(
                tooltip: paused ? 'Resume' : 'Pause',
                onPressed: onPause,
                iconSize: 18,
                color: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                icon: Icon(paused ? Icons.play_arrow : Icons.pause),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A running timer, as a dark pill that turns orange in the last minute; tap
/// it for a card with its ring and buttons. Uses the wall clock, so it stays
/// right while the app is in the background. ponytail: no notification when
/// the app is closed, [onFinished] fires when the app is next open.
class CountdownChip extends StatefulWidget {
  const CountdownChip({
    super.key,
    required this.setup,
    required this.onFinished,
    required this.onClose,
  });

  final TimerSetup setup;

  /// The editor buzzes and shows "Timer finished" here.
  final VoidCallback onFinished;
  final VoidCallback onClose;

  @override
  State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> {
  late final Timer _ticker;

  /// When it ends, while running.
  late DateTime? _end = DateTime.now().add(widget.setup.duration);

  /// What's left, while paused.
  Duration _pausedLeft = Duration.zero;

  /// What the ring counts down from.
  late Duration _total = widget.setup.duration;

  Offset _dragged = Offset.zero;

  Duration get _left => _end?.difference(DateTime.now()) ?? _pausedLeft;
  bool get _paused => _end == null;
  bool get _lastMinute => !_paused && _left < const Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_end == null) return;
      if (_left > Duration.zero) {
        setState(() {});
      } else {
        _ticker.cancel();
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _pauseOrResume() => setState(() {
    if (_end != null) {
      _pausedLeft = _left;
      _end = null;
    } else {
      _end = DateTime.now().add(_pausedLeft);
    }
  });

  void _add(int minutes) => setState(() {
    final extra = Duration(minutes: minutes);
    _total += extra;
    if (_end != null) {
      _end = _end!.add(extra);
    } else {
      _pausedLeft += extra;
    }
  });

  void _reset() => setState(() {
    _total = widget.setup.duration;
    if (_end != null) {
      _end = DateTime.now().add(_total);
    } else {
      _pausedLeft = _total;
    }
  });

  String get _text => _hms(max(_left.inMilliseconds / 1000, 0).ceil());

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _dragged,
      child: _Pill(
        icon: widget.setup.isBreak
            ? Icons.free_breakfast_outlined
            : Icons.timer_outlined,
        text: _text,
        color: _lastMinute ? _lastMinuteColor : _pillColor,
        paused: _paused,
        onPause: _pauseOrResume,
        onTap: () => showAppleDialog<void>(
          context: context,
          builder: (context) => _CountdownCard(this),
        ),
        onDrag: (details) => setState(() => _dragged += details.delta),
      ),
    );
  }
}

/// A running timer's card: the ring, more time, reset, pause and stop.
class _CountdownCard extends StatefulWidget {
  const _CountdownCard(this.chip);

  final _CountdownChipState chip;

  @override
  State<_CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<_CountdownCard> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (widget.chip.mounted) return setState(() {});
      // the time is up, or the timer was closed
      _ticker.cancel();
      Navigator.maybePop(context);
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chip = widget.chip;
    final colors = BadNotesColors.of(context);
    final total = chip._total;
    final share = total.inMilliseconds == 0
        ? 0.0
        : (chip._left.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    void act(VoidCallback action) => setState(action);
    return _Card(
      children: [
        Text(
          chip.widget.setup.isBreak ? 'Break' : 'Timer',
          style: BnType.section.copyWith(color: colors.text),
        ),
        const SizedBox(height: 16),
        _Ring(
          value: share,
          color: chip._lastMinute ? _lastMinuteColor : colors.accent,
          reading: chip._text,
          caption: 'of ${_hms(total.inSeconds)}',
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final minutes in const [1, 5, 10])
              BnChip(
                label: '+$minutes min',
                onTap: () => act(() => chip._add(minutes)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            BnButton(label: 'Reset', onPressed: () => act(chip._reset)),
            BnButton.primary(
              label: chip._paused ? 'Resume' : 'Pause',
              icon: chip._paused ? Icons.play_arrow : Icons.pause,
              onPressed: () => act(chip._pauseOrResume),
            ),
            BnButton.destructive(
              label: 'Stop',
              onPressed: () {
                Navigator.pop(context);
                chip.widget.onClose();
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Counts time spent focusing, and apart from it, time spent on a break.
/// Goes by the wall clock, so it stays right while the app is in the background.
class StudyStopwatch {
  StudyStopwatch({DateTime Function() clock = DateTime.now}) : _clock = clock {
    _since = _clock();
  }

  final DateTime Function() _clock;
  Duration _focus = Duration.zero, _break = Duration.zero;

  /// The focus time at each lap, oldest first.
  final laps = <Duration>[];

  /// Since when time hasn't been counted yet, or null while paused.
  DateTime? _since;
  var _onBreak = false;

  void _count() {
    final since = _since;
    if (since == null) return;
    final now = _clock();
    if (_onBreak) {
      _break += now.difference(since);
    } else {
      _focus += now.difference(since);
    }
    _since = now;
  }

  Duration get focus {
    _count();
    return _focus;
  }

  Duration get breakTime {
    _count();
    return _break;
  }

  bool get paused => _since == null;

  bool get onBreak => _onBreak;
  set onBreak(bool value) {
    _count();
    _onBreak = value;
  }

  void pauseOrResume() {
    if (paused) {
      _since = _clock();
    } else {
      _count();
      _since = null;
    }
  }

  void lap() => laps.add(focus);

  void reset() {
    _focus = _break = Duration.zero;
    _onBreak = false;
    laps.clear();
    if (!paused) _since = _clock();
  }
}

/// A stopwatch's time: big minutes and seconds, small hundredths.
class _StopwatchReading extends StatelessWidget {
  const _StopwatchReading(this.time);

  final Duration time;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Text.rich(
      TextSpan(
        text: _hms(time.inSeconds),
        children: [
          TextSpan(
            text: '.${_hundredths(time)}',
            style: TextStyle(fontSize: 26, color: colors.faint),
          ),
        ],
      ),
      style: TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.w700,
        height: 1,
        letterSpacing: -1,
        color: colors.text,
        fontFeatures: _tabular,
      ),
    );
  }
}

/// Shows a [StudyStopwatch] as a dark pill with the focus time (the break
/// time while on a break); tap it for a card with laps. Drag it anywhere.
class StopwatchChip extends StatefulWidget {
  const StopwatchChip({
    super.key,
    required this.stopwatch,
    required this.onClose,
  });

  final StudyStopwatch stopwatch;
  final VoidCallback onClose;

  @override
  State<StopwatchChip> createState() => _StopwatchChipState();
}

class _StopwatchChipState extends State<StopwatchChip> {
  late final Timer _ticker;
  Offset _dragged = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stopwatch = widget.stopwatch;
    return Transform.translate(
      offset: _dragged,
      child: _Pill(
        icon: stopwatch.onBreak ? Icons.free_breakfast_outlined : Icons.av_timer,
        text: _hms(
          (stopwatch.onBreak ? stopwatch.breakTime : stopwatch.focus).inSeconds,
        ),
        color: _pillColor,
        paused: stopwatch.paused,
        onPause: () => setState(stopwatch.pauseOrResume),
        onTap: () => showAppleDialog<void>(
          context: context,
          builder: (context) =>
              _StopwatchCard(stopwatch: stopwatch, onClose: widget.onClose),
        ),
        onDrag: (details) => setState(() => _dragged += details.delta),
      ),
    );
  }
}

/// A running stopwatch's card: the time to the hundredth, laps newest first,
/// and its buttons.
class _StopwatchCard extends StatefulWidget {
  const _StopwatchCard({required this.stopwatch, required this.onClose});

  final StudyStopwatch stopwatch;
  final VoidCallback onClose;

  @override
  State<_StopwatchCard> createState() => _StopwatchCardState();
}

class _StopwatchCardState extends State<_StopwatchCard> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 40),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stopwatch = widget.stopwatch;
    final colors = BadNotesColors.of(context);
    final laps = stopwatch.laps;
    void act(VoidCallback action) => setState(action);
    return _Card(
      children: [
        Text(
          stopwatch.onBreak ? 'On a break' : 'Stopwatch',
          style: BnType.section.copyWith(color: colors.text),
        ),
        const SizedBox(height: 16),
        _StopwatchReading(stopwatch.focus),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: .min,
          spacing: 4,
          children: [
            Icon(Icons.free_breakfast_outlined, size: 14, color: colors.muted),
            Text(
              '${_hms(stopwatch.breakTime.inSeconds)} break',
              style: BnType.caption.copyWith(
                color: colors.muted,
                fontFeatures: _tabular,
              ),
            ),
          ],
        ),
        if (laps.isNotEmpty) const SizedBox(height: 12),
        for (var i = laps.length - 1; i >= 0; i--) ...[
          Divider(height: 1, color: colors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  'Lap ${i + 1}',
                  style: BnType.body.copyWith(color: colors.text2),
                ),
                const Spacer(),
                Builder(
                  builder: (context) {
                    final lap = laps[i] - (i > 0 ? laps[i - 1] : Duration.zero);
                    return Text(
                      '${_hms(lap.inSeconds)}.${_hundredths(lap)}',
                      style: BnType.body.copyWith(
                        color: colors.text,
                        fontFeatures: _tabular,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            BnButton(
              label: 'Lap',
              icon: Icons.flag_outlined,
              onPressed: stopwatch.paused ? null : () => act(stopwatch.lap),
            ),
            BnButton.primary(
              label: stopwatch.paused ? 'Resume' : 'Pause',
              icon: stopwatch.paused ? Icons.play_arrow : Icons.pause,
              onPressed: () => act(stopwatch.pauseOrResume),
            ),
            BnButton(
              label: stopwatch.onBreak ? 'Focus' : 'Break',
              icon: stopwatch.onBreak
                  ? Icons.timer_outlined
                  : Icons.free_breakfast_outlined,
              onPressed: () => act(() => stopwatch.onBreak = !stopwatch.onBreak),
            ),
            BnButton(
              label: 'Reset',
              icon: Icons.replay,
              onPressed: () => act(stopwatch.reset),
            ),
            BnButton.destructive(
              label: 'Stop',
              onPressed: () {
                Navigator.pop(context);
                widget.onClose();
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// A handle on the edge of the canvas, to drag through a long note. Along the
/// right edge, or the bottom edge when pages scroll sideways.
class PageSlider extends StatefulWidget {
  const PageSlider({
    super.key,
    required this.pages,
    required this.transformationController,
    required this.onTap,
  });

  final List<EditorPage> pages;
  final TransformationController transformationController;

  /// A tap on the handle, instead of dragging it.
  final VoidCallback onTap;

  @override
  State<PageSlider> createState() => _PageSliderState();
}

class _PageSliderState extends State<PageSlider> {
  static const _handleLength = 60.0;
  static const _handleThickness = 28.0;
  static const _margin = 8.0;

  var _dragging = false;

  double _scrollableLength(Size size, bool horizontal) =>
      CanvasGestureDetector.getTopOfPage(
            pageIndex: widget.pages.length,
            pages: widget.pages,
            screenWidth: size.width,
          ) *
          widget.transformationController.value.approxScale -
      (horizontal ? size.width : size.height);

  void _dragBy(double delta, Size size, bool horizontal) {
    final controller = widget.transformationController;
    final scrollable = _scrollableLength(size, horizontal);
    final track =
        (horizontal ? size.width : size.height) -
        _handleLength -
        2 * _margin;
    if (scrollable <= 0 || track <= 0) return;

    final translation = controller.value.getTranslation();
    final position = horizontal ? translation.x : translation.y;
    final moved = (-position + delta / track * scrollable).clamp(
      0.0,
      scrollable,
    );
    controller.value = controller.value.clone()
      ..setTranslationRaw(
        horizontal ? -moved : translation.x,
        horizontal ? translation.y : -moved,
        translation.z,
      );
  }

  int _pageAt(double position, Size size, bool horizontal) {
    final scale = widget.transformationController.value.approxScale;
    final viewport = horizontal ? size.width : size.height;
    final middle = (position + viewport / 2) / scale;
    for (int i = 0; i < widget.pages.length; i++) {
      final end = CanvasGestureDetector.getTopOfPage(
        pageIndex: i + 1,
        pages: widget.pages,
        screenWidth: size.width,
      );
      if (middle < end) return i;
    }
    return widget.pages.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final horizontal = CanvasGestureDetector.horizontal;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return ListenableBuilder(
          listenable: widget.transformationController,
          builder: (context, _) {
            final scrollable = _scrollableLength(size, horizontal);
            if (scrollable <= 0) return const SizedBox.shrink();

            final translation = widget.transformationController.value
                .getTranslation();
            final position = (-(horizontal ? translation.x : translation.y))
                .clamp(0.0, scrollable);
            final track =
                (horizontal ? size.width : size.height) -
                _handleLength -
                2 * _margin;
            final along = _margin + position / scrollable * track;

            final handle = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              onPanStart: (_) => setState(() => _dragging = true),
              onPanUpdate: (details) => _dragBy(
                horizontal ? details.delta.dx : details.delta.dy,
                size,
                horizontal,
              ),
              onPanEnd: (_) => setState(() => _dragging = false),
              onPanCancel: () => setState(() => _dragging = false),
              child: Container(
                width: horizontal ? _handleLength : _handleThickness,
                height: horizontal ? _handleThickness : _handleLength,
                decoration: BoxDecoration(
                  color: _dragging
                      ? colorScheme.primary
                      : colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: RotatedBox(
                  quarterTurns: horizontal ? 1 : 0,
                  child: Icon(
                    Icons.unfold_more,
                    size: 20,
                    color: _dragging
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );

            return Stack(
              children: [
                if (horizontal)
                  Positioned(left: along, bottom: 2, child: handle)
                else
                  Positioned(top: along, right: 2, child: handle),
                if (_dragging)
                  Positioned(
                    left: horizontal ? along : null,
                    top: horizontal ? null : along + 14,
                    right: horizontal ? null : _handleThickness + 10,
                    bottom: horizontal ? _handleThickness + 10 : null,
                    child: IgnorePointer(
                      child: Chip(
                        label: Text(
                          '${_pageAt(position, size, horizontal) + 1} / ${widget.pages.length}',
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
