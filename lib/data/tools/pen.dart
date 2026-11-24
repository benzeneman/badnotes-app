
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/_tool.dart';
import 'package:badnotes/data/tools/highlighter.dart';
import 'package:badnotes/data/tools/pencil.dart';
import 'package:badnotes/data/tools/pressure_curve.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:sbn/tool_id.dart';

class Pen extends Tool {
  @protected
  @visibleForTesting
  new({
    required this.name,
    required this.sizeMin,
    required this.sizeMax,
    required this.sizeStep,
    required this.icon,
    required this.options,
    required this.pressureEnabled,
    required this.color,
    required this.toolId,
  });

  new fountainPen()
    : name = t.editor.pens.fountainPen,
      sizeMin = 0.5,
      sizeMax = 25,
      sizeStep = 0.5,
      icon = fountainPenIcon,
      options = stows.lastFountainPenOptions.value,
      pressureEnabled = stows.fountainPenPressure.value,
      color = Color(stows.lastFountainPenColor.value),
      toolId = .fountainPen;

  new ballpointPen()
    : name = t.editor.pens.ballpointPen,
      sizeMin = 1,
      sizeMax = 25,
      sizeStep = 1,
      icon = ballpointPenIcon,
      options = stows.lastBallpointPenOptions.value,
      pressureEnabled = false,
      color = Color(stows.lastBallpointPenColor.value),
      toolId = .ballpointPen;

  new brushPen()
    : name = 'Brush pen',
      sizeMin = 2,
      sizeMax = 40,
      sizeStep = 1,
      icon = brushPenIcon,
      options = stows.lastBrushPenOptions.value,
      pressureEnabled = true,
      color = Color(stows.lastBrushPenColor.value),
      toolId = .brushPen;

  new calligraphyPen()
    : name = 'Calligraphy pen',
      sizeMin = 2,
      sizeMax = 40,
      sizeStep = 1,
      icon = calligraphyPenIcon,
      options = stows.lastCalligraphyPenOptions.value,
      pressureEnabled = true,
      color = Colors.black,
      toolId = .calligraphyPen;

  final String name;
  final double sizeMin, sizeMax, sizeStep;
  late final int sizeStepsBetweenMinAndMax = ((sizeMax - sizeMin) / sizeStep)
      .round();
  final Object icon;

  @override
  final ToolId toolId;

  static const fountainPenIcon = FontAwesomeIcons.penFancy;
  static const ballpointPenIcon = FontAwesomeIcons.pen;
  static const calligraphyPenIcon = FontAwesomeIcons.penNib;
  static const brushPenIcon = FontAwesomeIcons.paintbrush;

  static Stroke? currentStroke;
  Color color;
  bool pressureEnabled;
  StrokeOptions options;

  /// Has its own toolbar button, so [currentPen] is never the ballpoint pen.
  static final currentBallpointPen = Pen.ballpointPen();

  /// Has its own toolbar button too.
  static final currentCalligraphyPen = Pen.calligraphyPen();

  /// Thick and thin with pressure, like a brush.
  static final currentBrushPen = Pen.brushPen();

  static var _currentPen = Pen.fountainPen();
  static Pen get currentPen => _currentPen;
  static set currentPen(Pen currentPen) {
    assert(
      currentPen is! Highlighter,
      'Use Highlighter.currentHighlighter instead',
    );
    assert(currentPen is! Pencil, 'Use Pencil.currentPencil instead');
    _currentPen = currentPen;
  }

  void onDragStart(
    Offset position,
    EditorPage page,
    int pageIndex,
    double? pressure,
  ) {
    currentStroke =
        Stroke(
            color: color,
            pressureEnabled: pressureEnabled,
            options: toolId == .highlighter
                // a wide marker shows every hand jitter: always round off the
                // outline; how much the line follows the hand is the user's
                // stabilization setting (streamline)
                ? (options.copyWith(isComplete: false, smoothing: 1)
                    ..start.taperEnabled = false
                    ..end.taperEnabled = false)
                : options.copyWith(isComplete: false),
            pageIndex: pageIndex,
            page: page,
            toolId: toolId,
          )
          ..speedInk = toolId == .fountainPen
          ..nib2 = true
          ..steadyLine = toolId == .ballpointPen
          ..steady2 = true
          ..inkLine = inkLine;
    onDragUpdate(position, pressure);
  }

  /// Whether strokes are a straight line from where the pen went down.
  bool get drawsStraight => switch (toolId) {
    .highlighter =>
      stows.highlighterStraight.value || stows.highlighterAxisLock.value,
    .tape => stows.tapeStraight.value,
    _ => false,
  };

  /// [position] moved onto the level or upright line through [start],
  /// whichever is closer.
  @visibleForTesting
  static Offset snapToAxis(Offset start, Offset position) {
    final delta = position - start;
    return delta.dx.abs() >= delta.dy.abs()
        ? Offset(position.dx, start.dy)
        : Offset(start.dx, position.dy);
  }

  /// Three sizes to tap between, small to large by default, with one chosen.
  /// Saved as `toolId:first:second:third:chosen`; older saves have two sizes.
  List<double> get sizeSlots => _readSlots().$1;
  int get chosenSizeSlot => _readSlots().$2;

  /// The sizes and chosen slot in a saved [entry] of this [tool], if it is one.
  @visibleForTesting
  static (List<double>, int)? parseSizeSlots(String entry, String tool) {
    final parts = entry.split(':');
    if (parts.length < 4 || parts.length > 5 || parts[0] != tool) return null;
    final sizes = [
      for (final part in parts.sublist(1, parts.length - 1))
        double.tryParse(part),
    ];
    final chosen = int.tryParse(parts.last);
    if (sizes.contains(null) || chosen == null) return null;
    return (
      [for (final size in sizes) size!],
      chosen.clamp(0, sizes.length - 1),
    );
  }

  (List<double>, int) _readSlots() {
    for (final entry in stows.penSizeSlots.value) {
      final saved = parseSizeSlots(entry, toolId.name);
      if (saved == null) continue;
      final slots = saved.$1;
      if (slots.length == 2) slots.add((slots[1] * 2).clamp(sizeMin, sizeMax));
      // the size can have been changed elsewhere: the chosen slot shows it
      slots[saved.$2] = options.size;
      return (slots, saved.$2);
    }
    if (defaultSizeSlots(toolId) case final sizes?) {
      // a new install: the first size is the pen's size
      final slots = [for (final size in sizes) size.clamp(sizeMin, sizeMax)];
      if (slots.contains(options.size)) return (slots, slots.indexOf(options.size));
      return ([options.size, ...slots.skip(1)], 0);
    }
    final size = options.size;
    return (
      [
        size,
        (size * 2).clamp(sizeMin, sizeMax),
        (size * 4).clamp(sizeMin, sizeMax),
      ],
      0,
    );
  }

  /// The three sizes a new install has: 5, 8 and 12 for the pens, 20, 40
  /// and 80 for the highlighter.
  static List<double>? defaultSizeSlots(ToolId tool) => switch (tool) {
    .fountainPen || .ballpointPen || .brushPen || .calligraphyPen => const [
      5,
      8,
      12,
    ],
    .highlighter => const [20, 40, 80],
    _ => null,
  };

  void _saveSlots(List<double> slots, int chosen) {
    final prefix = '${toolId.name}:';
    stows.penSizeSlots.value = [
      for (final entry in stows.penSizeSlots.value)
        if (!entry.startsWith(prefix)) entry,
      '$prefix${slots.join(':')}:$chosen',
    ];
  }

  void chooseSizeSlot(int slot) {
    final slots = sizeSlots;
    options.size = slots[slot];
    _saveSlots(slots, slot);
  }

  /// Changes the size of the chosen slot, and so the size of the pen.
  void setSize(double size) {
    // the slots as they were: unsaved, they're worked out from the size,
    // and all three would follow it
    final (slots, chosen) = _readSlots();
    slots[chosen] = size;
    options.size = size;
    _saveSlots(slots, chosen);
  }

  /// Whether this pen can draw dashed or dotted: the four pens, not the
  /// highlighter, pencil, shapes or tape.
  bool get hasInkLine => switch (toolId) {
    .fountainPen || .ballpointPen || .brushPen || .calligraphyPen => true,
    _ => false,
  };

  /// The line of the chosen size slot: solid, dashed or dotted.
  ShapeLine get inkLine => inkLineOf(chosenSizeSlot);

  ShapeLine inkLineOf(int slot) {
    if (!hasInkLine) return .solid;
    final prefix = '${toolId.name}:$slot:';
    for (final entry in stows.penSlotLines.value) {
      if (!entry.startsWith(prefix)) continue;
      final name = entry.substring(prefix.length);
      return ShapeLine.values.firstWhere(
        (line) => line.name == name,
        orElse: () => .solid,
      );
    }
    return .solid;
  }

  set inkLine(ShapeLine line) {
    final prefix = '${toolId.name}:$chosenSizeSlot:';
    stows.penSlotLines.value = [
      for (final entry in stows.penSlotLines.value)
        if (!entry.startsWith(prefix)) entry,
      if (line != .solid) '$prefix${line.name}',
    ];
  }

  /// A fountain pen's pressure spread out from the middle, or drawn in towards
  /// it, by the pressure sensitivity setting. 50% leaves it as it is.
  double? _adjustedPressure(double? pressure) {
    if (toolId != .fountainPen || pressure == null) return pressure;
    final amount = stows.fountainPressureAmount.value * 2;
    return (0.5 + (pressure - 0.5) * amount).clamp(0.0, 1.0);
  }

  void onDragUpdate(Offset position, double? pressure) {
    // a faint graze doesn't draw: the stroke only starts once the pen
    // presses hard enough, and an empty stroke is dropped when it lifts
    if (PressureCurve.tooLight(pressure)) return;
    pressure = PressureCurve.adjust(pressure);
    final start = currentStroke?.firstPoint;
    if (drawsStraight && start != null) {
      // tape goes straight at any angle; only the highlighter can be held
      // to level or upright
      currentStroke?.setEndOfLine(
        toolId == .highlighter && stows.highlighterAxisLock.value
            ? snapToAxis(start, position)
            : position,
      );
      return;
    }
    currentStroke?.addPoint(position, _adjustedPressure(pressure));
    if (!stows.penReduceLatency.value) return;
    // The ink reaches right to the pen, where the stabilized line would run
    // a little behind it; taken back when the pen lifts. It used to guess on
    // ahead of the pen too: on every turn and stop the guess overshot and
    // the ink pulled back, which felt like more lag with it on than off.
    if (switch (toolId) {
      .ballpointPen || .fountainPen || .pencil || .highlighter => true,
      _ => false,
    }) {
      currentStroke?.predictNextPoint(maxDistance: 0);
    }
  }

  Stroke? onDragEnd() {
    final stroke = currentStroke;
    currentStroke = null;
    if (stroke == null) return null;

    return stroke
      ..options.isComplete = true
      ..markPolygonNeedsUpdating();
  }

  /// The default stroke options.
  ///
  /// Note that these are different to the default options in [StrokeOptions]
  /// e.g. [StrokeOptions.defaultSize] for historical reasons
  /// (i.e. [StrokeOptions.toJson] does not include default values.)
  static final defaultOptions = StrokeOptions(size: 3);

  /// Tip sharpness 50% and stabilization 30%, with pressure sensitivity 50%
  /// and reduced latency on by default: a line that looks like ink without
  /// changing any setting, and keeps the corners of letters.
  /// A new install's pens: sizes 5, 8 and 12 ([defaultSizeSlots]), no
  /// stabilization; the fountain pen at full tip sharpness, the brush at
  /// 60%.
  static StrokeOptions get fountainPenOptions =>
      defaultOptions.copyWith(size: 5, thinning: 0.9, streamline: 0);
  static StrokeOptions get ballpointPenOptions =>
      defaultOptions.copyWith(size: 5, streamline: 0);
  static StrokeOptions get calligraphyPenOptions =>
      defaultOptions.copyWith(size: 5, streamline: 0);
  static StrokeOptions get brushPenOptions => defaultOptions.copyWith(
    size: 5,
    thinning: 0.9 * 0.6,
    smoothing: 0.6,
    streamline: 0,
  );
  static StrokeOptions get shapePenOptions =>
      defaultOptions.copyWith(smoothing: 0, streamline: 0);
  // stabilization 80% on the slider (which goes to 0.95)
  static StrokeOptions get highlighterOptions =>
      defaultOptions.copyWith(size: 20, streamline: 0.8 * 0.95);
  static StrokeOptions get pencilOptions => defaultOptions.copyWith(
    streamline: 0.1,
    start: StrokeEndOptions.start(taperEnabled: true, customTaper: 1),
    end: StrokeEndOptions.end(taperEnabled: true, customTaper: 1),
  );
}
