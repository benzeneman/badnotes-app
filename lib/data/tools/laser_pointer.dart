import 'dart:async';

import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/_tool.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:sbn/tool_id.dart';

/// A stroke waiting to fade, with the page callbacks it came with.
typedef _Waiting = ({
  LaserStroke stroke,
  VoidCallback redraw,
  void Function(LaserStroke) delete,
});

/// A pointer for presenting: what it draws is never saved, and disappears
/// on its own a moment after the pen stops.
///
/// There is only one, [currentLaserPointer]; its settings live in prefs.
class LaserPointer extends Tool {
  new _();

  static final _instance = LaserPointer._();
  static LaserPointer get currentLaserPointer => _instance;

  @override
  ToolId get toolId => .laserPointer;

  // ---- settings, all kept in prefs ----

  Color get color => Color(stows.laserColor.value);
  set color(Color value) => stows.laserColor.value = value.toARGB32();

  /// Shows only a glowing dot under the pen instead of a fading line.
  bool get dotMode => stows.laserDot.value;
  set dotMode(bool value) => stows.laserDot.value = value;

  /// Draws a soft halo around the line.
  bool get glow => stows.laserGlow.value;
  set glow(bool value) => stows.laserGlow.value = value;

  /// How long the writing stays after the pen lifts before it starts to fade.
  int get holdMillis => stows.laserHoldMillis.value;
  set holdMillis(int value) => stows.laserHoldMillis.value = value;

  final pressureEnabled = false;

  /// Very little streamline, so the line sits right under the pen tip
  /// instead of lagging behind it.
  final options = StrokeOptions(smoothing: 0.7, streamline: 0.1);

  // ---- drawing ----

  /// True while the pen is down with the laser. Nothing fades meanwhile.
  static var isDrawing = false;

  void onDragStart(Offset position, EditorPage page, int pageIndex) {
    isDrawing = true;
    noteActivity();
    final stroke = LaserStroke(
      color: color,
      pressureEnabled: pressureEnabled,
      options: options.copyWith(),
      pageIndex: pageIndex,
      page: page,
      toolId: toolId,
    );
    stroke.isDot = dotMode;
    Pen.currentStroke = stroke;
    onDragUpdate(position);
  }

  void onDragUpdate(Offset position) {
    isDrawing = true;
    final stroke = Pen.currentStroke;
    stroke?.addPoint(position);
    // a dot keeps only the newest point
    if (stroke is LaserStroke && stroke.isDot && stroke.length > 1) {
      stroke.popFirstPoint();
    }
  }

  /// Finishes the stroke and returns it, or null when there is nothing to
  /// keep on the page (no laser stroke, or just the dot, which goes with the
  /// pen). A returned stroke is queued to fade with [fadeOutStroke].
  LaserStroke? onDragEnd(
    VoidCallback redrawPage,
    void Function(Stroke) deleteStroke,
  ) {
    isDrawing = false;
    noteActivity();

    final stroke = Pen.currentStroke;
    Pen.currentStroke = null;
    if (stroke is! LaserStroke || stroke.isDot) return null;

    unawaited(
      fadeOutStroke(
        stroke: stroke,
        redrawPage: redrawPage,
        deleteStroke: deleteStroke,
      ),
    );
    stroke.options.isComplete = true;
    stroke.markPolygonNeedsUpdating();
    return stroke;
  }

  // ---- fading ----

  /// The rest the pen must take before the writing starts to fade.
  @visibleForTesting
  static Duration get fadeOutDelay =>
      Duration(milliseconds: stows.laserHoldMillis.value);

  /// How long the fade itself takes; all waiting strokes fade together.
  @visibleForTesting
  static const maxFadeDuration = Duration(milliseconds: 120);

  /// One step of the fade.
  @visibleForTesting
  static const fadeFrame = Duration(milliseconds: 16);

  /// Goes up every time the pen shows signs of life. A rest only counts if
  /// this stayed the same the whole time.
  static var _penActivity = 0;

  /// Records that the pen touched down or a stylus hovers near the page.
  static void noteActivity() => _penActivity++;

  static final _waiting = <_Waiting>[];
  static var _fadeRunning = false;

  /// Queues [stroke] to fade. Once the pen has rested, everything queued
  /// fades away together; if the pen returns before the fade is over, it all
  /// comes back at full strength and waits for the next rest.
  ///
  /// Only the first call runs the loop; calls made while it runs just add
  /// to the queue.
  @visibleForTesting
  static Future<void> fadeOutStroke({
    required LaserStroke stroke,
    required VoidCallback redrawPage,
    required void Function(LaserStroke) deleteStroke,
    @visibleForTesting Future<void> Function(Duration) wait = Future.delayed,
  }) async {
    _waiting.add((stroke: stroke, redraw: redrawPage, delete: deleteStroke));
    if (_fadeRunning) return;
    _fadeRunning = true;
    try {
      while (_waiting.isNotEmpty) {
        await _restOfPen(wait);
        final faded = await _fadeWaiting(wait);
        if (!faded) continue;
        final gone = _waiting.toList();
        _waiting.clear();
        for (final entry in gone) {
          entry.delete(entry.stroke);
          entry.redraw();
        }
      }
    } finally {
      _fadeRunning = false;
    }
  }

  /// Waits for [fadeOutDelay] with the pen up and no activity at all; any
  /// activity starts the wait over.
  static Future<void> _restOfPen(Future<void> Function(Duration) wait) async {
    while (true) {
      final before = _penActivity;
      await wait(fadeOutDelay);
      while (isDrawing) {
        await wait(const Duration(milliseconds: 100));
      }
      if (before == _penActivity) return;
    }
  }

  /// Steps the waiting strokes' opacity down to 0. Returns false, with
  /// everything shown in full again, if the pen came back part way.
  static Future<bool> _fadeWaiting(Future<void> Function(Duration) wait) async {
    final before = _penActivity;
    final steps = maxFadeDuration.inMilliseconds ~/ fadeFrame.inMilliseconds;
    for (var step = 1; step <= steps; step++) {
      await wait(fadeFrame);
      final interrupted = isDrawing || before != _penActivity;
      _showAt(interrupted ? 1 : 1 - step / steps);
      if (interrupted) return false;
    }
    return true;
  }

  static void _showAt(double opacity) {
    for (final entry in _waiting) {
      entry.stroke.opacity = opacity;
      entry.redraw();
    }
  }
}

/// A stroke drawn by the [LaserPointer]. It is never saved.
class LaserStroke extends Stroke {
  /// Whether this is the dot of [LaserPointer.dotMode] rather than a line.
  var isDot = false;

  /// 1 while fully shown, dropping to 0 as the stroke fades.
  double opacity = 1;

  new({
    required super.color,
    required super.pressureEnabled,
    required super.options,
    required super.pageIndex,
    required EditorPage super.page,
    required super.toolId,
  });

  /// Turns an ordinary stroke into a laser one with the same points.
  /// Note: this changes [stroke]'s own options (streamline and smoothing
  /// both become 0.7) rather than a copy.
  @visibleForTesting
  new convertStroke(Stroke stroke)
    : super(
        color: stroke.color,
        pressureEnabled: stroke.pressureEnabled,
        options: stroke.options
          ..streamline = 0.7
          ..smoothing = 0.7,
        pageIndex: stroke.pageIndex,
        page: stroke.page,
        toolId: stroke.toolId,
      ) {
    points.addAll(stroke.points);
  }

  /// The wide outer part of the stroke, painted in [color].
  @override
  List<Offset> get highQualityPolygon => super.highQualityPolygon;

  /// Always the full-quality outline, so the outer part lines up exactly
  /// with the inner one; there is no lower level of detail for lasers.
  @override
  List<Offset> get lowQualityPolygon => super.highQualityPolygon;
}
