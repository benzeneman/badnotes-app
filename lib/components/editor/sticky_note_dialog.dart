import 'dart:convert';
import 'dart:math';

import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:badnotes/components/editor/sticky_note_paper.dart';
import 'package:badnotes/components/editor/text_box_overlay.dart';

/// A text box or sticky note: what its SVG image is made from.
class StickyNoteResult {
  const StickyNoteResult(
    this.text,
    this.color, {
    this.style = StickyNoteStyle.curl,
    this.font,
    this.fontSize,
    this.maxWidth,
    this.textColor,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.align = TextAlign.left,
    this.list = TextList.none,
    this.lineHeight,
    this.collapsed = false,
    this.boxFill,
    this.boxBorder,
    this.boxRadius = 0,
    this.boxBorderWidth = 0,
    this.boxPadding,
    this.boxShadow = false,
  });
  final String text;

  /// A sticky note folded down to a small square, opened again with a tap.
  final bool collapsed;

  /// The text's own color, or null for the usual dark ink.
  final Color? textColor;
  final bool bold, italic, underline, strike;

  /// Left, center or right.
  final TextAlign align;

  /// Bullets or numbers in front of each paragraph.
  final TextList list;

  /// Space from one line to the next, in units of the text's size, or null
  /// for the usual 4/3.
  final double? lineHeight;
  final StickyNoteStyle style;

  /// null = plain text box (transparent background).
  final Color? color;

  /// Set on text boxes typed on the page. Without them a text box is laid out
  /// the way it always was, so older ones don't change.
  final String? font;
  final double? fontSize;
  final double? maxWidth;

  /// A text box's own background and border, see the Text Box Style panel.
  final Color? boxFill, boxBorder;
  final double boxRadius, boxBorderWidth;

  /// Space inside a text box's edge, or null for the usual [textBoxPadding].
  final double? boxPadding;
  final bool boxShadow;

  StickyNoteResult copyWith({
    String? text,
    Color? Function()? color,
    StickyNoteStyle? style,
    String? font,
    double? fontSize,
    double? maxWidth,
    Color? Function()? textColor,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    TextAlign? align,
    TextList? list,
    double? Function()? lineHeight,
    bool? collapsed,
    Color? Function()? boxFill,
    Color? Function()? boxBorder,
    double? boxRadius,
    double? boxBorderWidth,
    double? Function()? boxPadding,
    bool? boxShadow,
  }) => StickyNoteResult(
    text ?? this.text,
    color == null ? this.color : color(),
    style: style ?? this.style,
    font: font ?? this.font,
    fontSize: fontSize ?? this.fontSize,
    maxWidth: maxWidth ?? this.maxWidth,
    textColor: textColor == null ? this.textColor : textColor(),
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    strike: strike ?? this.strike,
    align: align ?? this.align,
    list: list ?? this.list,
    lineHeight: lineHeight == null ? this.lineHeight : lineHeight(),
    collapsed: collapsed ?? this.collapsed,
    boxFill: boxFill == null ? this.boxFill : boxFill(),
    boxBorder: boxBorder == null ? this.boxBorder : boxBorder(),
    boxRadius: boxRadius ?? this.boxRadius,
    boxBorderWidth: boxBorderWidth ?? this.boxBorderWidth,
    boxPadding: boxPadding == null ? this.boxPadding : boxPadding(),
    boxShadow: boxShadow ?? this.boxShadow,
  );

  /// This note, [collapsed] or not.
  StickyNoteResult withCollapsed(bool collapsed) =>
      copyWith(collapsed: collapsed);

  bool get _isTypedOnPage => color == null && fontSize != null;
  double get _fontSize => _isTypedOnPage ? fontSize! : _noteFontSize;
  double get _lineHeight => _isTypedOnPage && lineHeight != null
      ? _fontSize * lineHeight!
      : _fontSize * _noteLineHeight / _noteFontSize;
  double get _padding => _isTypedOnPage
      ? (boxPadding ?? textBoxPadding) + boxBorderWidth
      : _notePadding;
  double get _wrapWidth => _isTypedOnPage
      ? max((maxWidth ?? _noteSide) - 2 * _padding, _fontSize)
      : _noteSide - _notePadding * 2;
  TextStyle get _textStyle => TextStyle(
    fontSize: _fontSize,
    fontFamily: font,
    fontWeight: bold ? FontWeight.bold : null,
    fontStyle: italic ? FontStyle.italic : null,
  );

  /// [text] with the [list]'s bullets or numbers in front.
  String get shownText {
    if (list == TextList.none) return text;
    var n = 0;
    return [
      for (final paragraph in text.split('\n'))
        if (paragraph.trim().isEmpty)
          paragraph
        else
          '${list == TextList.bullets ? '•' : '${++n}.'} $paragraph',
    ].join('\n');
  }

  /// Where a sticky note's text starts and how it's set, in the note's own
  /// units, for typing over it: the left edge, the top of the first line's
  /// baseline less its size, the width it wraps at, the size and the
  /// distance from line to line.
  ({double left, double top, double width, TextStyle style, double line})
  get textArea => (
    left: _padding,
    top: color != null ? style.textTop : _padding,
    width: _wrapWidth,
    style: _textStyle,
    line: _lineHeight,
  );

  bool get _hasBox =>
      _isTypedOnPage &&
      (boxFill != null || (boxBorder != null && boxBorderWidth > 0) || boxShadow);
}

/// Bullets or numbers in front of each paragraph of a text box.
enum TextList { none, bullets, numbers }

String xmlEscape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

const stickyNoteColors = <Color>[
  Color(0xFFFFF176), // lemon
  Color(0xFFFFCC80), // peach
  Color(0xFFFFAB91), // coral
  Color(0xFFF48FB1), // pink
  Color(0xFFCE93D8), // lilac
  Color(0xFF9FA8DA), // periwinkle
  Color(0xFF81D4FA), // sky
  Color(0xFF80CBC4), // teal
  Color(0xFFA5D6A7), // leaf
  Color(0xFFE6EE9C), // lime
];

const _noteSide = 260.0;
const _notePadding = 16.0;
const _noteFontSize = 18.0;
const _noteLineHeight = 24.0;
const _inkColor = Color(0xFF202124);

/// Which sticky note to put on the page: tap a color to see every design in
/// it, tap a design to add it.
Future<StickyNoteResult?> showStickyNotePicker(BuildContext context) {
  return showAppleDialog<StickyNoteResult>(
    context: context,
    builder: (context) => const _StickyNotePicker(),
  );
}

class _StickyNotePicker extends StatefulWidget {
  const _StickyNotePicker();

  /// Remembered while the app is open.
  static var lastColor = stickyNoteColors.first;

  @override
  State<_StickyNotePicker> createState() => _StickyNotePickerState();
}

class _StickyNotePickerState extends State<_StickyNotePicker> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final color = _StickyNotePicker.lastColor;
    return AlertDialog(
      title: const Text('Sticky note'),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in stickyNoteColors)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () =>
                          setState(() => _StickyNotePicker.lastColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c == color
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: c == color ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final style in StickyNoteStyle.values)
                    InkWell(
                      onTap: () => Navigator.pop(
                        context,
                        StickyNoteResult('', color, style: style),
                      ),
                      child: SvgPicture.string(
                        stickyNoteToSvg(
                          StickyNoteResult('', color, style: style),
                        ),
                        width: 84,
                        height: 84,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Splits [text] the way it wraps in [maxWidth].
List<String> _wrapLines(String text, double maxWidth, TextStyle style) {
  if (text.isEmpty) return const [];
  final lines = <String>[];
  for (final paragraph in text.split('\n')) {
    final painter = TextPainter(
      text: TextSpan(
        text: paragraph,
        style: style,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    var start = 0;
    while (start < paragraph.length) {
      final end = painter.getLineBoundary(TextPosition(offset: start)).end;
      if (end <= start) break;
      lines.add(paragraph.substring(start, end).trimRight());
      start = end;
    }
    if (paragraph.isEmpty) lines.add('');
    painter.dispose();
  }
  return lines;
}

/// How big a [StickyNoteResult.collapsed] note is.
const collapsedNoteSide = 56.0;

/// The size of [note]'s SVG: a square note, longer if its text needs that.
Size stickyNoteSize(StickyNoteResult note) {
  if (note.collapsed && note.color != null) {
    return const Size.square(collapsedNoteSide);
  }
  final lines = _wrapLines(note.shownText, note._wrapWidth, note._textStyle);
  if (note._isTypedOnPage) {
    final painter = TextPainter(
      text: TextSpan(text: note.shownText, style: note._textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: note._wrapWidth);
    final width = painter.width;
    painter.dispose();
    final shadow = note.boxShadow ? 3.0 : 0.0;
    return Size(
      width + 2 * note._padding + 2 + shadow,
      lines.length * note._lineHeight +
          2 * note._padding +
          note._fontSize * 0.3 +
          shadow,
    );
  }
  final textHeight = lines.length * _noteLineHeight + _notePadding * 2;
  if (note.color != null) {
    return Size(
      _noteSide,
      max(
        _noteSide,
        note.style.textTop +
            lines.length * _noteLineHeight +
            note.style.textBottom +
            8,
      ),
    );
  }
  final longest = lines.fold(0, (m, l) => l.length > m ? l.length : m);
  return Size(
    (longest * _noteFontSize * 0.55 + _notePadding * 2).clamp(120.0, _noteSide),
    textHeight,
  );
}

/// Reads back what [stickyNoteToSvg] made, or null if [svg] isn't one.
StickyNoteResult? stickyNoteFromSvg(String svg) {
  final match = RegExp('<!--badnotes-note:([A-Za-z0-9_=-]+)-->').firstMatch(svg);
  if (match != null) {
    final json = jsonDecode(utf8.decode(base64Url.decode(match.group(1)!)));
    final color = json['color'] as int?;
    return StickyNoteResult(
      json['text'] as String,
      color == null ? null : Color(color),
      style: StickyNoteStyle.values.firstWhere(
        (style) => style.name == json['style'],
        orElse: () => StickyNoteStyle.curl,
      ),
      font: json['font'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      maxWidth: (json['maxWidth'] as num?)?.toDouble(),
      textColor: switch (json['textColor']) {
        final int c => Color(c),
        _ => null,
      },
      bold: json['bold'] == true,
      italic: json['italic'] == true,
      collapsed: json['collapsed'] == true,
      underline: json['underline'] == true,
      strike: json['strike'] == true,
      list: TextList.values.firstWhere(
        (list) => list.name == json['list'],
        orElse: () => TextList.none,
      ),
      lineHeight: (json['lineHeight'] as num?)?.toDouble(),
      boxFill: switch (json['boxFill']) {
        final int c => Color(c),
        _ => null,
      },
      boxBorder: switch (json['boxBorder']) {
        final int c => Color(c),
        _ => null,
      },
      boxRadius: (json['boxRadius'] as num?)?.toDouble() ?? 0,
      boxBorderWidth: (json['boxBorderWidth'] as num?)?.toDouble() ?? 0,
      boxPadding: (json['boxPadding'] as num?)?.toDouble(),
      boxShadow: json['boxShadow'] == true,
      align: switch (json['align']) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        _ => TextAlign.left,
      },
    );
  }
  // notes from before the color was saved with the text
  final old = RegExp('<!--badnotes-text:(.*?)-->', dotAll: true).firstMatch(svg);
  if (old == null) return null;
  final fill = RegExp('fill="#([0-9a-f]{6})"')
      .allMatches(svg)
      .map((m) => m.group(1)!)
      .where((hex) => hex != '000000' && hex != '202124')
      .firstOrNull;
  return StickyNoteResult(
    old
        .group(1)!
        .replaceAll('&#45;', '-')
        .replaceAll('&quot;', '"')
        .replaceAll('&gt;', '>')
        .replaceAll('&lt;', '<')
        .replaceAll('&amp;', '&'),
    fill == null ? null : Color(0xFF000000 | int.parse(fill, radix: 16)),
  );
}

/// Renders [note] as a self-contained SVG so it behaves like any other
/// image on the page (move, resize, delete with the lasso). Without
/// [withText], only the paper, as big as the text needs: typed over on the
/// page, see [NoteTextOverlay].
String stickyNoteToSvg(StickyNoteResult note, {bool withText = true}) {
  final isNote = note.color != null;
  final size = stickyNoteSize(note);
  final width = size.width, height = size.height;
  final lines = _wrapLines(note.shownText, note._wrapWidth, note._textStyle);
  String hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  final top = note._fontSize + (isNote ? note.style.textTop : note._padding);
  final paper = !isNote
      ? ''
      : stickyNotePaper(
          note.style,
          hex(note.color!),
          width,
          height,
          textStart: top,
          lineHeight: note._lineHeight,
        );
  final (x, anchor) = switch (note.align) {
    TextAlign.center => (width / 2, 'middle'),
    TextAlign.right => (width - note._padding, 'end'),
    _ => (note._padding, 'start'),
  };
  final tspans = [
    for (var i = 0; i < lines.length; i++)
      '<tspan x="$x" y="${top + i * note._lineHeight}">'
          '${xmlEscape(lines[i])}</tspan>',
  ].join();
  final text = lines.isEmpty || !withText
      ? ''
      : '<text font-family="${note.font ?? 'sans-serif'}" '
            'font-size="${note._fontSize}" '
            '${note.bold ? 'font-weight="bold" ' : ''}'
            '${note.italic ? 'font-style="italic" ' : ''}'
            '${note.underline || note.strike ? 'text-decoration="${[if (note.underline) 'underline', if (note.strike) 'line-through'].join(' ')}" ' : ''}'
            '${anchor == 'start' ? '' : 'text-anchor="$anchor" '}'
            'fill="${hex(note.textColor ?? _inkColor)}">$tspans</text>';
  final meta = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'text': note.text,
        'color': note.color?.toARGB32(),
        'style': note.style.name,
        if (note.font != null) 'font': note.font,
        if (note.fontSize != null) 'fontSize': note.fontSize,
        if (note.maxWidth != null) 'maxWidth': note.maxWidth,
        if (note.textColor != null) 'textColor': note.textColor!.toARGB32(),
        if (note.bold) 'bold': true,
        if (note.italic) 'italic': true,
        if (note.align != TextAlign.left) 'align': note.align.name,
        if (note.collapsed) 'collapsed': true,
        if (note.underline) 'underline': true,
        if (note.strike) 'strike': true,
        if (note.list != TextList.none) 'list': note.list.name,
        if (note.lineHeight != null) 'lineHeight': note.lineHeight,
        if (note.boxFill != null) 'boxFill': note.boxFill!.toARGB32(),
        if (note.boxBorder != null) 'boxBorder': note.boxBorder!.toARGB32(),
        if (note.boxRadius != 0) 'boxRadius': note.boxRadius,
        if (note.boxBorderWidth != 0) 'boxBorderWidth': note.boxBorderWidth,
        if (note.boxPadding != null) 'boxPadding': note.boxPadding,
        if (note.boxShadow) 'boxShadow': true,
      }),
    ),
  );

  if (note.collapsed && isNote) {
    // a small folded square, with lines for the writing inside
    const side = collapsedNoteSide;
    final ink = hex(note.color!);
    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="$side" height="$side" viewBox="0 0 $side $side">'
        '<!--badnotes-note:$meta-->'
        '<path d="M4 4H52V40L40 52H4Z" fill="$ink"/>'
        '<path d="M40 52V40H52Z" fill="#000000" fill-opacity="0.18"/>'
        '<path d="M12 18H44M12 27H44M12 36H32" stroke="#202124" '
        'stroke-opacity="0.45" stroke-width="2.5" stroke-linecap="round"/>'
        '</svg>';
  }
  var box = '';
  if (note._hasBox) {
    final inset = note.boxBorderWidth / 2;
    final w = width - (note.boxShadow ? 3 : 0), h = height - (note.boxShadow ? 3 : 0);
    if (note.boxShadow) {
      box +=
          '<rect x="3" y="3" width="${w - inset * 2}" height="${h - inset * 2}" '
          'rx="${note.boxRadius}" fill="#000000" fill-opacity="0.16"/>';
    }
    box +=
        '<rect x="$inset" y="$inset" width="${w - inset * 2}" '
        'height="${h - inset * 2}" rx="${note.boxRadius}" '
        'fill="${note.boxFill == null ? 'none' : hex(note.boxFill!)}" '
        '${note.boxFill != null && note.boxFill!.a < 1 ? 'fill-opacity="${note.boxFill!.a}" ' : ''}'
        '${note.boxBorder != null && note.boxBorderWidth > 0 ? 'stroke="${hex(note.boxBorder!)}" stroke-width="${note.boxBorderWidth}" ' : ''}'
        '/>';
  }
  return '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="$width" height="$height" viewBox="0 0 $width $height">'
      '<!--badnotes-note:$meta-->$paper$box$text</svg>';
}
