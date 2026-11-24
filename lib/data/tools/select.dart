import 'dart:math';

import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/_circle_stroke.dart';
import 'package:badnotes/components/canvas/_rectangle_stroke.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/_tool.dart';
import 'package:badnotes/data/tools/shape_pen.dart';
import 'package:sbn/tool_id.dart';

enum SelectHandle {
  scale,
  rotate,
  topLeft,
  topRight,
  right,
  bottomRight,
  bottomLeft,
  left,
  bottom,
  top,
}

class Select extends Tool {
  new _();

  static final _currentSelect = Select._();
  static Select get currentSelect => _currentSelect;

  /// Rectangle lasso instead of freehand. Remembered for the session.
  static var rectangleMode = false;
  Offset _start = .zero;

  var selectResult = SelectResult(
    pageIndex: -1,
    strokes: const [],
    images: const [],
    path: Path(),
    pageIndexStart: null,
  );
  var doneSelecting = false;

  @override
  ToolId get toolId => .select;

  void unselect() {
    angle = 0;
    doneSelecting = false;
    editingCorners = false;
    attached = const [];
    selectResult.pageIndex = -1;
  }

  /// Writing on the selected sticky note: it goes wherever the note goes.
  List<Stroke> attached = const [];

  /// The selected strokes and the writing on a selected sticky note.
  List<Stroke> get movingStrokes => attached.isEmpty
      ? selectResult.strokes
      : [...selectResult.strokes, ...attached];

  /// How far the selection has been turned since it was made: its box
  /// turns with it, instead of growing round it.
  double angle = 0;

  /// The lasso's points as drawn.
  List<Offset> lassoPolygon = const [];

  static Offset turn(Offset p, double a) {
    final c = cos(a), s = sin(a);
    return Offset(p.dx * c - p.dy * s, p.dx * s + p.dy * c);
  }

  Rect? _box;
  int? _boxKey;

  /// What's picked, boxed tight, in the frame turned by [angle]: its
  /// points turned back by -[angle] round the page's origin. Drawn and
  /// touched after turning the canvas by [angle].
  Rect get box {
    final strokes = movingStrokes;
    final images = selectResult.images;
    final key = Object.hash(
      angle,
      Object.hashAll([for (final s in strokes) s.version]),
      Object.hashAll([for (final i in images) i.dstRect]),
      Object.hashAll([for (final i in images) i.rotation]),
    );
    if (key == _boxKey && _box != null) return _box!;
    Rect? r;
    void add(Offset p, double pad) {
      final q = turn(p, -angle);
      final b = Rect.fromCircle(center: q, radius: pad);
      r = r == null ? b : r!.expandToInclude(b);
    }

    for (final stroke in strokes) {
      final points = stroke.shownPoints;
      final step = max(1, points.length ~/ 300);
      for (int i = 0; i < points.length; i += step) {
        if (points[i].isFinite) add(points[i], stroke.options.size / 2);
      }
      if (points.isNotEmpty && points.last.isFinite) {
        add(points.last, stroke.options.size / 2);
      }
    }
    for (final image in images) {
      for (final corner in imageCorners(image)) {
        add(corner, 0);
      }
    }
    _boxKey = key;
    return _box = r ?? selectResult.path.getBounds();
  }

  /// The middle of [box], on the page.
  Offset get boxCenter => turn(box.center, angle);

  /// Whether [position] is in the picked area: the lasso or the box.
  bool grabs(Offset position) =>
      selectResult.path.contains(position) ||
      box.contains(turn(position, -angle));

  /// Whether the box is still level, so its sides can stretch it.
  bool get level => (angle % (2 * pi)).abs() < 1e-3;

  /// [stroke] split along the lasso, inside and outside, when it's a
  /// highlighter the eraser has cut that runs out of the lasso: the eraser
  /// only makes holes in a highlighter, so what looks like two pieces is one
  /// stroke, and the lasso took the piece outside too. Null when it needn't
  /// be split.
  static (Stroke, Stroke)? splitAtLasso(Stroke stroke, List<Offset> polygon) {
    if (stroke.toolId != .highlighter || stroke.holes.isEmpty) return null;
    if (polygon.length < 3) return null;
    final lasso = Path()..addPolygon(polygon, true);
    final points = stroke.shownPoints;
    final inside = points.where(lasso.contains).length;
    if (inside == 0 || inside == points.length) return null;
    Stroke piece(bool isInside) => stroke.copy()
      ..drawOrder = stroke.drawOrder
      ..clips = [...stroke.clips, (polygon: polygon, inside: isInside)];
    return (piece(true), piece(false));
  }

  /// Dragging the corners of the selected shape, instead of moving it.
  var editingCorners = false;

  /// The drawn shape, when it's all that is selected and its corners can be
  /// moved.
  Stroke? get singleShape {
    if (!doneSelecting || selectResult.images.isNotEmpty) return null;
    if (selectResult.strokes.length != 1) return null;
    final stroke = selectResult.strokes.first;
    if (stroke.toolId != .shapePen) return null;
    if (stroke is CircleStroke || stroke is RectangleStroke) return null;
    return stroke.centerPoints.length >= 2 ? stroke : null;
  }

  /// The corners of [singleShape] while [editingCorners].
  List<Offset> get shapeCorners {
    final shape = editingCorners ? singleShape : null;
    if (shape == null) return const [];
    final points = shape.centerPoints;
    return [for (final i in ShapePen.cornerIndices(shape)) points[i]];
  }

  /// The corner of [shapeCorners] under [position], if any.
  int? cornerAt(Offset position, double zoom) {
    final corners = shapeCorners;
    final reach = 28 / zoom;
    int? nearest;
    var nearestDistance = reach;
    for (final (i, corner) in corners.indexed) {
      final distance = (position - corner).distance;
      if (distance <= nearestDistance) {
        nearestDistance = distance;
        nearest = i;
      }
    }
    return nearest;
  }

  Color? getDominantStrokeColor() {
    if (!doneSelecting) return null;
    if (selectResult.strokes.isEmpty) return null;

    final colorDistribution = <Color, int>{};
    for (final stroke in selectResult.strokes) {
      colorDistribution.update(
        stroke.color,
        (value) => value + stroke.length,
        ifAbsent: () => stroke.length,
      );
    }
    assert(colorDistribution.isNotEmpty);

    return colorDistribution.entries.reduce((a, b) {
      return a.value > b.value ? a : b;
    }).key;
  }

  /// Screen-pixel gap between the selection and the rotate handle.
  static const handleGap = 32.0;

  /// Bottom-right corner: drag to resize.
  static Offset scaleHandle(Rect bounds) => bounds.bottomRight;

  /// Below the selection, clear of its bottom middle handle: drag to rotate.
  static Offset rotateHandle(Rect bounds, double zoom) =>
      Offset(bounds.center.dx, bounds.bottom + handleGap * 1.4 / zoom);

  /// The picture being edited, when it's all that is selected.
  EditorImage? get singleImage =>
      doneSelecting &&
          selectResult.strokes.isEmpty &&
          selectResult.images.length == 1
      ? selectResult.images.first
      : null;

  static Offset _onImage(EditorImage image, Offset point) =>
      Stroke.transformPoint(point, image.dstRect.center, 1, image.rotation);

  static List<Offset> imageCorners(EditorImage image) {
    final r = image.dstRect;
    return [
      for (final corner in [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft])
        _onImage(image, corner),
    ];
  }

  /// The four corners keep the picture's shape. The sides stretch it.
  static Map<SelectHandle, Offset> imageHandles(EditorImage image) {
    final r = image.dstRect;
    return {
      .topLeft: _onImage(image, r.topLeft),
      .topRight: _onImage(image, r.topRight),
      .right: _onImage(image, r.centerRight),
      .bottomRight: _onImage(image, r.bottomRight),
      .bottomLeft: _onImage(image, r.bottomLeft),
      .left: _onImage(image, r.centerLeft),
      .bottom: _onImage(image, r.bottomCenter),
      .top: _onImage(image, r.topCenter),
    };
  }

  static Offset imageBottomCenter(EditorImage image) =>
      _onImage(image, image.dstRect.bottomCenter);

  static Offset imageTopCenter(EditorImage image) =>
      _onImage(image, image.dstRect.topCenter);

  /// Under the picture, clear of its bottom middle handle.
  static Offset imageRotateHandle(EditorImage image, double zoom) => _onImage(
    image,
    image.dstRect.bottomCenter + Offset(0, handleGap * 1.4 / zoom),
  );

  /// Where [image] goes when [handle] is dragged to [position]. The opposite
  /// side stays at [anchor], which is where [handle]'s opposite was when the
  /// drag started.
  static Rect resizedImage({
    required EditorImage image,
    required SelectHandle handle,
    required Offset anchor,
    required Size startSize,
    required Offset position,
  }) {
    final across = switch (handle) {
      .topRight || .right || .bottomRight => 1.0,
      .topLeft || .left || .bottomLeft => -1.0,
      _ => 0.0,
    };
    final down = switch (handle) {
      .bottomLeft || .bottomRight || .bottom => 1.0,
      .topLeft || .topRight || .top => -1.0,
      _ => 0.0,
    };
    final u = Offset.fromDirection(image.rotation);
    final v = Offset(-u.dy, u.dx);
    final d = position - anchor;
    final wanted = Size(
      (d.dx * u.dx + d.dy * u.dy) * across,
      (d.dx * v.dx + d.dy * v.dy) * down,
    );

    final Size size;
    if (down == 0) {
      size = Size(max(wanted.width, minImageSide), startSize.height);
    } else if (across == 0) {
      size = Size(startSize.width, max(wanted.height, minImageSide));
    } else {
      final fit = max(
        wanted.width / startSize.width,
        wanted.height / startSize.height,
      );
      final smallest = minImageSide / startSize.shortestSide;
      size = startSize * max(fit, smallest);
    }
    final center =
        anchor +
        u * (across * size.width / 2) +
        v * (down * size.height / 2);
    return Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
  }

  /// A resized picture stays big enough to grab, and to fill its touch area.
  static const minImageSide = 50.0;

  /// The handle under [position] (page coordinates), if any.
  SelectHandle? handleAt(Offset position, double zoom) {
    if (selectResult.isEmpty) return null;
    final image = singleImage;
    if (image != null) {
      final reach = 28 / zoom;
      SelectHandle? nearest;
      var nearestDistance = reach;
      final handles = {
        ...imageHandles(image),
        SelectHandle.rotate: imageRotateHandle(image, zoom),
      };
      handles.forEach((handle, point) {
        final distance = (position - point).distance;
        if (distance <= nearestDistance) {
          nearestDistance = distance;
          nearest = handle;
        }
      });
      return nearest;
    }
    // in the box's own turned frame
    final bounds = box;
    final local = turn(position, -angle);
    // the rotate handle first: it's just under the bottom middle one
    if ((local - rotateHandle(bounds, zoom)).distance <= 20 / zoom) {
      return .rotate;
    }
    final reach = 24 / zoom; // finger-sized touch target on screen
    SelectHandle? nearest;
    var nearestDistance = reach;
    boxHandles(bounds).forEach((handle, point) {
      final distance = (local - point).distance;
      if (distance <= nearestDistance) {
        nearestDistance = distance;
        nearest = handle;
      }
    });
    if (level || nearest == null) return nearest;
    // turned: the corners grow it evenly, the sides don't stretch it
    return switch (nearest) {
      .topLeft || .topRight || .bottomLeft || .bottomRight => .scale,
      _ => null,
    };
  }

  /// The 4 corners and 4 side middles of a selection's [bounds], to drag
  /// for resizing it.
  static Map<SelectHandle, Offset> boxHandles(Rect bounds) => {
    SelectHandle.topLeft: bounds.topLeft,
    SelectHandle.top: bounds.topCenter,
    SelectHandle.topRight: bounds.topRight,
    SelectHandle.right: bounds.centerRight,
    SelectHandle.bottomRight: bounds.bottomRight,
    SelectHandle.bottom: bounds.bottomCenter,
    SelectHandle.bottomLeft: bounds.bottomLeft,
    SelectHandle.left: bounds.centerLeft,
  };

  /// [start] with the side or corner [handle] dragged to [position], the
  /// opposite side staying where it is. Never smaller than [minSide].
  static Rect resizedBox(
    Rect start,
    SelectHandle handle,
    Offset position, {
    double minSide = 8,
  }) {
    var left = start.left, top = start.top;
    var right = start.right, bottom = start.bottom;
    switch (handle) {
      case .topLeft:
        left = position.dx;
        top = position.dy;
      case .top:
        top = position.dy;
      case .topRight:
        right = position.dx;
        top = position.dy;
      case .right:
        right = position.dx;
      case .bottomRight || .scale:
        right = position.dx;
        bottom = position.dy;
      case .bottom:
        bottom = position.dy;
      case .bottomLeft:
        left = position.dx;
        bottom = position.dy;
      case .left:
        left = position.dx;
      case .rotate:
        break;
    }
    if (right - left < minSide) {
      if (left != start.left) {
        left = right - minSide;
      } else {
        right = left + minSide;
      }
    }
    if (bottom - top < minSide) {
      if (top != start.top) {
        top = bottom - minSide;
      } else {
        bottom = top + minSide;
      }
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void onDragStart(Offset position, int pageIndex) {
    doneSelecting = false;
    editingCorners = false;
    selectResult = SelectResult(
      pageIndex: pageIndex,
      strokes: [],
      images: [],
      path: Path(),
      pageIndexStart: pageIndex,
    );
    _start = position;
    angle = 0;
    lassoPolygon = [position];
    selectResult.path.moveTo(position.dx, position.dy);
    onDragUpdate(position);
  }

  void onDragUpdate(Offset position) {
    if (rectangleMode) {
      final r = Rect.fromPoints(_start, position);
      selectResult.path = Path()..addRect(r);
      lassoPolygon = [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
    } else {
      selectResult.path.lineTo(position.dx, position.dy);
      lassoPolygon.add(position);
    }
  }

  /// Adds the indices of any [strokes] that are inside the selection area
  /// to [selectResult.indices].
  /// Which [Stows.lassoFilter] group [stroke] is in.
  static String groupOf(Stroke stroke) {
    if (stroke.toolId == .tape) return 'tape';
    if (stroke.toolId != .shapePen) return 'handwriting';
    final style = stroke.shapeStyle;
    if (style != null &&
        (style.arrowStart != ShapeArrow.none ||
            style.arrowEnd != ShapeArrow.none)) {
      return 'arrows';
    }
    return 'shapes';
  }

  /// Which [Stows.lassoFilter] group [image] is in.
  static String imageGroupOf(EditorImage image) => switch (image) {
    final SvgEditorImage svg when svg.isTextBox => 'textBoxes',
    final SvgEditorImage svg when svg.isStickyNote => 'stickyNotes',
    _ => 'images',
  };

  void onDragEnd(List<Stroke> strokes, List<EditorImage> images) {
    selectResult.path.close();
    doneSelecting = true;
    final filter = stows.lassoFilter.value;

    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      if (!filter.contains(groupOf(stroke))) continue;
      // a piece a lasso split off: only its shown side counts
      if (lineTouches(selectResult.path, stroke.shownPoints)) {
        selectResult.strokes.add(stroke);
      }
    }

    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      if (!filter.contains(imageGroupOf(image))) continue;
      if (rectPercentInside(selectResult.path, image.dstRect) > 0) {
        selectResult.images.add(image);
      }
    }
  }

  static double rectPercentInside(Path selection, Rect rect) {
    const int gridSize = 5;
    final gridCellWidth = rect.width / (gridSize - 1);
    final gridCellHeight = rect.height / (gridSize - 1);

    int pointsInside = 0;
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        if (selection.contains(
          Offset(rect.left + gridCellWidth * x, rect.top + gridCellHeight * y),
        )) {
          pointsInside++;
        }
      }
    }

    // times 1.25 because the grid is not very accurate
    return pointsInside / (gridSize * gridSize) * 1.25;
  }

  /// Whether any part of [line] is inside [selection], even if none of its
  /// points are: a long straight line can cross the lasso between two points.
  static bool lineTouches(Path selection, List<Offset> line) {
    final bounds = selection.getBounds();
    final spacing = max(bounds.shortestSide / 4, 1.0);
    bool inside(Offset p) => bounds.contains(p) && selection.contains(p);

    for (int i = 0; i < line.length; i++) {
      if (!line[i].isFinite) continue;
      if (inside(line[i])) return true;
      if (i == 0 || !line[i - 1].isFinite) continue;

      final segment = line[i] - line[i - 1];
      final segmentBounds = Rect.fromPoints(line[i - 1], line[i]);
      if (segment.distance <= spacing || !segmentBounds.overlaps(bounds)) {
        continue;
      }
      final steps = (segment.distance / spacing).ceil();
      for (int k = 1; k < steps; k++) {
        if (inside(line[i - 1] + segment * (k / steps))) return true;
      }
    }
    return false;
  }
}

class SelectResult {
  int pageIndex;
  final List<Stroke> strokes;
  final List<EditorImage> images;
  Path path;
  int? pageIndexStart;

  new({
    required this.pageIndex,
    required this.strokes,
    required this.images,
    required this.path,
    required this.pageIndexStart,
  });

  bool get isEmpty {
    return strokes.isEmpty && images.isEmpty;
  }

  SelectResult copyWith({
    int? pageIndex,
    List<Stroke>? strokes,
    List<EditorImage>? images,
    Path? path,
    int? pageIndexStart,
  }) {
    return SelectResult(
      pageIndex: pageIndex ?? this.pageIndex,
      strokes: strokes ?? this.strokes,
      images: images ?? this.images,
      path: path ?? this.path,
      pageIndexStart: pageIndexStart ?? this.pageIndexStart,
    );
  }
}
