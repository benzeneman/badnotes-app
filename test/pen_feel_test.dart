import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/shape_pen.dart';
import 'package:sbn/tool_id.dart';

void main() {
  setUp(FlavorConfig.setup);

  /// The line drawn while the pen is down at the end of a fast curve, and
  /// once it has lifted.
  (Rect, Rect) drawFastCurve(Pen pen) {
    pen.onDragStart(const Offset(100, 100), EditorPage(), 0, null);
    for (int i = 1; i <= 40; i++) {
      pen.onDragUpdate(
        Offset(100 + 300 * sin(i / 40 * pi), 100 + i * 12.0),
        null,
      );
    }
    final live = Pen.currentStroke!.centerlinePath.getBounds();
    final done = pen.onDragEnd()!.centerlinePath.getBounds();
    return (live, done);
  }

  test('with reduce latency off nothing springs back when the pen lifts', () {
    stows.penReduceLatency.value = false;
    addTearDown(() => stows.penReduceLatency.value = true);
    for (final pen in [Pen.ballpointPen(), Pen.fountainPen()]) {
      for (final stable in [0.0, 0.95]) {
        pen.options.streamline = stable;
        final (live, done) = drawFastCurve(pen);
        expect(live, done, reason: '${pen.toolId} at $stable');
      }
    }
  });

  test('with it on the ink never runs on past the pen', () {
    stows.penReduceLatency.value = true;
    for (final pen in [Pen.ballpointPen(), Pen.fountainPen()]) {
      for (final stable in [0.0, 0.95]) {
        pen.options.streamline = stable;
        final (live, done) = drawFastCurve(pen);
        // the curve ends going down: the ink stops where the pen is
        expect(
          live.bottom,
          lessThanOrEqualTo(done.bottom + 0.5 + pen.options.size),
          reason: '${pen.toolId} at $stable',
        );
      }
    }
  });

  test('with it on the ink reaches the pen, never past it', () {
    /// How far behind the pen the ink ends, writing fast to the right.
    double behind(bool reduce) {
      stows.penReduceLatency.value = reduce;
      final pen = Pen.fountainPen()..options.streamline = 0.6;
      pen.onDragStart(const Offset(0, 100), EditorPage(), 0, 0.5);
      for (int i = 1; i <= 30; i++) {
        pen.onDragUpdate(Offset(i * 14.0, 100), 0.5);
      }
      final ink = Pen.currentStroke!.highQualityPath.getBounds();
      pen.onDragEnd();
      return 30 * 14.0 - ink.right;
    }

    addTearDown(() => stows.penReduceLatency.value = true);
    final off = behind(false), on = behind(true);
    expect(on, lessThanOrEqualTo(off + 0.01), reason: 'on: $on, off: $off');
    // and not past it
    expect(on, greaterThan(-0.5 - 2), reason: 'on: $on');
  });

  test('a pencil held into a shape stays pencil', () {
    for (final toolId in [ToolId.pencil, ToolId.highlighter]) {
      final drawn = Stroke(
        color: Colors.black,
        pressureEnabled: false,
        options: StrokeOptions(size: 3),
        pageIndex: 0,
        page: EditorPage(),
        toolId: toolId,
      );
      for (final (a, b) in [
        (const Offset(0, 0), const Offset(300, 0)),
        (const Offset(300, 0), const Offset(300, 200)),
        (const Offset(300, 200), const Offset(0, 200)),
        (const Offset(0, 200), const Offset(0, 0)),
      ]) {
        for (int k = 0; k < 20; k++) {
          drawn.addPoint(Offset.lerp(a, b, k / 20)!);
        }
      }
      final shape = ShapePen.snapToShape(drawn);
      expect(shape, isNotNull);
      expect(shape!.toolId, toolId);
      expect(shape.centerPoints.length, greaterThan(20));
    }
  });

  group('each fountain pen setting does something on its own', () {
    test('tip sharpness thins faster lines, and not at 0%', () {
      expect(Stroke.nibSpeedFactor(2, 0), 1);
      expect(Stroke.nibSpeedFactor(2, 1), lessThan(0.7));
      expect(Stroke.nibSpeedFactor(2, 0.5), greaterThan(0.6));
      // a slow line stays as wide
      expect(Stroke.nibSpeedFactor(0.2, 1), greaterThanOrEqualTo(1));
    });

    test('new strokes say so, in the note too', () {
      final pen = Pen.fountainPen();
      pen.onDragStart(const Offset(10, 10), EditorPage(), 0, 0.5);
      pen.onDragUpdate(const Offset(40, 10), 0.5);
      final stroke = pen.onDragEnd()!;
      expect(stroke.nib2, isTrue);
      expect(stroke.toJson()['n2'], isTrue);
      expect(stroke.copy().nib2, isTrue);
    });

    // How close the line gets to a sharp corner at a stabilization setting.
    // The steadied line trails the pen more as the setting rises (like the
    // highlighter's), so the setting shows; at everyday settings letters
    // keep their corners.
    double cornerMiss(double stabilization) {
      final pen = Pen.ballpointPen()..options.streamline = stabilization;
      pen.onDragStart(const Offset(0, 0), EditorPage(), 0, null);
      for (int i = 1; i <= 30; i++) {
        pen.onDragUpdate(Offset(i * 10.0, 0), null);
      }
      // a sharp turn: straight down
      for (int i = 1; i <= 30; i++) {
        pen.onDragUpdate(Offset(300, i * 10.0), null);
      }
      final stroke = pen.onDragEnd()!;
      return stroke.centerlinePath.computeMetrics().fold<double>(
        double.infinity,
        (best, metric) {
          for (double d = 0; d <= metric.length; d += 1) {
            final p = metric.getTangentForOffset(d)!.position;
            best = min(best, (p - const Offset(300, 0)).distance);
          }
          return best;
        },
      );
    }

    test('stabilization keeps corners at everyday settings', () {
      final size = Pen.ballpointPen().options.size;
      expect(cornerMiss(0.4), lessThan(max(size * 2, 3.0) + 1));
    });

    test('high stabilization rounds corners, but never far off', () {
      final size = Pen.ballpointPen().options.size;
      final high = cornerMiss(0.95);
      expect(high, greaterThan(cornerMiss(0.4)));
      expect(high, lessThan(size * 7));
    });

    test('calligraphy: tip sharpness is how much pressure widens the nib', () {
      double spread(double sharp) {
        final pen = Pen.calligraphyPen()..options.thinning = sharp * 0.9;
        pen.onDragStart(const Offset(0, 0), EditorPage(), 0, 0.1);
        for (int i = 1; i <= 40; i++) {
          pen.onDragUpdate(Offset(i * 3.0, i * 3.0), i < 20 ? 0.1 : 1.0);
        }
        final bounds = pen.onDragEnd()!.highQualityPath.getBounds();
        return bounds.width + bounds.height;
      }

      expect(spread(1), greaterThan(spread(0) + 1));
    });
  });
}
