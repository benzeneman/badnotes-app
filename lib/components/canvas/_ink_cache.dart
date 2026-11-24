import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:logging/logging.dart';
import 'package:badnotes/data/lag_recorder.dart';
import 'package:badnotes/components/canvas/_stroke.dart';

/// Finished ink on a page, kept as pictures at the size it shows on screen.
///
/// Impeller has no raster cache, so without this every stroke on every visible
/// page was drawn again on every frame: while writing (for the stroke being
/// drawn on top), scrolling and zooming. Now a page draws one image per frame,
/// and a new stroke is drawn onto the last image instead of redrawing the page.
///
/// One per page widget, see [InnerCanvas]. Call [dispose] when it goes away.
class InkCache {

  static final log = Logger('InkCache');

  /// Largest image kept for a page, in pixels: 6M is a tablet's whole page at
  /// full width in landscape, about 24 MB. Zoomed in further than that, the
  /// strokes are drawn directly; only the visible ones are drawn then.
  static const maxPixels = 6000000;

  /// Longest side of an image, which every phone's GPU can hold.
  static const maxSide = 4096;

  final _layers = <int?, _LayerInk>{};

  /// Set when making an image failed, so it isn't tried on every frame.
  var _broken = false;

  /// Ticks when an image put off by [_FrameBudget] can be drawn: the page's
  /// ink painter listens to it to paint again.
  final retry = ValueNotifier(0);

  /// The size images are drawn at for [pixelScale]: in steps of about a fifth,
  /// rounded up so the ink is never blurry. Zooming a little, or back and
  /// forth, keeps the images it has instead of drawing every page again.
  static double renderScale(double pixelScale) => math
      .pow(2, (math.log(pixelScale) / math.ln2 * 4 - 1e-9).ceil() / 4)
      .toDouble();

  /// Whether the pages are being scrolled or zoomed. Zoomed in too far for an
  /// image of the whole page, the ink is then drawn from the biggest image
  /// that fits, a little soft, and sharp again once it stops: drawing every
  /// stroke on every frame of a pan made deep zoom stutter.
  static final moving = ValueNotifier(false);
  static Timer? _stopTimer;

  /// Whether the eraser is down: the ink changes on every frame then, and is
  /// drawn directly instead of onto a new image each time.
  static final erasing = ValueNotifier(false);

  /// Whether a pen or tool is down on a page: images aren't made then.
  static var penDown = false;

  /// Whether the zoom is changing (a pinch going on): tiles for the zoom
  /// shown aren't made then, those there are are stretched. Made at every
  /// step of a pinch, two at a time, most were thrown away a moment later
  /// and kept the GPU busy all through it.
  static var zooming = false;
  static Timer? _zoomTimer;

  /// Call on every frame the zoom changes.
  static void markZooming() {
    zooming = true;
    _zoomTimer?.cancel();
    _zoomTimer = Timer(const Duration(milliseconds: 120), () {
      zooming = false;
      _zoomStopped.value++;
    });
  }

  /// Ticks when the zoom stops changing, for pages to paint the tiles for it.
  static final _zoomStopped = ValueNotifier(0);
  static ValueListenable<int> get zoomStopped => _zoomStopped;

  /// Whether a page that isn't on screen yet already made its images in this
  /// frame. While the pages move, pages built ahead of the screen make their
  /// images one a frame: several at once held up a frame by 90 ms.
  static var _madeAheadThisFrame = false;

  /// Whether a page off screen may make its images now; if not, it's asked
  /// again ([retry]) next frame.
  bool mayMakeAhead() {
    if (!moving.value) return true;
    if (_madeAheadThisFrame) {
      SchedulerBinding.instance.addPostFrameCallback((_) => retry.value++);
      return false;
    }
    _madeAheadThisFrame = true;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _madeAheadThisFrame = false,
    );
    return true;
  }

  /// The part of the page being drawn into an image, in page units, while
  /// only part of it is: the painter draws only the pieces of big strokes
  /// there (see [Stroke.areaPieces]).
  static Rect? drawingArea;

  /// Pixels in a band of [inBands].
  static const bandPixels = 1500000;

  /// [strokes] drawn by [draw] into an image of the page at [key], a band
  /// at a time, one band a frame. Made in one go, an image of a page full of
  /// writing held the GPU, and every frame, for up to a second. Null if
  /// [stillWanted] turns false on the way.
  static Future<ui.Image?> inBands(
    (Size, double, bool) key,
    List<Stroke> strokes,
    void Function(Canvas canvas, List<Stroke> strokes) draw, {
    required bool Function() stillWanted,
  }) async {
    final (size, scale, _) = key;
    final width = (size.width * scale).ceil();
    final height = (size.height * scale).ceil();
    final rows = math.max(256, bandPixels ~/ math.max(width, 1));
    final bands = <(int, ui.Image)>[];
    try {
      for (var top = 0; top < height; top += rows) {
        if (!stillWanted()) return null;
        final rowsHere = math.min(rows, height - top);
        final area = Rect.fromLTWH(
          0,
          top / scale,
          size.width,
          rowsHere / scale,
        ).inflate(2 / scale);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)
          ..translate(0, -top.toDouble())
          ..scale(scale);
        drawingArea = area;
        try {
          draw(canvas, [
            for (final stroke in strokes)
              if (strokeArea(stroke).overlaps(area)) stroke,
          ]);
        } finally {
          drawingArea = null;
        }
        final picture = recorder.endRecording();
        try {
          bands.add((top, await picture.toImage(width, rowsHere)));
        } finally {
          picture.dispose();
        }
        // the next band in another frame
        await SchedulerBinding.instance.endOfFrame;
      }
      if (!stillWanted()) return null;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final (top, band) in bands) {
        canvas.drawImage(band, Offset(0, top.toDouble()), Paint());
      }
      final picture = recorder.endRecording();
      try {
        return await picture.toImage(width, height);
      } finally {
        picture.dispose();
      }
    } finally {
      for (final (_, band) in bands) {
        band.dispose();
      }
    }
  }

  /// Call on every scroll or zoom frame.
  static void markMoving() {
    LagRecorder.doing(
      'zoom or scroll',
      lasts: const Duration(milliseconds: 300),
    );
    if (!moving.value) moving.value = true;
    _stopTimer?.cancel();
    _stopTimer = Timer(const Duration(milliseconds: 180), () {
      moving.value = false;
    });
  }

  /// The biggest scale, in [renderScale]'s steps, that a page of [size] can
  /// be kept at.
  static double? largestScale(Size size) {
    final raw = math.min(
      math.sqrt(maxPixels / (size.width * size.height)),
      maxSide / math.max(size.width, size.height),
    );
    if (!raw.isFinite || raw <= 0) return null;
    return math
        .pow(2, (math.log(raw) / math.ln2 * 4 + 1e-9).floor() / 4)
        .toDouble();
  }

  /// Whether ink of a page of [size] can be kept at [pixelScale].
  bool canHold(Size size, double pixelScale) {
    if (_broken || !pixelScale.isFinite || pixelScale <= 0) return false;
    return _fits(size, renderScale(pixelScale));
  }

  /// Whether an image of a page of [size] at [scale] isn't too big.
  static bool _fits(Size size, double scale) {
    final width = size.width * scale, height = size.height * scale;
    return width * height <= maxPixels && math.max(width, height) <= maxSide;
  }

  /// The images for the ink of [layer] (or of all layers if null), and how
  /// many pixels they have for each unit of the page.
  ({InkLayer highlighter, InkLayer ink, InkLayer inkOver, double scale})?
  images({
    required int? layer,
    required Size size,
    required double pixelScale,
    required bool invert,
    required List<Stroke> highlighters,
    required List<Stroke> ink,
    required List<Stroke> inkOver,
    required void Function(Canvas canvas, List<Stroke> strokes)
    drawHighlighters,
    required void Function(Canvas canvas, List<Stroke> strokes) drawInk,
    void Function(Canvas canvas, List<(Stroke, int)> holes)?
    cutHighlighterHoles,
    bool tiled = false,
  }) {
    final entry = _layers.putIfAbsent(layer, () => _LayerInk(retry));
    // Images up to a quarter bigger than needed are kept: shrunk that little,
    // they look the same. Shrunk more, thin lines looked bolder.
    var scale = entry.scale;
    if (scale != null && moving.value) {
      // While a pinch or scroll goes on, the images it has are stretched,
      // with any changes since drawn over them: drawing the page again at
      // every step of a zoom made pages stutter, and with ink not yet in the
      // images (a pile of highlighters) the app stopped responding. Stretched
      // a good deal, the part of the page on screen is made sharp instead
      // ([view]): making all of the page again meanwhile, three images of up
      // to 6 million pixels, held up frames for 40 ms.
    } else if (tiled && scale != null && scale < pixelScale) {
      // Zoomed in: tiles are drawn over them where they're stretched, and
      // the images are only for under those not made yet. Made again at
      // every zoom, up to three images of 6 million pixels, they hitched.
    } else if (scale == null ||
        scale < pixelScale * 0.999 ||
        scale > pixelScale * 1.25) {
      var wanted = renderScale(
        scale == null && moving.value ? pixelScale / 2 : pixelScale,
      );
      if (tiled && scale == null) {
        // only under the tiles not made yet: small, so a page scrolled into
        // view zoomed in doesn't hold up the scroll making a big image
        wanted = math.min(
          wanted,
          renderScale(math.sqrt(1500000 / (size.width * size.height))),
        );
      }
      // Only the size changed: made in the background, and swapped in when
      // ready. Made right away, the frame the fingers lifted on hitched.
      final background =
          scale != null &&
          entry.sharpen(
            (size, wanted, invert),
            [
              (entry.highlighter, highlighters, drawHighlighters),
              (entry.ink, ink, drawInk),
              (entry.inkOver, inkOver, drawInk),
            ],
          );
      // A page scrolled into view is drawn at half the size first, a quarter
      // of the pixels, and sharp once the pages stop: drawing each new page
      // whole held up the scroll.
      if (!background) scale = wanted;
    }
    try {
      // A page only changing size has its old images drawn bigger or smaller
      // for a frame or two, when several pages need drawing at once.
      final waits =
          entry.scale != null &&
          entry.scale != scale &&
          !_FrameBudget.take() &&
          entry.highlighter.couldResize(size, invert, highlighters) &&
          entry.ink.couldResize(size, invert, ink) &&
          entry.inkOver.couldResize(size, invert, inkOver);
      if (waits) {
        _FrameBudget.later(retry);
        InkLayer only(ui.Image? image) => (
          image: image,
          hole: null,
          outsideHole: null,
          inHole: const <Stroke>[],
          over: const <Stroke>[],
          newHoles: const <(Stroke, int)>[],
        );
        return (
          highlighter: only(entry.highlighter.image),
          ink: only(entry.ink.image),
          inkOver: only(entry.inkOver.image),
          scale: entry.scale!,
        );
      }
      final key = (size, scale, invert);
      entry.scale = scale;
      return (
        highlighter: entry.highlighter.update(
          key,
          highlighters,
          drawHighlighters,
          cutHoles: cutHighlighterHoles,
        ),
        ink: entry.ink.update(key, ink, drawInk),
        inkOver: entry.inkOver.update(key, inkOver, drawInk),
        scale: scale,
      );
    } catch (e, stack) {
      log.warning(
        'Drawing ink to an image failed, drawing it directly',
        e,
        stack,
      );
      _broken = true;
      dispose();
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Tiles. Zoomed in past the images of the whole page (too big for an
  // image, or shown stretched), the ink on screen is drawn from tiles: 512
  // pixel squares of the page at the zoom shown (in steps of half a power
  // of two), each with only the strokes on it, made in the background two
  // at a time. Drawing all the ink on every frame, or making images of the
  // whole page again, took 30-60 ms on a tablet. A tile not made yet shows
  // a coarser tile, or else the image of the whole page, stretched.

  /// Ticks when the part of the page on screen moves while tiles are shown,
  /// for the page to paint the tiles there (and ask for the missing ones).
  final viewMoved = ValueNotifier(0);
  ValueNotifier<Rect?>? _visible;
  final _tiles = <(int?, bool), _Tiles>{};

  /// Whether the last paint drew tiles.
  var _tiled = false;

  /// Follows [visibleArea], the part of the page on screen.
  void follow(ValueNotifier<Rect?> visibleArea) {
    if (identical(visibleArea, _visible)) return;
    _visible?.removeListener(_visibleChanged);
    _visible = visibleArea..addListener(_visibleChanged);
  }

  void _visibleChanged() {
    if (_tiled && _visible?.value != null) viewMoved.value++;
  }

  /// Pixels across a tile.
  static const tilePixels = 512;

  /// How many tiles were asked to be made, for tests.
  @visibleForTesting
  static var tilesMade = 0;

  /// The pixels per page unit tiles are made at for [pixelScale]: in steps
  /// of half a power of two, never more than one step bigger.
  static double tileScale(double pixelScale) => math
      .pow(2, (math.log(pixelScale / 1.02) / math.ln2 * 2).ceil() / 2)
      .toDouble();

  /// Where a stroke draws, generously, for which tiles it's on.
  static Rect strokeArea(Stroke stroke) {
    final known = _strokeAreas[stroke];
    if (known != null && known.$1 == stroke.version) return known.$2;
    final area = stroke.bounds.inflate(math.max(stroke.options.size, 4) + 4);
    _strokeAreas[stroke] = (stroke.version, area);
    return area;
  }

  static final _strokeAreas = Expando<(int, Rect)>();

  /// Whether there are images of the whole page of [layer] yet.
  bool hasImages(int? layer) => _layers[layer]?.scale != null;

  /// Whether the images of the whole page of [layer] are shown stretched at
  /// [pixelScale]: tiles are drawn then, see [tiles].
  bool stretched(int? layer, double pixelScale) {
    final have = _layers[layer]?.scale;
    return have != null && renderScale(pixelScale) > have * 1.01;
  }

  /// The tiles to draw for [visible], the part of the page on screen, at
  /// [pixelScale]; tiles missing are asked for. [strokes] are all the ink,
  /// in the order drawn; [draw] draws those of them on [area] onto a canvas
  /// in page units at the given pixels per unit.
  ({List<TileDraw> draws, Path covered, bool all}) tiles({
    required int? layer,
    required bool invert,
    required Size size,
    required Rect visible,
    required double pixelScale,
    required List<Stroke> strokes,
    required void Function(Canvas canvas, double scale, Rect area) draw,
  }) {
    _tiled = true;
    final tiles = _tiles.putIfAbsent((layer, invert), () => _Tiles(retry));
    return tiles.paint(size, visible, pixelScale, strokes, draw);
  }

  /// Not zoomed in past the whole page's images any more: the tiles go.
  void wholePages() {
    if (!_tiled) return;
    _tiled = false;
    for (final tiles in _tiles.values) {
      tiles.dispose();
    }
    _tiles.clear();
  }

  /// Lets go of the images, for when they can't be used for a while.
  void dispose() {
    _visible?.removeListener(_visibleChanged);
    _visible = null;
    for (final tiles in _tiles.values) {
      tiles.dispose();
    }
    _tiles.clear();
    for (final entry in _layers.values) {
      entry.dispose();
    }
    _layers.clear();
  }
}

/// A tile to draw: [image]'s part [from] at [to] on the page, then [over]
/// on top as they are; or, with no image ([direct]), the ink on [to] as it
/// is. See [InkCache.tiles].
typedef TileDraw = ({
  ui.Image? image,
  Rect from,
  Rect to,
  List<Stroke> over,
  bool direct,
});

/// One tile of [_Tiles]: its image, once made, and the strokes on it.
class _Tile {
  _Tile(this.area);

  final Rect area;
  ui.Image? image;
  var strokes = const <Stroke>[];
  var versions = const <int>[];
  var making = false;

  /// Used to keep the tiles last looked at, see [_Tiles._trim].
  var lastUsed = 0;

  bool shows(List<Stroke> on) =>
      image != null && on.length == strokes.length && startOf(on);

  /// Whether the strokes on the image are the first of [on], unchanged.
  bool startOf(List<Stroke> on) {
    if (image == null || on.length < strokes.length) return false;
    for (int i = 0; i < strokes.length; i++) {
      if (!identical(on[i], strokes[i]) || on[i].version != versions[i]) {
        return false;
      }
    }
    return true;
  }

  void dispose() {
    image?.dispose();
    image = null;
  }
}

/// The tiles of the ink of a page, see [InkCache.tiles].
class _Tiles {
  _Tiles(this.ready);

  /// Ticked when a tile is made.
  final ValueNotifier<int> ready;

  /// By scale, then by column and row.
  final _levels = <double, Map<(int, int), _Tile>>{};
  var _paints = 0;
  var _disposed = false;

  /// The tiles' scale on the last paint, to tell zooming in from out.
  double? _lastScale;
  var _zoomingIn = false;

  /// Tiles being made, across all pages: each is a little work for the GPU,
  /// and many at once held up frames.
  static var _making = 0;
  // Four since pens are drawn as triangles ([Stroke.inkVertices]): a tile
  // is quick to make now, and two at a time left a zoomed page blurry for a
  // second or two.
  static const _atOnce = 4;

  /// Tiles kept for a page, about a megabyte each.
  static const _kept = 40;

  ({List<TileDraw> draws, Path covered, bool all}) paint(
    Size size,
    Rect visible,
    double pixelScale,
    List<Stroke> strokes,
    void Function(Canvas canvas, double scale, Rect area) draw,
  ) {
    _paints++;
    final scale = InkCache.tileScale(pixelScale);
    final side = InkCache.tilePixels / scale;
    final page = Offset.zero & size;
    final view = visible.intersect(page);
    final draws = <TileDraw>[];
    final covered = Path();
    if (view.isEmpty) return (draws: draws, covered: covered, all: true);

    // the strokes on screen, once, then those on each tile
    final onScreen = <(Stroke, Rect)>[
      for (final stroke in strokes)
        if (InkCache.strokeArea(stroke).overlaps(view))
          (stroke, InkCache.strokeArea(stroke)),
    ];
    List<Stroke> on(Rect area) => [
      for (final (stroke, at) in onScreen)
        if (at.overlaps(area)) stroke,
    ];

    final level = _levels.putIfAbsent(scale, () => {});
    final x0 = (view.left / side).floor(),
        x1 = ((view.right - 1e-6) / side).floor();
    final y0 = (view.top / side).floor(),
        y1 = ((view.bottom - 1e-6) / side).floor();
    var all = true;
    final wanted = <_Tile>[];
    for (int y = y0; y <= y1; y++) {
      for (int x = x0; x <= x1; x++) {
        final area = Rect.fromLTWH(
          x * side,
          y * side,
          side,
          side,
        ).intersect(page);
        if (area.isEmpty) continue;
        final tile = level.putIfAbsent((x, y), () => _Tile(area));
        tile.lastUsed = _paints;
        final want = on(area);
        final pixels = Rect.fromLTWH(
          0,
          0,
          area.width * scale,
          area.height * scale,
        );
        if (tile.startOf(want)) {
          // and any strokes written on it since, as they are, till it's
          // made again
          draws.add((
            image: tile.image!,
            from: pixels,
            to: area,
            over: want.sublist(tile.strokes.length),
            direct: false,
          ));
          covered.addRect(area);
          if (want.length != tile.strokes.length && !tile.making) {
            wanted.add(tile);
          }
          continue;
        }
        if (!tile.making) wanted.add(tile);
        if (tile.image != null) {
          // erased, moved or undone there: the ink there as it is, till it's
          // made again (a coarser tile would blur it for a moment)
          draws.add((
            image: null,
            from: pixels,
            to: area,
            over: const <Stroke>[],
            direct: true,
          ));
          covered.addRect(area);
          continue;
        }
        // not made yet: a coarser tile meanwhile, if one is there and right
        final coarser = _coarser(scale, area, on);
        if (coarser != null) {
          draws.add(coarser);
          covered.addRect(area);
        } else {
          all = false;
        }
      }
    }

    // nearest the middle of the screen first
    final middle = view.center;
    wanted.sort(
      (a, b) => (a.area.center - middle).distanceSquared.compareTo(
        (b.area.center - middle).distanceSquared,
      ),
    );
    // While zooming in, one at a time, for the zoom shown: made only once
    // the zoom stopped, the ink stayed blurry all through a pinch. Zooming
    // out, the finer tiles there are do.
    // the same zoom as the last paint: only scrolling or panning
    final panning = _lastScale == scale;
    if (_lastScale case final last? when last != scale) {
      _zoomingIn = scale > last;
    }
    _lastScale = scale;
    final zoomingIn = InkCache.zooming && _zoomingIn;
    // Scrolling, none: each new tile drew its strokes in the frame, two a
    // frame all through a scroll (10 ms of a frame on a tablet). The page's
    // whole image (or a coarser tile) shows meanwhile, and the tiles come
    // once it stops.
    final atOnce = InkCache.zooming
        ? (zoomingIn ? 2 : 0)
        : InkCache.moving.value && panning
        ? 0
        // erasing changes tiles on every move: one at a time then, four
        // made again each move of the eraser held it up
        : InkCache.erasing.value
        ? 1
        : _atOnce;
    for (final tile in wanted) {
      if (_making >= atOnce) break;
      _make(tile, scale, on(tile.area), draw);
    }
    _trim(scale);
    return (draws: draws, covered: covered, all: all);
  }

  /// The part of a tile at a smaller scale that covers [area], if it shows
  /// the strokes there as they are.
  TileDraw? _coarser(
    double scale,
    Rect area,
    List<Stroke> Function(Rect area) on,
  ) {
    // While writing (pen down, not zooming or scrolling): at most twice as
    // coarse. A whiteboard's sheet is so big that its zoomed-out tiles are
    // tiny, and one stretched over just-written ink showed it as a grey
    // smudge until its own tile was made; without one close enough, the
    // ink there is drawn as it is (sharp) meanwhile. Otherwise any coarser
    // tile does, as before: drawing a whole board's ink on every frame of a
    // pinch took the GPU 50-300 ms a frame.
    final writing =
        InkCache.penDown && !InkCache.zooming && !InkCache.moving.value;
    final scales = _levels.keys
        .where((s) => s < scale && (!writing || s * 2 >= scale))
        .toList()
      ..sort((a, b) => b.compareTo(a));
    for (final s in scales) {
      final side = InkCache.tilePixels / s;
      final key = ((area.left / side).floor(), (area.top / side).floor());
      final tile = _levels[s]![key];
      if (tile == null || tile.image == null) continue;
      if (!tile.area.contains(area.topLeft) ||
          tile.area.right < area.right - 1e-6 ||
          tile.area.bottom < area.bottom - 1e-6) {
        continue;
      }
      if (!tile.shows(on(tile.area))) continue;
      tile.lastUsed = _paints;
      final from = area.shift(-tile.area.topLeft);
      return (
        image: tile.image!,
        from: Rect.fromLTWH(
          from.left * s,
          from.top * s,
          from.width * s,
          from.height * s,
        ),
        to: area,
        over: const <Stroke>[],
        direct: false,
      );
    }
    return null;
  }

  void _make(
    _Tile tile,
    double scale,
    List<Stroke> strokes,
    void Function(Canvas canvas, double scale, Rect area) draw,
  ) {
    final area = tile.area;
    final width = math.max(1, (area.width * scale).round());
    final height = math.max(1, (area.height * scale).round());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(scale)
      ..translate(-area.left, -area.top)
      ..clipRect(area);
    draw(canvas, scale, area);
    final picture = recorder.endRecording();
    final kept = List.of(strokes);
    final versions = [for (final stroke in kept) stroke.version];
    tile.making = true;
    _making++;
    InkCache.tilesMade++;
    LagRecorder.addSpan('a tile into an image (background)', 0);
    picture
        .toImage(width, height)
        .then((image) {
          if (_disposed) {
            image.dispose();
            return;
          }
          tile.image?.dispose();
          tile.image = image;
          tile.strokes = kept;
          tile.versions = versions;
          ready.value++;
        })
        .catchError((Object e, StackTrace stack) {
          InkCache.log.warning('Making a tile failed', e, stack);
        })
        .whenComplete(() {
          picture.dispose();
          tile.making = false;
          _making--;
          // the next ones
          if (!_disposed) ready.value++;
        });
  }

  /// Lets go of the tiles looked at longest ago, past [_kept]; those at
  /// [scale] last.
  void _trim(double scale) {
    var count = 0;
    for (final level in _levels.values) {
      count += level.length;
    }
    if (count <= _kept) return;
    final all =
        <(double, (int, int), _Tile)>[
          for (final MapEntry(key: s, value: level) in _levels.entries)
            for (final MapEntry(key: key, value: tile) in level.entries)
              // not one being made, or drawn on this paint
              if (!tile.making && tile.lastUsed != _paints) (s, key, tile),
        ]..sort((a, b) {
          final atA = a.$1 == scale ? 1 : 0, atB = b.$1 == scale ? 1 : 0;
          if (atA != atB) return atA - atB;
          return a.$3.lastUsed.compareTo(b.$3.lastUsed);
        });
    for (final (s, key, tile) in all.take(math.max(0, count - _kept))) {
      tile.dispose();
      _levels[s]!.remove(key);
    }
  }

  void dispose() {
    _disposed = true;
    for (final level in _levels.values) {
      for (final tile in level.values) {
        tile.dispose();
      }
    }
    _levels.clear();
  }
}

/// How many pages may be drawn again at a new size in one frame. After a zoom,
/// every visible page needed drawing again in the same frame, which stuttered.
abstract final class _FrameBudget {
  static const _perFrame = 1;
  static var _used = 0;
  static var _resetScheduled = false;
  static final _waiting = <ValueNotifier<int>>{};

  /// Whether a page can be drawn now. Counts it if so.
  static bool take() {
    _scheduleReset();
    if (_used >= _perFrame) return false;
    _used++;
    return true;
  }

  /// Ticks [retry] once the next frame can draw more.
  static void later(ValueNotifier<int> retry) {
    _waiting.add(retry);
    _scheduleReset();
  }

  static void _scheduleReset() {
    if (_resetScheduled) return;
    _resetScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _resetScheduled = false;
      _used = 0;
      final waiting = List.of(_waiting);
      _waiting.clear();
      for (final retry in waiting) {
        retry.value++;
      }
      if (waiting.isNotEmpty) SchedulerBinding.instance.scheduleFrame();
    });
  }
}

typedef _Key = (Size size, double pixelScale, bool invert);

typedef _Looks = ({
  List<List<({Offset center, double radius})>> holes,
  List<({Object lineage, int points, double size, Color color, bool flatEnds})>
  looks,
});

class _LayerInk {
  _LayerInk(ValueNotifier<int> retry)
    : highlighter = _InkImage(retry),
      ink = _InkImage(retry),
      inkOver = _InkImage(retry);

  final _InkImage highlighter;

  /// Ink under the highlighters, and ink written after them, over them.
  final _InkImage ink, inkOver;

  /// Pixels per unit of the page of both images, once drawn.
  double? scale;

  /// The size [sharpen] is making images at, and which try it is.
  _Key? _sharpening;
  var _sharpenTry = 0;

  /// Makes all the images again at [key]'s size, off the frame, and swaps
  /// them in at once when they're all ready, if the ink hasn't changed
  /// meanwhile. For zooming: the images it has are shown stretched until
  /// then.
  bool sharpen(
    _Key key,
    List<
      (
        _InkImage image,
        List<Stroke> strokes,
        void Function(Canvas canvas, List<Stroke> strokes) draw,
      )
    >
    parts,
  ) {
    if (_sharpening == key) return true;
    if (!InkCache._fits(key.$1, key.$2)) return false;
    for (final (image, strokes, _) in parts) {
      if (!image.couldResize(key.$1, key.$3, strokes)) return false;
    }
    _sharpening = key;
    final attempt = ++_sharpenTry;
    final (_, pixels, _) = key;
    final made =
        <
          (
            _InkImage,
            List<Stroke>,
            int,
            void Function(Canvas canvas, List<Stroke> strokes),
          )
        >[];
    for (final (image, strokes, draw) in parts) {
      if (strokes.isEmpty) continue;
      made.add((image, List.of(strokes), image._generation, draw));
    }
    LagRecorder.addSpan('sharper images for the zoom (background)', 0);
    // One after another, not all at once: each is several frames' worth of
    // drawing for the GPU.
    Future<void> makeAll() async {
      final images = <ui.Image>[];
      try {
        for (final part in made) {
          if (attempt != _sharpenTry) break;
          final image = await InkCache.inBands(
            key,
            part.$2,
            part.$4,
            stillWanted: () => attempt == _sharpenTry,
          );
          if (image == null) break;
          images.add(image);
        }
        final current =
            images.length == made.length &&
            attempt == _sharpenTry &&
            made.every(
              (part) =>
                  part.$1._generation == part.$3 &&
                  part.$1.couldResize(key.$1, key.$3, part.$2),
            );
        if (!current) {
          for (final image in images) {
            image.dispose();
          }
          return;
        }
        for (int i = 0; i < made.length; i++) {
          made[i].$1._set(images[i], key, made[i].$2);
        }
        scale = pixels;
        made.firstOrNull?.$1.retry.value++;
      } catch (e, stack) {
        for (final image in images) {
          image.dispose();
        }
        InkCache.log.warning('Making sharper images failed', e, stack);
      } finally {
        if (attempt == _sharpenTry) _sharpening = null;
      }
    }

    unawaited(makeAll());
    return true;
  }

  void dispose() {
    _sharpenTry++;
    _sharpening = null;
    highlighter.dispose();
    ink.dispose();
    inkOver.dispose();
    scale = null;
  }
}

/// What a layer's ink is drawn from: [image], except inside [hole], where
/// [inHole] are drawn as they are; then [over] on top. [newHoles]: holes the
/// eraser cut since the image was made, each stroke's from the index given,
/// to be cleared out of the image (highlighters only).
typedef InkLayer = ({
  ui.Image? image,
  Path? hole,
  Path? outsideHole,
  List<Stroke> inHole,
  List<Stroke> over,
  List<(Stroke, int)> newHoles,
});

const InkLayer _noInk = (
  image: null,
  hole: null,
  outsideHole: null,
  inHole: <Stroke>[],
  over: <Stroke>[],
  newHoles: <(Stroke, int)>[],
);

/// One image of strokes, and which strokes are on it.
///
/// The image isn't drawn again while the ink changes:
/// - a stroke added on top is drawn over it, as it is;
/// - where strokes were erased, moved or undone, squares of the page (a
///   [cells] by [cells] grid) are cut out of it and the strokes there drawn
///   as they are, the way OneNote and Rnote draw in tiles.
/// Once the pen has rested, the changes go into a new image in the
/// background. Drawing the whole page into an image as the pen or eraser
/// lifted, and every stroke on the page on every frame of erasing, made a
/// full page lag.
class _InkImage {
  _InkImage(this.retry);

  /// Ticked when a background image is ready, to paint it.
  final ValueNotifier<int> retry;

  ui.Image? _image;
  _Key? _key;
  var _strokes = const <Stroke>[];
  var _versions = const <int>[];

  /// Where each stroke on the image was drawn, for when it changes later.
  var _areas = Expando<Rect>();

  /// Squares across (and down, of the same size) the page is cut into.
  static const cells = 24;

  /// The holes and look of each stroke on the image, see [_grownHoles].
  var _holes = const <List<({Offset center, double radius})>>[];
  var _looks =
      const <
        ({Object lineage, int points, double size, Color color, bool flatEnds})
      >[];

  /// Clears holes out of a layer: set for the highlighters' image, whose
  /// holes go through all of them. Null for ink.
  void Function(Canvas canvas, List<(Stroke, int)> holes)? _holesCut;

  /// Holes cut since the image was made, see [_grownHoles].
  var _grown = const <(Stroke, int)>[];

  /// What [update] last gave, put into a new image by [_bake].
  List<Stroke> _latest = const [];
  Set<int> _dirty = const {};
  void Function(Canvas canvas, List<Stroke> strokes)? _draw;
  Timer? _bakeTimer;
  var _generation = 0;

  /// More strokes than this drawn as they are go into the image soon, even
  /// while writing: each one costs a little on every frame the page paints.
  static const _maxLoose = 40;

  ui.Image? get image => _image;

  /// Whether this image shows exactly [strokes], with nothing changed but the
  /// size it's drawn at: then it can stand in for a frame, shrunk or grown.
  bool couldResize(Size size, bool invert, List<Stroke> strokes) {
    final key = _key;
    if (strokes.isEmpty) return _image == null;
    return _image != null &&
        key != null &&
        key.$1 == size &&
        key.$3 == invert &&
        strokes.length == _strokes.length &&
        _startsWith(strokes);
  }

  /// How to draw [strokes]: see [InkLayer].
  InkLayer update(
    _Key key,
    List<Stroke> strokes,
    void Function(Canvas canvas, List<Stroke> strokes) draw, {
    void Function(Canvas canvas, List<(Stroke, int)> holes)? cutHoles,
  }) {
    if (strokes.isEmpty) {
      dispose();
      return _noInk;
    }

    _holesCut = cutHoles;
    final old = _image;
    if (old != null && key == _key) {
      _draw = draw;
      _latest = strokes;
      _grown = const [];
      if (_grownHoles(strokes) case final grown?) {
        _dirty = const {};
        if (grown.isNotEmpty) {
          _grown = grown;
          _scheduleHolesBake();
        }
        return (
          image: old,
          hole: null,
          outsideHole: null,
          inHole: const [],
          over: const [],
          newHoles: grown,
        );
      }
      if (_startsWith(strokes)) {
        // only added on top
        _dirty = const {};
        final over = strokes.length == _strokes.length
            ? const <Stroke>[]
            : strokes.sublist(_strokes.length);
        _scheduleBake(over.length);
        return (
          image: old,
          hole: null,
          outsideHole: null,
          inHole: const [],
          over: over,
          newHoles: const [],
        );
      }
      final dirty = _changedCells(strokes);
      if (dirty != null) {
        _dirty = dirty;
        final inHole = [
          for (final stroke in strokes)
            if (_touches(_area(stroke), dirty)) stroke,
        ];
        _scheduleBake(inHole.length);
        final hole = _cellsPath(dirty);
        return (
          image: old,
          hole: hole,
          outsideHole: Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(Offset.zero & key.$1)
            ..addPath(hole, Offset.zero),
          inHole: inHole,
          over: const [],
          newHoles: const [],
        );
      }
    }

    // a new size, or the order changed: the whole page again
    final (size, scale, _) = key;
    final picture = _record(key, null, strokes, draw);
    final ui.Image image;
    try {
      LagRecorder.step('page into an image');
      image = LagRecorder.span(
        'whole page into an image',
        () => picture.toImageSync(
          (size.width * scale).ceil(),
          (size.height * scale).ceil(),
        ),
      );
    } finally {
      picture.dispose();
    }
    _set(image, key, strokes);
    return (
      image: image,
      hole: null,
      outsideHole: null,
      inHole: const [],
      over: const [],
      newHoles: const [],
    );
  }

  /// When only holes were cut since the image was made (the precise eraser
  /// on highlighters): for each stroke with new holes, it and how many
  /// holes it had on the image. Null if anything else changed.
  ///
  /// Then the image stays, with the new holes cleared out of it on screen,
  /// and they go into it a few times a second while erasing. Drawn as
  /// changed strokes instead, every highlighter there and all its holes
  /// were drawn again on every frame: 12 to 30 ms a frame on a phone.
  List<(Stroke, int)>? _grownHoles(List<Stroke> strokes) {
    if (_holesCut == null || strokes.length != _strokes.length) return null;
    final grown = <(Stroke, int)>[];
    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i], was = _strokes[i];
      if (identical(stroke, was) && stroke.version == _versions[i]) continue;
      final look = _looks[i], holes = _holes[i], now = stroke.holes;
      if (!identical(stroke.lineage, look.lineage) ||
          stroke.length != look.points ||
          stroke.options.size != look.size ||
          stroke.color != look.color ||
          stroke.flatEnds != look.flatEnds ||
          now.length <= holes.length ||
          (holes.isNotEmpty && now[holes.length - 1] != holes.last)) {
        return null;
      }
      grown.add((stroke, holes.length));
    }
    return grown;
  }

  /// Takes note of how [strokes] look on the image, for [_grownHoles].
  void _noteLooks(List<Stroke> strokes) => _setLooks(_looksOf(strokes));

  /// How [strokes] look now. Taken as an image starts being made from
  /// them: the eraser goes on cutting holes while it's made in the
  /// background, and holes taken as in the image when it was ready, but
  /// cut after it was started, were never drawn: the eraser's line had
  /// bits left uncut along it.
  static _Looks _looksOf(List<Stroke> strokes) => (
    holes: [for (final stroke in strokes) stroke.holes],
    looks: [
      for (final stroke in strokes)
        (
          lineage: stroke.lineage,
          points: stroke.length,
          size: stroke.options.size,
          color: stroke.color,
          flatEnds: stroke.flatEnds,
        ),
    ],
  );

  void _setLooks(_Looks looks) {
    _holes = looks.holes;
    _looks = looks.looks;
  }

  static ui.Picture _record(
    _Key key,
    ui.Image? under,
    List<Stroke> strokes,
    void Function(Canvas canvas, List<Stroke> strokes) draw,
  ) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (under != null) canvas.drawImage(under, Offset.zero, Paint());
    canvas.scale(key.$2);
    draw(canvas, strokes);
    return recorder.endRecording();
  }

  void _set(ui.Image image, _Key key, List<Stroke> strokes) {
    _bakeTimer?.cancel();
    _generation++;
    _image?.dispose();
    _image = image;
    _key = key;
    _strokes = List.of(strokes);
    _versions = [for (final stroke in strokes) stroke.version];
    _areas = Expando();
    for (final stroke in strokes) {
      _areas[stroke] = _area(stroke);
    }
    _noteLooks(strokes);
    _latest = const [];
    _dirty = const {};
    _grown = const [];
  }

  /// Where [stroke] draws as it is now, generously. Kept for each version:
  /// asked of every stroke on every frame of erasing.
  Rect _area(Stroke stroke) {
    final known = _areaNow[stroke];
    if (known != null && known.$1 == stroke.version) return known.$2;
    final area = stroke.bounds.inflate(math.max(stroke.options.size, 4) + 4);
    _areaNow[stroke] = (stroke.version, area);
    return area;
  }

  final _areaNow = Expando<(int, Rect)>();

  double get _cell => _key!.$1.width / cells;

  /// Calls [each] with every square [rect] covers.
  void _forCells(Rect rect, void Function(int cell) each) {
    final cell = _cell;
    final rows = (_key!.$1.height / cell).ceil();
    final left = math.max(0, (rect.left / cell).floor());
    final right = math.min(cells - 1, (rect.right / cell).floor());
    final top = math.max(0, (rect.top / cell).floor());
    final bottom = math.min(rows - 1, (rect.bottom / cell).floor());
    for (int y = top; y <= bottom; y++) {
      for (int x = left; x <= right; x++) {
        each(y * cells + x);
      }
    }
  }

  bool _touches(Rect rect, Set<int> dirty) {
    var touches = false;
    _forCells(rect, (cell) => touches = touches || dirty.contains(cell));
    return touches;
  }

  /// The squares where the image is wrong for [strokes], or null if the
  /// strokes that stayed changed order.
  Set<int>? _changedCells(List<Stroke> strokes) {
    final old = Map<Stroke, int>.identity();
    for (int i = 0; i < _strokes.length; i++) {
      // a stroke changed since is as good as removed
      old[_strokes[i]] = _versions[i] == _strokes[i].version ? i : -1;
    }
    final dirty = <int>{};
    var lastIndex = -1;
    final kept = Set<Stroke>.identity();
    for (final stroke in strokes) {
      final index = old[stroke];
      if (index != null && index >= 0) {
        if (index < lastIndex) return null;
        lastIndex = index;
        kept.add(stroke);
      } else {
        _forCells(_area(stroke), dirty.add);
      }
    }
    for (final stroke in _strokes) {
      if (kept.contains(stroke)) continue;
      // where it was when it went onto the image
      _forCells(_areas[stroke] ?? _area(stroke), dirty.add);
    }
    return dirty;
  }

  /// [dirty] as one shape, in rows of squares side by side.
  Path _cellsPath(Set<int> dirty) {
    final cell = _cell;
    final path = Path();
    final sorted = dirty.toList()..sort();
    var i = 0;
    while (i < sorted.length) {
      final start = sorted[i];
      var end = start;
      while (i + 1 < sorted.length &&
          sorted[i + 1] == end + 1 &&
          (end + 1) % cells != 0) {
        end = sorted[++i];
      }
      i++;
      final y = start ~/ cells;
      path.addRect(
        Rect.fromLTRB(
          (start % cells) * cell,
          y * cell,
          (end % cells + 1) * cell,
          (y + 1) * cell,
        ),
      );
    }
    return path;
  }

  void _scheduleBake(int loose) {
    _bakeTimer?.cancel();
    if (loose == 0 && _dirty.isEmpty && _latest.length == _strokes.length) {
      return;
    }
    _bakeTimer = Timer(
      Duration(milliseconds: loose >= _maxLoose ? 60 : 450),
      _bake,
    );
  }

  /// New holes go into the image while erasing too, a few times a second, so
  /// the ones cleared on screen stay few. The timer isn't put off by each
  /// move of the eraser, or it would never go off while erasing.
  void _scheduleHolesBake() {
    if (_bakeTimer?.isActive ?? false) return;
    _bakeTimer = Timer(const Duration(milliseconds: 120), _bake);
  }

  /// Puts the changes into a new image, off the frame.
  void _bake() {
    final old = _image, key = _key, draw = _draw;
    if (old == null || key == null || draw == null) return;
    final strokes = List.of(_latest);
    final grown = _grown, cutHoles = _holesCut;
    if (grown.isNotEmpty && cutHoles != null) {
      final generation = _generation;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImage(old, Offset.zero, Paint());
      canvas.scale(key.$2);
      cutHoles(canvas, grown);
      final picture = recorder.endRecording();
      final versions = [for (final stroke in strokes) stroke.version];
      final looks = _looksOf(strokes);
      LagRecorder.addSpan('holes into the image (background)', 0);
      picture
          .toImage(old.width, old.height)
          .then((image) {
            if (generation != _generation || !identical(old, _image)) {
              image.dispose();
              return;
            }
            old.dispose();
            _image = image;
            _strokes = strokes;
            _versions = versions;
            _setLooks(looks);
            _grown = const [];
            retry.value++;
          })
          .catchError((Object e, StackTrace stack) {
            InkCache.log.warning(
              'Baking holes in the background failed',
              e,
              stack,
            );
          })
          .whenComplete(picture.dispose);
      return;
    }
    final dirty = _dirty;
    final added = _startsWith(strokes)
        ? strokes.sublist(_strokes.length)
        : const <Stroke>[];
    if (dirty.isEmpty && added.isEmpty) return;
    final loose = _latest.length - _strokes.length;
    if (InkCache.penDown && dirty.isEmpty && loose < _maxLoose) {
      // not while writing or erasing: the next frame would hitch
      _scheduleBake(loose);
      return;
    }
    final versions = [for (final stroke in strokes) stroke.version];
    final looks = _looksOf(strokes);
    final generation = _generation;
    final ui.Picture picture;
    if (dirty.isEmpty) {
      picture = _record(key, old, added, draw);
    } else {
      final scale = key.$2;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImage(old, Offset.zero, Paint());
      canvas.scale(scale);
      final cellsPath = _cellsPath(dirty);
      canvas.clipPath(cellsPath, doAntiAlias: false);
      canvas.drawColor(const Color(0x00000000), BlendMode.clear);
      // only the pieces of big strokes where the changes are
      InkCache.drawingArea = cellsPath.getBounds();
      try {
        draw(canvas, [
          for (final stroke in strokes)
            if (_touches(_area(stroke), dirty)) stroke,
        ]);
      } finally {
        InkCache.drawingArea = null;
      }
      picture = recorder.endRecording();
    }
    LagRecorder.addSpan('changes into the image (background)', 0);
    picture
        .toImage(old.width, old.height)
        .then((image) {
          if (generation != _generation || !identical(old, _image)) {
            image.dispose();
            return;
          }
          // Changes since are found again on the next frame.
          old.dispose();
          _image = image;
          _strokes = strokes;
          _versions = versions;
          for (final stroke in strokes) {
            _areas[stroke] = _area(stroke);
          }
          _setLooks(looks);
          _dirty = const {};
          retry.value++;
        })
        .catchError((Object e, StackTrace stack) {
          InkCache.log.warning('Baking ink in the background failed', e, stack);
        })
        .whenComplete(picture.dispose);
  }

  /// Whether [strokes] starts with the strokes on the image, all unchanged.
  bool _startsWith(List<Stroke> strokes) {
    if (strokes.length < _strokes.length) return false;
    for (int i = 0; i < _strokes.length; i++) {
      if (!identical(strokes[i], _strokes[i])) return false;
      if (strokes[i].version != _versions[i]) return false;
    }
    return true;
  }

  void dispose() {
    _bakeTimer?.cancel();
    _generation++;
    _image?.dispose();
    _image = null;
    _key = null;
    _strokes = const [];
    _versions = const [];
    _areas = Expando();
    _holes = const [];
    _looks = const [];
    _grown = const [];
    _latest = const [];
    _dirty = const {};
    _draw = null;
  }
}
