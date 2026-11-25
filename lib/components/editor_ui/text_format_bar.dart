import 'package:flutter/material.dart';
import 'package:badnotes/data/pro/pro.dart';
import 'package:badnotes/components/editor/sticky_note_dialog.dart';
import 'package:badnotes/components/editor/text_box_overlay.dart';
import 'package:badnotes/components/editor_ui/color_panel.dart';
import 'package:badnotes/components/editor_ui/editor_ui_colors.dart';
import 'package:badnotes/components/editor_ui/tool_chips.dart';
import 'package:badnotes/components/editor_ui/tool_panel.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/ui/bn_tool_panels.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/custom_fonts.dart';

/// The three fonts offered first, by the name shown, then the family.
const textMainFonts = <String, String>{
  'Modern': 'AtkinsonHyperlegibleNext',
  'Classic': 'PlayfairDisplay',
  'Technical': 'FiraMono',
};

/// The name a font goes by in the text bar.
String textFontName(String? family) {
  for (final MapEntry(:key, :value) in textMainFonts.entries) {
    if (value == family) return key;
  }
  return textBoxFonts[family] ?? family ?? 'Modern';
}

/// Text colors in the text bar's presets: two rows of eight.
const textColorPresets = <Color>[
  Color(0xFF000000), Color(0xFF5E5E5E), Color(0xFF9E9E9E), Color(0xFFD6D6D6),
  Color(0xFFFFFFFF), Color(0xFFC86DD7), Color(0xFFD50000), Color(0xFFF14B4B),
  Color(0xFFF7A1A1), Color(0xFFF2992E), Color(0xFF1E88E5), Color(0xFF123F8C),
  Color(0xFF0B6E4F), Color(0xFF8BC34A), Color(0xFFFFF59D), Color(0xFF26A69A),
];

/// The backgrounds offered as text box styles: none, then nine.
const _boxPresets = <({Color? fill, Color? border})>[
  (fill: null, border: null),
  (fill: Color(0xFF2E3440), border: null),
  (fill: Color(0xFFB2F35C), border: null),
  (fill: Color(0xFFFFD7CC), border: null),
  (fill: Color(0xFFFFFFFF), border: Color(0xFFD0D0D0)),
  (fill: Color(0xFFF25656), border: null),
  (fill: Color(0xFFFFF36B), border: null),
  (fill: Color(0xFFEAF2FF), border: null),
  (fill: Color(0xFF4A5A85), border: null),
  (fill: Color(0xFFFFFFFF), border: null),
];

/// The text tool's bar: color, size, font, bold and such, alignment, lists
/// and the text box's style. Edits a [StickyNoteResult] used as a format.
/// [leading] and [trailing] go at its ends, such as Done or Pin.
class TextFormatBar extends StatelessWidget {
  const TextFormatBar({
    super.key,
    required this.format,
    required this.onChanged,
    this.axis = Axis.horizontal,
    this.leading = const [],
    this.trailing = const [],
    this.afterPanel,
    this.freezeEditor = false,
  });

  final StickyNoteResult format;
  final ValueChanged<StickyNoteResult> onChanged;
  final Axis axis;
  final List<Widget> leading, trailing;

  /// Called when a panel it opened has closed, as to type again.
  final VoidCallback? afterPanel;

  /// Its panels show a still picture of the pages under them: for when
  /// nothing on the page changes as they're used (the tool's own bar).
  final bool freezeEditor;

  /// Typing in a text box ([afterPanel] set): the panels leave the keyboard
  /// up rather than closing it and opening it again around each one.
  bool get _keepFocus => afterPanel != null;

  static const _ink = Color(0xFF202124);

  Future<void> _panel(BuildContext anchor, PanelPage page) async {
    await showToolPanel(
      anchor,
      anchor: rectOf(anchor),
      page: page,
      freezeEditor: freezeEditor,
      keepFocus: _keepFocus,
    );
    afterPanel?.call();
  }

  Widget _chip(
    BuildContext context,
    String tooltip,
    Widget icon,
    void Function(BuildContext chip) onTap, {
    bool selected = false,
  }) => Builder(
    builder: (chip) => ToolChip(
      icon: icon,
      tooltip: tooltip,
      selected: selected,
      selectedColor: EditorUi.of(context).chosenChip,
      onTap: () => onTap(chip),
    ),
  );

  Widget _label(BuildContext context, String text, {String? font}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        text,
        style: TextStyle(
          color: EditorUi.of(context).icon,
          fontSize: 14,
          fontFamily: font,
        ),
      ),
      const Icon(Icons.expand_more, size: 14),
    ],
  );

  /// The format as it changes in an open panel, for the panel to show.
  static StickyNoteResult? _live;
  StickyNoteResult get _now => _live ?? format;

  void _set(StickyNoteResult next) {
    _live = next;
    onChanged(next);
  }

  PanelPage _sizePage() => PanelPage(
    title: 'Size',
    width: 300,
    builder: (context, setPanel) {
      final size = _now.fontSize ?? 36;
      void to(double v) {
        _set(_now.copyWith(fontSize: v.clamp(6.0, 144.0).roundToDouble()));
        setPanel(() {});
      }

      return PanelGroup(
        children: [
          PanelSliderRow(
            title: 'Size',
            value: size,
            min: 6,
            max: 144,
            valueText: '${size.round()}',
            onChanged: to,
          ),
          PanelStepperRow(
            title: 'Size',
            unit: '',
            value: size,
            min: 6,
            max: 144,
            onChanged: to,
          ),
        ],
      );
    },
  );

  PanelPage _fontPage() => PanelPage(
    title: 'Font',
    width: 260,
    builder: (context, _) {
      Widget row(String name, String family) => PanelNavRow(
        title: name,
        titleStyle: _fontStyle(family),
        chevron: false,
        checked: _now.font == family,
        onTap: () {
          _set(_now.copyWith(font: family));
          Navigator.pop(context);
        },
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelGroup(
            children: [
              for (final MapEntry(:key, :value) in textMainFonts.entries)
                row(key, value),
            ],
          ),
          const SizedBox(height: 10),
          PanelGroup(
            children: [
              PanelNavRow(
                title: 'More Fonts…',
                onTap: () => ToolPanel.push(context, _moreFontsPage()),
              ),
            ],
          ),
        ],
      );
    },
  );

  /// [family] at the size of a panel row, to show a font in itself.
  static TextStyle _fontStyle(String family) =>
      BnType.body.copyWith(fontFamily: family, fontSize: 16);

  PanelPage _moreFontsPage() => PanelPage(
    title: 'More Fonts',
    width: 280,
    builder: (context, setPanel) {
      Widget row(String family, String name) => PanelNavRow(
        title: name,
        titleStyle: _fontStyle(family),
        chevron: false,
        checked: _now.font == family,
        onTap: () {
          _set(_now.copyWith(font: family));
          Navigator.pop(context);
        },
      );
      Future<void> add() async {
        if (!await Pro.require(context, ProFeature.fonts)) return;
        try {
          final family = await CustomFonts.add({
            ...textBoxFonts.keys,
            ...textMainFonts.values,
          });
          if (family == null) return;
          _set(_now.copyWith(font: family));
          setPanel(() {});
        } on FormatException catch (e) {
          if (context.mounted) showBanner(context, e.message);
        } catch (e) {
          if (context.mounted) showBanner(context, 'Font not added: $e');
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelGroup(
            children: [
              for (final MapEntry(:key, :value) in textBoxFonts.entries)
                row(key, value),
            ],
          ),
          const PanelSection('Your Fonts'),
          PanelGroup(
            children: [
              for (final family in CustomFonts.families.value)
                Row(
                  children: [
                    Expanded(child: row(family, family)),
                    BnSubButton(
                      icon: BnIcons.trash,
                      iconSize: 16,
                      tooltip: 'Remove $family',
                      onTap: () async {
                        await CustomFonts.remove(family);
                        setPanel(() {});
                      },
                    ),
                  ],
                ),
              PanelNavRow(
                icon: BnIcons.add,
                title: 'Add Font…',
                chevron: false,
                onTap: add,
              ),
            ],
          ),
        ],
      );
    },
  );

  PanelPage _stylePage() => PanelPage(
    title: 'Style',
    width: 260,
    builder: (context, setPanel) {
      Widget toggle(String tip, IconData icon, bool on, StickyNoteResult next) =>
          _chip(context, tip, Icon(icon), (_) {
            _set(next);
            setPanel(() {});
          }, selected: on);
      final f = _now;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggle('Bold', Icons.format_bold, f.bold, f.copyWith(bold: !f.bold)),
          toggle(
            'Italic',
            Icons.format_italic,
            f.italic,
            f.copyWith(italic: !f.italic),
          ),
          toggle(
            'Underline',
            Icons.format_underlined,
            f.underline,
            f.copyWith(underline: !f.underline),
          ),
          toggle(
            'Strikethrough',
            Icons.format_strikethrough,
            f.strike,
            f.copyWith(strike: !f.strike),
          ),
        ],
      );
    },
  );

  PanelPage _lineHeightPage() => PanelPage(
    title: 'Line Height',
    width: 300,
    builder: (context, setPanel) {
      final f = _now;
      final size = f.fontSize ?? 36;
      final auto = f.lineHeight == null;
      final points = size * (f.lineHeight ?? 4 / 3);
      void to(double v) {
        _set(f.copyWith(lineHeight: () => (v / size).clamp(0.8, 3.0)));
        setPanel(() {});
      }

      return PanelGroup(
        children: [
          PanelSliderRow(
            title: 'Line height',
            value: points.clamp(size * 0.8, size * 3),
            min: size * 0.8,
            max: size * 3,
            valueText: '${points.round()}',
            onChanged: to,
          ),
          PanelStepperRow(
            title: 'Line height',
            unit: '',
            value: points.roundToDouble(),
            min: (size * 0.8).ceilToDouble(),
            max: (size * 3).floorToDouble(),
            onChanged: to,
          ),
          PanelSwitchRow(
            title: 'Automatic',
            value: auto,
            onChanged: (on) {
              _set(f.copyWith(lineHeight: () => on ? null : 4 / 3));
              setPanel(() {});
            },
          ),
        ],
      );
    },
  );

  PanelPage _alignPage() => PanelPage(
    title: 'Alignment',
    width: 280,
    builder: (context, setPanel) {
      final f = _now;
      Widget option(TextAlign align, IconData icon, String tip) =>
          _chip(context, tip, Icon(icon), (_) {
            _set(f.copyWith(align: align));
            setPanel(() {});
          }, selected: f.align == align);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              option(TextAlign.left, Icons.format_align_left, 'Left'),
              option(TextAlign.center, Icons.format_align_center, 'Center'),
              option(TextAlign.right, Icons.format_align_right, 'Right'),
            ],
          ),
          const SizedBox(height: 10),
          PanelGroup(
            children: [
              PanelNavRow(
                icon: Icons.format_line_spacing,
                title: 'Line Height',
                trailing: f.lineHeight == null ? 'Automatic' : null,
                onTap: () => ToolPanel.push(context, _lineHeightPage()),
              ),
            ],
          ),
        ],
      );
    },
  );

  PanelPage _listPage() => PanelPage(
    title: 'List',
    width: 240,
    builder: (context, setPanel) {
      final f = _now;
      Widget option(TextList list, IconData icon, String tip) =>
          _chip(context, tip, Icon(icon), (_) {
            _set(f.copyWith(list: f.list == list ? TextList.none : list));
            setPanel(() {});
          }, selected: f.list == list);
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          option(TextList.bullets, Icons.format_list_bulleted, 'Bullets'),
          option(TextList.numbers, Icons.format_list_numbered, 'Numbers'),
        ],
      );
    },
  );

  PanelPage _boxPage() {
    var tab = 0;
    return PanelPage(
      title: 'Text Box Style',
      width: 320,
      builder: (context, setPanel) {
        final f = _now;
        final ui = EditorUi.of(context);
        void apply(StickyNoteResult next) {
          _set(next);
          setPanel(() {});
        }

        Widget swatch(({Color? fill, Color? border}) preset) {
          final chosen = f.boxFill == preset.fill &&
              (f.boxBorder == preset.border || preset.border == null);
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => apply(
              f.copyWith(
                boxFill: () => preset.fill,
                boxBorder: () => preset.border ?? f.boxBorder,
                boxBorderWidth: preset.border != null && f.boxBorderWidth == 0
                    ? 1
                    : null,
                // light text on a dark background
                textColor: preset.fill != null &&
                        preset.fill!.computeLuminance() < 0.25 &&
                        (f.textColor == null || f.textColor == _ink)
                    ? () => Colors.white
                    : null,
              ),
            ),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: preset.fill ?? Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: chosen ? EditorUi.accent : ui.cardDivider,
                  width: chosen ? 2.5 : 1,
                ),
              ),
              child: preset.fill == null
                  ? CustomPaint(painter: _SlashPainter(ui.iconDim))
                  : null,
            ),
          );
        }

        // anchored at the row tapped, not the whole panel: a panel-sized
        // anchor left no room on screen, so the colours opened half cut off
        Future<void> pickColor(
          BuildContext row,
          String title,
          Color? now,
          bool fill,
        ) => ColorPanel.show(
              row,
              anchor: rectOf(row),
              freezeEditor: freezeEditor,
              keepFocus: _keepFocus,
              title: title,
              color: now ?? Colors.white,
              onChanged: (c) => apply(
                fill
                    ? _now.copyWith(boxFill: () => c)
                    : _now.copyWith(
                        boxBorder: () => c,
                        boxBorderWidth: _now.boxBorderWidth == 0 ? 1 : null,
                      ),
              ),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PanelSegmented(
              labels: const ['Presets', 'Advanced'],
              index: tab,
              onChanged: (i) => setPanel(() => tab = i),
            ),
            const SizedBox(height: 12),
            if (tab == 0)
              Wrap(
                alignment: WrapAlignment.center,
                children: [for (final preset in _boxPresets) swatch(preset)],
              )
            else
              PanelGroup(
                children: [
                  Builder(
                    builder: (row) => PanelNavRow(
                      title: 'Background Color',
                      onTap: () =>
                          pickColor(row, 'Background Color', f.boxFill, true),
                    ),
                  ),
                  Builder(
                    builder: (row) => PanelNavRow(
                      title: 'Border Color',
                      onTap: () =>
                          pickColor(row, 'Border Color', f.boxBorder, false),
                    ),
                  ),
                  PanelStepperRow(
                    title: 'Round Corner',
                    value: f.boxRadius,
                    max: 40,
                    onChanged: (v) => apply(f.copyWith(boxRadius: v)),
                  ),
                  PanelSwitchRow(
                    title: 'Shadow',
                    value: f.boxShadow,
                    onChanged: (v) => apply(f.copyWith(boxShadow: v)),
                  ),
                  PanelStepperRow(
                    title: 'Border',
                    value: f.boxBorderWidth,
                    max: 12,
                    onChanged: (v) => apply(
                      f.copyWith(
                        boxBorderWidth: v,
                        boxBorder: f.boxBorder == null
                            ? () => const Color(0xFF202124)
                            : null,
                      ),
                    ),
                  ),
                  PanelStepperRow(
                    title: 'Padding',
                    value: f.boxPadding ?? textBoxPadding,
                    max: 40,
                    onChanged: (v) => apply(f.copyWith(boxPadding: () => v)),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  static IconData _alignIcon(TextAlign align) => switch (align) {
    TextAlign.center => Icons.format_align_center,
    TextAlign.right => Icons.format_align_right,
    _ => Icons.format_align_left,
  };

  @override
  Widget build(BuildContext context) {
    final f = format;
    Future<void> open(BuildContext chip, PanelPage page) async {
      _live = format;
      await _panel(chip, page);
      _live = null;
    }

    return Flex(
      direction: axis,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...leading,
        Builder(
          builder: (dot) => ColorDot(
            color: f.textColor ?? _ink,
            selected: true,
            showChevron: true,
            onTap: () async {
              await ColorPanel.show(
                dot,
                anchor: rectOf(dot),
                freezeEditor: freezeEditor,
                keepFocus: _keepFocus,
                title: 'Text Color',
                color: f.textColor ?? _ink,
                presets: textColorPresets,
                onChanged: (c) => _set((_live ?? format).copyWith(textColor: () => c)),
              );
              afterPanel?.call();
            },
          ),
        ),
        _chip(
          context,
          'Size',
          _label(context, '${(f.fontSize ?? 36).round()}'),
          (chip) => open(chip, _sizePage()),
        ),
        _chip(
          context,
          'Font',
          _label(context, textFontName(f.font), font: f.font),
          (chip) => open(chip, _fontPage()),
        ),
        _chip(
          context,
          'Bold, italic, underline',
          const Icon(Icons.format_bold),
          (chip) => open(chip, _stylePage()),
          selected: f.bold || f.italic || f.underline || f.strike,
        ),
        _chip(
          context,
          'Alignment and line height',
          Icon(_alignIcon(f.align)),
          (chip) => open(chip, _alignPage()),
        ),
        _chip(
          context,
          'List',
          Icon(
            f.list == TextList.numbers
                ? Icons.format_list_numbered
                : Icons.format_list_bulleted,
          ),
          (chip) => open(chip, _listPage()),
          selected: f.list != TextList.none,
        ),
        _chip(
          context,
          'Text box style',
          const Icon(Icons.format_color_fill),
          (chip) => open(chip, _boxPage()),
          selected: f.boxFill != null || f.boxBorderWidth > 0 || f.boxShadow,
        ),
        ...trailing,
      ],
    );
  }
}

/// A diagonal line: "no background".
class _SlashPainter extends CustomPainter {
  _SlashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawLine(
    Offset(size.width * 0.2, size.height * 0.8),
    Offset(size.width * 0.8, size.height * 0.2),
    Paint()
      ..color = color
      ..strokeWidth = 1.5,
  );

  @override
  bool shouldRepaint(_SlashPainter old) => old.color != color;
}
