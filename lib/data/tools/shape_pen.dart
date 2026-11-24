import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/components/canvas/_circle_stroke.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/shape_recognizer.dart';
import 'package:badnotes/i18n/strings.g.dart';

/// What dragging with the shape tool draws. [auto] is freehand ink that snaps
/// to whatever it looks like when the pen is held still.
enum ShapeKind {
  auto(Icons.gesture, 'Draw and hold'),
  line(Icons.remove, 'Line'),
  arrow(Icons.arrow_right_alt, 'Arrow'),
  elbow(Icons.turn_right, 'Elbow connector'),
  rectangle(Icons.crop_square, 'Rectangle'),
  ellipse(Icons.circle_outlined, 'Circle'),
  triangle(Icons.change_history, 'Triangle'),
  pentagon(Icons.pentagon_outlined, 'Pentagon'),
  hexagon(Icons.hexagon_outlined, 'Hexagon'),
  star(Icons.star_border, 'Star'),
  heart(Icons.favorite_border, 'Heart');

  const ShapeKind(this.icon, this.label);
  final IconData icon;
  final String label;

  /// The shape's corners when dragged from [from] to [to].
  List<Offset> corners(Offset from, Offset to) {
    final box = Rect.fromPoints(from, to);
    Offset at(double x, double y) =>
        Offset(box.left + x * box.width, box.top + y * box.height);
    List<Offset> around(int count, {int skip = 1}) => [
      for (int i = 0; i <= count; i++)
        at(
          0.5 + 0.5 * cos(-pi / 2 + i * skip * 2 * pi / count),
          0.5 + 0.5 * sin(-pi / 2 + i * skip * 2 * pi / count),
        ),
    ];
    switch (this) {
      case .auto || .line:
        return [from, to];
      case .arrow:
        final length = (to - from).distance;
        if (length == 0) return [from, to];
        final back = (from - to).direction;
        final head = min(length / 3, 40.0);
        const spread = 28 * pi / 180;
        return [
          from,
          to,
          to + Offset.fromDirection(back + spread, head),
          to,
          to + Offset.fromDirection(back - spread, head),
        ];
      case .elbow:
        // across, then up or down, then across again: right angles only, in
        // whichever direction it's dragged
        final middle = (from.dx + to.dx) / 2;
        if ((to.dx - from.dx).abs() < 2 || (to.dy - from.dy).abs() < 2) {
          return [from, to];
        }
        return [from, Offset(middle, from.dy), Offset(middle, to.dy), to];
      case .rectangle:
        return [
          box.topLeft,
          box.topRight,
          box.bottomRight,
          box.bottomLeft,
          box.topLeft,
        ];
      case .ellipse:
        return around(96);
      case .triangle:
        return [at(0.5, 0), at(1, 1), at(0, 1), at(0.5, 0)];
      case .pentagon:
        return around(5);
      case .hexagon:
        return around(6);
      case .star:
        return around(5, skip: 2);
      case .heart:
        return [
          for (int i = 0; i <= 96; i++)
            () {
              final t = i / 96 * 2 * pi;
              final x = 16 * pow(sin(t), 3);
              final y =
                  13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t);
              return at(0.5 + x / 34, 0.42 - y / 32);
            }(),
        ];
    }
  }
}

class ShapePen extends Pen {
  new()
    : super(
        name: t.editor.pens.shapePen,
        sizeMin: 1,
        sizeMax: 25,
        sizeStep: 1,
        icon: shapePenIcon,
        options: stows.lastShapePenOptions.value,
        pressureEnabled: false,
        color: Color(stows.lastShapePenColor.value),
        toolId: .shapePen,
      );

  static const shapePenIcon = FontAwesomeIcons.shapes;

  /// Has its own toolbar button, like the ballpoint pen.
  static final currentShapePen = ShapePen();

  static ShapeKind get kind => ShapeKind.values.firstWhere(
    (kind) => kind.name == stows.shapeKind.value,
    orElse: () => .rectangle,
  );
  static set kind(ShapeKind kind) => stows.shapeKind.value = kind.name;

  Offset _dragStart = .zero;

  @override
  void onDragStart(
    Offset position,
    EditorPage page,
    int pageIndex,
    double? pressure,
  ) {
    _dragStart = position;
    super.onDragStart(position, page, pageIndex, pressure);
    Pen.currentStroke?.shapeStyle = defaultStyle(color);
  }

  /// How a new shape of [color] looks, from the shape settings.
  static ShapeStyle defaultStyle(Color color) {
    int at(int i, int length) => i.clamp(0, length - 1);
    return ShapeStyle(
      fill: stows.shapeFill.value
          ? color.withValues(
              alpha: stows.shapeFillOpacity.value.clamp(0.0, 1.0),
            )
          : null,
      line:
          ShapeLine.values[at(stows.shapeLine.value, ShapeLine.values.length)],
      rounded: stows.shapeRounded.value,
      arrowStart: ShapeArrow
          .values[at(stows.shapeArrowStart.value, ShapeArrow.values.length)],
      arrowEnd: ShapeArrow
          .values[at(stows.shapeArrowEnd.value, ShapeArrow.values.length)],
    );
  }

  /// The corners of a drawn shape: where its line turns, and its ends.
  /// Its points also run along the sides, for erasing and the lasso.
  static List<int> cornerIndices(Stroke stroke) {
    final points = stroke.centerPoints;
    if (points.length < 3) return [for (int i = 0; i < points.length; i++) i];
    final closed = stroke.isClosedShape;
    final last = closed ? points.length - 2 : points.length - 1;
    final corners = <int>[0];
    for (int i = 1; i < last; i++) {
      final a = points[i] - points[i - 1], b = points[i + 1] - points[i];
      if (a.distance == 0 || b.distance == 0) continue;
      final turn = (a.direction - b.direction).abs() % (2 * pi);
      // a real corner turns sharply: the gentle turns between the points of
      // a curve or a hand-drawn wobble (10 degrees and up used to count) gave
      // a dot at every one of them
      if (min(turn, 2 * pi - turn) > 0.5) corners.add(i);
    }
    // a closed shape's last point is next to its first, one corner not two
    if (last > 0 && !closed) corners.add(last);
    // that many turns is a curve, not a polygon: just its two ends
    if (corners.length > 12) return closed ? <int>[] : [0, last];
    return corners;
  }

  /// Moves corner [corner] (of [cornerIndices]) of [stroke] to [to], keeping
  /// the sides straight and closed shapes closed.
  static void moveCorner(Stroke stroke, int corner, Offset to) {
    final points = stroke.centerPoints;
    final indices = cornerIndices(stroke);
    if (corner < 0 || corner >= indices.length) return;
    final closed = stroke.isClosedShape;
    final corners = [for (final i in indices) points[i]];
    corners[corner] = to;
    if (closed) corners.add(corners.first);
    stroke.replacePoints(_withPointsAlongSides(corners, stroke.options.size));
  }

  @override
  void onDragUpdate(Offset position, double? pressure) {
    final stroke = Pen.currentStroke;
    if (kind == .auto || stroke == null || stroke.isEmpty) {
      super.onDragUpdate(position, pressure);
      return;
    }
    stroke.replacePoints(
      _withPointsAlongSides(
        kind.corners(_dragStart, position),
        stroke.options.size,
      ),
    );
  }

  /// [stroke]'s area drawn as [kind] instead.
  static Stroke changedTo(Stroke stroke, ShapeKind kind) {
    final box = stroke.bounds.deflate(stroke.options.size / 2);
    return Stroke(
        color: stroke.color,
        pressureEnabled: false,
        options: stroke.options.copyWith(),
        pageIndex: stroke.pageIndex,
        page: stroke.page,
        toolId: .shapePen,
      )
      ..addPoints(
        _withPointsAlongSides(
          kind.corners(box.topLeft, box.bottomRight),
          stroke.options.size,
        ),
      )
      ..shapeStyle = stroke.shapeStyle;
  }

  /// How long the pen has to stay still before the ink snaps to a shape.
  static var debounceDuration = getDebounceFromPref();
  static Duration getDebounceFromPref() {
    assert(stows.shapeRecognitionDelay.loaded);
    final ms = stows.shapeRecognitionDelay.value;
    if (ms < 0) {
      return const Duration(hours: 1);
    } else {
      return Duration(milliseconds: ms);
    }
  }

  /// [rawStroke] as a clean shape, or null if it doesn't look like one.
  ///
  /// The result is a [ToolId.shapePen] stroke, which is painted as a line of
  /// constant width whichever pen drew it. Except from a pencil or a
  /// highlighter: those stay what they are, graphite or see-through marker
  /// along the shape. As a shape-pen line, a pencil's shape turned solid dark.
  static Stroke? snapToShape(Stroke rawStroke) {
    final shape = recognizeShape(rawStroke.centerPoints);
    if (shape == null) return null;

    final options = rawStroke.options.copyWith(
      isComplete: true,
      smoothing: 0,
      streamline: 0,
      simulatePressure: false,
      start: StrokeEndOptions.start(taperEnabled: false),
      end: StrokeEndOptions.end(taperEnabled: false),
    );
    if (rawStroke.toolId == .pencil || rawStroke.toolId == .highlighter) {
      final corners = shape.center != null
          ? [
              for (int i = 0; i <= 72; i++)
                shape.center! +
                    Offset.fromDirection(i / 72 * 2 * pi, shape.radius!),
            ]
          : shape.points;
      return Stroke(
        color: rawStroke.color,
        pressureEnabled: false,
        options: options,
        pageIndex: rawStroke.pageIndex,
        page: rawStroke.page,
        toolId: rawStroke.toolId,
      )..addPoints(_withPointsAlongSides(corners, options.size));
    }
    if (shape.center != null) {
      return CircleStroke(
        color: rawStroke.color,
        pressureEnabled: false,
        options: options,
        pageIndex: rawStroke.pageIndex,
        page: rawStroke.page,
        toolId: .shapePen,
        center: shape.center!,
        radius: shape.radius!,
      )..shapeStyle = defaultStyle(rawStroke.color);
    }
    return Stroke(
        color: rawStroke.color,
        pressureEnabled: false,
        options: options,
        pageIndex: rawStroke.pageIndex,
        page: rawStroke.page,
        toolId: .shapePen,
      )
      ..addPoints(_withPointsAlongSides(shape.points, options.size))
      ..shapeStyle = defaultStyle(rawStroke.color);
  }

  /// Erasing, the lasso and exporting all work from the stroke's points,
  /// so a long side can't be just its two ends.
  static List<Offset> _withPointsAlongSides(List<Offset> corners, double size) {
    final spacing = max(size, 4.0);
    final points = [corners.first];
    for (int i = 1; i < corners.length; i++) {
      final side = corners[i] - corners[i - 1];
      final steps = (side.distance / spacing).ceil();
      for (int k = 1; k <= steps; k++) {
        points.add(corners[i - 1] + side * (k / steps));
      }
    }
    return points;
  }
}
