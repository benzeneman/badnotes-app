import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:badnotes/data/pro/pro.dart';
import 'package:badnotes/components/editor_ui/color_wheel.dart';
import 'package:badnotes/components/editor_ui/editor_ui_colors.dart';
import 'package:badnotes/components/editor_ui/screen_color_picker.dart';
import 'package:badnotes/components/editor_ui/tool_panel.dart';
import 'package:badnotes/components/editor_ui/tool_chips.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/data/prefs.dart';

/// Choosing a color. First the presets, each a tap away, with a + at the
/// end that opens a grid of every hue (or the wheel, or a color picked off
/// the note): a color chosen there is added to the presets. With
/// [replacing] (opened from a color already in the bar), a color chosen
/// anywhere is applied at once, live while dragging, with nothing to add.
/// Optionally a fill switch and its opacity, for shapes.
class ColorPanel extends StatefulWidget {
  const ColorPanel({
    super.key,
    required this.color,
    required this.onChanged,
    this.presets = defaultPresets,
    this.fill,
    this.replacing = false,
  });

  final Color? color;

  /// Changing a color rather than adding one: see the class comment.
  final bool replacing;

  /// A preset was tapped.
  final ValueChanged<Color> onChanged;
  final List<Color> presets;

  /// The fill switch and opacity, for shapes.
  final ({
    bool on,
    double opacity,
    ValueChanged<bool> setOn,
    ValueChanged<double> setOpacity,
  })?
  fill;

  /// 4 rows of 8: pale, bright, deep, then greys.
  static const defaultPresets = <Color>[
    Color(0xFFFFD6DA),
    Color(0xFFFFE0C7),
    Color(0xFFFFF2B8),
    Color(0xFFD9F5D2),
    Color(0xFFC9F2F0),
    Color(0xFFD7E9FF),
    Color(0xFFEBDDFF),
    Color(0xFFFFDDF1),
    Color(0xFFF14B4B),
    Color(0xFFFF8A2B),
    Color(0xFFFFC21A),
    Color(0xFF3CC85A),
    Color(0xFF2BB7C9),
    Color(0xFF3E8EF7),
    Color(0xFFAB6CF2),
    Color(0xFFF25AAE),
    Color(0xFFB3261E),
    Color(0xFFB4501C),
    Color(0xFFB07A0C),
    Color(0xFF1E7D32),
    Color(0xFF136F7E),
    Color(0xFF2A55B8),
    Color(0xFF6B3BB0),
    Color(0xFFA0357A),
    Color(0xFFFFFFFF),
    Color(0xFFE6E6E6),
    Color(0xFFA6A6A6),
    Color(0xFF5E5E5E),
    Color(0xFF000000),
  ];

  /// Opens a [ColorPanel] in a panel titled [title].
  static Future<void> show(
    BuildContext context, {
    required Rect anchor,
    required String title,
    required Color? color,
    required ValueChanged<Color> onChanged,
    List<Color> presets = defaultPresets,
    ({
      bool on,
      double opacity,
      ValueChanged<bool> setOn,
      ValueChanged<double> setOpacity,
    })?
    fill,
    bool replacing = false,
    bool freezeEditor = false,
    bool keepFocus = false,
  }) => showToolPanel(
    context,
    anchor: anchor,
    freezeEditor: freezeEditor,
    keepFocus: keepFocus,
    page: PanelPage(
      title: title,
      width: 320,
      builder: (context, _) => ColorPanel(
        color: color,
        onChanged: onChanged,
        presets: presets,
        fill: fill,
        replacing: replacing,
      ),
    ),
  );

  @override
  State<ColorPanel> createState() => _ColorPanelState();
}

/// Asks, by a menu on [dot], whether to remove its color.
Future<bool> askRemoveColor(
  BuildContext dot, {
  String label = 'Remove color',
}) async {
  var remove = false;
  await showAppleMenu(
    dot,
    anchor: rectOf(dot),
    entries: [
      AppleMenuItem(
        label,
        icon: Icons.delete_outline,
        destructive: true,
        onTap: () => remove = true,
      ),
    ],
  );
  return remove;
}

enum _View { presets, grid, wheel }

class _ColorPanelState extends State<ColorPanel> {
  var _view = _View.presets;

  /// Ringed in the presets.
  late Color? _color = widget.color;

  /// Chosen in the grid or wheel, to add to the presets.
  Color? _draft;
  late var _fillOn = widget.fill?.on ?? false;
  late var _opacity = widget.fill?.opacity ?? 0.15;
  final _hex = TextEditingController();

  static String _hexOf(Color? c) => c == null
      ? ''
      : (c.toARGB32() & 0xFFFFFF)
            .toRadixString(16)
            .padLeft(6, '0')
            .toUpperCase();

  static String _keyOf(Color c) => c.withValues(alpha: 1).toARGB32().toString();

  /// The most width the wheel or grid can have for the rest of the panel to
  /// fit on screen: about 35% of the screen's height.
  static double _room(BuildContext context) =>
      MediaQuery.sizeOf(context).height * 0.35;

  static List<Color> get _custom => [
    for (final s in stows.pinnedColors.value)
      if (int.tryParse(s) case final v?) Color(v),
  ];

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  bool _same(Color a, Color? b) =>
      b != null && (a.toARGB32() & 0xFFFFFF) == (b.toARGB32() & 0xFFFFFF);

  void _pick(Color color) {
    setState(() => _color = color);
    widget.onChanged(color.withValues(alpha: 1));
  }

  void _choose(Color color, {bool hex = true}) {
    setState(() {
      _draft = color.withValues(alpha: 1);
      if (hex) _hex.text = _hexOf(color);
      if (widget.replacing) _color = _draft;
    });
    // changing a color: it's used straight away
    if (widget.replacing) widget.onChanged(color.withValues(alpha: 1));
  }

  void _openGrid() => setState(() {
    _view = _View.grid;
    // changing a color: start from it
    _draft = widget.replacing ? _color?.withValues(alpha: 1) : null;
    _hex.text = widget.replacing ? _hexOf(_color) : '';
  });

  Future<void> _add() async {
    final c = _draft;
    if (c == null) return;
    if (!stows.pinnedColors.value.contains(_keyOf(c)) &&
        !await Pro.mayAddColor(context, _custom.length)) {
      return;
    }
    if (!mounted) return;
    if (!stows.pinnedColors.value.contains(_keyOf(c))) {
      stows.pinnedColors.value = [...stows.pinnedColors.value, _keyOf(c)];
    }
    setState(() {
      _color = c;
      _draft = null;
      _view = _View.presets;
    });
  }

  Future<void> _removeCustom(BuildContext dot, Color c) async {
    if (!await askRemoveColor(dot) || !mounted) return;
    setState(() {
      stows.pinnedColors.value = [
        for (final s in stows.pinnedColors.value)
          if (s != _keyOf(c)) s,
      ];
    });
  }

  Future<void> _pickOffNote() async {
    final c = await ScreenColorPicker.pick(context);
    if (c != null && mounted) _choose(c);
  }

  Widget _presets() => Wrap(
    children: [
      for (final c in widget.presets)
        ColorDot(
          color: c,
          selected: _same(c, _color),
          size: 22,
          onTap: () => _pick(c),
        ),
      for (final c in _custom)
        Builder(
          builder: (dot) => ColorDot(
            color: c,
            selected: _same(c, _color),
            size: 22,
            onTap: () => _pick(c),
            onLongPress: () => _removeCustom(dot, c),
          ),
        ),
      AddColorDot(onTap: _openGrid),
    ],
  );

  /// Greys down the left, then 12 hues from dark to light.
  Widget _spectrum() {
    const rows = 10;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          for (int r = 0; r < rows; r++)
            Row(
              children: [
                for (int h = -1; h < 12; h++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final light = 0.12 + r / (rows - 1) * 0.8;
                        final c = h < 0
                            ? HSLColor.fromAHSL(
                                1,
                                0,
                                0,
                                1 - r / (rows - 1),
                              ).toColor()
                            : HSLColor.fromAHSL(
                                1,
                                h * 30.0,
                                0.85,
                                light,
                              ).toColor();
                        final chosen = _same(c, _draft);
                        return GestureDetector(
                          onTap: () => _choose(c),
                          child: AspectRatio(
                            aspectRatio: 1,
                            // always a white ring, with a faint dark line
                            // inside it so it shows on the pale colors too
                            child: Container(
                              color: c,
                              padding: chosen
                                  ? const EdgeInsets.all(2.5)
                                  : null,
                              foregroundDecoration: chosen
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                    )
                                  : null,
                              child: chosen
                                  ? const DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.fromBorderSide(
                                          BorderSide(color: Colors.black38),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// A round button on a soft disc, as the back and pipette buttons.
  Widget _disc(
    BuildContext context, {
    required String tooltip,
    required VoidCallback onTap,
    required Widget child,
  }) => Tooltip(
    message: tooltip,
    child: InkResponse(
      radius: 22,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: EditorUi.of(context).card,
        ),
        child: Center(child: child),
      ),
    ),
  );

  /// Back to the presets at the left, picking off the note at the right.
  Widget _header(BuildContext context) {
    final ui = EditorUi.of(context);
    return Row(
      children: [
        _disc(
          context,
          tooltip: 'Back to presets',
          onTap: () => setState(() => _view = _View.presets),
          child: Icon(Icons.chevron_left, color: ui.icon),
        ),
        const Spacer(),
        _disc(
          context,
          tooltip: 'Pick a color from the note',
          onTap: _pickOffNote,
          child: Icon(Symbols.colorize, size: 20, weight: 300, color: ui.icon),
        ),
      ],
    );
  }

  /// The color chosen with a + to add it, its hex, and the grid or wheel.
  Widget _addRow(BuildContext context) {
    final ui = EditorUi.of(context);
    final draft = _draft;
    final wheel = _view == _View.wheel;
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: widget.replacing
                ? 'The color in the bar changes as you choose'
                : 'Add to presets',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: draft == null || widget.replacing ? null : _add,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  spacing: 10,
                  children: [
                    SizedBox.square(
                      dimension: 34,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: draft ?? ui.card,
                                border: Border.all(
                                  color: ui.iconDim.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                          if (!widget.replacing)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: EditorUi.accent,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Text(
                        widget.replacing ? 'Changing this color' : 'Add to Presets',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: draft == null ? ui.label : ui.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 108,
          child: TextField(
            controller: _hex,
            textAlign: TextAlign.center,
            style: TextStyle(color: ui.text, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'HEX',
              hintStyle: TextStyle(color: ui.label),
              prefixText: _hex.text.isEmpty ? null : 'HEX ',
              prefixStyle: TextStyle(color: ui.label),
              filled: true,
              fillColor: ui.card,
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            onChanged: (text) {
              final t = text.replaceAll('#', '').trim();
              final v = t.length == 6 ? int.tryParse(t, radix: 16) : null;
              if (v != null) _choose(Color(0xFF000000 | v), hex: false);
            },
          ),
        ),
        const SizedBox(width: 10),
        // a color ring for the wheel; on the wheel, squares back to the grid
        Tooltip(
          message: wheel ? 'Color grid' : 'Color wheel',
          child: InkResponse(
            radius: 20,
            onTap: () =>
                setState(() => _view = wheel ? _View.grid : _View.wheel),
            child: SizedBox.square(
              dimension: 34,
              child: wheel
                  ? Icon(Icons.grid_view_rounded, color: ui.icon)
                  : Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFFFF00),
                            Color(0xFF00FF00),
                            Color(0xFF00FFFF),
                            Color(0xFF0000FF),
                            Color(0xFFFF00FF),
                            Color(0xFFFF0000),
                          ],
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ui.panel,
                        ),
                        child: Center(
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: draft ?? _color ?? Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.fill;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (_view) {
          _View.presets => _presets(),
          _View.grid => Column(
            spacing: 14,
            children: [
              _header(context),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _room(context) * 1.3),
                  child: _spectrum(),
                ),
              ),
              _addRow(context),
            ],
          ),
          _View.wheel => Column(
            spacing: 14,
            children: [
              _header(context),
              Center(
                child: ConstrainedBox(
                  // on a short (landscape) screen the wheel shrinks so the
                  // rows under it stay on screen
                  constraints: BoxConstraints(maxWidth: _room(context)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ColorWheel(
                      color: _draft ?? _color ?? Colors.black,
                      onChanged: _choose,
                    ),
                  ),
                ),
              ),
              _addRow(context),
            ],
          ),
        },
        if (fill != null) ...[
          const SizedBox(height: 12),
          PanelGroup(
            children: [
              PanelSwitchRow(
                title: 'Fill Color',
                value: _fillOn,
                onChanged: (v) {
                  setState(() => _fillOn = v);
                  fill.setOn(v);
                },
              ),
              if (_fillOn)
                PanelSliderRow(
                  title: 'Opacity',
                  value: _opacity,
                  onChanged: (v) {
                    setState(() => _opacity = v);
                    fill.setOpacity(v);
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}
