import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/editor/board_map.dart';
import 'package:badnotes/components/editor/board_paper.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:sbn/canvas_background_pattern.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

Stroke _line(Offset a, Offset b) =>
    Stroke(
        color: Colors.black,
        pressureEnabled: false,
        options: StrokeOptions(size: 4, isComplete: true, thinning: 0),
        pageIndex: 0,
        page: const HasSize(Size(1000, 1000)),
        toolId: ToolId.fountainPen,
      )
      ..addPoints([for (int i = 0; i <= 10; i++) Offset.lerp(a, b, i / 10)!]);

void main() {
  setUp(FlavorConfig.setup);

  test('a board\'s content: all its ink, or nothing when empty', () {
    final page = EditorPage();
    expect(boardContent(page), isNull);
    page.strokes
      ..add(_line(const Offset(100, 100), const Offset(200, 100)))
      ..add(_line(const Offset(500, 700), const Offset(600, 720)));
    final content = boardContent(page)!;
    expect(content.left, lessThanOrEqualTo(100));
    expect(content.top, lessThanOrEqualTo(100));
    expect(content.right, greaterThanOrEqualTo(600));
    expect(content.bottom, greaterThanOrEqualTo(720));
  });

  testWidgets('the paper samples are squares, not thin lines', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 380,
          height: 700,
          child: BoardPanel(
            pattern: CanvasBackgroundPattern.dots,
            spacing: 40,
            color: Colors.white,
            setPaper: (_) {},
            setColor: (_) {},
            placeKit: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );
    final samples = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is BoardPaperPainter,
    );
    expect(samples, findsNWidgets(BoardPaper.all.length));
    final size = tester.getSize(samples.first);
    expect(size.width, greaterThan(40), reason: '$size');
    expect(size.height, greaterThan(40), reason: '$size');
  });
}
