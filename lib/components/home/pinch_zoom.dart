import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pinch to zoom and pan [child] with two fingers (one too, with
/// [panWithOneFinger]), the mouse wheel (ctrl to zoom) or a trackpad.
///
/// Reads raw pointers instead of joining the gesture arena, so the taps,
/// holds and drags of what's inside can't win over a pinch: with
/// InteractiveViewer, a pinch that began on a note on the board did
/// nothing. Pointers [ignore] claims (e.g. on a picked-up note) are left
/// to [child].
class PinchZoom extends StatefulWidget {
  const new({
    super.key,
    required this.view,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 3,
    this.panWithOneFinger = false,
    this.ignore,
    this.moved,
    this.content,
  });

  final TransformationController view;
  final Widget child;
  final double minScale, maxScale;
  final bool panWithOneFinger;

  /// Whether a pointer that just went down belongs to [child] alone.
  final bool Function(int pointer)? ignore;

  /// Set false when a gesture starts, true once it pans or zooms: a tap
  /// that ends a pinch is no tap.
  final ValueNotifier<bool>? moved;

  /// The size of what's zoomed, to keep some of it on the screen.
  final Size? content;

  /// The view's zoom.
  static double scaleOf(Matrix4 m) => m.getMaxScaleOnAxis();

  @override
  State<PinchZoom> createState() => _PinchZoomState();
}

class _PinchZoomState extends State<PinchZoom> {
  /// Where each pointer is, in this widget.
  final _at = <int, Offset>{};
  final _ignored = <int>{};

  Matrix4? _start;
  Offset _startFocal = Offset.zero;
  double _startSpan = 0;
  var _pinching = false, _panning = false, _hadTwo = false;
  Size _viewport = Size.zero;

  Matrix4 get _value => widget.view.value;

  /// [m], kept so part of [PinchZoom.content] stays on the screen.
  Matrix4 _clamped(Matrix4 m) {
    final content = widget.content;
    if (content == null || _viewport.isEmpty) return m;
    final s = PinchZoom.scaleOf(m);
    final w = content.width * s, h = content.height * s;
    final mx = _viewport.width * 0.5, my = _viewport.height * 0.5;
    double fit(double t, double size, double view, double margin) {
      final lo = (view - size - margin).clamp(double.negativeInfinity, 0.0);
      final hi = margin.clamp(view - size, double.infinity);
      return t.clamp(lo, hi);
    }

    final t = m.getTranslation();
    return Matrix4.copy(m)..setTranslationRaw(
      fit(t.x, w, _viewport.width, mx),
      fit(t.y, h, _viewport.height, my),
      0,
    );
  }

  /// [from] zoomed by [by] about [focal] (a point here), moved by [pan].
  Matrix4 _zoomed(Matrix4 from, double by, Offset focal, Offset pan) {
    final current = PinchZoom.scaleOf(from);
    final target = (current * by).clamp(widget.minScale, widget.maxScale);
    final f = target / current;
    return Matrix4.identity()
      ..translateByDouble(focal.dx + pan.dx, focal.dy + pan.dy, 0, 1)
      ..scaleByDouble(f, f, 1, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1)
      ..multiply(from);
  }

  void _set(Matrix4 m) {
    widget.view.value = _clamped(m);
    widget.moved?.value = true;
  }

  List<Offset> get _live => [
    for (final e in _at.entries)
      if (!_ignored.contains(e.key)) e.value,
  ];

  void _beginPinch() {
    final p = _live;
    _start = Matrix4.copy(_value);
    _startFocal = (p[0] + p[1]) / 2;
    _startSpan = (p[0] - p[1]).distance;
    _pinching = true;
    _panning = false;
    _hadTwo = true;
  }

  void _down(PointerDownEvent e) {
    if (_at.isEmpty) {
      widget.moved?.value = false;
      _hadTwo = false;
    }
    _at[e.pointer] = e.localPosition;
    if (widget.ignore?.call(e.pointer) ?? false) _ignored.add(e.pointer);
    if (_ignored.isNotEmpty) return;
    final count = _at.length;
    if (count == 2) {
      _beginPinch();
    } else if (count == 1) {
      _start = Matrix4.copy(_value);
      _startFocal = e.localPosition;
    }
  }

  void _move(PointerMoveEvent e) {
    if (!_at.containsKey(e.pointer)) return;
    _at[e.pointer] = e.localPosition;
    if (_ignored.isNotEmpty) return;
    final p = _live;
    if (_pinching && p.length >= 2) {
      final focal = (p[0] + p[1]) / 2;
      final span = (p[0] - p[1]).distance;
      final by = _startSpan < 1 ? 1.0 : span / _startSpan;
      _set(_zoomed(_start!, by, _startFocal, focal - _startFocal));
      return;
    }
    if (p.length != 1 || _hadTwo || !widget.panWithOneFinger) return;
    final delta = p.first - _startFocal;
    if (!_panning && delta.distance < kTouchSlop) return;
    _panning = true;
    _set(Matrix4.translationValues(delta.dx, delta.dy, 0)..multiply(_start!));
  }

  void _up(PointerEvent e) {
    _at.remove(e.pointer);
    _ignored.remove(e.pointer);
    if (_at.length < 2) _pinching = false;
    if (_at.length == 2 && _ignored.isEmpty) _beginPinch();
    if (_at.isEmpty) _panning = false;
  }

  void _signal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(e, (e) {
      e as PointerScrollEvent;
      final zoom =
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      if (zoom) {
        final by = e.scrollDelta.dy > 0 ? 1 / 1.1 : 1.1;
        _set(_zoomed(_value, by, e.localPosition, Offset.zero));
      } else {
        _set(
          Matrix4.translationValues(-e.scrollDelta.dx, -e.scrollDelta.dy, 0)
            ..multiply(_value),
        );
      }
    });
  }

  Matrix4? _padStart;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _viewport = constraints.biggest;
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _up,
        onPointerSignal: _signal,
        // trackpads: two fingers pan, a pinch zooms
        onPointerPanZoomStart: (_) => _padStart = Matrix4.copy(_value),
        onPointerPanZoomUpdate: (e) {
          final start = _padStart;
          if (start == null) return;
          _set(_zoomed(start, e.scale, e.localPosition, e.pan));
        },
        onPointerPanZoomEnd: (_) => _padStart = null,
        // the transform is laid out at the content's own size, under an
        // unconstrained box: then a tap on any part of the content hits it,
        // also parts past the bottom of the screen at 100%
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: ValueListenableBuilder(
              valueListenable: widget.view,
              // only the transform changes as it zooms: what's inside isn't
              // built again
              builder: (context, m, child) => Transform(
                key: const ValueKey('pinch-zoom-transform'),
                transform: m,
                child: child,
              ),
              child: SizedBox.fromSize(
                size: widget.content ?? _viewport,
                child: widget.child,
              ),
            ),
          ),
        ),
      );
    },
  );
}
