import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:badnotes/components/editor/board_kits.dart';
import 'package:badnotes/data/extensions/color_extensions.dart';
import 'package:badnotes/data/extensions/matrix4_extensions.dart';
import 'package:sbn/canvas_background_pattern.dart';

/// A kind of paper for the whiteboard.
class BoardPaper {
  const BoardPaper(this.name, this.pattern, this.spacing);

  final String name;
  final CanvasBackgroundPattern pattern;
  final int spacing;

  static const all = [
    BoardPaper('Blank', .none, 40),
    BoardPaper('Dots', .dots, 40),
    BoardPaper('Fine dots', .dots, 20),
    BoardPaper('Squares', .grid, 40),
    BoardPaper('Small squares', .grid, 20),
    BoardPaper('Big squares', .grid, 80),
    BoardPaper('Lines', .lined, 40),
    BoardPaper('Wide lines', .lined, 70),
  ];

  static const colors = <String, Color>{
    'White': Color(0xFFFFFFFF),
    'Ivory': Color(0xFFFFFCEE),
    'Sky': Color(0xFFE3F2FD),
    'Mint': Color(0xFFE8F5E9),
    'Grey': Color(0xFFECEFF1),
    'Navy': Color(0xFF1A237E),
    'Chalkboard': Color(0xFF1B5E20),
    'Black': Color(0xFF121212),
  };
}

/// The whiteboard's paper, drawn only where the screen is, however far the
/// board goes. The marks stay on the board as it moves, and thin out when
/// zoomed out so they don't turn into a solid tone.
class BoardPaperPainter extends CustomPainter {
  BoardPaperPainter({
    required this.pattern,
    required this.spacing,
    required this.color,
    required this.invert,
    this.transformation,
  }) : super(repaint: transformation);

  final CanvasBackgroundPattern pattern;
  final int spacing;
  final Color color;
  final bool invert;

  /// Where the board is on screen. Null for a sample that stays put.
  final TransformationController? transformation;

  /// Marks closer together on screen than this are thinned out.
  static const _minGap = 12.0;

  /// The distance on screen between marks [spacing] apart on the board.
  @visibleForTesting
  static double gapOnScreen(int spacing, double scale) {
    var gap = spacing * scale;
    while (gap < _minGap) {
      gap *= 2;
    }
    return gap;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paper = color.withInversion(invert);
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    if (pattern == .none) return;

    final matrix = transformation?.value;
    final scale = matrix?.approxScale ?? 1.0;
    final translation = matrix?.getTranslation();
    final gap = gapOnScreen(spacing, scale);
    final startX = (translation?.x ?? 0) % gap;
    final startY = (translation?.y ?? 0) % gap;
    final mark = Paint()
      ..color = (paper.computeLuminance() > 0.5 ? Colors.black : Colors.white)
          .withValues(alpha: 0.28)
      ..strokeWidth = 1;

    if (pattern == .dots) {
      mark
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      final dots = <Offset>[
        for (var x = startX; x < size.width; x += gap)
          for (var y = startY; y < size.height; y += gap) Offset(x, y),
      ];
      canvas.drawPoints(.points, dots, mark);
      return;
    }
    for (var y = startY; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), mark);
    }
    if (pattern == .grid) {
      for (var x = startX; x < size.width; x += gap) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), mark);
      }
    }
  }

  @override
  bool shouldRepaint(BoardPaperPainter oldDelegate) =>
      pattern != oldDelegate.pattern ||
      spacing != oldDelegate.spacing ||
      color != oldDelegate.color ||
      invert != oldDelegate.invert;
}

/// The panel at the side of the whiteboard: its paper, its color and layouts to
/// place on it.
class BoardPanel extends StatelessWidget {
  const BoardPanel({
    super.key,
    required this.pattern,
    required this.spacing,
    required this.color,
    required this.setPaper,
    required this.setColor,
    required this.placeKit,
    required this.onClose,
  });

  final CanvasBackgroundPattern pattern;
  final int spacing;
  final Color color;
  final ValueChanged<BoardPaper> setPaper;
  final ValueChanged<Color> setColor;
  final ValueChanged<BoardKit> placeKit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(text, style: TextTheme.of(context).titleSmall),
    );
    Widget tile({
      required String name,
      required bool chosen,
      required VoidCallback onTap,
      required Widget child,
    }) => GestureDetector(
      onTap: onTap,
      // stretched: a sample has no size of its own, and was a thin line
      child: Column(
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: chosen
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: chosen ? 2.5 : 1,
                ),
              ),
              child: child,
            ),
          ),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: .ellipsis,
            style: TextTheme.of(context).labelSmall,
          ),
        ],
      ),
    );
    return Material(
      elevation: 8,
      color: colorScheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Board',
                    style: TextTheme.of(context).titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            heading('Paper'),
            GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final paper in BoardPaper.all)
                  tile(
                    name: paper.name,
                    chosen: paper.pattern == pattern && paper.spacing == spacing,
                    onTap: () => setPaper(paper),
                    child: CustomPaint(
                      painter: BoardPaperPainter(
                        pattern: paper.pattern,
                        spacing: paper.spacing,
                        color: color,
                        invert: false,
                      ),
                    ),
                  ),
              ],
            ),
            heading('Color'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final MapEntry(key: name, value: swatch)
                    in BoardPaper.colors.entries)
                  Semantics(
                    button: true,
                    selected: swatch == color,
                    label: name,
                    child: GestureDetector(
                      onTap: () => setColor(swatch),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: swatch,
                          shape: .circle,
                          border: Border.all(
                            color: swatch == color
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: swatch == color ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            heading('Ready-made layouts'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                for (final kit in BoardKit.all)
                  tile(
                    name: kit.name,
                    chosen: false,
                    onTap: () => placeKit(kit),
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: SvgPicture.string(kit.svg),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
