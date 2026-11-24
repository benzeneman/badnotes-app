import 'dart:math';

import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:badnotes/components/canvas/_canvas_painter.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/components/toolbar/ink_dial.dart';
import 'package:badnotes/data/extensions/axis_extensions.dart';
import 'package:badnotes/data/extensions/color_extensions.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/highlighter.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/pencil.dart';
import 'package:badnotes/data/tools/shape_pen.dart';
import 'package:badnotes/data/tools/tape.dart';
import 'package:badnotes/data/tools/tape_pattern.dart';
import 'package:sbn/has_size.dart';

class PenModal<T extends Pen> extends StatefulWidget {
  const new({super.key, required this.getTool, required this.setTool});

  /// Gets the current/last-used tool of type [T],
  /// e.g. [Pen.currentPen] or [Highlighter.currentHighlighter].
  final T Function() getTool;

  /// Sets a pen to be the current pen.
  final void Function(Pen) setTool;

  @override
  State<PenModal<T>> createState() => _PenModalState<T>();
}

class _PenModalState<T extends Pen> extends State<PenModal<T>> {
  @override
  Widget build(BuildContext context) {
    final axis = stows.editorToolbarAlignment.value.axis.opposite;
    final pen = widget.getTool();

    return Flex(
      direction: axis,
      mainAxisAlignment: .center,
      spacing: 8,
      children: [
        _SizeDots(pen: pen, axis: axis, onChanged: () => setState(() {})),

        if (pen is Tape)
          Flexible(
            child: _TapeOptions(
              axis: axis,
              tape: pen,
              setState: setState,
            ),
          ),

        if (pen is ShapePen)
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: axis,
              child: Flex(
                direction: axis,
                mainAxisSize: .min,
                children: [
                  for (final kind in ShapeKind.values)
                    IconButton(
                      tooltip: kind.label,
                      style: IconButton.styleFrom(
                        backgroundColor: ShapePen.kind == kind
                            ? ColorScheme.of(
                                context,
                              ).secondary.withValues(alpha: 0.2)
                            : Colors.transparent,
                      ),
                      icon: Icon(kind.icon),
                      onPressed: () => setState(() => ShapePen.kind = kind),
                    ),
                ],
              ),
            ),
          ),

        if (pen is! ShapePen && pen is! Tape)
          IconButton(
            tooltip: 'Pen settings',
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await showPenSettings(context, pen, widget.setTool);
              // the panel can change the size too
              if (mounted) setState(() {});
            },
          ),
      ],
    );
  }
}

/// A tape's colors and designs.
class _TapeOptions extends StatelessWidget {
  const _TapeOptions({
    required this.axis,
    required this.tape,
    required this.setState,
  });

  final Axis axis;
  final Tape tape;
  final void Function(VoidCallback) setState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return SingleChildScrollView(
      scrollDirection: axis,
      child: Flex(
        direction: axis,
        mainAxisSize: .min,
        spacing: 6,
        children: [
          for (final pattern in TapePattern.values)
            if (pattern != .custom)
            InkWell(
              onTap: () => setState(() => Tape.pattern = pattern),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Tape.pattern == pattern
                        ? colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CustomPaint(
                  size: const Size(44, 22),
                  painter: TapeSamplePainter(tape.color, pattern),
                ),
              ),
            ),
          const SizedBox.square(dimension: 6),
          for (final color in Tape.colors)
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => setState(() {
                tape.color = color;
                stows.tapeColor.value = color.toARGB32();
              }),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  shape: .circle,
                  border: Border.all(
                    color: tape.color.toARGB32() == color.toARGB32()
                        ? colorScheme.onSurface
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TapeSamplePainter extends CustomPainter {
  TapeSamplePainter(this.color, this.pattern, {this.doodle});

  final Color color;
  final TapePattern pattern;

  /// What a [TapePattern.custom] tape prints.
  final String? doodle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final middle = size.height / 2;
    final line = Path()
      ..moveTo(0, middle)
      ..lineTo(size.width, middle);
    canvas.drawPath(
      pattern.stamps(line, size.height, doodle: doodle),
      Paint()
        ..color = color.computeLuminance() > 0.55
            ? const Color(0x33000000)
            : const Color(0x88FFFFFF),
    );
  }

  @override
  bool shouldRepaint(TapeSamplePainter oldDelegate) =>
      color != oldDelegate.color ||
      pattern != oldDelegate.pattern ||
      doodle != oldDelegate.doodle;
}

/// A quick way to a whole style of writing with this pen.
typedef _PenStyle = ({String name, void Function(Pen pen) apply});

List<_PenStyle> _stylesFor(Pen pen) {
  void pencilStrength(Pen pen, double size, int alpha) {
    pen.options.size = size;
    stows.pencilAlpha.value = alpha;
    pen.color = pen.color.withAlpha(alpha);
  }

  void fountain(Pen pen, double size, double sharpness, double pressure) {
    pen.options
      ..size = size
      ..thinning = sharpness;
    stows.fountainPressureAmount.value = pressure;
    pen.pressureEnabled = pressure > 0;
    stows.fountainPenPressure.value = pressure > 0;
  }

  _PenStyle sized(String name, double size) =>
      (name: name, apply: (pen) => pen.options.size = size);

  return switch (pen.toolId) {
    .fountainPen => [
      (name: 'Tiny', apply: (pen) => fountain(pen, 1, 0.5, 0.3)),
      (name: 'Neat', apply: (pen) => fountain(pen, 2, 0.5, 0.5)),
      (name: 'Flowing', apply: (pen) => fountain(pen, 3, 0.8, 0.9)),
      (name: 'Heading', apply: (pen) => fountain(pen, 6, 0.4, 0.6)),
    ],
    .pencil => [
      (name: 'Faint', apply: (pen) => pencilStrength(pen, 3, 130)),
      (name: 'Sketch', apply: (pen) => pencilStrength(pen, 6, 200)),
      (name: 'Dark', apply: (pen) => pencilStrength(pen, 8, 255)),
    ],
    .highlighter => [sized('Thin', 12), sized('Wide', 20), sized('Broad', 35)],
    .calligraphyPen => [sized('Small', 6), sized('Medium', 10), sized('Large', 18)],
    _ => [sized('Tiny', 1), sized('Neat', 3), sized('Heading', 6)],
  };
}

/// A slider for a pen's size. Squared, so the thin sizes used for writing have
/// most of the slider.
Widget _sizeSlider(Pen pen, VoidCallback changed) {
  final range = pen.sizeMax - pen.sizeMin;
  return InkSlider(
    label: 'Size',
    value: sqrt(((pen.options.size - pen.sizeMin) / range).clamp(0.0, 1.0)),
    valueText: pen.options.size.toStringAsFixed(1),
    onChanged: (v) {
      final steps = (v * v * range / pen.sizeStep).round();
      pen.setSize(pen.sizeMin + steps * pen.sizeStep);
      changed();
    },
  );
}

/// The toolbar's two sizes, as dots as big as the ink. Tapping the chosen one
/// again changes its size.
class _SizeDots extends StatelessWidget {
  const _SizeDots({
    required this.pen,
    required this.axis,
    required this.onChanged,
  });

  final Pen pen;
  final Axis axis;
  final VoidCallback onChanged;

  static const _target = 44.0, _smallest = 6.0, _largest = 30.0;

  Future<void> _editSize(BuildContext context) => showAppleDialog<void>(
    context: context,
    barrierColor: Colors.black26,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: InkPalette.of(context).desk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Theme(
            data: Theme.of(context),
            child: Column(
              mainAxisSize: .min,
              spacing: 8,
              children: [
                SizedBox(
                  width: 260,
                  child: _sizeSlider(pen, () {
                    setState(() {});
                    onChanged();
                  }),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final slots = pen.sizeSlots;
    final chosen = pen.chosenSizeSlot;
    final range = pen.sizeMax - pen.sizeMin;
    return Flex(
      direction: axis,
      mainAxisSize: .min,
      children: [
        for (final (slot, size) in slots.indexed)
          Semantics(
            button: true,
            selected: slot == chosen,
            label: 'Size ${size.toStringAsFixed(1)}',
            child: InkResponse(
              radius: _target / 2,
              onTap: () {
                if (slot == chosen) {
                  _editSize(context);
                } else {
                  pen.chooseSizeSlot(slot);
                  onChanged();
                }
              },
              child: Container(
                width: _target,
                height: _target,
                alignment: .center,
                decoration: BoxDecoration(
                  shape: .circle,
                  border: Border.all(
                    color: slot == chosen
                        ? colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  width:
                      _smallest +
                      (_largest - _smallest) *
                          sqrt(((size - pen.sizeMin) / range).clamp(0.0, 1.0)),
                  height:
                      _smallest +
                      (_largest - _smallest) *
                          sqrt(((size - pen.sizeMin) / range).clamp(0.0, 1.0)),
                  decoration: BoxDecoration(
                    shape: .circle,
                    color: pen.color.withValues(alpha: 1),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The ink bench: the pen's line on a sheet of paper its tab belongs to, then
/// whole styles to try and sliders.
/// Edits [pen.options] in place, which is the saved stow value.
Future<void> showPenSettings(
  BuildContext context,
  Pen pen,
  void Function(Pen) setTool,
) {
  var current = pen;
  return showAppleDialog<void>(
    context: context,
    barrierColor: Colors.black38,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final pen = current;
        final isFountainPen = pen.toolId == .fountainPen;
        final isBallpointPen = pen.toolId == .ballpointPen;
        final penKinds = <(Pen, IconData, String)>[
          (Pen.currentPen, Symbols.stylus_fountain_pen, 'Fountain'),
          (Pen.currentBallpointPen, Symbols.ink_pen, 'Ball'),
          (Pen.currentCalligraphyPen, Symbols.history_edu, 'Calligraphy'),
        ];
        final tabs = penKinds.any((kind) => kind.$1 == pen)
            ? penKinds
            : <(Pen, IconData, String)>[(pen, Symbols.edit, pen.name)];

        final sliders = <Widget>[
          _sizeSlider(pen, () => setState(() {})),
          if (isFountainPen) ...[
            InkSlider(
              label: 'Sharp ends',
              value: pen.options.thinning.clamp(0.0, 0.9) / 0.9,
              onChanged: (v) => setState(() => pen.options.thinning = v * 0.9),
            ),
            InkSlider(
              label: 'Pressure',
              value: pen.pressureEnabled
                  ? stows.fountainPressureAmount.value
                  : 0,
              onChanged: (v) => setState(() {
                stows.fountainPressureAmount.value = v;
                pen.pressureEnabled = v > 0;
                stows.fountainPenPressure.value = v > 0;
              }),
            ),
          ],
          if (pen is Pencil || pen is Highlighter)
            InkSlider(
              label: 'Strength',
              value:
                  (pen is Pencil
                      ? stows.pencilAlpha.value
                      : stows.highlighterAlpha.value) /
                  255,
              onChanged: (v) => setState(() {
                final alpha = (max(v, 0.1) * 255).round();
                if (pen is Pencil) {
                  stows.pencilAlpha.value = alpha;
                } else {
                  stows.highlighterAlpha.value = alpha;
                }
                pen.color = pen.color.withAlpha(alpha);
              }),
            ),
          InkSlider(
            label: 'Steady hand',
            value: pen.options.streamline.clamp(0.0, 0.95) / 0.95,
            onChanged: (v) => setState(() => pen.options.streamline = v * 0.95),
          ),
        ];

        Widget toggle(
          IconData icon,
          String label,
          String tooltip,
          bool value,
          ValueChanged<bool> onChanged,
        ) => InkPill(
          icon: icon,
          label: label,
          tooltip: tooltip,
          on: value,
          onTap: () => setState(() => onChanged(!value)),
        );

        final toggles = <Widget>[
          if (pen is Highlighter) ...[
            toggle(
              Icons.horizontal_rule,
              'Straight',
              'Highlights in a straight line',
              stows.highlighterStraight.value,
              (v) => stows.highlighterStraight.value = v,
            ),
            toggle(
              Icons.add,
              'Only 90° and 180°',
              'Highlights run only level or upright, never at a slant',
              stows.highlighterAxisLock.value,
              (v) => stows.highlighterAxisLock.value = v,
            ),
          ],
          if (isBallpointPen || isFountainPen)
            toggle(
              Icons.bolt,
              'Faster ink',
              'Ink predicts where the pen is going. May wobble on sharp turns',
              stows.penReduceLatency.value,
              (v) => stows.penReduceLatency.value = v,
            ),
          if (isBallpointPen)
            toggle(
              Icons.pan_tool_alt_outlined,
              'Hold for shapes',
              'Hold the pen still after drawing to snap to a perfect shape',
              stows.penDrawAndHold.value,
              (v) => stows.penDrawAndHold.value = v,
            ),
          if (isBallpointPen || isFountainPen)
            toggle(
              Icons.gesture,
              'Scribble erases',
              'Scribble back and forth over ink to erase it',
              isBallpointPen
                  ? stows.penScribbleToErase.value
                  : stows.fountainScribbleToErase.value,
              (v) {
                if (isBallpointPen) {
                  stows.penScribbleToErase.value = v;
                } else {
                  stows.fountainScribbleToErase.value = v;
                }
              },
            ),
        ];

        return Dialog(
          alignment: Alignment.bottomCenter,
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: InkPalette.of(context).desk,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Theme(
            data: Theme.of(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  children: [
                    // tabs of the sheet below: the chosen one is part of it
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 10),
                      child: Row(
                        children: [
                          for (final (kind, icon, name) in tabs)
                            GestureDetector(
                              onTap: () => setState(() {
                                current = kind;
                                setTool(kind);
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: kind == pen ? InkPalette.paperOf(context) : null,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  spacing: 6,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 18,
                                      color: kind == pen
                                          ? InkPalette.of(context).text
                                          : InkPalette.of(context).muted,
                                    ),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: kind == pen
                                            ? InkPalette.of(context).text
                                            : InkPalette.of(context).muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Done',
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 92,
                      child: CustomPaint(
                        painter: PenSamplePainter(
                          pen,
                          paper: InkPalette.paperOf(context),
                          invert:
                              Theme.brightnessOf(context) == .dark &&
                              stows.editorAutoInvert.value,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                      child: Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: .stretch,
                        spacing: 14,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final style in _stylesFor(pen))
                                InkPill(
                                  icon: Icons.auto_awesome,
                                  label: style.name,
                                  onTap: () => setState(() {
                                    style.apply(pen);
                                    pen.setSize(pen.options.size);
                                  }),
                                ),
                            ],
                          ),
                          Column(
 spacing: 6,
 crossAxisAlignment: .stretch,
 children: sliders,
),
                          if (toggles.isNotEmpty)
                            Wrap(spacing: 6, runSpacing: 6, children: toggles),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  ).whenComplete(() {
    // save now, not only when the editor closes
    stows.lastFountainPenOptions.notifyListeners();
    stows.lastBallpointPenOptions.notifyListeners();
    stows.lastCalligraphyPenOptions.notifyListeners();
    stows.lastHighlighterOptions.notifyListeners();
    stows.lastPencilOptions.notifyListeners();
  });
}

/// A line drawn with the real pen on a strip of dotted paper, so its settings
/// show as they change.
class PenSamplePainter extends CustomPainter {
  PenSamplePainter(this.pen, {required this.paper, required this.invert});

  final Pen pen;
  final Color paper;

  /// Whether ink shows inverted, as on a page in dark mode.
  final bool invert;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(paper, BlendMode.src);
    final dot = Paint()
      ..color = (invert ? Colors.white : Colors.black).withValues(alpha: 0.14);
    const spacing = 18.0;
    for (var x = spacing / 2; x < size.width; x += spacing) {
      for (var y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, dot);
      }
    }

    final ink = pen.color.withInversion(invert);
    final stroke = Stroke(
      color: ink,
      pressureEnabled: pen.pressureEnabled,
      options: pen.options.copyWith(isComplete: true),
      pageIndex: 0,
      page: HasSize(size),
      toolId: pen.toolId,
    );
    const steps = 80;
    final margin = pen.options.size + 16;
    final height = max(size.height / 2 - margin, 6.0);
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      // pressed light, hard, then light, so tip and pressure settings show
      stroke.addPoint(
        Offset(
          margin + (size.width - 2 * margin) * t,
          size.height / 2 + sin(t * 3 * pi) * height,
        ),
        0.08 + 0.9 * pow(sin(t * pi), 2).toDouble(),
      );
    }
    stroke.inkLine = pen.inkLine;
    switch (pen.toolId) {
      case .pencil:
        CanvasPainter.paintGraphite(canvas, stroke, ink);
      case .highlighter:
      case .ballpointPen when pen.inkLine == .solid:
        canvas.drawPath(
          stroke.centerlinePath,
          Paint()
            ..color = ink
            ..style = .stroke
            ..strokeCap = .round
            ..strokeJoin = .round
            ..strokeWidth = pen.options.size,
        );
      default:
        canvas.drawPath(stroke.highQualityPath, Paint()..color = ink);
    }
  }

  @override
  bool shouldRepaint(PenSamplePainter oldDelegate) => true;
}
