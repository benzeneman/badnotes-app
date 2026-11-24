import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:badnotes/components/editor_ui/editor_ui_colors.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/prefs.dart';

/// Which side of the page a [FloatingToolbar] sits at.
enum ToolbarEdge { top, left, right, bottom }

/// The rounded bar of the tool in use, floating over the page.
///
/// Hold it anywhere and it lifts off as a round pen that follows the finger.
/// Near an edge (most of the way to a side) it opens up into the bar again,
/// laid out for that edge. Let go, it glides to that edge,
/// or the nearest one, at the place along it where it was dropped, turning
/// upright at the sides. Remembers where.
///
/// Moving it only lays it out again: its buttons aren't rebuilt on each
/// frame of the drag, so it doesn't stutter.
///
/// Fills its parent, which should be the area over the page: put it in a
/// [Stack] with `Positioned.fill`.
class FloatingToolbar extends StatefulWidget {
  const FloatingToolbar({
    super.key,
    required this.builder,
    this.defaultEdge = ToolbarEdge.top,
    this.framed = true,
  });

  /// Builds the bar's contents along [axis].
  final Widget Function(BuildContext context, Axis axis) builder;
  final ToolbarEdge defaultEdge;

  /// Draws the white bar around the contents; off when they draw their own
  /// (the tool dock and its sub-bar).
  final bool framed;

  /// The edge the bar in [context] is at now.
  static ToolbarEdge edgeOf(BuildContext context) =>
      context.findAncestorStateOfType<_FloatingToolbarState>()?._shownEdge ??
      savedEdge;

  /// Six dots to drag the bar in [context] by: it lifts at once and follows
  /// the finger, as when the bar is held still for a moment.
  static Widget handle(BuildContext context, {bool vertical = false}) {
    final state = context.findAncestorStateOfType<_FloatingToolbarState>();
    // docked, there's nothing to drag
    if (state == null) return const SizedBox.shrink();
    return Semantics(
      label: 'Move the toolbar',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: state == null ? null : (d) => state._lift(d.globalPosition),
        onPanUpdate: state == null ? null : (d) => state._move(d.globalPosition),
        onPanEnd: state == null ? null : (_) => state._drop(),
        onPanCancel: state?._drop,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: BnDragHandle(vertical: vertical),
        ),
      ),
    );
  }

  static ToolbarEdge get savedEdge => switch (stows.floatingToolbarEdge.value) {
    0 => ToolbarEdge.top,
    1 => ToolbarEdge.left,
    2 => ToolbarEdge.right,
    3 => ToolbarEdge.bottom,
    _ => ToolbarEdge.top,
  };

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar>
    with SingleTickerProviderStateMixin {
  /// Where the bar's middle is while it's held, in this widget.
  final _held = ValueNotifier<Offset?>(null);

  /// The edge the held pen would drop the bar at, shown as a ghost there.
  /// Only this changes while it's dragged: the bar isn't built again until
  /// it's let go, so the drag stays smooth.
  final _near = ValueNotifier<ToolbarEdge?>(null);

  /// Nearer than this to an edge (logical pixels), it's chosen and its
  /// ghost shows; it stays chosen until the pen is further than [_leavePx],
  /// so a shaking finger at the border doesn't flicker between the two.
  /// Before, it was 15% of the screen: the ghost showed almost at once.
  static const _nearPx = 90.0, _leavePx = 130.0;

  /// From the drop to its place at an edge, on a spring.
  late final _glide = AnimationController.unbounded(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _from = null;
    });

  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 420,
    ratio: 0.82,
  );

  /// The bar's top left when it was let go, to glide from.
  Offset? _from;

  /// Where along its edge the bar's middle is, from 0 to 1.
  double get _along => stows.floatingToolbarAlong.value.clamp(0.0, 1.0);

  ToolbarEdge get _edge => stows.floatingToolbarEdge.value < 0
      ? widget.defaultEdge
      : FloatingToolbar.savedEdge;

  /// The edge the bar is laid out for now.
  ToolbarEdge get _shownEdge => _edge;

  /// The bar's last laid out top left and size, to start a drag from.
  Rect _last = Rect.zero;

  /// The bar's size before it was lifted, for the ghost.
  Size _barSize = Size.zero;
  Size _area = Size.zero;

  @override
  void dispose() {
    _held.dispose();
    _near.dispose();
    _glide.dispose();
    super.dispose();
  }

  void _lift(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    HapticFeedback.mediumImpact();
    _glide.stop();
    _from = null;
    _barSize = _last.size;
    // the pen is under the finger from the start: nothing jumps later
    _held.value = box.globalToLocal(global);
    _near.value = _edgeNear(_held.value!);
    setState(() {}); // shows it lifted
  }

  void _move(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || _held.value == null) return;
    final at = box.globalToLocal(global);
    _held.value = at;
    final near = _edgeNear(at);
    if (near != _near.value) {
      if (near != null) HapticFeedback.selectionClick();
      _near.value = near;
    }
  }

  /// The edge to drop at from [at]: the nearest within [_nearPx] of it;
  /// the one chosen already while within [_leavePx], unless
  /// another is clearly nearer (in a corner).
  ToolbarEdge? _edgeNear(Offset at) {
    final w = _area.width, h = _area.height;
    if (w <= 0 || h <= 0) return null;
    final distances = {
      ToolbarEdge.top: at.dy,
      ToolbarEdge.bottom: h - at.dy,
      ToolbarEdge.left: at.dx,
      ToolbarEdge.right: w - at.dx,
    };
    final nearest = distances.entries.reduce(
      (a, b) => a.value <= b.value ? a : b,
    );
    final now = _near.value;
    if (now != null &&
        distances[now]! <= _leavePx &&
        !(nearest.key != now && nearest.value < distances[now]! - 40)) {
      return now;
    }
    return nearest.value <= _nearPx ? nearest.key : null;
  }

  /// [along] pulled to the start, middle or end of an edge when close.
  static double _snap(double along) {
    for (final stop in const [0.0, 0.5, 1.0]) {
      if ((along - stop).abs() < 0.07) {
        HapticFeedback.selectionClick();
        return stop;
      }
    }
    return along;
  }

  void _drop() {
    final at = _held.value;
    if (at == null) return;
    final area = _area;
    // the nearest edge, by how far the pen is from each
    final distances = {
      ToolbarEdge.top: at.dy,
      ToolbarEdge.bottom: area.height - at.dy,
      ToolbarEdge.left: at.dx,
      ToolbarEdge.right: area.width - at.dx,
    };
    final edge =
        _near.value ??
        distances.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
    final along = _snap(
      edge == ToolbarEdge.top || edge == ToolbarEdge.bottom
          ? at.dx / area.width
          : at.dy / area.height,
    );
    _from = at - _last.size.center(Offset.zero);
    _held.value = null;
    _near.value = null;
    stows.floatingToolbarEdge.value = edge.index;
    stows.floatingToolbarAlong.value = along.clamp(0.0, 1.0);
    HapticFeedback.selectionClick();
    setState(() {});
    _glide.value = 0;
    _glide.animateWith(SpringSimulation(_spring, 0, 1, 0));
  }

  /// Where the bar will land at [edge], as a soft outline: the pen's at
  /// [at], so the place follows it along the edge.
  Widget _ghost(BuildContext context, ToolbarEdge edge, Offset at) {
    final side = edge == ToolbarEdge.left || edge == ToolbarEdge.right;
    // the bar runs the other way at the sides
    final wasSide = _edge == ToolbarEdge.left || _edge == ToolbarEdge.right;
    var size = side == wasSide ? _barSize : _barSize.flipped;
    size = Size(
      size.width.clamp(56.0, _area.width - 16),
      size.height.clamp(48.0, _area.height - 16),
    );
    const margin = 8.0;
    final left = switch (edge) {
      ToolbarEdge.left => margin,
      ToolbarEdge.right => _area.width - size.width - margin,
      _ => (at.dx - size.width / 2).clamp(margin, _area.width - size.width - margin),
    };
    final top = switch (edge) {
      ToolbarEdge.top => margin,
      ToolbarEdge.bottom => _area.height - size.height - margin,
      _ => (at.dy - size.height / 2).clamp(margin, _area.height - size.height - margin),
    };
    return Positioned(
      left: left,
      top: top,
      width: size.width,
      height: size.height,
      child: IgnorePointer(
        key: const ValueKey('toolbar-ghost'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EditorUi.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(EditorUi.barRadius),
            border: Border.all(
              color: EditorUi.accent.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = EditorUi.of(context);
    final lifted = _held.value != null;
    final edge = _edge;
    final axis = edge == ToolbarEdge.left || edge == ToolbarEdge.right
        ? Axis.vertical
        : Axis.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        _area = constraints.biggest;
        final bar = RepaintBoundary(
          child: RawGestureDetector(
            behavior: HitTestBehavior.deferToChild,
            gestures: {
              // held still for a moment, anywhere on the bar, it lifts off
              LongPressGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    LongPressGestureRecognizer
                  >(
                    () => LongPressGestureRecognizer(
                      duration: const Duration(milliseconds: 280),
                    ),
                    (r) => r
                      ..onLongPressStart = ((d) => _lift(d.globalPosition))
                      ..onLongPressMoveUpdate = ((d) => _move(d.globalPosition))
                      ..onLongPressEnd = ((_) => _drop())
                      ..onLongPressCancel = _drop,
                  ),
            },
            child: AnimatedSwitcher(
              // no overshoot: a bounce here looked like the bar shaking
              duration: const Duration(milliseconds: 150),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              // held, the whole bar follows the finger on its own layer:
              // nothing is built again until it's let go (design 10)
              child: !widget.framed
                  ? ConstrainedBox(
                      key: ValueKey(axis),
                      constraints: BoxConstraints(
                        maxWidth: _area.width - 16,
                        maxHeight: _area.height - 16,
                      ),
                      // a phone held upright: the tools scroll along
                      child: SingleChildScrollView(
                        scrollDirection: axis,
                        clipBehavior: Clip.none,
                        child: widget.builder(context, axis),
                      ),
                    )
                  : Material(
                      key: ValueKey(axis),
                      color: ui.bar,
                      elevation: lifted ? 12 : 4,
                      shadowColor: Colors.black45,
                      borderRadius: BorderRadius.circular(EditorUi.barRadius),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            // at the top, clear of the undo pill at the right
                            maxWidth:
                                _area.width -
                                (edge == ToolbarEdge.top
                                    ? _BarLayout.pillRoom + 24
                                    : 24),
                            maxHeight: _area.height - 16,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: axis,
                            child: widget.builder(context, axis),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        );
        final placed = CustomSingleChildLayout(
          delegate: _BarLayout(
            edge: edge,
            along: _along,
            held: _held,
            glide: _glide,
            from: () => _from,
            laidOut: (rect) => _last = rect,
          ),
          child: bar,
        );
        // the same tree held or not, so the drag that lifted it carries on
        return Stack(
          fit: StackFit.expand,
          children: [
            // where the bar will land, under the pen
            if (lifted)
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: Listenable.merge([_near, _held]),
                  builder: (context, _) {
                    final near = _near.value, at = _held.value;
                    return Stack(
                      children: [
                        if (near != null && at != null)
                          _ghost(context, near, at),
                      ],
                    );
                  },
                ),
              ),
            KeyedSubtree(key: const ValueKey('bar'), child: placed),
          ],
        );
      },
    );
  }
}

/// Puts the bar at its edge, under the finger while held, or on its way
/// from where it was dropped. Laid out again on every frame of those, without
/// building anything.
class _BarLayout extends SingleChildLayoutDelegate {
  _BarLayout({
    required this.edge,
    required this.along,
    required this.held,
    required this.glide,
    required this.from,
    required this.laidOut,
  }) : super(relayout: Listenable.merge([held, glide]));

  final ToolbarEdge edge;
  final double along;
  final ValueNotifier<Offset?> held;
  final Animation<double> glide;
  final Offset? Function() from;
  final ValueChanged<Rect> laidOut;

  static const _margin = 8.0;

  /// Room left at the top right for the floating undo/redo pill (two 38 px
  /// buttons, its padding and margin) and a 16 px gap from it.
  static const pillRoom = 2 * 38 + 6 + 16 + 16.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest);

  Offset _clamp(Offset at, Size area, Size child) => Offset(
    at.dx.clamp(_margin, max0(area.width - child.width - _margin)),
    at.dy.clamp(_margin, max0(area.height - child.height - _margin)),
  );

  static double max0(double v) => v < _margin ? _margin : v;

  @override
  Offset getPositionForChild(Size area, Size child) {
    final Offset position;
    if (held.value case final middle?) {
      position = _clamp(middle - child.center(Offset.zero), area, child);
    } else {
      var target = _clamp(
        switch (edge) {
          ToolbarEdge.top => Offset(area.width * along - child.width / 2, 0),
          ToolbarEdge.bottom => Offset(
            area.width * along - child.width / 2,
            area.height,
          ),
          ToolbarEdge.left => Offset(0, area.height * along - child.height / 2),
          ToolbarEdge.right => Offset(
            area.width,
            area.height * along - child.height / 2,
          ),
        },
        area,
        child,
      );
      if (edge == ToolbarEdge.top &&
          target.dx + child.width > area.width - pillRoom) {
        target = Offset(
          (area.width - pillRoom - child.width).clamp(_margin, double.infinity),
          target.dy,
        );
      }
      final start = from();
      // the spring can go a little past and come back
      position = start != null
          ? Offset.lerp(_clamp(start, area, child), target, glide.value)!
          : target;
    }
    laidOut(position & child);
    return position;
  }

  @override
  bool shouldRelayout(_BarLayout old) => old.edge != edge || old.along != along;
}
