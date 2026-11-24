/// How long the pen's work takes, per move and when it lifts, for strokes of
/// several lengths. Prints timings; run with
/// `flutter test test/perf/stroke_cost_test.dart`.
@Tags(['perf'])
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:sbn/tool_id.dart';

import '../utils/test_mock_channel_handlers.dart';

void main() {
  setupMockPathProvider();

  for (final tool in [ToolId.fountainPen, ToolId.ballpointPen, ToolId.brushPen, ToolId.pencil, ToolId.highlighter]) {
    for (final n in [200, 800, 2000]) {
      test('$tool, $n points', () {
        final page = EditorPage();
        final stroke = Stroke(
          color: Colors.black,
          pressureEnabled: true,
          options: Pen.defaultOptions.copyWith(isComplete: false, streamline: 0.5),
          pageIndex: 0,
          page: page,
          toolId: tool,
        )..speedInk = tool == ToolId.fountainPen;
        final random = Random(1);
        final watch = Stopwatch();
        var worst = 0;
        // a frame draws the stroke after each move
        for (var i = 0; i < n; i++) {
          stroke.addPoint(Offset(20 + i * 0.4 + random.nextDouble(), 300 + sin(i / 9) * 60), 0.3 + random.nextDouble() * 0.5);
          watch
            ..reset()
            ..start();
          stroke.highQualityPath;
          watch.stop();
          if (i >= n - 10) worst += watch.elapsedMicroseconds;
        }
        watch
          ..reset()
          ..start();
        stroke
          ..options.isComplete = true
          ..markPolygonNeedsUpdating();
        stroke.highQualityPath;
        stroke.lowQualityPath;
        watch.stop();
        // ignore: avoid_print
        print('PERF $tool n=$n lastMove=${worst ~/ 10}us lift=${watch.elapsedMicroseconds}us');
      });
    }
  }
}
