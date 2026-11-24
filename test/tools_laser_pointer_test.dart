import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/laser_pointer.dart';
import 'package:badnotes/data/tools/pen.dart';

void main() {
  FlavorConfig.setup();

  group('Laser fade', () {
    final laserPointer = LaserPointer.currentLaserPointer;
    const pointCount = 4;
    final page = EditorPage();

    setUp(() {
      var cursorPos = const Offset(200, 200);
      laserPointer.onDragStart(cursorPos, page, 0);
      for (var i = 1; i < pointCount; i++) {
        cursorPos += const Offset(15, 15);
        laserPointer.onDragUpdate(cursorPos);
      }
    });

    test('stays while resting, then goes all at once', () async {
      final stroke = Pen.currentStroke as LaserStroke;
      LaserPointer.isDrawing = false;
      var deletions = 0;
      final delays = <Duration>[];
      await LaserPointer.fadeOutStroke(
        stroke: stroke,
        redrawPage: () {},
        deleteStroke: (_) => deletions++,
        wait: (duration) async {
          delays.add(duration);
          // not a single point goes while fading
          expect(stroke.length, pointCount);
        },
      );
      expect(deletions, 1);
      expect(delays.first, LaserPointer.fadeOutDelay);
      expect(stows.laserHoldMillis.value, 300);
    });

    test('stays in full when the pen comes back while fading', () async {
      final stroke = Pen.currentStroke as LaserStroke;
      LaserPointer.isDrawing = false;
      final seen = <double>[];
      var frames = 0;
      await LaserPointer.fadeOutStroke(
        stroke: stroke,
        redrawPage: () => seen.add(stroke.opacity),
        deleteStroke: (_) {},
        wait: (duration) async {
          if (duration == LaserPointer.fadeFrame && ++frames == 2) {
            LaserPointer.noteActivity();
          }
        },
      );
      expect(seen.first, lessThan(1));
      expect(seen, contains(1.0));
      expect(stroke.opacity, lessThan(1.0));
    });

    test('a stroke written during the wait goes along with the first', () async {
      final first = Pen.currentStroke as LaserStroke;
      LaserPointer.isDrawing = false;
      final second = LaserStroke(
        color: first.color,
        pressureEnabled: false,
        options: first.options.copyWith(),
        pageIndex: 0,
        page: page,
        toolId: first.toolId,
      )..addPoint(const Offset(1, 1));
      final deleted = <LaserStroke>[];
      var added = false;
      await LaserPointer.fadeOutStroke(
        stroke: first,
        redrawPage: () {},
        deleteStroke: deleted.add,
        wait: (duration) async {
          if (added) return;
          added = true;
          LaserPointer.noteActivity();
          await LaserPointer.fadeOutStroke(
            stroke: second,
            redrawPage: () {},
            deleteStroke: deleted.add,
          );
        },
      );
      expect(deleted, [first, second]);
    });
  });
}
