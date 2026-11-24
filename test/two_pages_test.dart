import 'package:badnotes/components/canvas/canvas_gesture_detector.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(FlavorConfig.setup);
  tearDown(() => CanvasGestureDetector.twoPages = false);

  test('two to a row: a page and the one beside it start at the same top', () {
    CanvasGestureDetector.twoPages = true;
    final pages = [for (int i = 0; i < 6; i++) EditorPage()];
    const wide = 1200.0;
    expect(CanvasGestureDetector.spread(wide), isTrue);
    double top(int i) => CanvasGestureDetector.getTopOfPage(
      pageIndex: i,
      pages: pages,
      screenWidth: wide,
    );
    expect(top(0), 0);
    expect(top(1), top(0), reason: 'page 2 is beside page 1');
    expect(top(3), top(2), reason: 'page 4 is beside page 3');
    expect(top(2), greaterThan(top(1)), reason: 'page 3 starts the next row');
    // and back: a scroll inside the second row is on its first page
    expect(
      CanvasGestureDetector.getPageIndex(
        scrollY: top(2) + 10,
        pages: pages,
        screenWidth: wide,
      ),
      2,
    );
  });

  test('not on a narrow screen, nor when off', () {
    CanvasGestureDetector.twoPages = true;
    expect(CanvasGestureDetector.spread(700), isFalse);
    CanvasGestureDetector.twoPages = false;
    expect(CanvasGestureDetector.spread(1200), isFalse);
  });
}
