import 'dart:math';

import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Everything on [page]: its ink and pictures, or null if it's empty.
Rect? boardContent(EditorPage page) {
  Rect? r;
  for (final stroke in page.strokes) {
    final b = stroke.bounds;
    if (b.isFinite) r = r == null ? b : r.expandToInclude(b);
  }
  for (final image in page.images) {
    r = r == null ? image.dstRect : r.expandToInclude(image.dstRect);
  }
  return r;
}

/// A small map of the whiteboard in the corner: everything on it, and a box
/// for what's on screen. Tapping or dragging on it goes there; the zoom
/// shows above it (tap for 50, 100 or 200%), with Fit to show everything.
/// Folds to a round button, and fades only while the pen writes near it.
class BoardMap extends StatefulWidget {
  const BoardMap({
    super.key,
    required this.page,
    required this.repositioned,
    required this.visible,
    required this.zoom,
    required this.centerOn,
    required this.zoomTo,
    required this.fit,
    required this.writingAt,
  });

  final EditorPage page;

  /// Fires when the board moves or zooms.
  final Listenable repositioned;

  /// The part of the board on screen, in its own units.
  final Rect? Function() visible;

  /// The zoom: 1 is 100%, as the board opened.
  final double Function() zoom;
  final ValueChanged<Offset> centerOn;
  final ValueChanged<double> zoomTo;
  final VoidCallback fit;

  /// Where the pen is writing on the screen, or null.
  final ValueListenable<Offset?> writingAt;

  /// Folded, until it's opened again (while the app is open).
  static var folded = false;

  @override
  State<BoardMap> createState() => _BoardMapState();
}

class _BoardMapState extends State<BoardMap> {
  static const _width = 180.0, _height = 112.0;

  /// Whether the pen is writing near the map: it fades out of the way.
  var _near = false;

  @override
  void initState() {
    super.initState();
    widget.writingAt.addListener(_pen);
  }

  @override
  void dispose() {
    widget.writingAt.removeListener(_pen);
    super.dispose();
  }

  void _pen() {
    final at = widget.writingAt.value;
    final box = context.findRenderObject() as RenderBox?;
    final near =
        at != null &&
        box != null &&
        box.hasSize &&
        (box.localToGlobal(Offset.zero) & box.size).inflate(48).contains(at);
    // a stroke just finished: drawn on the map too (not on every move,
    // which would draw the whole map again as the pen moves)
    if (near != _near || at == null) setState(() => _near = near);
  }

  /// The part of the board the map shows: everything on it and the screen,
  /// with room around so the screen's box is a window into more. Kept while dragging, so the map doesn't move under the
  /// finger.
  Rect? _frame;

  Rect _shown() {
    final content = boardContent(widget.page);
    final visible = widget.visible();
    var r = content ?? visible ?? Offset.zero & widget.page.size;
    if (visible != null) {
      r = r.expandToInclude(visible).inflate(visible.longestSide * 0.6);
    }
    // as wide as the map, around the middle
    final aspect = _width / _height;
    final w = max(r.width, r.height * aspect), h = w / aspect;
    return Rect.fromCenter(center: r.center, width: w * 1.1, height: h * 1.1);
  }

  void _goTo(Offset local) {
    final frame = _frame ?? _shown();
    widget.centerOn(
      frame.topLeft + Offset(local.dx, local.dy) * (frame.width / _width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    if (BoardMap.folded) {
      return Material(
        color: colors.surface,
        elevation: 4,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: 'Show map',
          icon: const Icon(Icons.map_outlined),
          onPressed: () => setState(() => BoardMap.folded = false),
        ),
      );
    }
    return IgnorePointer(
      ignoring: _near,
      child: AnimatedOpacity(
        opacity: _near ? 0.15 : 1,
        duration: BnMotion.fast,
        curve: BnMotion.curve,
        child: Material(
        color: colors.surface,
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: _width,
          child: ListenableBuilder(
            listenable: widget.repositioned,
            builder: (context, _) {
              final frame = _frame ?? _shown();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        _small(
                          'Hide map',
                          Icons.close_fullscreen,
                          () => setState(() => BoardMap.folded = true),
                        ),
                        Expanded(
                          child: Builder(
                            builder: (context) => TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                foregroundColor: colors.text,
                              ),
                              onPressed: () => showAppleMenu(
                                context,
                                anchor: rectOf(context),
                                entries: [
                                  for (final percent in const [50, 100, 200])
                                    AppleMenuItem(
                                      '$percent%',
                                      onTap: () =>
                                          widget.zoomTo(percent / 100),
                                    ),
                                ],
                              ),
                              child: Text(
                                '${(widget.zoom() * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _small('Show everything', Icons.fit_screen, widget.fit),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTapUp: (d) => _goTo(d.localPosition),
                    onPanStart: (d) {
                      setState(() => _frame = _shown());
                      _goTo(d.localPosition);
                    },
                    onPanUpdate: (d) => _goTo(d.localPosition),
                    onPanEnd: (_) => setState(() => _frame = null),
                    child: CustomPaint(
                      size: const Size(_width, _height),
                      painter: _MapPainter(
                        page: widget.page,
                        frame: frame,
                        visible: widget.visible(),
                        ink: colors.text,
                        paper: colors.sunkenSoft,
                        box: colors.accentStrong,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      ),
    );
  }

  Widget _small(String tooltip, IconData icon, VoidCallback onTap) =>
      IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        iconSize: 16,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        icon: Icon(icon),
      );
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.page,
    required this.frame,
    required this.visible,
    required this.ink,
    required this.paper,
    required this.box,
  });

  final EditorPage page;
  final Rect frame;
  final Rect? visible;
  final Color ink, paper, box;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    final k = size.width / frame.width;
    Offset map(Offset p) => (p - frame.topLeft) * k;
    final pictures = Paint()..color = ink.withValues(alpha: 0.18);
    for (final image in page.images) {
      final r = image.dstRect;
      canvas.drawRect(Rect.fromPoints(map(r.topLeft), map(r.bottomRight)), pictures);
    }
    // ponytail: every stroke's points, thinned to 12; draw a cached picture
    // if boards get thousands of strokes
    final line = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final stroke in page.strokes) {
      final points = stroke.centerPoints;
      if (points.isEmpty) continue;
      line.color = stroke.color.withValues(alpha: 1);
      final step = max(1, points.length ~/ 12);
      final path = Path()..moveTo(map(points.first).dx, map(points.first).dy);
      for (int i = step; i < points.length; i += step) {
        final p = map(points[i]);
        path.lineTo(p.dx, p.dy);
      }
      final last = map(points.last);
      path.lineTo(last.dx + 0.5, last.dy);
      canvas.drawPath(path, line);
    }
    if (visible case final v?) {
      final r = Rect.fromPoints(map(v.topLeft), map(v.bottomRight));
      canvas
        ..drawRect(r, Paint()..color = box.withValues(alpha: 0.12))
        ..drawRect(
          r,
          Paint()
            ..color = box
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => true;
}
