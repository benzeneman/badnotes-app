import 'dart:math';
import 'dart:ui';

import 'package:badnotes/data/lag_recorder.dart';
import 'package:badnotes/components/canvas/_circle_stroke.dart';
import 'package:badnotes/components/canvas/_rectangle_stroke.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/editor/editor_history.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/_tool.dart';
import 'package:sbn/tool_id.dart';

double square(double x) => x * x;

/// How the eraser takes ink away.
enum EraserType {
  /// Rubs out just where the eraser goes: holes in highlighter, which is
  /// drawn as one layer, and pens cut into pieces.
  precision('Precision Eraser', 'Precise erasing for small details'),

  /// Every stroke it touches goes, whole.
  stroke('Stroke Eraser', 'Erases whole strokes');

  const EraserType(this.label, this.description);
  final String label, description;
}

double sqrDistanceBetween(Offset p1, Offset p2) =>
    square(p1.dx - p2.dx) + square(p1.dy - p2.dy);

/// Precise mode cuts away only what the eraser touches;
/// otherwise every touched stroke is removed whole.
class Eraser extends Tool {
  final double size;

  /// Strokes that existed before this drag and were erased or cut.
  List<Stroke> _removed = [];

  /// Pieces left over by precise erasing during this drag.
  final List<Stroke> _added = [];

  new({this.size = 10});

  @override
  ToolId get toolId => .eraser;

  /// Saved as it was when there was a standard eraser too (1), between
  /// these two: that one now erases precisely, as GoodNotes has it.
  static EraserType get type =>
      stows.eraserType.value == 2 ? EraserType.stroke : EraserType.precision;
  static set type(EraserType type) =>
      stows.eraserType.value = type == EraserType.stroke ? 2 : 0;

  /// Whether strokes are cut instead of erased whole.
  static bool get precise => type != EraserType.stroke;

  /// Eraser radius in screen pixels, see [sizes].
  static double get screenRadius => stows.eraserRadius.value;
  static set screenRadius(double radius) => stows.eraserRadius.value = radius;

  /// Small, medium and large, in screen pixels.
  static const sizes = [16.0, 28.0, 56.0];

  /// The filter group a stroke belongs to (see [Stows.eraserFilter]).
  static String filterGroup(ToolId id) => switch (id) {
    .pencil => 'pencil',
    .highlighter => 'highlighter',
    .tape => 'tape',
    _ => 'pen',
  };

  /// Erases along the eraser's movement from [from] to [to] (page
  /// coordinates). [scale] is the zoom level, so the eraser never gets
  /// tinier than ~14 screen pixels when zoomed out.
  /// Only touches strokes that pass [only].
  /// Returns whether anything was erased.
  bool erase(
    List<Stroke> strokes,
    Offset from,
    Offset to,
    double scale, {
    bool Function(Stroke)? only,
  }) => LagRecorder.span(
    'erase',
    () => _erase(strokes, from, to, scale, only: only),
  );

  bool _erase(
    List<Stroke> strokes,
    Offset from,
    Offset to,
    double scale, {
    bool Function(Stroke)? only,
  }) {
    var erased = false;
    // same size on screen at any zoom
    final radius = screenRadius / max(scale, 0.05);
    final filter = stows.eraserFilter.value;
    for (int i = strokes.length - 1; i >= 0; i--) {
      final stroke = strokes[i];
      if (only != null && !only(stroke)) continue;
      if (!filter.contains(filterGroup(stroke.toolId))) continue;
      if (!stroke.touchedBy(from, to, radius)) continue;

      final type = Eraser.type;
      // Highlighters are drawn as one layer: the precise eraser rubs out
      // just where it goes from all of them at once, as GoodNotes does, with
      // round holes drawn once into that layer. Cut into pieces instead, a
      // straight line of eraser left a wavy gap, and the pieces' round ends
      // overlapped.
      if (type == EraserType.precision && stroke.toolId == .highlighter) {
        // on a copy of the stroke for this drag (for undo)
        final target = _added.contains(stroke)
            ? stroke
            : (stroke.copy()..drawOrder = stroke.drawOrder);
        _cutHoles(target, from, to, radius);
        final pieces = target.erasedAway ? <Stroke>[] : [target];
        if (identical(target, stroke) && pieces.isNotEmpty) {
          erased = true;
          continue;
        }
        strokes.replaceRange(i, i + 1, pieces);
        if (!_added.remove(stroke)) _removed.add(stroke);
        _added.addAll(pieces);
        erased = true;
        continue;
      }

      // Pens are cut into pieces, as OneNote does: thin, their round ends
      // look like the eraser's edge.

      // Tape goes as one strip: cut pieces would be new tape, covering again
      // even where the tape had been tapped open.
      final whole =
          type == EraserType.stroke ||
          stroke.toolId == .tape ||
          stroke is CircleStroke ||
          stroke is RectangleStroke;
      final pieces = whole ? <Stroke>[] : stroke.eraseAlong(from, to, radius);
      if (pieces == null) continue;

      strokes.replaceRange(i, i + 1, pieces);
      if (!_added.remove(stroke)) _removed.add(stroke);
      _added.addAll(pieces);
      erased = true;
    }
    return erased;
  }

  /// Holes along the eraser's way from [from] to [to], close enough
  /// together to make one smooth gap with straight sides.
  static void _cutHoles(Stroke stroke, Offset from, Offset to, double radius) {
    final distance = (to - from).distance;
    // close enough that the sides of the gap look straight, no closer:
    // every hole is drawn
    final steps = max(1, (distance / (radius * 0.5)).ceil());
    for (int i = 0; i <= steps; i++) {
      stroke.addHole(Offset.lerp(from, to, i / steps)!, radius);
    }
  }

  /// The undo step for this drag, or null if nothing was erased.
  Historic? onDragEnd() {
    final removed = _removed;
    final added = List.of(_added);
    _removed = [];
    _added.clear();
    if (removed.isEmpty) return null;
    if (added.isEmpty) return HistoricDelete(strokes: removed, images: []);
    return HistoricReplace(removed: removed, added: added);
  }
}
