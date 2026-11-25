import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:badnotes/data/lag_recorder.dart';
import 'package:badnotes/components/canvas/_circle_stroke.dart';
import 'package:badnotes/components/canvas/_ink_cache.dart';
import 'package:badnotes/components/canvas/_rectangle_stroke.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/extensions/color_extensions.dart';
import 'package:badnotes/data/tools/eraser.dart';
import 'package:badnotes/data/tools/laser_pointer.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/select.dart';
import 'package:badnotes/data/tools/shape_pen.dart';

/// Paints one page's finished ink (from [inkCache]'s images where it can),
/// the laser pointer, the lasso selection and the page number. A page is
/// often painted by a few of these, one for each gap between the pictures
/// over the ink ([tier]).
class CanvasPainter extends CustomPainter {
  const new({
    super.repaint,
    required this.page,
    required this.pageIndex,
    required this.totalPages,
    required this.showPageIndicator,
    required this.strokes,
    required this.currentStroke,
    required this.laserStrokes,
    required this.currentSelection,
    required this.currentScale,
    required this.primaryColor,
    required this.defaultTextStyle,
    this.invert = false,
    this.paintCurrentStroke = true,
    this.onlyLayer,
    this.paintInk = true,
    this.paintOverlays = true,
    this.inkCache,
    this.pixelScale,
    this.onFrontImages,
    this.tier,
    this.frontImages = const [],
    this.topTier = true,
  });

  /// Only the writing in this gap between the [frontImages] (see
  /// [EditorPage.tierOf]); null for all. Takes the place of
  /// [onFrontImages].
  final int? tier;

  /// The pictures and text boxes over the writing, in the order put on.
  final List<EditorImage> frontImages;

  /// Whether this paints the top gap, which tapes go over.
  final bool topTier;

  /// Whether the stroke being written is part of what this paints; see
  /// [shouldRepaint].
  final bool paintCurrentStroke;

  /// Only the ink written on a picture or sticky note over the ink (true), or
  /// only the rest (false): the pictures go between the two. Null for all.
  final bool? onFrontImages;

  /// Keeps finished ink as images, see [InkCache]. Without it, or without
  /// [pixelScale], every stroke is drawn on every paint.
  final InkCache? inkCache;

  /// Screen pixels per unit of the page: the size to keep [inkCache]'s images.
  final double? pixelScale;

  /// Paints the ink of this layer only, for images to go between the layers.
  final int? onlyLayer;

  /// Whether to paint finished strokes.
  final bool paintInk;

  /// Whether to paint what goes above all ink, like the selection.
  final bool paintOverlays;

  bool _isShown(Stroke stroke) {
    if (!_isShownOnAnySide(stroke)) return false;
    if (tier case final tier?) {
      return page.tierOf(stroke, frontImages) == tier;
    }
    if (onFrontImages case final onFront?
        when page.isOnFrontImage(stroke) != onFront) {
      return false;
    }
    return true;
  }

  /// [_isShown], under the pictures or over them.
  bool _isShownOnAnySide(Stroke stroke) {
    if (!(page.replayShown?.contains(stroke) ?? true)) return false;
    if (!page.isLayerVisible(stroke.layer)) return false;
    final layer = onlyLayer;
    return layer == null || page.drawnOnLayer(stroke.layer) == layer;
  }

  /// Whether tapes are drawn here: over everything, so with pictures on the
  /// page, by the painter over the pictures.
  bool get _drawsTapes => tier != null ? topTier : onFrontImages != false;

  /// The page being painted, and where it is in the note.
  final EditorPage page;
  final int pageIndex;
  final int totalPages;

  /// Whether "page / pages" is written in the bottom corner.
  final bool showPageIndicator;

  /// The page's finished strokes.
  final List<Stroke> strokes;

  /// The stroke being written, if any.
  final Stroke? currentStroke;

  /// Laser pointer lines, still fading out.
  final List<LaserStroke> laserStrokes;

  /// What the lasso holds, drawn on top with its handles.
  final SelectResult? currentSelection;

  /// How far the page is zoomed: the lasso's lines and handles are drawn
  /// the same size on screen at any zoom.
  final double currentScale;

  /// The app's accent color, used for the lasso.
  final Color primaryColor;

  /// Font for the page number.
  final TextStyle defaultTextStyle;

  /// Whether the page is shown with inverted colors (dark pages).
  final bool invert;

  @override
  void paint(Canvas canvas, Size size) {
    if (paintInk) _paintInk(canvas, size);
    if (!paintOverlays) return;
    for (final stroke in laserStrokes) _drawLaserStroke(canvas, stroke);
    // the stroke being drawn lives in [CurrentStrokePainter] so finished
    // strokes aren't repainted on every pen move
    if (paintCurrentStroke) {
      _drawCurrentStroke(canvas, currentStroke);
    }
    _drawPageIndicator(canvas, size);
    _drawSearchHighlights(canvas, size);
  }

  void _drawSearchHighlights(Canvas canvas, Size size) {
    for (final rect in page.searchHighlights) {
      final wholePage = rect.width >= size.width && rect.height >= size.height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(1), const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFFFFC107)
              .withValues(alpha: wholePage ? 0.14 : 0.45),
      );
    }
  }

  /// Ink, then highlighters over it, see-through like a marker. From
  /// [InkCache]'s images when it can, otherwise stroke by stroke.
  ///
  /// Highlighters used to multiply onto the page. A multiply blend makes a
  /// phone's GPU copy the whole screen under it, every frame: a page with
  /// any highlighter on it drew in 17-30 ms a frame, too slow for a 90 Hz
  /// screen. Laid over the ink as they are, all of it is plain drawing.
  void _paintInk(Canvas canvas, Size size) =>
      LagRecorder.span('paint page ink', () {
        // tapes and what's written on them, from the writing under the
        // pictures and over them alike: the tape covers both
        final (tapes, onTape) = tapesOf(
          strokes.where(_isShownOnAnySide).toList(),
        );
        _paintPageInk(canvas, size, tapes: tapes, onTape: onTape);
        if (!_drawsTapes) return;
        // Tape goes over all that was there before it: ink, highlighter and
        // typed text (under all the ink) alike. It was drawn with the ink,
        // so highlighter, and ink drawn over highlighter, showed through.
        // What's written on it afterwards is on it; peeking under a tape
        // hides that, and shows what's under it.
        for (final tape in tapes) {
          _drawTapeStroke(canvas, tape);
          if (tape.tapeRevealed) continue;
          final on = onTape[tape]!;
          if (on.isEmpty) continue;
          final scale = _drawScale;
          _drawScale = pixelScale ?? 1000;
          _drawNonHighlighterStrokes(canvas, [
            for (final stroke in on)
              if (stroke.toolId != .highlighter) stroke,
          ]);
          _drawHighlighterStrokes(canvas, [
            for (final stroke in on)
              if (stroke.toolId == .highlighter) stroke,
          ]);
          _drawScale = scale;
        }
      });

  /// The tapes among [shown] strokes (in the order drawn), and for each the
  /// strokes written on it after it was put down.
  @visibleForTesting
  static (List<Stroke> tapes, Map<Stroke, List<Stroke>> onTape) tapesOf(
    List<Stroke> shown,
  ) {
    final tapes = <Stroke>[];
    final onTape = <Stroke, List<Stroke>>{};
    for (final stroke in shown) {
      if (stroke.toolId == .tape) {
        tapes.add(stroke);
        onTape[stroke] = [];
        continue;
      }
      // on the last tape put down before it that it touches
      for (final tape in tapes.reversed) {
        if (_writtenOn(stroke, tape)) {
          onTape[tape]!.add(stroke);
          break;
        }
      }
    }
    return (tapes, onTape);
  }

  static bool _writtenOn(Stroke stroke, Stroke tape) {
    final area = tape.bounds.inflate(tape.options.size / 2);
    if (!area.overlaps(stroke.bounds)) return false;
    final line = stroke.centerPoints;
    final step = max(1, line.length ~/ 24);
    for (int i = 0; i < line.length; i += step) {
      if (tape.touchedBy(line[i], line[i], 0)) return true;
    }
    return line.isNotEmpty && tape.touchedBy(line.last, line.last, 0);
  }

  void _paintPageInk(
    Canvas canvas,
    Size size, {
    List<Stroke> tapes = const [],
    Map<Stroke, List<Stroke>> onTape = const {},
  }) {
    final apart = {...tapes, for (final on in onTape.values) ...on};
    final highlighters = <Stroke>[], ink = <Stroke>[];
    for (final stroke in strokes) {
      if (!_isShown(stroke) || apart.contains(stroke)) continue;
      (stroke.toolId == .highlighter ? highlighters : ink).add(stroke);
    }

    final selected = currentSelection?.strokes;
    final cache = inkCache;
    // Selected ink is tinted and moves on every frame of a drag: the rest
    // stays in the images, and the selection is drawn over them.
    final selectedSet = selected == null || selected.isEmpty
        ? null
        : selected.toSet();
    final selectedHighlighters = <Stroke>[], selectedInk = <Stroke>[];
    if (selectedSet != null) {
      highlighters.removeWhere((stroke) {
        final picked = selectedSet.contains(stroke);
        if (picked) selectedHighlighters.add(stroke);
        return picked;
      });
      ink.removeWhere((stroke) {
        final picked = selectedSet.contains(stroke);
        if (picked) selectedInk.add(stroke);
        return picked;
      });
    }
    final bands = inkBands([
      for (final stroke in strokes)
        if (_isShown(stroke) &&
            !apart.contains(stroke) &&
            !(selectedSet?.contains(stroke) ?? false))
          stroke,
    ], page.size);
    // the first three layers are kept as images; any more (pen and
    // highlighter taking turns over each other again) are drawn over them,
    // each in its place
    final inkUnder = bands[0];
    final layerHighlighters = bands.length > 1 ? bands[1] : <Stroke>[];
    final inkOver = bands.length > 2 ? bands[2] : <Stroke>[];
    final above = bands.length > 3 ? bands.sublist(3) : const <List<Stroke>>[];
    void drawAbove(Canvas canvas, {bool Function(Stroke)? only}) {
      for (final (i, band) in above.indexed) {
        final strokes = only == null ? band : band.where(only).toList();
        // layer 3 is highlighter, 4 ink, 5 highlighter…
        if (i.isEven) {
          _drawHighlighterStrokes(canvas, strokes);
        } else {
          _drawNonHighlighterStrokes(canvas, strokes, live: true);
        }
      }
    }

    var scale = pixelScale;

    // Zoomed in past the images of the whole page (too far for an image of
    // it, or shown stretched): drawn from tiles of the part on screen, made
    // in the background, see [InkCache.tiles].
    ({List<TileDraw> draws, Path covered, bool all})? tiles;
    // the ink on an area of the page, as it is
    void drawArea(Canvas canvas, double pixels, Rect area) {
      _drawScale = pixels;
      bool on(Stroke stroke) => InkCache.strokeArea(stroke).overlaps(area);
      _drawNonHighlighterStrokes(
        canvas,
        inkUnder.where(on).toList(),
        area: area,
      );
      _drawHighlighterStrokes(canvas, layerHighlighters.where(on).toList());
      _drawNonHighlighterStrokes(
        canvas,
        inkOver.where(on).toList(),
        area: area,
      );
      drawAbove(canvas, only: on);
    }

    final visible = page.visibleArea.value;
    if (cache != null && scale != null && scale.isFinite && scale > 0) {
      final tooBig = !cache.canHold(page.size, scale);
      if (visible != null &&
          (tooBig ||
              cache.stretched(onlyLayer, scale) ||
              // scrolled into view zoomed in: tiles, over a small image of
              // the whole page instead of a big one made in one frame
              (currentScale > 1.05 && !cache.hasImages(onlyLayer)))) {
        tiles = cache.tiles(
          layer: onlyLayer,
          invert: invert,
          size: page.size,
          visible: visible,
          pixelScale: scale,
          strokes: [...inkUnder, ...layerHighlighters, ...inkOver, ...above.expand((b) => b)],
          draw: drawArea,
        );
        if (tiles.all) {
          _drawTiles(canvas, tiles.draws, scale, drawArea);
          if (selectedSet != null) {
            _drawScale = scale;
            _drawNonHighlighterStrokes(
              canvas,
              selectedInk,
              selected: selectedSet,
            );
            _drawHighlighterStrokes(canvas, selectedHighlighters);
          }
          return;
        }
        // Zooming, or the tiles for this zoom not all made yet: the ink on
        // screen drawn as it is, sharp at any zoom, instead of an image
        // stretched (blurry) meanwhile. The pens are triangles worked out
        // once, quick for the GPU however many there are.
        final area = visible.inflate(8 / scale);
        if (_quickToDraw(area)) {
          canvas.save();
          canvas.clipRect(area);
          drawArea(canvas, scale, area);
          if (selectedSet != null) {
            _drawScale = scale;
            _drawNonHighlighterStrokes(
              canvas,
              selectedInk,
              selected: selectedSet,
            );
            _drawHighlighterStrokes(canvas, selectedHighlighters);
          }
          canvas.restore();
          return;
        }
      } else {
        cache.wholePages();
      }
      if (tooBig && (InkCache.moving.value || tiles != null)) {
        // under the tiles not made yet: the biggest image of the whole page
        scale = InkCache.largestScale(page.size);
      }
    }

    // built ahead of the screen while scrolling: its images wait their turn
    if (cache != null &&
        page.visibleArea.value == null &&
        !cache.hasImages(onlyLayer) &&
        !cache.mayMakeAhead()) {
      return;
    }
    if (cache != null && scale != null && cache.canHold(page.size, scale)) {
      final images = cache.images(
        layer: onlyLayer,
        size: page.size,
        pixelScale: scale,
        invert: invert,
        highlighters: layerHighlighters,
        ink: inkUnder,
        inkOver: inkOver,
        drawHighlighters: (canvas, strokes) {
          _drawScale = InkCache.renderScale(scale!);
          // the image is the highlighters' layer
          _highlighterLayer(canvas, strokes);
        },
        drawInk: (canvas, strokes) {
          _drawScale = InkCache.renderScale(scale!);
          _drawNonHighlighterStrokes(
            canvas,
            strokes,
            area: InkCache.drawingArea,
          );
        },
        cutHighlighterHoles: _cutNewHoles,
        tiled: tiles != null,
      );
      if (images != null) {
        final scale = images.scale;
        // where there are tiles, those instead
        if (tiles != null) {
          canvas.save();
          canvas.clipPath(
            Path()
              ..fillType = PathFillType.evenOdd
              ..addRect(Offset.zero & page.size)
              ..addPath(tiles.covered, Offset.zero),
            doAntiAlias: false,
          );
        }
        void drawImage(ui.Image image) {
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(
              0,
              0,
              image.width.toDouble(),
              image.height.toDouble(),
            ),
            Rect.fromLTWH(0, 0, image.width / scale, image.height / scale),
            // smoother when drawn smaller than it was made
            Paint()..filterQuality = .medium,
          );
        }

        // Each layer: its image, but where strokes changed since it was made,
        // and the new strokes on top, drawn as they are until they're in it.
        void drawLayer(
          InkLayer layer,
          void Function(List<Stroke> strokes, Rect? area) drawStrokes,
        ) {
          final image = layer.image;
          if (image != null) {
            if (layer.outsideHole case final outside?) {
              canvas.save();
              canvas.clipPath(outside, doAntiAlias: false);
              drawImage(image);
              canvas.restore();
            } else {
              drawImage(image);
            }
          }
          if (layer.hole case final hole? when layer.inHole.isNotEmpty) {
            canvas.save();
            canvas.clipPath(hole, doAntiAlias: false);
            // where strokes changed: only there (a big stroke's pieces
            // there, the eraser's holes there)
            drawStrokes(layer.inHole, hole.getBounds());
            canvas.restore();
          }
          drawStrokes(layer.over, null);
        }

        _drawScale = InkCache.renderScale(scale);
        drawLayer(
          images.ink,
          (strokes, area) => _drawNonHighlighterStrokes(
            canvas,
            strokes,
            live: true,
            area: area,
          ),
        );
        final highlighter = images.highlighter;
        final holesArea = highlighter.image == null
            ? null
            : _newHolesArea(highlighter.newHoles)
                  ?.intersect(Offset.zero & page.size);
        if (holesArea != null && !holesArea.isEmpty) {
          // the image as it is, but where the eraser went since it was
          // made: there in a layer of its own the size of that, with the
          // new holes cleared out of it
          final image = highlighter.image!;
          canvas.save();
          // hard edges, so the two halves meet without a seam
          canvas.clipRect(
            holesArea,
            clipOp: ui.ClipOp.difference,
            doAntiAlias: false,
          );
          drawImage(image);
          canvas.restore();
          canvas.saveLayer(holesArea, Paint());
          canvas.clipRect(holesArea, doAntiAlias: false);
          drawImage(image);
          _cutNewHoles(canvas, highlighter.newHoles);
          canvas.restore();
        } else if (highlighter.inHole.isEmpty && highlighter.over.isEmpty) {
          drawLayer(highlighter, (_, _) {});
        } else {
          // the image and the strokes not in it yet, as one layer, so the
          // newest is on top and eraser holes go through all of them
          canvas.saveLayer(Offset.zero & page.size, Paint());
          drawLayer(
            highlighter,
            (strokes, _) => _highlighterLayer(canvas, strokes),
          );
          canvas.restore();
        }
        drawLayer(
          images.inkOver,
          (strokes, area) => _drawNonHighlighterStrokes(
            canvas,
            strokes,
            live: true,
            area: area,
          ),
        );
        drawAbove(canvas);
        if (tiles != null) {
          canvas.restore();
          _drawTiles(canvas, tiles.draws, pixelScale!, drawArea);
        }
        if (selectedSet != null) {
          _drawNonHighlighterStrokes(
            canvas,
            selectedInk,
            selected: selectedSet,
          );
          _drawHighlighterStrokes(canvas, selectedHighlighters);
        }
        return;
      }
    } else if (cache != null && scale == null) {
      // not on screen any more
      cache.dispose();
    }

    // exports have no pixel scale: there, lines are drawn as wide as they are
    _drawScale = pixelScale ?? 1000;
    _drawNonHighlighterStrokes(canvas, inkUnder);
    _drawHighlighterStrokes(canvas, layerHighlighters);
    _drawNonHighlighterStrokes(canvas, inkOver);
    drawAbove(canvas);
    if (selectedSet != null) {
      _drawNonHighlighterStrokes(canvas, selectedInk, selected: selectedSet);
      _drawHighlighterStrokes(canvas, selectedHighlighters);
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    return pixelScale != oldDelegate.pixelScale ||
        inkCache != oldDelegate.inkCache ||
        // a stroke being written (or just finished) changes every move
        (paintCurrentStroke &&
            (currentStroke != null || oldDelegate.currentStroke != null)) ||
        // laser lines fade a little every frame until they're gone
        (laserStrokes.isNotEmpty || oldDelegate.laserStrokes.isNotEmpty) ||
        // otherwise, only when something painted here has changed
        onlyLayer != oldDelegate.onlyLayer ||
        onFrontImages != oldDelegate.onFrontImages ||
        tier != oldDelegate.tier ||
        frontImages.length != oldDelegate.frontImages.length ||
        invert != oldDelegate.invert ||
        strokes.length != oldDelegate.strokes.length ||
        currentSelection != oldDelegate.currentSelection ||
        primaryColor != oldDelegate.primaryColor ||
        page != oldDelegate.page ||
        showPageIndicator != oldDelegate.showPageIndicator ||
        pageIndex != oldDelegate.pageIndex ||
        totalPages != oldDelegate.totalPages ||
        // zoom only matters for lasso handle sizes;
        // repainting every page on every zoom frame made pinch-zoom hang
        (currentSelection != null && currentScale != oldDelegate.currentScale);
  }

  /// [ordered] strokes (oldest first) in layers, bottom to top, as on
  /// paper: the even layers ink, the odd ones highlighter. A highlighter
  /// goes just over the ink under it, or into the highlighter layer already
  /// on top there (overlapping highlighters don't get darker); a pen line,
  /// pencil or shape goes just over a highlighter under it, or into the ink
  /// layer on top there. So whatever is drawn later is on top, however
  /// often pen and highlighter take turns.
  ///
  /// Worked out on a coarse grid, oldest first, so it stays quick on a full
  /// page, and adding a stroke never moves the ones before it.
  @visibleForTesting
  static List<List<Stroke>> inkBands(List<Stroke> ordered, Size pageSize) {
    final bands = <List<Stroke>>[[]];
    if (!ordered.any((s) => s.toolId == .highlighter)) {
      bands[0].addAll(ordered.where((s) => s.toolId != .highlighter));
      return bands;
    }
    // The grid covers the ink, not the page: a whiteboard's page is
    // 200000 units square, and a grid over all of it (25 million cells,
    // made again on every paint) took 300-850 ms a frame there.
    Rect? area;
    for (final stroke in ordered) {
      final bounds = stroke.bounds.inflate(stroke.options.size / 2);
      if (!bounds.isFinite) continue;
      area = area == null ? bounds : area.expandToInclude(bounds);
    }
    area ??= Offset.zero & pageSize;
    // ponytail: cells grow on ink spread far over a board, so the grid stays
    // near 250k cells; ordering is coarser there
    final cell = max(40.0, sqrt(area.width * area.height / 250000));
    final columns = max(1, (area.width / cell).ceil());
    final rows = max(1, (area.height / cell).ceil());
    // the top layer on each square, -1 for none
    final top = List.filled(columns * rows, -1);
    for (final stroke in ordered) {
      final highlighter = stroke.toolId == .highlighter;
      final bounds = stroke.bounds.inflate(stroke.options.size / 2);
      if (!bounds.isFinite) {
        bands[0].add(stroke);
        continue;
      }
      final x0 = ((bounds.left - area.left) / cell).floor().clamp(0, columns - 1);
      final y0 = ((bounds.top - area.top) / cell).floor().clamp(0, rows - 1);
      final x1 = ((bounds.right - area.left) / cell).floor().clamp(0, columns - 1);
      final y1 = ((bounds.bottom - area.top) / cell).floor().clamp(0, rows - 1);
      var base = -1;
      for (int y = y0; y <= y1; y++) {
        for (int x = x0; x <= x1; x++) {
          base = max(base, top[y * columns + x]);
        }
      }
      final int band;
      if (highlighter) {
        band = base < 0 ? 1 : (base.isOdd ? base : base + 1);
      } else if (!stroke.nib2) {
        // ink from before strokes kept their order stays under, as it was
        band = 0;
      } else {
        band = base < 0 ? 0 : (base.isEven ? base : base + 1);
      }
      while (bands.length <= band) {
        bands.add([]);
      }
      bands[band].add(stroke);
      for (int y = y0; y <= y1; y++) {
        for (int x = x0; x <= x1; x++) {
          if (top[y * columns + x] < band) top[y * columns + x] = band;
        }
      }
    }
    return bands;
  }

  /// Highlighter strokes, over the ink ([_paintInk]), in a layer of their
  /// own over what's on [canvas].
  void _drawHighlighterStrokes(Canvas canvas, List<Stroke> highlighters) {
    if (highlighters.isEmpty) return;
    var bounds = Rect.zero;
    for (final stroke in highlighters) {
      bounds = bounds.isEmpty
          ? stroke.bounds
          : bounds.expandToInclude(stroke.bounds);
    }
    final pad = highlighters.map((s) => s.options.size).reduce(max) + 2;
    canvas.saveLayer(bounds.inflate(pad), Paint());
    _highlighterLayer(canvas, highlighters);
    canvas.restore();
  }

  /// Draws [highlighters] onto [canvas], which is their layer: see-through
  /// like a marker, so going over one again makes it darker and a newer
  /// colour shows on top of an older one; and as one layer, so the precise
  /// eraser's holes go through every one under them at once.
  /// In their own color on a dark page too.
  ///
  /// The holes are cleared right after their stroke: a stroke drawn after
  /// the erasing stays whole.
  void _highlighterLayer(Canvas canvas, List<Stroke> highlighters) {
    final paint = _highlighterPaint();
    for (final stroke in highlighters) {
      final (width, alpha) = hairline(stroke.options.size, _drawScale);
      paint
        ..color = stroke.color.withValues(alpha: stroke.color.a * alpha)
        ..strokeWidth = width
        ..strokeCap = stroke.flatEnds ? StrokeCap.butt : StrokeCap.round;
      // a piece a lasso split off shows only its side of the split
      final clip = stroke.clipPath;
      if (clip != null) {
        canvas.save();
        canvas.clipPath(clip);
      }
      canvas.drawPath(stroke.centerlinePath, paint);
      // its holes too only on its side, not through the other piece
      if (stroke.holes.isNotEmpty) {
        for (final (path, radius) in _holePaths(stroke)) {
          canvas.drawPath(path, _clearHole(radius));
        }
      }
      if (clip != null) canvas.restore();
    }
  }

  /// [holes] as the eraser's way through them: a line through each run of
  /// holes the eraser cut one after another, as wide as they are, for each
  /// eraser size. Kept until the holes change (each cut makes a new list).
  ///
  /// As a circle for each hole, a phone's GPU took 18 to 54 ms a frame
  /// while erasing highlighter, more the longer it went on, and as much
  /// while zooming: every circle was cut into triangles on every frame.
  static List<(Path, double)> _holePaths(Stroke stroke) {
    final holes = stroke.holes;
    var cache = _holePathCache[stroke];
    if (cache != null && identical(cache.holes, holes)) return cache.paths;
    // a cut adds holes at the end of a new list: only those are added on,
    // not the whole way worked out again on every move of the eraser
    if (cache == null ||
        cache.holes.isEmpty ||
        cache.holes.length > holes.length ||
        holes[cache.holes.length - 1] != cache.holes.last) {
      cache = _holePathCache[stroke] = _HolePaths();
    }
    cache.extend(holes);
    return cache.paths;
  }

  static final _holePathCache = Expando<_HolePaths>('highlighter holes');

  /// The holes of each stroke past the index given, as [_holePaths] does.
  static _HolePaths _newHolePaths(Stroke stroke, int from) {
    final holes = stroke.holes;
    var cache = _newHoleCache[stroke];
    if (cache == null ||
        cache.start != from ||
        cache.holes.length > holes.length ||
        (cache.holes.length > from &&
            holes[cache.holes.length - 1] != cache.holes.last)) {
      cache = _newHoleCache[stroke] = _HolePaths(start: from);
    }
    if (!identical(cache.holes, holes)) cache.extend(holes);
    return cache;
  }

  static final _newHoleCache = Expando<_HolePaths>('new highlighter holes');

  /// Where [holes] are, see [InkLayer.newHoles].
  static Rect? _newHolesArea(List<(Stroke, int)> holes) {
    Rect? area;
    for (final (stroke, from) in holes) {
      final bounds = _newHolePaths(stroke, from).bounds;
      if (bounds == null) continue;
      area = area == null ? bounds : area.expandToInclude(bounds);
    }
    return area;
  }

  /// Clears [holes] out of the highlighters' layer, see [InkLayer.newHoles].
  ///
  /// The eraser cuts the same holes into every highlighter under it: those
  /// are cleared once, not once for each of a pile of highlighters.
  static void _cutNewHoles(Canvas canvas, List<(Stroke, int)> holes) {
    final done = <(Object, Object, int)>{};
    for (final (stroke, from) in holes) {
      final all = stroke.holes;
      if (!done.add((all[from], all.last, all.length - from))) continue;
      for (final (path, radius) in _newHolePaths(stroke, from).paths) {
        canvas.drawPath(path, _clearHole(radius));
      }
    }
  }

  static Paint _clearHole(double radius) => Paint()
    ..blendMode = BlendMode.clear
    ..style = PaintingStyle.stroke
    ..strokeWidth = radius * 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Screen pixels per unit of the page that ink is being drawn at now.
  static double _drawScale = 1;

  /// A line [width] units wide, drawn at [scale] pixels per unit: lines
  /// thinner than a pixel are drawn a pixel wide but see-through, as much
  /// as they cover it. Drawn at their own width, the GPU made them a whole
  /// solid pixel, so zoomed-out writing looked bold and dark.
  static (double width, double alpha) hairline(double width, double scale) {
    final pixels = width * scale;
    // (no scale, or next to none: a pixel would be wider than the page)
    if (pixels >= 1 || scale < 1e-3) return (width, 1);
    return (1 / scale, pixels.clamp(0.2, 1.0));
  }

  static Paint _highlighterPaint() => Paint()
    ..style = .stroke
    ..strokeCap = .round
    ..strokeJoin = .round;

  /// Draws [ink], which has no highlighters. [selected] strokes are tinted.
  /// [live]: drawn on screen as they are, not into an image: a stroke whose
  /// outline isn't worked out yet, past this frame's share of time for
  /// that ([_Outlines]), is drawn along its line for now.
  /// Whether the ink on [area] is quick enough to draw on every frame of a
  /// zoom: the pens' triangles are, outlines (calligraphy, shapes) and
  /// pencil grains cost more, so only so many of those.
  bool _quickToDraw(Rect area) {
    var heavy = 0, points = 0;
    for (final stroke in strokes) {
      if (!InkCache.strokeArea(stroke).overlaps(area)) continue;
      points += stroke.length;
      if (stroke.inkVertices == null) heavy += stroke.length;
      // handwriting in fountain pen is outlines: a page full of it is
      // still quick enough
      if (points > 400000 || heavy > 150000) return false;
    }
    return true;
  }

  void _drawNonHighlighterStrokes(
    Canvas canvas,
    List<Stroke> ink, {
    Set<Stroke>? selected,
    bool live = false,
    Rect? area,
  }) {
    late final paint = Paint();

    void drawOne(Stroke stroke) {
      if (stroke.toolId == .tape) {
        _drawTapeStroke(canvas, stroke);
        return;
      }

      final color = stroke.color.withInversion(invert);
      // picked ink keeps its own colour, with a soft blue edge behind it
      if (selected != null && selected.contains(stroke)) {
        canvas.drawPath(
          stroke.centerlinePath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = stroke.options.size + 7 / max(currentScale, 0.05)
            ..color = primaryColor.withValues(alpha: 0.22),
        );
      }

      if (_drawShape(canvas, stroke, color)) return;
      if (stroke.toolId == .pencil) {
        _drawPencilStroke(canvas, stroke, color);
        return;
      }
      if (live && !_Outlines.ready(stroke)) {
        canvas.drawPath(
          stroke.centerlinePath,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = stroke.options.size * 0.85,
        );
        return;
      }
      paint.color = color;
      // ink as triangles, worked out once (see [Stroke.inkVertices])
      if (stroke.inkVertices case final vertices?) {
        canvas.drawVertices(vertices, BlendMode.srcOver, paint);
        return;
      }
      // A big stroke in pieces, and in a tile only those on it. A scribble
      // crossing itself thousands of times, filled as one shape, took the
      // GPU over a second to draw into the page's image.
      if (color.a >= 1) {
        if (stroke.areaPieces case final pieces?) {
          for (final piece in pieces) {
            if (area == null || piece.area.overlaps(area)) {
              canvas.drawPath(piece.path, paint);
            }
          }
          return;
        }
      }
      canvas.drawPath(_selectPath(stroke), paint);
    }

    for (final stroke in ink) {
      _withHoles(canvas, stroke, () => drawOne(stroke), area: area);
    }
  }

  /// Draws with [draw] around the round holes the eraser cut out of
  /// [stroke], if it has any.
  ///
  /// Clipped to what the holes leave of the stroke's area, worked out once
  /// ([Stroke.keptRegion]). A layer of its own for each stroke, with every
  /// hole cleared out of it on every frame, made a page the eraser had been
  /// over draw at two frames a second on a phone.
  static void _withHoles(
    Canvas canvas,
    Stroke stroke,
    VoidCallback draw, {
    Rect? area,
  }) {
    final holes = stroke.holes;
    if (holes.isEmpty) return draw();
    if (area case final only?) {
      // Only [area] is drawn (a tile, or where the eraser has been): only
      // the holes there are cut, fresh. All of a big stroke's holes, taken
      // out of its outline on every move of the eraser, took 50-130 ms.
      final there = only.intersect(
        stroke.bounds.inflate(stroke.options.size + 2),
      );
      if (there.isEmpty) return;
      final cut = Path();
      var any = false;
      for (final hole in holes) {
        final circle = Rect.fromCircle(
          center: hole.center,
          radius: hole.radius,
        );
        if (!circle.overlaps(there)) continue;
        cut.addOval(circle);
        any = true;
      }
      canvas.save();
      if (any) {
        canvas.clipPath(
          Path.combine(PathOperation.difference, Path()..addRect(there), cut),
        );
      } else {
        canvas.clipRect(there);
      }
      draw();
      canvas.restore();
      return;
    }
    final bounds = stroke.bounds.inflate(stroke.options.size + 2);
    final kept = stroke.keptRegion(bounds);
    if (kept != null) {
      canvas.save();
      canvas.clipPath(kept);
      draw();
      canvas.restore();
      return;
    }
    canvas.saveLayer(bounds, Paint());
    draw();
    final clear = Paint()..blendMode = BlendMode.clear;
    for (final hole in holes) {
      canvas.drawCircle(hole.center, hole.radius, clear);
    }
    canvas.restore();
  }

  void _drawPencilStroke(Canvas canvas, Stroke stroke, Color color) =>
      paintGraphite(canvas, stroke, color, scale: _drawScale);

  /// Graphite: only grains, thinning out towards the edges, with the paper
  /// showing through. All of it is vectors on the page, so it stays sharp at
  /// every zoom and doesn't crawl while scrolling.
  static void paintGraphite(
    Canvas canvas,
    Stroke stroke,
    Color color, {
    double scale = 1,
  }) {
    // Grains under ~1.6 px were snapped to whole pixels: zoomed out, each
    // shifted and changed weight as the zoom moved, so the pencil seemed to
    // jitter and flicker. They're drawn at least that wide, round and soft,
    // with as much colour as their real area would have.
    const minPixels = 1.6;
    final pixels = stroke.pencilGrainSize * scale;
    final double width, alpha;
    if (pixels >= minPixels || scale < 1e-3) {
      (width, alpha) = (stroke.pencilGrainSize, 1.0);
    } else {
      final share = pixels / minPixels;
      (width, alpha) = (minPixels / scale, (share * share).clamp(0.08, 1.0));
    }
    canvas.drawRawPoints(
      ui.PointMode.points,
      stroke.pencilGrain,
      Paint()
        ..color = color.withValues(alpha: color.a * 0.95 * alpha)
        ..strokeCap = .round
        ..isAntiAlias = true
        ..strokeWidth = width,
    );
  }

  /// Draws [stroke] with a pen of fixed width if it's a shape.
  /// Returns whether it was.
  bool _drawShape(Canvas canvas, Stroke stroke, Color color) {
    final Path outline;
    if (stroke is CircleStroke) {
      outline = Path()
        ..addOval(
          Rect.fromCircle(center: stroke.center, radius: stroke.radius),
        );
    } else if (stroke is RectangleStroke) {
      outline = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            stroke.rect,
            Radius.circular(
              (stroke.shapeStyle ?? ShapeStyle.plain).boxCornerRadius(
                stroke.options.size,
                stroke.rect,
              ),
            ),
          ),
        );
    } else if (stroke.toolId == .shapePen) {
      outline = _shapeOutline(stroke);
    } else if (stroke.toolId == .ballpointPen) {
      // A ball pen has one width, so no outline is needed. That outline was
      // recalculated for the whole stroke on every move, which is what lagged.
      final (width, alpha) = hairline(stroke.options.size, _drawScale);
      final line = stroke.centerlinePath;
      canvas.drawPath(
        switch (stroke.inkLine) {
          .dashed => dashPath(
            line,
            dashArray: CircularIntervalList([
              max(width * 3, 6.0),
              max(width * 2, 4.0),
            ]),
          ),
          .dotted => dashPath(
            line,
            dashArray: CircularIntervalList([0.01, max(width * 2.2, 4.0)]),
          ),
          _ => line,
        },
        _highlighterPaint()
          ..color = color.withValues(alpha: color.a * alpha)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
      return true;
    } else {
      return false;
    }
    paintShape(
      canvas,
      stroke,
      outline,
      color,
      invert: invert,
      scale: _drawScale,
    );
    return true;
  }

  /// The rounded line of each shape, kept with the line it was made from
  /// (a new line when the points change) and the pen size.
  static final _roundedOutlines = Expando<(double, Path)>();

  /// [stroke]'s line, its corners rounded if its style says so.
  static Path _shapeOutline(Stroke stroke) {
    final line = stroke.polylinePath;
    if (!(stroke.shapeStyle ?? ShapeStyle.plain).rounded) return line;
    final size = stroke.options.size;
    if (_roundedOutlines[line] case (final s, final path) when s == size) {
      return path;
    }
    final path = ShapeStyle.roundCorners(
      stroke.centerPoints,
      ShapePen.cornerIndices(stroke),
      ShapeStyle.cornerRadius(size),
      closed: stroke.isClosedShape,
    );
    _roundedOutlines[line] = (size, path);
    return path;
  }

  /// Tiles of the ink, see [InkCache.tiles]. [drawArea] draws the ink on an
  /// area as it is.
  void _drawTiles(
    Canvas canvas,
    List<TileDraw> draws,
    double scale,
    void Function(Canvas canvas, double scale, Rect area) drawArea,
  ) {
    // Hard edges: smoothed, two tiles side by side each half covered the
    // pixels where they meet, and a faint line showed through the ink.
    final paint = Paint()
      ..filterQuality = .medium
      ..isAntiAlias = false;
    for (final tile in draws) {
      if (tile.image case final image?) {
        canvas.drawImageRect(image, tile.from, tile.to, paint);
      }
      if (!tile.direct && tile.over.isEmpty) continue;
      canvas.save();
      canvas.clipRect(tile.to, doAntiAlias: false);
      _drawScale = scale;
      if (tile.direct) {
        drawArea(canvas, scale, tile.to);
      } else {
        for (final stroke in tile.over) {
          if (stroke.toolId == .highlighter) {
            _drawHighlighterStrokes(canvas, [stroke]);
          } else {
            _drawNonHighlighterStrokes(canvas, [stroke]);
          }
        }
      }
      canvas.restore();
    }
  }

  /// A shape's fill, outline and arrowheads. Also used for previews.
  static void paintShape(
    Canvas canvas,
    Stroke stroke,
    Path outline,
    Color color, {
    bool invert = false,
    double scale = 1,
  }) {
    final style = stroke.shapeStyle ?? ShapeStyle.plain;
    final (width, alpha) = hairline(stroke.options.size, scale);
    color = color.withValues(alpha: color.a * alpha);
    final closed =
        stroke is CircleStroke ||
        stroke is RectangleStroke ||
        stroke.isClosedShape;
    if (style.fill case final fill? when closed) {
      canvas.drawPath(outline, Paint()..color = fill.withInversion(invert));
    }
    final line = Paint()
      ..style = .stroke
      ..color = color
      ..strokeWidth = width
      ..strokeCap = style.rounded ? .round : .butt
      ..strokeJoin = style.rounded ? .round : .miter;
    switch (style.line) {
      case .none:
        break;
      case .solid:
        canvas.drawPath(outline, line);
      case .dashed:
        canvas.drawPath(
          dashPath(
            outline,
            dashArray: CircularIntervalList([width * 4, width * 2.5]),
          ),
          line,
        );
      case .dotted:
        canvas.drawPath(
          dashPath(outline, dashArray: CircularIntervalList([0.01, width * 2])),
          line..strokeCap = .round,
        );
    }
    if (closed || style.line == .none) return;
    final points = stroke.editablePoints;
    if (points.length < 2) return;
    void head(ShapeArrow arrow, Offset tip, Offset from) {
      if (arrow == .none) return;
      final direction = tip - from;
      if (direction.distance == 0) return;
      final unit = direction / direction.distance;
      final normal = Offset(-unit.dy, unit.dx);
      final length = max(width * 3.5, 10.0);
      final back = tip - unit * length;
      final left = back + normal * length * 0.55;
      final right = back - normal * length * 0.55;
      if (arrow == .filled) {
        canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(right.dx, right.dy)
            ..close(),
          Paint()..color = color,
        );
      } else {
        canvas.drawPath(
          Path()
            ..moveTo(left.dx, left.dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(right.dx, right.dy),
          Paint()
            ..style = .stroke
            ..color = color
            ..strokeWidth = width
            ..strokeCap = .round
            ..strokeJoin = .round,
        );
      }
    }

    // Pointing the way the line comes in over the arrowhead's length, not
    // just its last two points: a shape's points also run along its sides,
    // close together, and a hand's wobble there turned the head askew.
    final reach = max(width * 3.5, 10.0);
    // Up to a sharp corner, though: a short last side of a bent arrow
    // points its own way.
    Offset from(Iterable<Offset> back) {
      final tip = back.first;
      var at = tip;
      double? heading;
      for (final p in back.skip(1)) {
        final step = at - p;
        if (step.distance > 0) {
          final turn = heading == null
              ? 0.0
              : (step.direction - heading).abs() % (2 * pi);
          if (min(turn, 2 * pi - turn) > 0.5) break;
          heading = step.direction;
        }
        at = p;
        if ((p - tip).distance >= reach) break;
      }
      return at;
    }

    head(style.arrowEnd, points.last, from(points.reversed));
    head(style.arrowStart, points.first, from(points));
  }

  void _drawTapeStroke(Canvas canvas, Stroke stroke) {
    final color = stroke.color.withInversion(invert);
    if (!stroke.tapeRevealed) {
      // lifted off the page: a soft shadow, then a darker edge all around
      final border = stroke.tapeBorder;
      final size = stroke.options.size;
      canvas.save();
      canvas.translate(1.5, 3);
      canvas.drawPath(
        border,
        Paint()
          ..style = .stroke
          ..strokeJoin = .round
          ..strokeWidth = size + 2
          ..color = const Color(0x55000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.restore();
      canvas.drawPath(
        border,
        Paint()
          ..style = .stroke
          ..strokeJoin = .round
          ..strokeWidth = size + 3
          ..color = Color.lerp(color, Colors.black, 0.4)!,
      );
    }
    canvas.drawPath(
      stroke.centerlinePath,
      Paint()
        ..style = .stroke
        ..strokeJoin = .round
        ..strokeWidth = stroke.options.size
        ..color = stroke.tapeRevealed ? color.withValues(alpha: 0.2) : color,
    );
    if (stroke.tapeRevealed) return;
    // a design that shows up on pale and on deep colors alike
    canvas.drawPath(
      stroke.tapeStamps,
      Paint()
        ..color = color.computeLuminance() > 0.55
            ? const Color(0x33000000)
            : const Color(0x88FFFFFF),
    );
  }

  void _drawCurrentStroke(Canvas canvas, Stroke? stroke) {
    if (stroke == null) return;

    if (stroke is LaserStroke) {
      return _drawLaserStroke(canvas, stroke);
    }
    if (stroke.toolId == .tape) {
      return _drawTapeStroke(canvas, stroke);
    }

    final color = stroke.color.withInversion(invert);
    if (_drawShape(canvas, stroke, color)) return;

    if (stroke.toolId == .pencil) {
      return _drawPencilStroke(canvas, stroke, color);
    }

    if (stroke.toolId == .highlighter) {
      // in its own color on a dark page too, as [_drawHighlighterStrokes]
      canvas.drawPath(
        stroke.centerlinePath,
        _highlighterPaint()
          ..color = stroke.color
          ..strokeWidth = stroke.options.size,
      );
      return;
    }

    // Current stroke always uses high quality
    if (_LongStroke.drawn(canvas, stroke, color, pixelScale)) return;
    _drawInk(canvas, stroke, Paint()..color = color);
  }

  void _drawLaserStroke(Canvas canvas, LaserStroke stroke) {
    if (stroke.isDot) {
      // same size on screen at any zoom
      final radius = 5 / max(currentScale, 0.05);
      final tip = stroke.centerPoints.last;
      canvas.drawCircle(
        tip,
        radius,
        Paint()
          ..color = stroke.color.withInversion(invert)
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, radius * 0.6),
      );
      canvas.drawCircle(
        tip,
        radius * 0.45,
        Paint()..color = const Color(0xDDffffff),
      );
      return;
    }
    // Drawn as wide lines along the center. A filled outline left holes where
    // a long stroke crossed itself, and a blur mask that large can drop parts.
    final color = stroke.color.withInversion(invert);
    // same thickness on screen at any zoom
    final size = stroke.options.size / max(currentScale, 0.05);
    final path = stroke.centerlinePath;
    final paint = _highlighterPaint()
      ..strokeCap = .round
      ..strokeJoin = .round;
    final opacity = stroke.opacity;
    // A soft glow fading out over a few widths, like light: one band 1.4
    // times as wide, a third as strong, had a hard edge close to the line.
    for (final (width, alpha) in [
      if (LaserPointer.currentLaserPointer.glow) ...const [
        (4.2, 0.05),
        (3.0, 0.08),
        (2.1, 0.13),
      ],
      // a thin edge even without the glow
      (1.45, 0.22),
    ]) {
      canvas.drawPath(
        path,
        paint
          ..color = color.withValues(alpha: alpha * opacity)
          ..strokeWidth = size * width,
      );
    }
    canvas.drawPath(
      path,
      paint
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = size * 0.75,
    );
    canvas.drawPath(
      path,
      paint
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85 * opacity)
        ..strokeWidth = size * 0.28,
    );
  }

  /// The lasso, its moving dotted edge ([phase] from 0 to 1 runs the dashes
  /// once round) and the box with its handles. Everything is sized for the
  /// screen, so it's as thin at 300% as at 100%.
  void _drawSelection(Canvas canvas, {double phase = 0}) {
    if (currentSelection == null) return;

    final image = Select.currentSelect.singleImage;
    if (image != null && currentSelection!.images.contains(image)) {
      return _drawImageEditor(canvas, image);
    }
    final zoom = max(currentScale, 0.05);

    // a faint tint over what's inside the lasso
    canvas.drawPath(
      currentSelection!.path,
      Paint()..color = primaryColor.withValues(alpha: 0.08),
    );

    // Solid line while the lasso is still being drawn: dashing the whole
    // growing path on every move made freehand lassos stutter.
    if (!Select.currentSelect.doneSelecting) {
      canvas.drawPath(
        currentSelection!.path,
        Paint()
          ..color = primaryColor
          ..strokeWidth = 1.6 / zoom
          ..style = .stroke,
      );
      return;
    }

    // marching ants: a white line under dashes that run round
    final dash = 6 / zoom, gap = 5 / zoom;
    canvas.drawPath(
      currentSelection!.path,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.4 / zoom
        ..style = .stroke,
    );
    canvas.drawPath(
      dashPath(
        currentSelection!.path,
        dashArray: CircularIntervalList([dash, gap]),
        dashOffset: DashOffset.absolute((1 - phase) * (dash + gap)),
      ),
      Paint()
        ..color = primaryColor
        ..strokeWidth = 1.6 / zoom
        ..style = .stroke,
    );

    // resize + rotate handles
    if (currentSelection!.isEmpty) return;
    final fill = Paint()..color = primaryColor;
    final ring = Paint()
      ..color = Colors.white
      ..style = .stroke
      ..strokeWidth = 2 / zoom;

    // the corners of a shape being edited, instead
    final corners = Select.currentSelect.shapeCorners;
    if (corners.isNotEmpty) {
      for (final corner in corners) {
        canvas.drawCircle(corner, 7 / zoom, Paint()..color = Colors.white);
        canvas.drawCircle(
          corner,
          7 / zoom,
          Paint()
            ..color = primaryColor
            ..style = .stroke
            ..strokeWidth = 2.5 / zoom,
        );
      }
      return;
    }

    // the box hugs what's picked and turns with it
    final select = Select.currentSelect;
    final bounds = select.box;
    canvas.save();
    canvas.rotate(select.angle);
    final rotateHandle = Select.rotateHandle(bounds, zoom);
    final line = Paint()
      ..color = primaryColor
      ..strokeWidth = 1.4 / zoom;
    canvas.drawRect(
      bounds,
      Paint()
        ..color = primaryColor
        ..style = .stroke
        ..strokeWidth = 1.2 / zoom,
    );
    canvas.drawLine(
      Offset(bounds.center.dx, bounds.bottom),
      rotateHandle,
      line,
    );
    final white = Paint()..color = Colors.white;
    final blueRing = Paint()
      ..color = primaryColor
      ..style = .stroke
      ..strokeWidth = 1.4 / zoom;
    Select.boxHandles(bounds).forEach((handle, point) {
      final corner = switch (handle) {
        .topLeft || .topRight || .bottomLeft || .bottomRight => true,
        _ => false,
      };
      if (corner) {
        canvas.drawCircle(point, 5 / zoom, white);
        canvas.drawCircle(point, 5 / zoom, blueRing);
      } else if (select.level) {
        // the side middles are small pills along their side; a turned box
        // can't be stretched, so it has none
        final across = handle == .top || handle == .bottom;
        final pill = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: point,
            width: (across ? 14 : 5) / zoom,
            height: (across ? 5 : 14) / zoom,
          ),
          Radius.circular(2.5 / zoom),
        );
        canvas.drawRRect(pill, white);
        canvas.drawRRect(pill, blueRing);
      }
    });
    canvas.drawCircle(rotateHandle, 8 / zoom, fill);
    canvas.drawCircle(rotateHandle, 8 / zoom, ring);
    // little arrow hint inside the rotate handle
    canvas.drawCircle(
      rotateHandle,
      3.5 / zoom,
      Paint()
        ..color = Colors.white
        ..style = .stroke
        ..strokeWidth = 1.4 / zoom,
    );
    canvas.restore();
  }

  /// A solid outline around the picture, with its resize and rotate handles.
  void _drawImageEditor(Canvas canvas, EditorImage image) {
    final zoom = max(currentScale, 0.05);
    final outline = Paint()
      ..color = primaryColor
      ..style = .stroke
      ..strokeWidth = 2 / zoom;
    canvas.drawPath(
      Path()..addPolygon(Select.imageCorners(image), true),
      outline,
    );

    final rotateHandle = Select.imageRotateHandle(image, zoom);
    canvas.drawLine(Select.imageBottomCenter(image), rotateHandle, outline);
    final fill = Paint()..color = Colors.white;
    for (final handle in Select.imageHandles(image).values) {
      canvas.drawCircle(handle, 8 / zoom, fill);
      canvas.drawCircle(handle, 8 / zoom, outline);
    }
    canvas.drawCircle(rotateHandle, 9 / zoom, Paint()..color = primaryColor);
    canvas.drawCircle(
      rotateHandle,
      4 / zoom,
      Paint()
        ..color = Colors.white
        ..style = .stroke
        ..strokeWidth = 1.5 / zoom,
    );
  }

  /// Size of the page number's text, and its gap from the page's edges.
  static const double _indicatorTextSize = 20;
  static const double _indicatorMargin = 5;

  /// Writes "page / pages" faintly in the bottom right corner of the page.
  void _drawPageIndicator(Canvas canvas, Size pageSize) {
    if (!showPageIndicator) return;

    final label =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: .end,
              textDirection: .ltr,
              maxLines: 1,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: Colors.black.withInversion(invert).withValues(alpha: 0.5),
              fontSize: _indicatorTextSize,
              fontFamily: defaultTextStyle.fontFamily,
              fontFamilyFallback: defaultTextStyle.fontFamilyFallback,
            ),
          )
          ..addText('${pageIndex + 1} / $totalPages');

    // right-aligned across the page, one line (about 1.2x the text size) up
    // from the bottom
    final paragraph = label.build()
      ..layout(
        ui.ParagraphConstraints(width: pageSize.width - 2 * _indicatorMargin),
      );
    final origin = Offset(
      _indicatorMargin,
      pageSize.height - _indicatorMargin - _indicatorTextSize * 1.2,
    );
    canvas.drawParagraph(paragraph, origin);
  }

  // Always the smooth path: the low quality one (every 4th point, straight
  // segments) made handwriting look like broken lines when zoomed out.
  Path _selectPath(Stroke stroke) => stroke.highQualityPath;
}

/// Paints only the stroke being drawn, on its own layer, so each pen move
/// repaints one path instead of the whole page.
///
/// The stroke is looked up when painting rather than passed in, so that
/// starting and finishing a stroke only has to repaint this layer instead of
/// rebuilding the editor.
/// The selection on its own layer: the lasso with its moving dotted edge,
/// the box and its handles. Repaints on its own every frame while something
/// is picked, without the page's ink being painted again.
class SelectionPainter extends CanvasPainter {
  SelectionPainter({
    required Listenable repaint,
    required this.ants,
    required super.currentSelection,
    required super.invert,
    required super.primaryColor,
    required super.page,
    required super.currentScale,
    required super.defaultTextStyle,
  }) : super(
         repaint: Listenable.merge([repaint, ants]),
         strokes: const [],
         laserStrokes: const [],
         currentStroke: null,
         showPageIndicator: false,
         pageIndex: 0,
         totalPages: 0,
       );

  /// From 0 to 1, over and over: where the dashes are in their run round.
  final Animation<double> ants;

  @override
  void paint(Canvas canvas, Size size) =>
      _drawSelection(canvas, phase: ants.value);

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) => true;
}

class CurrentStrokePainter extends CanvasPainter {
  CurrentStrokePainter({
    required Listenable repaint,
    required super.invert,
    required super.primaryColor,
    required super.page,
    required super.currentScale,
    required super.defaultTextStyle,
    super.pixelScale,
  }) : super(
         repaint: repaint,
         strokes: const [],
         laserStrokes: const [],
         currentStroke: null,
         currentSelection: null,
         showPageIndicator: false,
         pageIndex: 0,
         totalPages: 0,
       );

  /// The stroke being drawn on [page], if any.
  Stroke? get _liveStroke {
    final stroke = Pen.currentStroke;
    return stroke != null && stroke.page == page ? stroke : null;
  }

  @override
  void paint(Canvas canvas, Size size) =>
      LagRecorder.span('paint pen stroke', () => _paintCurrent(canvas, size));

  void _paintCurrent(Canvas canvas, Size size) {
    // a recording playing in Spotlight: what isn't written yet, faded,
    // all in one layer so overlapping strokes don't get darker
    if (page.replayGhosts.isNotEmpty) {
      final picture = page.replayGhostPicture ??= () {
        final recorder = ui.PictureRecorder();
        final ghosts = Canvas(recorder);
        for (final stroke in page.replayGhosts) {
          _drawCurrentStroke(ghosts, stroke);
        }
        return recorder.endRecording();
      }();
      canvas
        ..saveLayer(
          Offset.zero & page.size,
          Paint()..color = const Color.fromRGBO(0, 0, 0, 0.28),
        )
        ..drawPicture(picture)
        ..restore();
    }
    // a recording playing: the strokes being written, as far as they've got
    for (final stroke in page.replayPartial) {
      _drawCurrentStroke(canvas, stroke);
    }
    _drawCurrentStroke(canvas, _liveStroke);
    _drawEraserRing(canvas);
  }

  /// A round marker showing what the eraser covers, the same size on screen
  /// at any zoom. A solid dark outline around a white ring keeps it easy to see
  /// on any page, over any ink.
  void _drawEraserRing(Canvas canvas) {
    final center = page.eraserRing;
    if (center == null) return;
    final zoom = max(currentScale, 0.05);
    final radius = Eraser.screenRadius / zoom;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0x55FFFFFF));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = .stroke
        ..strokeWidth = 3 / zoom,
    );
    canvas.drawCircle(
      center,
      radius + 2.5 / zoom,
      Paint()
        ..color = const Color(0xFF202124)
        ..style = .stroke
        ..strokeWidth = 2 / zoom,
    );
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) =>
      _liveStroke != null ||
      page.eraserRing != null ||
      invert != oldDelegate.invert ||
      page != oldDelegate.page ||
      currentScale != oldDelegate.currentScale;
}

/// Works out strokes' outlines a few milliseconds' worth a frame.
///
/// The eraser cuts a line of writing into many pieces at once, and each new
/// piece's outline had to be worked out before the frame it first showed in:
/// two thirds of every frame while erasing a full page, up to 35 ms.
/// Pieces past the frame's share are drawn along their line meanwhile, and
/// their outlines are worked out after each frame until done.
abstract final class _Outlines {
  static const _budgetMicros = 3000;
  static var _usedMicros = 0;
  static var _scheduled = false;
  static final _waiting = <Stroke>{};

  /// Ticks when outlines that were waiting are ready, to draw them again.
  static final done = ValueNotifier(0);

  /// Whether [stroke]'s outline is ready to draw, working it out now if
  /// this frame's share of time allows.
  static bool ready(Stroke stroke) {
    if (stroke.hasHighQualityPath || stroke.hasInkVertices) return true;
    _schedule();
    if (_usedMicros < _budgetMicros) {
      final watch = Stopwatch()..start();
      // what it's drawn with: its triangles, or its outline
      if (stroke.inkVertices == null) stroke.highQualityPath;
      _usedMicros += watch.elapsedMicroseconds;
      return true;
    }
    _waiting.add(stroke);
    return false;
  }

  static void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      _usedMicros = 0;
      if (_waiting.isEmpty) return;
      // between frames, a share's worth of the ones that waited
      final watch = Stopwatch()..start();
      final made = <Stroke>[];
      for (final stroke in _waiting) {
        if (watch.elapsedMicroseconds > _budgetMicros) break;
        if (stroke.inkVertices == null) stroke.highQualityPath;
        made.add(stroke);
      }
      _waiting.removeAll(made);
      done.value++;
      if (_waiting.isNotEmpty) {
        _schedule();
        SchedulerBinding.instance.scheduleFrame();
      }
    });
  }
}

/// Ticks when strokes drawn along their line for now have their outlines
/// ready, see [_Outlines].
ValueListenable<int> get outlinesReady => _Outlines.done;

/// The eraser's way through a stroke's holes, see [CanvasPainter._holePaths].
class _HolePaths {
  /// [start]: the holes before this index are left out.
  _HolePaths({this.start = 0});

  final int start;
  var holes = const <({Offset center, double radius})>[];
  final _byRadius = <double, Path>{};
  List<(Path, double)> paths = const [];

  /// Around all the holes in [paths], or null if none.
  Rect? bounds;

  /// Adds on the holes past those already in.
  void extend(List<({Offset center, double radius})> all) {
    var last = holes.length > start ? holes.last : null;
    for (final h in all.skip(max(start, holes.length))) {
      final r = Rect.fromCircle(center: h.center, radius: h.radius + 2);
      bounds = bounds?.expandToInclude(r) ?? r;
      final path = _byRadius.putIfAbsent(h.radius, Path.new);
      final joins =
          last != null &&
          last.radius == h.radius &&
          (h.center - last.center).distance <= h.radius * 1.5;
      if (joins) {
        path.lineTo(h.center.dx, h.center.dy);
      } else {
        // a hole on its own: a dot, from a line too short to see
        path
          ..moveTo(h.center.dx, h.center.dy)
          ..lineTo(h.center.dx + 0.01, h.center.dy);
      }
      last = h;
    }
    holes = all;
    paths = [for (final e in _byRadius.entries) (e.value, e.key)];
  }
}

/// [stroke]'s ink: its triangles if it has them, else its outline.
void _drawInk(Canvas canvas, Stroke stroke, Paint paint) {
  if (stroke.inkVertices case final vertices?) {
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
  } else {
    canvas.drawPath(stroke.highQualityPath, paint);
  }
}

/// A long stroke being written, drawn a piece at a time (see
/// [Stroke.livePiece]): what's written is kept in an image, and only the
/// last piece is worked out and drawn again as the pen moves. The whole
/// stroke is drawn as one once the pen lifts.
///
/// An image, not pictures: the GPU draws a picture's paths again on every
/// frame, and a stroke written for a minute took it 150 ms a frame.
class _LongStroke {
  _LongStroke(this.stroke, this.color, this.scale);

  final Stroke stroke;
  final Color color;

  /// Pixels per page unit of [image].
  final double scale;

  /// The pieces kept so far, in one image over [area] of the page.
  ///
  /// On a grid of whole pixels at one size for the whole stroke: the image
  /// so far goes into the next, bigger one exactly pixel for pixel. Put in
  /// a fraction of a pixel off each time, the line grew blurrier the longer
  /// it went (a fine fountain pen showed it); kept as an image for each
  /// piece instead, drawing them all took longer the longer it went.
  ui.Image? image;
  var area = Rect.zero;

  /// The points before this one are in [image].
  var keptTo = 0;

  /// Points in a kept piece.
  static const piece = 120;

  /// Points a piece goes back over the one before it, for a seamless join:
  /// each piece steadies its line afresh.
  static const overlap = 6;

  /// The most pixels [image] can have, if it covered the whole page.
  static const maxPixels = 10000000, maxSide = 4096;

  static _LongStroke? _current;

  void dispose() {
    image?.dispose();
    image = null;
  }

  /// Pixels per page unit: as on screen, unless an image of the whole page
  /// that size would be too big, so it never has to change size mid-stroke.
  late final double pixels = () {
    final page = stroke.page.size;
    // a whiteboard's page is 200000 units square: sized to all of it, the
    // image had about 0.016 pixels a unit and the line was a grey smudge
    // behind the pen. There it's as on screen, and [keep] stops at the
    // image size limit instead.
    if (page.width * page.height > 1e8) return min(scale, 4.0);
    final most = min(
      sqrt(maxPixels / max(page.width * page.height, 1)),
      maxSide / max(max(page.width, page.height), 1),
    );
    return min(scale, most);
  }();

  /// Adds a piece to [image]; false when the image would be too big
  /// (a line wandering far over a whiteboard), and the rest is drawn live.
  bool keep(Stroke piece) {
    final bounds = piece.bounds.inflate(piece.options.size + 2);
    final wanted = image == null ? bounds : area.expandToInclude(bounds);
    // whole pixels on a grid from the page's corner
    final left = (wanted.left * pixels).floorToDouble();
    final top = (wanted.top * pixels).floorToDouble();
    final right = (wanted.right * pixels).ceilToDouble();
    final bottom = (wanted.bottom * pixels).ceilToDouble();
    final width = (right - left).toInt(), height = (bottom - top).toInt();
    if (width <= 0 || height <= 0) return true;
    if (width > maxSide || height > maxSide || width * height > maxPixels) {
      return false;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (image case final old?) {
      // exactly where it was: no smoothing, a whole number of pixels over
      canvas.drawImage(
        old,
        Offset(
          (area.left * pixels).roundToDouble() - left,
          (area.top * pixels).roundToDouble() - top,
        ),
        Paint()..filterQuality = .none,
      );
    }
    canvas
      ..translate(-left, -top)
      ..scale(pixels);
    _drawInk(canvas, piece, Paint()..color = color);
    final picture = recorder.endRecording();
    LagRecorder.step('long stroke image');
    final made = picture.toImageSync(width, height);
    LagRecorder.step('long stroke image done');
    picture.dispose();
    image?.dispose();
    image = made;
    area = Rect.fromLTRB(
      left / pixels,
      top / pixels,
      right / pixels,
      bottom / pixels,
    );
    return true;
  }

  /// Draws [stroke] if it's long enough to draw in pieces; false if not.
  static bool drawn(
    Canvas canvas,
    Stroke stroke,
    Color color,
    double? pixelScale,
  ) {
    final live = Pen.currentStroke;
    final n = stroke.length;
    // a stroke finished (or its points taken back): its pieces go
    if (_current case final old?
        when !identical(old.stroke, live) ||
            (identical(stroke, live) && n < old.keptTo)) {
      release();
    }
    if (!identical(stroke, live) ||
        pixelScale == null ||
        !pixelScale.isFinite ||
        pixelScale <= 0 ||
        n < piece * 2 ||
        stroke.inkLine != .solid ||
        // see-through ink would show darker where the pieces overlap
        color.a < 1 ||
        stroke.options.isComplete) {
      return false;
    }
    var long = _current;
    if (long == null || long.color != color) {
      long?.dispose();
      long = _current = _LongStroke(stroke, color, pixelScale);
    }
    // keep a piece once there's a piece and more after it
    while (n - long.keptTo > piece + overlap * 2) {
      final from = max(long.keptTo - overlap, 0);
      final to = long.keptTo + piece;
      if (!long.keep(stroke.livePiece(from, to))) break;
      long.keptTo = to;
    }
    if (long.image case final image?) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        long.area,
        Paint()..filterQuality = .medium,
      );
    }
    _drawInk(
      canvas,
      stroke.livePiece(max(long.keptTo - overlap, 0), n),
      Paint()..color = color,
    );
    return true;
  }

  /// Lets go of the image once the stroke is done.
  static void release() {
    _current?.dispose();
    _current = null;
  }
}
