import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:sbn/font_fallbacks.dart';

typedef _StyleKey = ({bool invert, Color secondary, int lineHeight});

/// Text styles for the typed-text layer of a page.
///
/// Every size is a fraction of the page's ruled [lineHeight] so typed text
/// sits on the paper's lines, and no block adds extra padding that would push
/// text off them.
abstract class BadNotesQuillStyles {
  /// The most recent inputs and the styles built from them. Pages usually ask
  /// with the same inputs again and again, so only one entry is kept.
  static (_StyleKey, DefaultStyles)? _cache;

  /// Styles for text drawn in black, or white when [invert] is true, with
  /// links in [secondary]. Repeated calls with the same inputs return the
  /// same object.
  static DefaultStyles get({
    required bool invert,
    required Color secondary,
    required int lineHeight,
  }) {
    final _StyleKey key = (
      invert: invert,
      secondary: secondary,
      lineHeight: lineHeight,
    );
    final cached = _cache;
    if (cached != null && cached.$1 == key) return cached.$2;

    final styles = _build(key);
    _cache = (key, styles);
    return styles;
  }

  static DefaultTextBlockStyle _block(
    TextStyle style, {
    VerticalSpacing verticalSpacing = VerticalSpacing.zero,
    BoxDecoration? decoration,
  }) => DefaultTextBlockStyle(
    style,
    HorizontalSpacing.zero,
    verticalSpacing,
    VerticalSpacing.zero,
    decoration,
  );

  static TextStyle _mono(TextStyle style) => style.copyWith(
    fontFamily: 'FiraMono',
    fontFamilyFallback: badnotesMonoFontFallbacks,
  );

  static DefaultStyles _build(_StyleKey key) {
    final lineHeight = key.lineHeight;
    final ink = key.invert ? Colors.white : Colors.black;

    final base = TextStyle(
      inherit: false,
      fontFamily: 'Neucha',
      fontFamilyFallback: badnotesHandwritingFontFallbacks,
      color: ink,
      fontSize: lineHeight.toDouble(),
      height: 1.0,
      decoration: TextDecoration.none,
    );

    // A heading: [scale] lines tall, underlined with a faded copy of the ink.
    TextStyle heading(double scale, double underlineAlpha) => base.copyWith(
      fontSize: lineHeight * scale,
      height: 1 / scale,
      decoration: TextDecoration.underline,
      decorationColor: ink.withValues(alpha: underlineAlpha),
      decorationThickness: 3,
    );

    final body = base.copyWith(fontSize: lineHeight * 0.7, height: 1 / 0.7);
    final heading1 = heading(1.15, 0.6);
    final heading2 = heading(1, 0.5);
    final heading3 = heading(0.9, 0.4);

    final faded = body.color!.withValues(alpha: 0.6);
    final codeBackground = Colors.grey.withValues(alpha: 0.2);
    final plainLine = _block(base);
    final sameSizeAsBody = TextStyle(
      fontSize: body.fontSize!,
      height: body.height!,
    );

    return DefaultStyles(
      h1: _block(heading1),
      h2: _block(heading2),
      h3: _block(heading3),
      h4: _block(heading3),
      h5: _block(heading3),
      h6: _block(heading3),
      lineHeightNormal: plainLine,
      lineHeightTight: plainLine,
      lineHeightOneAndHalf: plainLine,
      lineHeightDouble: plainLine,
      paragraph: _block(body),
      small: TextStyle(fontSize: lineHeight * 0.4, height: 1 / 0.4),
      inlineCode: InlineCodeStyle(
        backgroundColor: codeBackground,
        radius: const .circular(3),
        style: _mono(body),
        header1: _mono(heading1),
        header2: _mono(heading2),
        header3: _mono(heading3),
      ),
      link: TextStyle(
        color: key.secondary,
        decoration: TextDecoration.underline,
      ),
      placeHolder: _block(
        body.copyWith(color: Colors.grey.withValues(alpha: 0.6)),
      ),
      lists: DefaultListBlockStyle(
        body,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
        null,
      ),
      quote: _block(
        TextStyle(color: faded),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: faded, width: 4)),
        ),
      ),
      code: _block(
        _mono(body),
        verticalSpacing: VerticalSpacing(-lineHeight * 0.16, lineHeight * 0.8),
        decoration: BoxDecoration(
          color: codeBackground,
          borderRadius: const .all(.circular(3)),
        ),
      ),
      indent: _block(body),
      align: _block(body),
      leading: _block(body),
      sizeSmall: sameSizeAsBody,
      sizeLarge: sameSizeAsBody,
      sizeHuge: sameSizeAsBody,
    );
  }
}
