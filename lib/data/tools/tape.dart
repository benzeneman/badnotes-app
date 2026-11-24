import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/tape_pattern.dart';

/// Covers what's under it, for revising: tap the tape with this tool to peek
/// underneath. Follows the pen, and straightens out if drawn nearly straight.
class Tape extends Pen {
  new()
    : super(
        name: 'Tape',
        sizeMin: 8,
        sizeMax: 80,
        sizeStep: 4,
        icon: tapeIcon,
        options: StrokeOptions(size: 24),
        pressureEnabled: false,
        color: Color(stows.tapeColor.value),
        toolId: .tape,
      );

  static const tapeIcon = Icons.crop_7_5;

  static final currentTape = Tape();

  static const colors = <Color>[
    Color(0xFFFFB74D), // amber
    Color(0xFFFF8A65), // coral
    Color(0xFFEF5350), // red
    Color(0xFFEC407A), // pink
    Color(0xFFAB47BC), // purple
    Color(0xFF7E57C2), // violet
    Color(0xFF5C6BC0), // indigo
    Color(0xFF42A5F5), // blue
    Color(0xFF26C6DA), // cyan
    Color(0xFF26A69A), // teal
    Color(0xFF66BB6A), // green
    Color(0xFFD4E157), // lime
    Color(0xFF8D6E63), // brown
    Color(0xFF546E7A), // slate
  ];

  /// The colours a tape's bar starts with; the rest of [colors] are a tap
  /// on + away.
  static const defaultColors = <Color>[
    Color(0xFFFFB74D), // amber
    Color(0xFFEF5350), // red
    Color(0xFF42A5F5), // blue
    Color(0xFF66BB6A), // green
    Color(0xFF546E7A), // slate
  ];

  /// The patterns the tape panel shows first; the rest are under "More
  /// patterns". The user's own are always shown.
  static const defaultPatterns = {
    TapePattern.plain,
    TapePattern.stripes,
    TapePattern.dots,
    TapePattern.grid,
  };

  static TapePattern get pattern => TapePattern.values.firstWhere(
    (pattern) => pattern.name == stows.tapePattern.value,
    orElse: () => .stripes,
  );
  static set pattern(TapePattern pattern) =>
      stows.tapePattern.value = pattern.name;

  /// The doodle a [TapePattern.custom] tape prints, from the saved ones in
  /// [stows.tapeDoodles].
  static String? get doodle => stows.tapeDoodle.value.isEmpty
      ? null
      : stows.tapeDoodle.value;

  @override
  void onDragStart(
    Offset position,
    EditorPage page,
    int pageIndex,
    double? pressure,
  ) {
    super.onDragStart(position, page, pageIndex, pressure);
    Pen.currentStroke
      ?..tapePattern = pattern
      ..tapeCustom = pattern == .custom ? doodle : null;
  }
}
