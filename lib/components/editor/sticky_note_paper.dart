import 'dart:math';

/// The designs a sticky note can have. Only uses SVG features that flutter_svg
/// draws: paths, gradients and opacity, no filters or patterns.
enum StickyNoteStyle {
  curl(textTop: 34),
  pin(textTop: 46),
  spiral(textTop: 50, ruled: true),
  torn(textTop: 40, ruled: true, textBottom: 24),
  washi(textTop: 44),
  bubble(textTop: 26, textBottom: 58);

  const StickyNoteStyle({
    required this.textTop,
    this.textBottom = 16,
    this.ruled = false,
  });

  /// Where the text area starts and how much is left below it.
  final double textTop, textBottom;

  /// Whether text sits on printed lines, [lineHeight] apart.
  final bool ruled;
}

const _defs =
    '<defs>'
    '<linearGradient id="sheen" x1="0" y1="0" x2="1" y2="1">'
    '<stop offset="0" stop-color="#ffffff" stop-opacity="0.45"/>'
    '<stop offset="0.55" stop-color="#ffffff" stop-opacity="0"/>'
    '<stop offset="1" stop-color="#000000" stop-opacity="0.1"/>'
    '</linearGradient>'
    '<linearGradient id="curl" x1="0" y1="0" x2="1" y2="1">'
    '<stop offset="0" stop-color="#ffffff" stop-opacity="0.75"/>'
    '<stop offset="1" stop-color="#000000" stop-opacity="0.18"/>'
    '</linearGradient>'
    '<radialGradient id="pin" cx="0.35" cy="0.3" r="0.8">'
    '<stop offset="0" stop-color="#ff8a80"/>'
    '<stop offset="0.6" stop-color="#e53935"/>'
    '<stop offset="1" stop-color="#8e1c1a"/>'
    '</radialGradient>'
    '<linearGradient id="ring" x1="0" y1="0" x2="1" y2="0">'
    '<stop offset="0" stop-color="#6d7178"/>'
    '<stop offset="0.5" stop-color="#eceff1"/>'
    '<stop offset="1" stop-color="#6d7178"/>'
    '</linearGradient>'
    '</defs>';

String _n(double value) => value.toStringAsFixed(1);

/// A sheet in [color], its shadow and its shine, all following [path].
String _sheet(String path, String color) =>
    '<path d="$path" fill="#000000" fill-opacity="0.08" '
    'transform="translate(4 5)"/>'
    '<path d="$path" fill="#000000" fill-opacity="0.1" '
    'transform="translate(2 3)"/>'
    '<path d="$path" fill="$color"/>'
    '<path d="$path" fill="url(#sheen)"/>';

String _rules(double top, double right, double bottom, double lineHeight) {
  final out = StringBuffer();
  for (var y = top; y < bottom; y += lineHeight) {
    out.write(
      '<path d="M16 ${_n(y)}H${_n(right - 12)}" stroke="#000000" '
      'stroke-opacity="0.13" stroke-width="1"/>',
    );
  }
  return out.toString();
}

/// Everything of a note but its text.
String stickyNotePaper(
  StickyNoteStyle style,
  String color,
  double width,
  double height, {
  required double textStart,
  required double lineHeight,
}) {
  final right = width - 7, bottom = height - 8;
  final lines = style.ruled
      ? _rules(textStart + 6, right, bottom - style.textBottom + 6, lineHeight)
      : '';
  final String art;
  switch (style) {
    case .curl:
      const fold = 34.0;
      final path =
          'M2 2H${_n(right)}V${_n(bottom - fold)}'
          'Q${_n(right - 2)} ${_n(bottom - 8)} ${_n(right - fold)} ${_n(bottom)}'
          'H2Z';
      art =
          _sheet(path, color) +
          '<rect x="2" y="2" width="${_n(right - 2)}" height="26" '
              'fill="#000000" fill-opacity="0.05"/>' +
          '<path d="M${_n(right)} ${_n(bottom - fold)}'
              'Q${_n(right - fold * 0.75)} ${_n(bottom - fold * 0.85)} '
              '${_n(right - fold)} ${_n(bottom)}'
              'Q${_n(right - fold * 0.15)} ${_n(bottom - fold * 0.35)} '
              '${_n(right)} ${_n(bottom - fold)}Z" fill="url(#curl)"/>' +
          '<rect x="${_n(width / 2 - 38)}" y="3" width="76" height="22" '
              'fill="#ffffff" fill-opacity="0.6" '
              'transform="rotate(-3 ${_n(width / 2)} 14)"/>';
    case .pin:
      final cx = width / 2;
      art =
          _sheet('M3 12H${_n(right)}V${_n(bottom)}H3Z', color) +
          '<path d="M${_n(cx - 1)} 28l-9 13 10-8Z" fill="#000000" '
              'fill-opacity="0.2"/>' +
          '<circle cx="${_n(cx)}" cy="17" r="12" fill="url(#pin)"/>' +
          '<circle cx="${_n(cx - 4)}" cy="13" r="3" fill="#ffffff" '
              'fill-opacity="0.75"/>';
    case .spiral:
      final holes = StringBuffer();
      final count = ((width - 28) / 24).floor();
      final gap = (width - 28) / count;
      for (var i = 0; i <= count; i++) {
        final x = 14 + i * gap;
        holes.write(
          '<circle cx="${_n(x)}" cy="26" r="4.5" fill="#000000" '
          'fill-opacity="0.35"/>'
          '<rect x="${_n(x - 2)}" y="3" width="4" height="23" rx="2" '
          'fill="url(#ring)"/>',
        );
      }
      art = _sheet('M3 13H${_n(right)}V${_n(bottom)}H3Z', color) + '$holes';
    case .torn:
      final edge = StringBuffer('M3 10H${_n(right)}V${_n(bottom - 8)}');
      final random = Random(7); // the same tear every time
      for (var x = right; x > 3; x -= 9) {
        edge.write(
          'L${_n(max(x - 4.5, 3))} ${_n(bottom - 8 + random.nextDouble() * 8)}'
          'L${_n(max(x - 9, 3))} ${_n(bottom - 8 - random.nextDouble() * 3)}',
        );
      }
      edge.write('Z');
      final perforations = StringBuffer();
      for (var x = 12.0; x < right; x += 12) {
        perforations.write(
          '<circle cx="${_n(x)}" cy="20" r="2.5" fill="#000000" '
          'fill-opacity="0.22"/>',
        );
      }
      art =
          _sheet(edge.toString(), color) +
          '<path d="M3 10H${_n(right)}V30H3Z" fill="#ffffff" '
              'fill-opacity="0.22"/>' +
          '$perforations';
    case .washi:
      String tape(double x, double y, double angle) {
        final stripes = StringBuffer();
        for (var i = 0; i < 8; i += 2) {
          stripes.write(
            '<rect x="${_n(x + i * 9)}" y="${_n(y)}" width="9" height="20" '
            'fill="#ffffff" fill-opacity="0.45"/>',
          );
        }
        return '<g transform="rotate(${_n(angle)} ${_n(x + 36)} ${_n(y + 10)})">'
            '<rect x="${_n(x)}" y="${_n(y)}" width="72" height="20" '
            'fill="#37474f" fill-opacity="0.45"/>$stripes</g>';
      }
      art =
          _sheet('M8 8H${_n(right - 4)}V${_n(bottom - 2)}H8Z', color) +
          tape(2, 16, -38) +
          tape(right - 66, 16, 38);
    case .bubble:
      final b = bottom - 30, r = 22.0;
      final path =
          'M${_n(2 + r)} 2H${_n(right - r)}Q${_n(right)} 2 ${_n(right)} ${_n(2 + r)}'
          'V${_n(b - r)}Q${_n(right)} ${_n(b)} ${_n(right - r)} ${_n(b)}'
          'H82L46 ${_n(bottom)}L54 ${_n(b)}H${_n(2 + r)}'
          'Q2 ${_n(b)} 2 ${_n(b - r)}V${_n(2 + r)}Q2 2 ${_n(2 + r)} 2Z';
      art = _sheet(path, color);
  }
  return '$_defs$art$lines';
}
