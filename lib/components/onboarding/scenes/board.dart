import 'dart:math';

import 'package:badnotes/components/home/pin_board.dart';
import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/home/quick_ink.dart';
import 'package:badnotes/components/onboarding/tour_engine.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Pin board: a formula card, a to-do list, a sketch and a reminder land on
// the desk's real board
// ---------------------------------------------------------------------------

final _day = DateTime(2026);

/// A little double helix in ink, on a note 300 units wide.
final _sketch = () {
  const w = 300.0;
  List<double> strand(double phase) {
    final line = InkLine(
      plotSvg((x) => 150 + 34 * sin((x - 40) / 30 + phase), 40, 260, step: 6),
      pen: Pen.fountain,
      color: inkDark,
    );
    return [
      for (final p in line.points().whereIndexed((i) => i % 3 == 0)) ...[
        p.dx / w,
        p.dy / w,
        0.55,
      ],
    ];
  }

  const colors = [Color(0xFF2FB344), Color(0xFFF59F00), Color(0xFFF03E3E), Color(0xFF1C7ED6)];
  return [
    for (var x = 52.0, i = 0; x < 256; x += 15, i++)
      if ((sin((x - 40) / 30)).abs() > 0.3)
        BoardStroke(
          tool: QuickTool.ball,
          color: colors[i % 4],
          points: [
            x / w, (150 - 30 * sin((x - 40) / 30).abs()) / w, 0.5,
            x / w, (150 + 30 * sin((x - 40) / 30).abs()) / w, 0.5,
          ],
          width: 3 / w,
        ),
    BoardStroke(tool: QuickTool.fountain, color: const Color(0xFF364FC7), points: strand(0), width: 4 / w),
    BoardStroke(tool: QuickTool.fountain, color: const Color(0xFFC2255C), points: strand(pi), width: 4 / w),
  ];
}();

extension<T> on List<T> {
  Iterable<T> whereIndexed(bool Function(int i) test) sync* {
    for (var i = 0; i < length; i++) {
      if (test(i)) yield this[i];
    }
  }
}

List<BoardItem> _items(double t) {
  BoardItem note(
    String id,
    Rect box, {
    String text = '',
    List<BoardCheck> checklist = const [],
    int color = 0,
    double angle = 0,
    int deco = 1,
    int shape = 0,
    int z = 0,
    List<BoardStroke> ink = const [],
    List<String> labels = const [],
    int? decoColor,
  }) => BoardItem(
    id: id,
    photo: null,
    text: text,
    checklist: checklist,
    color: color,
    box: box,
    angle: angle,
    deco: deco,
    noteShape: shape,
    z: z,
    ink: ink,
    labels: labels,
    decoColor: decoColor,
    createdAt: _day,
    updatedAt: _day,
  );

  /// Dropped onto the board from above, settling with a little bounce.
  Rect drop(Rect to, double at) {
    final k = span(t, at, at + 0.1, Curves.easeOutBack);
    return to.shift(Offset(0, -620 * (1 - k)));
  }

  final move = span(t, 0.58, 0.78);
  const from = Rect.fromLTWH(560, 300, 300, 230);
  const to = Rect.fromLTWH(110, 330, 300, 230);
  return [
    note(
      'formulas',
      drop(const Rect.fromLTWH(30, 40, 290, 250), 0.04),
      text: 'E = mc²\nF = ma\nPV = nRT\na² + b² = c²',
      shape: 3,
      angle: -0.04,
      decoColor: 0xFFE03131,
      labels: const ['physics'],
    ),
    note(
      'sketch',
      drop(const Rect.fromLTWH(350, 30, 300, 270), 0.14),
      color: 5,
      angle: 0.03,
      deco: 2,
      ink: _sketch,
    ),
    note(
      'todo',
      drop(const Rect.fromLTWH(690, 50, 270, 290), 0.24),
      text: 'This week',
      checklist: const [
        BoardCheck('Heart labels', done: true),
        BoardCheck('Krebs cycle'),
        BoardCheck('Lab report'),
      ],
      color: 2,
      shape: 2,
      angle: 0.05,
      deco: 3,
    ),
    note(
      'exam',
      Rect.lerp(drop(from, 0.36), to, move)!,
      text: 'Anatomy exam\nFri 9:00, Room 204',
      color: 6,
      shape: 1,
      angle: 0.14 - 0.17 * move,
      z: 5,
      decoColor: 0xFF4C6EF5,
    ),
  ];
}

final boardScene = TourScene(
  duration: const Duration(milliseconds: 8000),
  rest: 0.9,
  build: (context, t) {
    final fade = loopFade(t, out: 0.95);
    return Opacity(
      opacity: fade,
      child: IgnorePointer(
        child: PinBoard(
          items: _items(t),
          openNote: (_, _) {},
          openPhoto: (_, _) {},
          minHeight: stageSize.height,
        ),
      ),
    );
  },
);
