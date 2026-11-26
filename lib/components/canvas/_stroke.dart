import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bson/bson.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:one_dollar_unistroke_recognizer/one_dollar_unistroke_recognizer.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_circle_stroke.dart';
import 'package:badnotes/components/canvas/_rectangle_stroke.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/data/extensions/list_extensions.dart';
import 'package:badnotes/data/extensions/point_extensions.dart';
import 'package:badnotes/data/tools/tape_pattern.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

class Stroke {
  static final log = Logger('Stroke');

  @visibleForTesting
  @protected
  final List<PointVector> points = [];

  bool get isEmpty => points.isEmpty;

  /// Where the stroke starts.
  Offset? get firstPoint =>
      points.isEmpty ? null : Offset(points.first.x, points.first.y);
  int get length => points.length;

  int pageIndex;
  HasSize page;
  final ToolId toolId;

  /// Goes up whenever anything that changes how this stroke looks changes, so
  /// a cached picture of the page can tell whether it's out of date.
  int get version => _version;
  var _version = 0;

  /// The id of the [PageLayer] this stroke is on.
  int get layer => _layer;
  set layer(int layer) {
    if (layer == _layer) return;
    _layer = layer;
    _version++;
  }

  var _layer = 0;

  static const defaultColor = Colors.black;
  static const defaultPressureEnabled = true;

  Color get color => _color;
  set color(Color color) {
    if (color == _color) return;
    _color = color;
    _version++;
  }

  Color _color;
  bool pressureEnabled;
  final StrokeOptions options;

  List<Offset>? _lowQualityPolygon, _highQualityPolygon;
  List<Offset> get lowQualityPolygon =>
      _lowQualityPolygon ??= getPolygon(quality: .low);
  List<Offset> get highQualityPolygon =>
      _highQualityPolygon ??= getPolygon(quality: .high);

  Path? _lowQualityPath, _highQualityPath, _centerlinePath, _polylinePath;

  /// Fill, outline and arrowheads, for shapes. Null draws a plain outline.
  ShapeStyle? get shapeStyle => _shapeStyle;
  set shapeStyle(ShapeStyle? style) {
    if (style == _shapeStyle) return;
    _shapeStyle = style == null || style.isPlain ? null : style;
    _version++;
  }

  ShapeStyle? _shapeStyle;

  /// Round holes the precision eraser cut out of this stroke: its center and
  /// radius, in page units. The stroke is drawn without them.
  List<({Offset center, double radius})> get holes => _holes;
  set holes(List<({Offset center, double radius})> holes) {
    _holes = holes;
    _kept = null;
    _version++;
  }

  /// Ends cut square instead of round: the pieces a highlighter is left in
  /// when the standard eraser cuts through it. Round ends stuck out past the
  /// cut, and where rows of a fill overlapped there they showed as darker
  /// lens shapes at the cut.
  bool flatEnds = false;

  /// Whether this was written on a picture put over the writing, so it's
  /// drawn over the picture; false when it was there before the picture
  /// came and the picture covers it. Null in notes saved before this was
  /// kept: where it lies decides then ([EditorPage.isOnFrontImage]).
  bool? onFrontImage;

  /// The [EditorImage.order] of the last picture or text box put over the
  /// writing before this was written: it's over that one and those before
  /// it, under the ones put on after. -1 for none. Null in notes saved
  /// before this was kept: [onFrontImage] decides then.
  int? afterImage;

  /// Drawn since each pen setting does something on its own ('n2' in the
  /// note): pressure sensitivity alone makes the line wider and thinner,
  /// tip sharpness alone narrows it with speed, and stabilization never
  /// lets the line fall far behind the pen. Off for strokes saved before,
  /// so they keep the look they were drawn with.
  var nib2 = false;

  /// A ballpoint line steadied by speed like the fountain pen's ('sl' in
  /// the note), so its stabilization setting shows: the pen library's own
  /// steadying, on a stylus's closely spaced samples, looked the same from
  /// 0% to 100%. Off for strokes saved before, so they keep their look.
  var steadyLine = false;

  /// Stabilization that grows with its setting ('st2' in the note): the
  /// pens' steadied line could only trail the pen by two pen widths, so
  /// 40% and 100% looked like 0%. Off for strokes saved before, so they
  /// keep their look.
  var steady2 = false;

  /// Whether the nib narrows when the pen moves fast and pools a little ink
  /// when it moves slowly. Off for strokes saved before this existed, so they
  /// keep the look they were drawn with.
  var speedInk = false;

  var _holes = const <({Offset center, double radius})>[];

  /// The same for this stroke and its [copy]s: the eraser works on a copy,
  /// and the ink cache tells by this that the copy is the same line, with
  /// only more holes (see [InkCache]).
  Object get lineage => _lineage;
  var _lineage = Object();

  /// When this was drawn, among all strokes: strokes are painted in this
  /// order (see [EditorPage.compareStrokes]). A new stroke comes after all
  /// before it, and strokes read from a note come in the order they were
  /// saved in. What the eraser leaves of a stroke (a copy with holes, or
  /// pieces) keeps the stroke's place.
  ///
  /// Kept only in the list's order before, undoing an erase put the stroke
  /// back on top of everything drawn after it: a highlighter's colour
  /// changed.
  int drawOrder = _nextDrawOrder++;
  static var _nextDrawOrder = 0;

  /// A [drawOrder] after every stroke's so far.
  static int nextDrawOrder() => _nextDrawOrder++;

  /// Cuts a round hole of [radius] at [center].
  ///
  /// A hole inside one already cut changes nothing, so it's left out:
  /// going over the same spot again and again piled up hundreds of them.
  void addHole(Offset center, double radius) {
    for (final h in _holes) {
      final apart = (h.center - center).distance;
      if (apart + radius <= h.radius + 0.01) return;
      // about the same hole again: going back over a spot added more and
      // more, all of them drawn on every frame
      if (h.radius >= radius * 0.95 && apart < radius * 0.25) return;
    }
    _holes = [..._holes, (center: center, radius: radius)];
    _version++;
  }

  Path? _kept;
  Rect? _keptArea;
  var _keptHoles = 0;
  var _keptFailed = false;

  /// [area] without the [holes]: drawn clipped to it, the stroke shows with
  /// its holes. Worked out once, and only the holes cut since are taken out
  /// of it after that.
  ///
  /// Clearing every hole out of a layer of the stroke's own on every frame
  /// took a phone's GPU ~20 ms a stroke, so a page where the eraser had
  /// been over a few highlighters drew at two frames a second.
  ///
  /// Null if the outline couldn't be worked out.
  Path? keptRegion(Rect area) {
    if (_keptFailed) return null;
    if (_kept == null || _keptArea != area) {
      _kept = Path()..addRect(area);
      _keptArea = area;
      _keptHoles = 0;
    }
    if (_keptHoles < _holes.length) {
      final cut = Path();
      for (int i = _keptHoles; i < _holes.length; i++) {
        final h = _holes[i];
        cut.addOval(Rect.fromCircle(center: h.center, radius: h.radius));
      }
      try {
        _kept = Path.combine(PathOperation.difference, _kept!, cut);
      } catch (e) {
        _keptFailed = true;
        return null;
      }
      _keptHoles = _holes.length;
    }
    return _kept;
  }

  /// Whether the [holes] cover the whole stroke, so nothing of it is left.
  bool get erasedAway {
    if (_holes.isEmpty) return false;
    final half = options.size / 2;
    return centerPoints.every(
      (p) => _holes.any((h) => (p - h.center).distance + half <= h.radius),
    );
  }

  /// [holes] as saved: x, y and radius of each.
  List<double> get holesJson => [
    for (final h in _holes) ...[h.center.dx, h.center.dy, h.radius],
  ];

  static List<({Offset center, double radius})> holesFromJson(Object? json) {
    if (json is! List) return const [];
    final values = [for (final v in json) (v as num).toDouble()];
    return [
      for (int i = 0; i + 2 < values.length; i += 3)
        (center: Offset(values[i], values[i + 1]), radius: values[i + 2]),
    ];
  }

  /// Where a lasso split this stroke: it shows only inside each clip whose
  /// `inside` is true and outside each whose `inside` is false. A
  /// highlighter the eraser had cut is split this way, so the pieces it was
  /// cut into can be picked one at a time.
  List<({List<Offset> polygon, bool inside})> get clips => _clips;
  set clips(List<({List<Offset> polygon, bool inside})> clips) {
    _clips = clips;
    _clipPath = null;
    _version++;
  }

  var _clips = const <({List<Offset> polygon, bool inside})>[];
  Path? _clipPath;

  /// The area the [clips] leave, or null if it has none.
  Path? get clipPath {
    if (_clips.isEmpty) return null;
    return _clipPath ??= () {
      var area = Path()..addRect(bounds.inflate(options.size + 4));
      for (final clip in _clips) {
        final polygon = Path()..addPolygon(clip.polygon, true);
        area = Path.combine(
          clip.inside ? PathOperation.intersect : PathOperation.difference,
          area,
          polygon,
        );
      }
      return area;
    }();
  }

  /// Whether [p] is in what the [clips] leave.
  bool showsAt(Offset p) => _clips.every((clip) {
    final inPolygon = (Path()..addPolygon(clip.polygon, true)).contains(p);
    return inPolygon == clip.inside;
  });

  /// [centerPoints] that are shown, not clipped away.
  List<Offset> get shownPoints => _clips.isEmpty
      ? centerPoints
      : [
          for (final p in centerPoints)
            if (showsAt(p)) p,
        ];

  /// [clips] as saved: each is 1 (inside) or 0, then its points' x and y.
  List<List<double>> get clipsJson => [
    for (final clip in _clips)
      [
        clip.inside ? 1 : 0,
        for (final p in clip.polygon) ...[p.dx, p.dy],
      ],
  ];

  static List<({List<Offset> polygon, bool inside})> clipsFromJson(
    Object? json,
  ) {
    if (json is! List) return const [];
    return [
      for (final clip in json)
        if (clip is List && clip.length >= 7)
          (
            inside: clip.first == 1,
            polygon: [
              for (int i = 1; i + 1 < clip.length; i += 2)
                Offset(
                  (clip[i] as num).toDouble(),
                  (clip[i + 1] as num).toDouble(),
                ),
            ],
          ),
    ];
  }

  void _mapHoles(Offset Function(Offset) map, double scale) {
    if (_clips.isNotEmpty) {
      // the clips go where the stroke goes
      _clips = [
        for (final clip in _clips)
          (
            inside: clip.inside,
            polygon: [for (final p in clip.polygon) map(p)],
          ),
      ];
      _clipPath = null;
    }
    if (_holes.isEmpty) return;
    _kept = null;
    _holes = [
      for (final h in _holes) (center: map(h.center), radius: h.radius * scale),
    ];
  }

  /// Whether the shape's line ends where it starts, so it has an inside.
  bool get isClosedShape {
    if (points.length < 3) return false;
    final a = points.first, b = points.last;
    return (a.x - b.x).abs() < 0.5 && (a.y - b.y).abs() < 0.5;
  }

  /// The shape's points without the repeated last one of a closed shape.
  List<Offset> get editablePoints => [
    for (int i = 0; i < points.length - (isClosedShape ? 1 : 0); i++)
      Offset(points[i].x, points[i].y),
  ];

  /// A tape stroke being peeked under. Tape is covering again next time the
  /// note opens, so this isn't saved.
  bool get tapeRevealed => _tapeRevealed;
  set tapeRevealed(bool revealed) {
    if (revealed == _tapeRevealed) return;
    _tapeRevealed = revealed;
    _version++;
  }

  var _tapeRevealed = false;

  /// The design printed on a tape stroke.
  TapePattern get tapePattern => _tapePattern;
  set tapePattern(TapePattern pattern) {
    _tapePattern = pattern;
    _tapeStamps = null;
    _version++;
  }

  var _tapePattern = TapePattern.plain;

  /// The doodle of a [TapePattern.custom] tape, see [TapePattern.parseDoodle].
  String? get tapeCustom => _tapeCustom;
  set tapeCustom(String? doodle) {
    _tapeCustom = doodle;
    _tapeStamps = null;
    _version++;
  }

  String? _tapeCustom;
  Path? _tapeStamps, _tapeBorder;

  /// The tape's center line with a little more at each end. Drawn wider and
  /// underneath the tape, it shows as an outline on all four sides.
  Path get tapeBorder => _tapeBorder ??= () {
    final line = centerlinePath;
    final border = Path()..addPath(line, Offset.zero);
    const overhang = 1.5;
    for (final metric in line.computeMetrics()) {
      final start = metric.getTangentForOffset(0);
      final end = metric.getTangentForOffset(metric.length);
      if (start != null) {
        final from = start.position - start.vector * overhang;
        border
          ..moveTo(from.dx, from.dy)
          ..lineTo(start.position.dx, start.position.dy);
      }
      if (end != null) {
        final to = end.position + end.vector * overhang;
        border
          ..moveTo(end.position.dx, end.position.dy)
          ..lineTo(to.dx, to.dy);
      }
    }
    return border;
  }();

  /// [tapePattern] along this stroke, to fill.
  Path get tapeStamps => _tapeStamps ??= tapePattern.stamps(
    centerlinePath,
    options.size,
    doodle: tapeCustom,
  );

  Float32List? _pencilGrain;

  /// The side of the squares of paper that hold one grain of graphite each.
  double get _pencilGrainCell => max(options.size * 0.07, 0.45);

  /// Width of each grain in [pencilGrain].
  double get pencilGrainSize => _pencilGrainCell * 0.8;

  /// A number from 0 to 1 belonging to one square of the paper.
  static double _paperAt(int x, int y, int salt) {
    var hash = (x * 73856093 ^ y * 19349663 ^ salt * 83492791) & 0xffffffff;
    hash = (hash ^ (hash >> 13)) * 1274126177 & 0xffffffff;
    return (hash ^ (hash >> 16)) / 0xffffffff;
  }

  /// Grains of graphite along a pencil stroke, as x, y pairs on the page. Where
  /// they land comes from the paper, not from the stroke: strokes over each
  /// other catch on the same bumps, and grains keep their place while drawing.
  /// Harder pressure fills in more of the paper's dips. Gaps between the grains
  /// are the paper showing through, as with real graphite.
  //
  // While drawing, the grains along the start of the line are kept in
  // [_grainDone] and only the last few segments are worked out again on each
  // move: the steadied line only changes near the pen.
  Float32List get pencilGrain => _pencilGrain ??= _buildPencilGrain();

  /// Grains of the part of the live line that can't change any more.
  _GrainProgress? _grainDone;

  /// How many segments at the end of the steadied line can still move. The
  /// curve through each pair of points looks one point further ahead, and the
  /// last point is where the pen is, so the last 3 gaps between points can
  /// change: up to 6 segments each, see [_buildSteadiedPoints].
  static const _grainTail = 20;

  Float32List _buildPencilGrain() {
    final line = _steadiedPoints();
    if (line.isEmpty) {
      _grainDone = null;
      return Float32List(0);
    }
    final cell = _pencilGrainCell;
    final radius = options.size / 2;
    const softFrom = 0.6, softTo = 1.1;
    final across = (radius * softTo / cell).ceil();

    var done = _grainDone;
    if (done != null && !done.fits(line, cell)) done = _grainDone = null;
    final grain = <double>[];
    final seen = <(int, int)>{};
    var doneSeen = done?.seen;
    void touch(double px, double py, double distance, double pressure) {
      final x = (px / cell).floor(), y = (py / cell).floor();
      if (doneSeen != null && doneSeen.contains((x, y))) return;
      if (!seen.add((x, y))) return;
      // single squares, plus larger patches: real paper isn't evenly rough
      final tooth =
          0.75 * _paperAt(x, y, 0) +
          0.25 * _paperAt((x / 5).floor(), (y / 5).floor(), 1);
      final soft = distance < softFrom
          ? 1.0
          : (softTo - distance) / (softTo - softFrom);
      if (tooth < soft * (0.55 + 0.7 * pressure) * 0.56) {
        grain
          ..add((x + _paperAt(x, y, 2)) * cell)
          ..add((y + _paperAt(x, y, 3)) * cell);
      }
    }

    var length = done?.length ?? 0.0;
    for (int i = (done?.segments ?? 0) + 1; i < line.length; i++) {
      length += sqrt(line[i - 1].distanceSquaredTo(line[i]));
    }
    if (done == null && length < cell * 2) {
      // a dot
      final center = line.first;
      final pressure = center.pressure ?? 0.5;
      for (var i = -across; i <= across; i++) {
        for (var j = -across; j <= across; j++) {
          touch(
            center.x + i * cell,
            center.y + j * cell,
            sqrt(i * i + j * j) * cell / radius,
            pressure,
          );
        }
      }
      return Float32List.fromList(grain);
    }

    // Straight across the line, at steps of less than a grain's width along it:
    // going over every square of paper near every point was far too slow to
    // draw. The steps go by distance, as points can be far apart.
    final step = cell * 0.75;
    var at = done?.at ?? 0.0;
    var doneLength = done?.length ?? 0.0;
    void walk(int i) {
      final a = line[i - 1], b = line[i];
      final segment = sqrt(a.distanceSquaredTo(b));
      if (segment == 0 || !segment.isFinite) return;
      final ux = (b.x - a.x) / segment, uy = (b.y - a.y) / segment;
      final pressure = a.pressure ?? 0.5;
      while (at < segment) {
        final x = a.x + ux * at, y = a.y + uy * at;
        for (var j = -across; j <= across; j++) {
          final offset = j * cell;
          touch(
            x - uy * offset,
            y + ux * offset,
            offset.abs() / radius,
            pressure,
          );
        }
        at += step;
      }
      at -= segment;
    }

    final from = (done?.segments ?? 0) + 1;
    // nothing more gets drawn onto a finished stroke, so nothing more is kept
    final settled = options.isComplete
        ? from - 1
        : line.length - 1 - _grainTail;
    if (settled >= from) {
      done ??= _grainDone = _GrainProgress(line.first, cell);
      for (int i = from; i <= settled; i++) {
        doneLength += sqrt(line[i - 1].distanceSquaredTo(line[i]));
        walk(i);
      }
      done
        ..grain.addAll(grain)
        ..seen.addAll(seen)
        ..segments = settled
        ..at = at
        ..length = doneLength
        ..lastPoint = line[settled];
      grain.clear();
      seen.clear();
      doneSeen = done.seen;
    }
    for (int i = max(from, settled + 1); i < line.length; i++) {
      walk(i);
    }
    if (done == null) return Float32List.fromList(grain);
    return Float32List(done.grain.length + grain.length)
      ..setAll(0, done.grain)
      ..setAll(done.grain.length, grain);
  }

  /// Straight lines through the stroke's points, without any smoothing.
  /// Shapes and tape are drawn as this line with a pen of fixed width, which
  /// keeps their corners and can't leave gaps in the ink.
  Path get polylinePath => _polylinePath ??= () {
    final line = centerPoints;
    if (line.length == 1) line.add(line.first + const Offset(0.01, 0));
    return Path()..addPolygon(line, false);
  }();

  /// Smoothed center line of the stroke. Highlighters are drawn as this
  /// line with a wide round-capped pen, which stays smooth at any width
  /// (a wide filled outline shows every wobble of the hand).
  /// [StrokeOptions.streamline] is the stabilization amount.
  Path get centerlinePath => _centerlinePath ??= _buildCenterline();

  /// [points] steadied by speed as for [_buildCenterline], with a curve through
  /// them where the pen moved fast: an outline around widely spaced points has
  /// visible corners.
  ///
  /// Kept until the points change: the outline and the pencil grains both
  /// need it on every paint of a live stroke.
  List<PointVector> _steadiedPoints() => _steadied ??= _buildSteadiedPoints();
  List<PointVector>? _steadied;

  /// Whether this steadies its own line ([steadyLine]) before the pen
  /// library outlines it.
  bool get _steadiesOwnLine => steadyLine && toolId == .ballpointPen;

  /// [points] steadied by speed, with their own pressure, ending where the
  /// pen is: [steadyLine].
  List<PointVector> _steadiedLine({List<int>? src}) {
    if (points.length < 3) {
      src?.addAll([for (int i = 0; i < points.length; i++) i]);
      return points;
    }
    final line = _steadiedOffsets(bySpeed: true);
    final out = <PointVector>[];
    for (final (i, p) in line.indexed) {
      if (p == null) continue;
      out.add(PointVector(p.dx, p.dy, points[i].pressure));
      src?.add(i);
    }
    if (!_openEnd) {
      out.add(PointVector(points.last.x, points.last.y, points.last.pressure));
      src?.add(points.length - 1);
    }
    return out;
  }

  /// How much of the stabilization [StrokeOptions.streamline] applies at a
  /// [slowness] from 0 (fast) to 1 (still). Most when slow, where a shaky hand
  /// shows, but some at any speed: with it only when slow, 0% and 100% felt
  /// the same. At 0% there's none at all, so the ink is exactly on the pen.
  static double _steadying(double slowness) => 0.4 + 0.6 * slowness * slowness;

  /// [_steadying] for [steady2]: the higher the [setting], the more a fast
  /// line is steadied too, not only a slow one (at 100%, nearly as much).
  static double _steadying2(double slowness, double setting) {
    final fast = 0.4 + 0.5 * setting;
    return fast + (1 - fast) * slowness * slowness;
  }

  /// [points] steadied by the stabilization setting: each moves only part of
  /// the way from the last steadied point to where the pen is. Null for a
  /// point that isn't on the page.
  List<Offset?> _steadiedOffsets({required bool bySpeed}) {
    final setting = options.streamline.clamp(0.0, 0.95);
    // Pens steadied by speed: eased in, so the slider's lower half already
    // does something visible. 0%, 50% and 100% looked about the same.
    // Others are steadied the same at any speed, which already shows.
    final amount = bySpeed
        ? min(1 - (1 - setting) * (1 - setting), 0.95)
        : setting;
    final fastMove = max(options.size * 1.5, 2.0);
    final n = points.length;
    var prev = _steadyFrom ?? Offset(points.first.x, points.first.y);
    final out = <Offset?>[prev];
    for (int i = 1; i < n; i++) {
      final p = Offset(points[i].x, points[i].y);
      if (!p.isFinite) {
        out.add(null);
        continue;
      }
      final slowness = bySpeed
          ? 1.0 - min((p - prev).distance / fastMove, 1.0)
          : 1.0;
      final hold = steady2
          ? _steadying2(slowness, setting)
          : _steadying(slowness);
      prev += (p - prev) * (1 - amount * hold);
      if (nib2 && toolId != .highlighter) {
        // never far behind the pen: at high stabilization a turn was cut
        // short, and letters lost their corners. With [steady2] the leash
        // lengthens with the setting, so the setting shows as it does on
        // the highlighter.
        final lag = p - prev;
        final leash = max(options.size * 2, 3.0);
        final maxLag = steady2 ? leash * (1 + 6 * setting) : leash;
        if (lag.distance > maxLag) prev = p - lag / lag.distance * maxLag;
      }
      out.add(prev);
    }
    return out;
  }

  List<PointVector> _buildSteadiedPoints() {
    final pressures = nibPressures;
    if (points.length < 3) {
      _steadiedSrc = [for (int i = 0; i < points.length; i++) i];
      return [
        for (final (i, p) in points.indexed)
          PointVector(p.x, p.y, pressures[i]),
      ];
    }
    final line = _steadiedOffsets(bySpeed: true);
    final steadied = <PointVector>[];
    final steadiedSrc = <int>[];
    for (final (i, p) in line.indexed) {
      if (p == null) continue;
      steadied.add(PointVector(p.dx, p.dy, pressures[i]));
      steadiedSrc.add(i);
    }
    // finish where the pen is, unless the line goes on in another piece
    if (!_openEnd) {
      steadied.add(PointVector(points.last.x, points.last.y, pressures.last));
      steadiedSrc.add(points.length - 1);
    }

    final spacing = max(options.size, 3.0);
    final out = <PointVector>[steadied.first];
    final src = <int>[steadiedSrc.first];
    for (int i = 0; i < steadied.length - 1; i++) {
      final p0 = steadied[max(i - 1, 0)];
      final p1 = steadied[i];
      final p2 = steadied[i + 1];
      final p3 = steadied[min(i + 2, steadied.length - 1)];
      final gap = sqrt(p1.distanceSquaredTo(p2));
      final steps = min((gap / spacing).ceil(), 6);
      for (int k = 1; k < steps; k++) {
        final t = k / steps, t2 = t * t, t3 = t2 * t;
        double curve(double a, double b, double c, double d) =>
            0.5 *
            (2 * b +
                (c - a) * t +
                (2 * a - 5 * b + 4 * c - d) * t2 +
                (3 * b - a - 3 * c + d) * t3);
        out.add(
          PointVector(
            curve(p0.x, p1.x, p2.x, p3.x),
            curve(p0.y, p1.y, p2.y, p3.y),
            p1.pressure == null || p2.pressure == null
                ? p2.pressure
                : p1.pressure! + (p2.pressure! - p1.pressure!) * t,
          ),
        );
        src.add(steadiedSrc[i]);
      }
      out.add(p2);
      src.add(steadiedSrc[i + 1]);
    }
    _steadiedSrc = src;
    return out;
  }

  /// For each of [_steadiedPoints], the index in [points] it comes from.
  List<int>? _steadiedSrc;

  /// How hard the nib is pressing at each point, from 0 to 1. With nothing
  /// measuring pressure it stays in the middle, so the line keeps one width
  /// instead of changing with the pen's speed.
  ///
  /// Real pressure is lifted (styluses report little of their range in normal
  /// writing) and smoothed along the line: raw readings jump about between
  /// samples, which showed as ink going thin and thick for no reason. Never
  /// near zero, or the first light touch would make a dot vanish.
  @visibleForTesting
  List<double> get nibPressures {
    final hasPressure =
        pressureEnabled && points.any((p) => p.pressure != null);
    if (nib2 && toolId == .fountainPen) return _fountainWidths(hasPressure);
    if (!hasPressure && !speedInk) {
      return List.filled(points.length, 0.5);
    }
    final out = <double>[];
    double? smoothed;
    PointVector? before;
    for (final point in points) {
      final raw = point.pressure ?? smoothed ?? 0.5;
      var lifted = hasPressure
          ? max(pow(raw.clamp(0.0, 1.0), 0.6).toDouble(), 0.25)
          : 0.5;
      if (speedInk && before != null) {
        final factor = speedFactor(sqrt(before.distanceSquaredTo(point)));
        // tip sharpness: how much faster lines are thinner
        lifted *= nib2
            ? nibSpeedFactor(sqrt(before.distanceSquaredTo(point)), _sharpness)
            : factor;
      }
      if (smoothed == null || before == null) {
        smoothed = lifted;
      } else {
        final gap = sqrt(before.distanceSquaredTo(point));
        // With speed ink the width follows the pen's speed, which jumps
        // about from sample to sample: eased over the line, about a pen's
        // width or two, so it can't swell at a slow turn and shrink again.
        smoothed +=
            (lifted - smoothed) *
            (speedInk
                ? min(0.06 + gap / (options.size * 8), 0.18)
                : min(0.15 + gap / (options.size * 3), 1.0));
      }
      out.add(smoothed);
      before = point;
    }
    return out;
  }

  /// The fountain pen's width at each point, as half of how wide it is
  /// against its size (0.5 is its size): the pressure (already spread by
  /// the pressure sensitivity setting, see `Pen`) makes it from about half
  /// to 1.6 times as wide; the tip sharpness thins it when the pen moves
  /// really fast, by up to half its size. The two used to multiply down to a tenth, and
  /// at any tip sharpness the pressure hardly showed.
  List<double> _fountainWidths(bool hasPressure) {
    if (!hasPressure && !speedInk) return List.filled(points.length, 0.5);
    // a piece of a longer line has the width the line has there: worked out
    // afresh, each piece began at full width (the pen seemed still at its
    // first point) and thinned again, a bead at every piece
    if (_widthsGiven case final given? when given.length == points.length) {
      return given;
    }
    if (_widthsOf == _version && _widths?.length == points.length) {
      return _widths!;
    }
    final sharpness = _sharpness;
    final out = <double>[];
    double? smoothed;
    PointVector? before;
    for (final point in points) {
      var width = 1.0;
      if (hasPressure) {
        // most writing reads a little under the middle
        width = 1 + 1.2 * ((point.pressure ?? 0.45) - 0.45);
      }
      if (speedInk && before != null) {
        // Only really fast lines thin, by up to half the pen's size, taken
        // off whatever the pressure made: multiplied, the thinning scaled
        // the pressure's difference down too, and as everyday writing
        // already counted as fast, the pressure hardly showed.
        final speed = sqrt(before.distanceSquaredTo(point));
        final t = ((speed - 2) / 6).clamp(0.0, 1.0);
        width -= 0.55 * sharpness * t * t * (3 - 2 * t);
      }
      final target = width.clamp(0.3, 1.7) / 2;
      if (smoothed == null || before == null) {
        // From the width the line has as it moves off: at its first point
        // the pen seems still, so the line began at full width and
        // thinned, a round blob at the start of a quick line and at each
        // end the eraser cut.
        smoothed = target;
        if (speedInk && points.length > 1) {
          final speed = sqrt(point.distanceSquaredTo(points[1]));
          final t = ((speed - 2) / 6).clamp(0.0, 1.0);
          smoothed =
              (target * 2 - 0.55 * sharpness * t * t * (3 - 2 * t)).clamp(
                0.3,
                1.7,
              ) /
              2;
        }
      } else {
        final gap = sqrt(before.distanceSquaredTo(point));
        // eased along the line, so it can't swell at a slow turn (a bead)
        smoothed +=
            (target - smoothed) * min(0.06 + gap / (options.size * 8), 0.18);
      }
      out.add(smoothed);
      before = point;
    }
    _widthsOf = _version;
    return _widths = List.unmodifiable(out);
  }

  int? _widthsOf;
  List<double>? _widths;

  /// The widths of [livePiece]'s points in the line it is a piece of.
  List<double>? _widthsGiven;

  /// Where the line [livePiece] is a piece of is steadied to at its first
  /// point.
  Offset? _steadyFrom;

  /// A fountain pen's ends narrow over a fixed distance, set by
  /// [StrokeOptions.thinning], its tip sharpness. The outline is the same while
  /// writing and after the pen lifts: anything depending on the stroke's length
  /// or on it being finished made ink already on the page visibly change.
  /// The ends don't narrow to nothing, so dots and commas stay visible.
  StrokeOptions _nibOptions() {
    if (toolId == .pencil) {
      // A pencil's point barely changes width: pressing harder makes it darker,
      // see [pencilGrain]. Its body stops short of the grains at the edge.
      double ease(double t) => 0.75 + 0.25 * t;
      return options.copyWith(
        size: options.size * 0.8,
        thinning: 0.2,
        smoothing: 0.25,
        streamline: 0.05,
        simulatePressure: false,
        isComplete: false,
        start: StrokeEndOptions.start(
          customTaper: options.size * 1.5,
          easing: ease,
        ),
        end: StrokeEndOptions.end(customTaper: options.size, easing: ease),
      );
    }
    if (toolId == .brushPen) {
      // A brush keeps its round ends and its own smoothing: only its line is
      // steadied ([_steadiedPoints]), not anything else about it.
      return options.copyWith(
        smoothing: max(options.smoothing, 0.5),
        streamline: 0.05,
        simulatePressure: false,
        isComplete: false,
      );
    }
    final sharpness = options.thinning.clamp(0.0, 1.0);
    // sharper ends, a little more than before at the same setting
    final narrowest = 0.7 - 0.58 * sharpness;
    // How much the width follows the pressure (and the speed) is fixed: the
    // pressure sensitivity and tip sharpness settings change how much those
    // vary. With the width following them by tip sharpness, each setting
    // did nothing while the other was at 0.
    // the fountain pen's width is all in its pressures ([_fountainWidths]):
    // its radius is its size times the pressure
    final widthFollows = nib2 && toolId == .fountainPen ? 1.0 : null;
    double ease(double t) => narrowest + (1 - narrowest) * t;
    return options.copyWith(
      thinning: widthFollows,
      // a finer outline, for a smooth edge at any pen size
      smoothing: 0.25,
      // already steadied, by speed. A fixed amount here would make the line
      // trail the pen at any speed.
      streamline: 0.05,
      simulatePressure: false,
      isComplete: false,
      start: StrokeEndOptions.start(
        customTaper: options.size * (1 + 4 * sharpness),
        easing: ease,
      ),
      end: StrokeEndOptions.end(
        customTaper: options.size * (0.5 + 2 * sharpness),
        easing: ease,
      ),
    );
  }

  /// How wide the nib is at [speed] (the distance moved since the last
  /// sample) for a tip [sharpness] from 0 to 1, as a factor of its width.
  /// [speedFactor] only starts past a speed of 1.5 a sample, faster than
  /// most writing, so tip sharpness alone changed nothing that showed.
  @visibleForTesting
  static double nibSpeedFactor(double speed, double sharpness) {
    if (!speed.isFinite || sharpness <= 0) return 1;
    // No pooling when slow, and never thinner than 40%: at full tip
    // sharpness the line went from a fifth of its width to more than its
    // width wherever the pen slowed at a turn, a knob (a bead) at each.
    const startsAt = 0.3;
    var factor = 1.0;
    if (speed > startsAt) factor -= 0.72 * atan(0.9 * (speed - startsAt));
    return max(1 + (factor - 1) * sharpness, 0.4);
  }

  /// Tip sharpness, from 0 to 1.
  double get _sharpness => (options.thinning / 0.9).clamp(0.0, 1.0);

  /// How wide the nib is at [speed], the distance moved since the last
  /// sample, as a factor of its width. Fast lines are thinner and slow ones a
  /// little wider, like ink that has time to spread. The curve is the one in
  /// StarNote's ballpoint engine: narrowing by `0.6 * atan(0.06 * speed)`
  /// past a speed too small to count, which levels off instead of vanishing.
  @visibleForTesting
  static double speedFactor(double speed) {
    const sensitivity = 0.8, ignoreBelow = 1.5;
    const slowBoost = 0.15, slowSpeed = 3.0;
    if (!speed.isFinite) return 1;
    var factor = 1.0;
    if (speed > ignoreBelow) {
      factor -= 0.6 * sensitivity * atan(0.06 * (speed - ignoreBelow));
    }
    if (speed < slowSpeed) factor *= 1 + slowBoost * (1 - speed / slowSpeed);
    return factor;
  }

  /// Makes this stroke a straight line if it nearly is one.
  void straightenIfNearlyStraight() {
    if (points.length < 3) return;
    final start = Offset(points.first.x, points.first.y);
    final end = Offset(points.last.x, points.last.y);
    final tolerance = max((end - start).distance * 0.06, options.size * 0.25);
    final tolerance2 = tolerance * tolerance;
    for (final p in points) {
      if (sqrDistanceToSegment(Offset(p.x, p.y), start, end) > tolerance2) {
        return;
      }
    }
    setEndOfLine(end);
  }

  /// A wide strip shows every wobble of the hand, and can't bend tighter than
  /// its own width without creasing. So tape follows only the larger movements:
  /// points at least about half its width apart, then evened out. The result
  /// stays put behind the pen while drawing, as each step only looks at points
  /// close by. The ends stay where they are, and the last bit of the line is
  /// long enough that wobble at the pen's touch and lift can't skew the cuts.
  @visibleForTesting
  static List<Offset> smoothTapeLine(List<Offset> line, double size) {
    if (line.length <= 2) return line;
    final spacing = max(size * 0.6, 6.0);
    final kept = <Offset>[line.first];
    for (final point in line) {
      if ((point - kept.last).distance >= spacing) kept.add(point);
    }
    final end = line.last;
    while (kept.length > 1 && (kept.last - end).distance < size / 2) {
      kept.removeLast();
    }
    kept.add(end);

    var smooth = kept;
    for (var pass = 0; pass < 3; pass++) {
      smooth = [
        smooth.first,
        for (int i = 1; i < smooth.length - 1; i++)
          (smooth[i - 1] + smooth[i] * 2 + smooth[i + 1]) / 4,
        smooth.last,
      ];
    }
    return smooth;
  }

  /// Whether every one of [pts] is within a hair of the line through the
  /// first and the farthest of them.
  static bool _allOnOneLine(List<Offset> pts) {
    var far = pts.first;
    for (final p in pts) {
      if ((p - pts.first).distance > (far - pts.first).distance) far = p;
    }
    final line = far - pts.first;
    final length = line.distance;
    if (length < 1e-6) return false;
    for (final p in pts) {
      final off = p - pts.first;
      final across = (off.dx * line.dy - off.dy * line.dx).abs() / length;
      final along = (off.dx * line.dx + off.dy * line.dy) / length;
      if (across > 0.01 || along < -0.01 || along > length + 0.01) return false;
    }
    return true;
  }

  Path _buildCenterline() {
    final path = Path();
    if (points.isEmpty) return path;
    if (points.length == 2 && _predictedPoint == null) {
      // A straight line stays a plain line: a curve whose points all lie on one
      // line is what a renderer can drop, more so if exactly level or upright.
      return path
        ..moveTo(points.first.x, points.first.y)
        ..lineTo(points.last.x, points.last.y);
    }
    // A ball pen is steadied most when it moves slowly, where a shaky hand
    // shows. Moving fast it follows the pen, so the line doesn't trail behind.
    final pts = _steadiedOffsets(bySpeed: toolId == .ballpointPen).nonNulls
        .toList();
    // finish where the pen actually lifted
    if (!_openEnd) pts.add(Offset(points.last.x, points.last.y));
    if (toolId == .tape) {
      final smooth = smoothTapeLine(pts, options.size);
      pts
        ..clear()
        ..addAll(smooth);
    }
    if (_predictedPoint != null && !options.isComplete) {
      pts.add(_predictedPoint!);
    }

    // Points all on one line (a ruler line, a level or upright swipe): a
    // curve through them is one the renderer can drop, and the stroke was
    // invisible. Draw it as the plain line it is.
    if (pts.length > 2 && _allOnOneLine(pts)) {
      return path
        ..moveTo(pts.first.dx, pts.first.dy)
        ..lineTo(pts.last.dx, pts.last.dy);
    }

    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length <= 2) {
      // a tap still leaves a dot thanks to the round cap
      return path..lineTo(pts.last.dx + 0.01, pts.last.dy);
    }
    for (int i = 1; i < pts.length - 1; i++) {
      final mid = (pts[i] + pts[i + 1]) / 2;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    return path..lineTo(pts.last.dx, pts.last.dy);
  }

  Path get lowQualityPath =>
      _lowQualityPath ??= _lined(getPath(lowQualityPolygon, smooth: false));
  Path get highQualityPath =>
      _highQualityPath ??= _lined(getPath(highQualityPolygon));

  /// A pen's line, solid, dashed or dotted. Only the pens use it.
  ShapeLine get inkLine => _inkLine;
  set inkLine(ShapeLine line) {
    if (line == _inkLine) return;
    _inkLine = line;
    markPolygonNeedsUpdating();
  }

  var _inkLine = ShapeLine.solid;

  /// [outline] cut into dashes, or dots along the line, by [inkLine].
  Path _lined(Path outline) {
    if (_inkLine == .solid || _inkLine == .none || points.length < 2) {
      return outline;
    }
    final size = options.size;
    final dots = Path();
    final mask = Path();
    for (final metric in centerlinePath.computeMetrics()) {
      if (_inkLine == .dotted) {
        final spacing = max(size * 2.2, 4.0);
        final radius = max(size / 2, 0.8);
        for (var at = 0.0; at <= metric.length; at += spacing) {
          final p = metric.getTangentForOffset(at)?.position;
          if (p != null)
            dots.addOval(Rect.fromCircle(center: p, radius: radius));
        }
        continue;
      }
      // dashes: the ink kept where a band along the line covers it
      final dash = max(size * 3, 6.0), gap = max(size * 2, 4.0);
      final half = size * 2 + 2;
      final step = max(size / 2, 1.0);
      for (var from = 0.0; from < metric.length; from += dash + gap) {
        final to = min(from + dash, metric.length);
        final left = <Offset>[], right = <Offset>[];
        for (var at = from; ; at += step) {
          final t = metric.getTangentForOffset(min(at, to));
          if (t != null) {
            final across = Offset(-t.vector.dy, t.vector.dx) * half;
            left.add(t.position + across);
            right.add(t.position - across);
          }
          if (at >= to) break;
        }
        if (left.length > 1) {
          mask.addPolygon([...left, ...right.reversed], true);
        }
      }
    }
    if (_inkLine == .dotted) return dots;
    return Path.combine(PathOperation.intersect, outline, mask);
  }

  /// Whether [highQualityPath] is worked out already, so asking is quick.
  bool get hasHighQualityPath => _highQualityPath != null;

  void shift(Offset offset) {
    if (offset == .zero) return;

    points.shift(offset);
    _mapHoles((p) => p + offset, 1);
    _lowQualityPolygon?.shift(offset);
    _highQualityPolygon?.shift(offset);
    _lowQualityPath = _lowQualityPath?.shift(offset);
    _centerlinePath = _centerlinePath?.shift(offset);
    _polylinePath = _polylinePath?.shift(offset);
    _tapeStamps = _tapeStamps?.shift(offset);
    _tapeBorder = _tapeBorder?.shift(offset);
    _highQualityPath = _highQualityPath?.shift(offset);
    _inkVertices = null;
    _tri = null;
    _cutFrom = null;
    _pencilGrain = null;
    _grainDone = null;
    _steadied = null;
    _widthsOf = null;
    _version++;
  }

  /// Maps [p] by scaling by [scale] and rotating by [angle] radians around [center].
  static Offset transformPoint(
    Offset p,
    Offset center,
    double scale,
    double angle,
  ) {
    final d = (p - center) * scale;
    final c = cos(angle), s = sin(angle);
    return center + Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c);
  }

  /// A highlighter's line is as wide as the rows of a fill are close: moving
  /// its points apart without widening it left gaps between the strokes of a
  /// filled box made bigger, so it grows and shrinks with the stroke.
  void _scaleWidth(double factor) {
    if (toolId != .highlighter ||
        factor == 1 ||
        !factor.isFinite ||
        factor <= 0) {
      return;
    }
    options.size = (options.size * factor).clamp(1.0, 600.0);
  }

  /// Scales and rotates this stroke around [center]. Used by lasso resize/rotate.
  void transform(Offset center, double scale, double angle) {
    _scaleWidth(scale);
    _mapHoles((p) => transformPoint(p, center, scale, angle), scale);
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final q = transformPoint(Offset(p.x, p.y), center, scale, angle);
      points[i] = PointVector(q.dx, q.dy, p.pressure);
    }
    markPolygonNeedsUpdating();
  }

  /// How much a stretch by [sx] across and [sy] down moves this stroke's
  /// neighbours apart: the stretch at right angles to the way it mostly goes.
  /// A box filled with level strokes stretched taller spreads the strokes
  /// apart by [sy], and they must widen by as much not to come apart.
  @visibleForTesting
  double stretchAcross(double sx, double sy) {
    // the way the stroke mostly goes, from its pieces: angles doubled, so
    // going back and forth along one line still counts as that line
    var sumX = 0.0, sumY = 0.0, total = 0.0;
    for (int i = 1; i < points.length; i++) {
      final dx = points[i].x - points[i - 1].x;
      final dy = points[i].y - points[i - 1].y;
      final length = sqrt(dx * dx + dy * dy);
      if (length == 0 || !length.isFinite) continue;
      final angle = atan2(dy, dx) * 2;
      sumX += cos(angle) * length;
      sumY += sin(angle) * length;
      total += length;
    }
    if (total == 0 || sqrt(sumX * sumX + sumY * sumY) < 0.3 * total) {
      // no main direction, like a circle: grown both ways, as wide as the
      // bigger; shrunk both ways, the smaller; otherwise in between
      if (sx >= 1 && sy >= 1) return max(sx, sy);
      if (sx <= 1 && sy <= 1) return min(sx, sy);
      return sqrt(sx * sy);
    }
    final along = atan2(sumY, sumX) / 2;
    // at right angles to the main direction
    final nx = -sin(along), ny = cos(along);
    return sqrt((sx * nx) * (sx * nx) + (sy * ny) * (sy * ny));
  }

  /// Whether the box around this stroke's points, as wide as it's drawn,
  /// comes within [radius] of the segment from [a] to [b]. Cheap: no lists.
  bool _maybeNear(Offset a, Offset b, double radius) {
    if (points.isEmpty) return true;
    final box = _pointBounds();
    if (box == null) return true;
    // the outline can bulge past the points by up to the width
    final reach = radius + options.size * 1.5 + 2;
    return box.inflate(reach).overlaps(Rect.fromPoints(a, b));
  }

  /// The box round [points], kept until they change: the eraser asks every
  /// stroke on the page on every move, and going through all their points
  /// each time made fast erasing on a full page lag.
  Rect? _pointBounds() {
    if (_pointBoundsVersion == _version &&
        _pointBoundsLength == points.length) {
      return _pointBoundsCache;
    }
    var left = double.infinity, top = double.infinity;
    var right = -double.infinity, bottom = -double.infinity;
    for (final p in points) {
      if (p.x < left) left = p.x;
      if (p.x > right) right = p.x;
      if (p.y < top) top = p.y;
      if (p.y > bottom) bottom = p.y;
    }
    final finite =
        left.isFinite && top.isFinite && right.isFinite && bottom.isFinite;
    _pointBoundsCache = finite ? Rect.fromLTRB(left, top, right, bottom) : null;
    _pointBoundsVersion = _version;
    _pointBoundsLength = points.length;
    return _pointBoundsCache;
  }

  Rect? _pointBoundsCache;
  int? _pointBoundsVersion;
  int? _pointBoundsLength;

  /// Gives this stroke the points, width and holes of [other], a copy of it
  /// from before or after it was reshaped, for undo and redo.
  void reshapeLike(Stroke other) {
    points
      ..clear()
      ..addAll(other.points);
    options.size = other.options.size;
    holes = other.holes;
    markPolygonNeedsUpdating();
  }

  /// Maps [p] from the box [from] onto the box [to], stretching it.
  static Offset mapPoint(Offset p, Rect from, Rect to) => Offset(
    to.left +
        (p.dx - from.left) * (from.width == 0 ? 1 : to.width / from.width),
    to.top +
        (p.dy - from.top) * (from.height == 0 ? 1 : to.height / from.height),
  );

  /// Stretches this stroke from the box [from] onto the box [to]: resizing
  /// by a side or corner handle.
  void mapRect(Rect from, Rect to) {
    final sx = from.width == 0 ? 1.0 : to.width / from.width;
    final sy = from.height == 0 ? 1.0 : to.height / from.height;
    _scaleWidth(stretchAcross(sx, sy));
    _mapHoles((p) => mapPoint(p, from, to), (sx + sy) / 2);
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final q = mapPoint(Offset(p.x, p.y), from, to);
      points[i] = PointVector(q.dx, q.dy, p.pressure);
    }
    markPolygonNeedsUpdating();
  }

  /// Works out the outline or pencil grains this stroke is drawn with. They
  /// are plain lists, so this can run on another isolate.
  void prepareForDrawing() {
    if (points.isEmpty) return;
    switch (toolId) {
      case .pencil:
        pencilGrain;
      case .fountainPen || .calligraphyPen:
        highQualityPolygon;
      default:
        // drawn along their center line, which is quick
        break;
    }
  }

  /// Forgets everything worked out from the points, after they changed.
  ///
  /// [keepSettledGrain] keeps the pencil grains along the part of the line
  /// that can't change any more: only true when points were added at the end,
  /// or when the stroke was only marked complete.
  void markPolygonNeedsUpdating({bool keepSettledGrain = false}) {
    _forgetOutline();
    _steadied = null;
    _widthsOf = null;
    _pencilGrain = null;
    if (!keepSettledGrain) _grainDone = null;
  }

  /// Forgets what depends on [_predictedPoint] or [options], but not on the
  /// steadied line alone.
  void _forgetOutline() {
    _version++;
    _inkVertices = null;
    _tri = null;
    _cutFrom = null;
    _lowQualityPolygon = null;
    _highQualityPolygon = null;
    _lowQualityPath = null;
    _highQualityPath = null;
    _centerlinePath = null;
    _polylinePath = null;
    _tapeStamps = null;
    _tapeBorder = null;
  }

  new({
    required this._color,
    required this.pressureEnabled,
    required this.options,
    required this.pageIndex,
    required this.page,
    required this.toolId,
  });

  factory fromJson(
    Map<String, dynamic> json, {
    required int fileVersion,
    required int pageIndex,
    required HasSize page,
  }) {
    assert(json['i'] == pageIndex || json['i'] == null);
    switch (json['shape'] as String?) {
      case null:
        break;
      case 'circle':
        return CircleStroke.fromJson(
          json,
          fileVersion: fileVersion,
          pageIndex: pageIndex,
          page: page,
        );
      case 'rect':
        return RectangleStroke.fromJson(
          json,
          fileVersion: fileVersion,
          pageIndex: pageIndex,
          page: page,
        );
      default:
        log.severe('Unknown shape: ${json['shape']}');
    }

    final ToolId toolId = .parsePenType(json['ty'], fallback: .fountainPen);

    final options = StrokeOptions.fromJson(json);
    final pressureEnabled = json['pe'] ?? defaultPressureEnabled;
    if (toolId == .shapePen) {
      // Shapes are drawn without smoothing or streamline, which bent their
      // straight edges.
      options.smoothing = 0;
      options.streamline = 0;
    }

    final Color color;
    switch (json['c']) {
      case (final int value):
        color = Color(value);
      case (final Int64 value):
        color = Color(value.toInt());
      case null:
        color = defaultColor;
      default:
        throw Exception(
          'Invalid color value: (${json['c'].runtimeType}) ${json['c']}',
        );
    }

    final offset = Offset(json['ox'] ?? 0, json['oy'] ?? 0);
    final pointsJson = json['p'] as List<dynamic>;
    final Iterable<PointVector> points;
    if (fileVersion >= 13) {
      points = pointsJson.map(
        (point) => PointExtensions.fromBsonBinary(json: point, offset: offset),
      );
    } else {
      points = pointsJson.map(
        // ignore: deprecated_member_use_from_same_package
        (point) => PointExtensions.fromJson(
          json: Map<String, dynamic>.from(point),
          offset: offset,
        ),
      );
    }

    return Stroke(
        color: color,
        pressureEnabled: pressureEnabled,
        options: options,
        pageIndex: pageIndex,
        page: page,
        toolId: toolId,
      )
      ..points.addAll(points)
      ..tapePattern = TapePattern.values.firstWhere(
        (pattern) => pattern.name == json['tapePattern'],
        orElse: () => .plain,
      )
      ..tapeCustom = json['tc'] as String?
      ..inkLine = ShapeLine.values.firstWhere(
        (line) => line.name == json['il'],
        orElse: () => .solid,
      )
      ..shapeStyle = ShapeStyle.fromJson(json['ss'])
      ..holes = holesFromJson(json['eh'])
      ..clips = clipsFromJson(json['cl'])
      ..onFrontImage = json['of'] as bool?
      ..afterImage = json['ai'] as int?
      ..nib2 = json['n2'] == true
      ..steadyLine = json['sl'] == true
      ..steady2 = json['st2'] == true
      ..flatEnds = json['fl'] == true
      ..speedInk = json['sv'] == true;
  }

  /// The points' bytes from the last save, and the points they were made
  /// from (as the float32 that's saved). A save encoded every point of every
  /// stroke again, on the main thread: on a big note that's hundreds of
  /// thousands of small objects each time. Now only a changed stroke is.
  List<BsonBinary>? _savedPoints;
  Float32List? _savedFrom;
  static final _f32 = Float32List(1);
  static double _asSaved(double v) {
    _f32[0] = v;
    return _f32[0];
  }

  List<BsonBinary> _pointsBson() {
    final cached = _savedPoints, from = _savedFrom;
    if (cached != null && from != null && _sameAsSaved(from, cached.length)) {
      return cached;
    }
    final finite = points.where((point) => point.isFinite).toList();
    final saved = Float32List(finite.length * 3);
    for (final (j, point) in finite.indexed) {
      saved[j * 3] = point.x;
      saved[j * 3 + 1] = point.y;
      saved[j * 3 + 2] = point.pressure ?? double.nan;
    }
    _savedFrom = saved;
    return _savedPoints = [for (final point in finite) point.toBsonBinary()];
  }

  bool _sameAsSaved(Float32List from, int count) {
    var j = 0;
    for (final point in points) {
      if (!point.isFinite) continue;
      if (j == count) return false;
      final k = j * 3;
      if (_asSaved(point.x) != from[k] || _asSaved(point.y) != from[k + 1]) {
        return false;
      }
      final pressure = point.pressure;
      if (pressure == null) {
        if (!from[k + 2].isNaN) return false;
      } else if (from[k + 2].isNaN || _asSaved(pressure) != from[k + 2]) {
        return false;
      }
      j++;
    }
    return j == count;
  }

  Map<String, dynamic> toJson() {
    // these json keys should not be the same as the ones in [StrokeOptions.toJson]
    return {
      'shape': null,
      'p': _pointsBson(),
      'i': pageIndex,
      'ty': toolId.id,
      'pe': pressureEnabled,
      'c': color.toARGB32(),
      if (toolId == .tape) 'tapePattern': tapePattern.name,
      if (toolId == .tape && tapeCustom != null) 'tc': tapeCustom,
      if (inkLine != .solid) 'il': inkLine.name,
      if (shapeStyle != null) 'ss': shapeStyle!.toJson(),
      if (holes.isNotEmpty) 'eh': holesJson,
      if (clips.isNotEmpty) 'cl': clipsJson,
      if (onFrontImage != null) 'of': onFrontImage,
      if (afterImage != null) 'ai': afterImage,
      if (flatEnds) 'fl': true,
      if (speedInk) 'sv': true,
      if (nib2) 'n2': true,
      if (steadyLine) 'sl': true,
      if (steady2) 'st2': true,
    }..addAll(options.toJson());
  }

  /// Where the pen is about to be: drawn at the tip of an unfinished stroke,
  /// never saved. ponytail: extrapolation only, Flutter has no access to
  /// Android's front-buffer or motion-predictor APIs.
  Offset? _predictedPoint;

  /// Longest prediction, so a jerky sample can't throw a spike of ink.
  static const _maxPrediction = 16.0;

  /// Sets [_predictedPoint] two samples ahead. As in the touch predictor on
  /// Oplus phones: a straight guess at the speed of the last 3 samples (the
  /// average doesn't jump around like a single sample does), averaged with a
  /// cubic fitted through the last few samples, which follows a curve the
  /// straight guess would overshoot. The cubic is damped and kept near the
  /// straight guess, as one can swing wildly past the points it was fitted to.
  // ponytail: steps by sample, not by time: the points have no timestamps.
  void predictNextPoint({double maxDistance = _maxPrediction}) {
    if (points.length < 4) return;
    if (maxDistance <= 0) {
      // only up to the pen, see [Pen.onDragUpdate]
      _predictedPoint = Offset(points.last.x, points.last.y);
      _forgetOutline();
      return;
    }
    const ahead = 2.0;
    final last = Offset(points.last.x, points.last.y);
    final before = points[points.length - 4];
    final linear =
        last + Offset(last.dx - before.x, last.dy - before.y) * (ahead / 3);
    var guess = linear;
    if (points.length >= 6) {
      final recent = points.sublist(max(points.length - 8, 0));
      final x = fitCubicAhead([for (final p in recent) p.x], ahead * 0.8);
      final y = fitCubicAhead([for (final p in recent) p.y], ahead * 0.8);
      if (x != null && y != null) {
        var curved = Offset(x, y) - linear;
        final reach = maxDistance / 2;
        if (curved.distance > reach) curved = curved / curved.distance * reach;
        guess = linear + curved / 2;
      }
    }
    final delta = guess - last;
    final distance = delta.distance;
    _predictedPoint =
        last +
        (distance > maxDistance ? delta / distance * maxDistance : delta);
    // the steadied line and pencil grains don't use the prediction
    _forgetOutline();
  }

  /// The least-squares cubic through [values], taken one per step, evaluated
  /// [ahead] steps past the last one. Null if the fit can't be solved.
  @visibleForTesting
  static double? fitCubicAhead(List<double> values, double ahead) {
    final n = values.length;
    if (n < 4) return null;
    // normal equations (AᵀA)c = Aᵀv, with time 0 at the last value
    final m = List.generate(4, (_) => List.filled(5, 0.0));
    for (int i = 0; i < n; i++) {
      final t = (i - (n - 1)).toDouble();
      final row = [1.0, t, t * t, t * t * t];
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          m[r][c] += row[r] * row[c];
        }
        m[r][4] += row[r] * values[i];
      }
    }
    // Gaussian elimination with partial pivoting
    for (int col = 0; col < 4; col++) {
      var pivot = col;
      for (int r = col + 1; r < 4; r++) {
        if (m[r][col].abs() > m[pivot][col].abs()) pivot = r;
      }
      if (m[pivot][col].abs() < 1e-9) return null;
      final swap = m[col];
      m[col] = m[pivot];
      m[pivot] = swap;
      for (int r = 0; r < 4; r++) {
        if (r == col) continue;
        final f = m[r][col] / m[col][col];
        for (int c = col; c < 5; c++) {
          m[r][c] -= f * m[col][c];
        }
      }
    }
    final c = [for (int r = 0; r < 4; r++) m[r][4] / m[r][r]];
    final result = c[0] + ahead * (c[1] + ahead * (c[2] + ahead * c[3]));
    return result.isFinite ? result : null;
  }

  void addPoint(Offset point, [double? pressure]) {
    _predictedPoint = null;
    if (!pressureEnabled) {
      pressure = null;
    } else if (pressure != null) {
      options.simulatePressure = false;
    }

    points.add(PointVector(point.dx, point.dy, pressure));
    markPolygonNeedsUpdating(keepSettledGrain: true);
  }

  /// Makes this stroke a straight line from its first point to [end].
  void setEndOfLine(Offset end) {
    final first = points.first;
    final (start, last) = snapLine(
      first,
      PointVector(end.dx, end.dy, first.pressure),
    );
    points
      ..clear()
      ..add(start)
      ..add(last);
    markPolygonNeedsUpdating();
  }

  /// Replaces this stroke's points, for a shape being dragged out.
  void replacePoints(List<Offset> newPoints) {
    points
      ..clear()
      ..addAll([for (final p in newPoints) PointVector(p.dx, p.dy, null)]);
    markPolygonNeedsUpdating();
  }

  /// The area this stroke covers, including its width.
  Rect get bounds {
    // Kept until the points or the size change, as [_pointBounds] is: it's
    // asked for on every paint, for every stroke on the page, and went
    // through all the points each time.
    if (points.isNotEmpty &&
        _boundsVersion == _version &&
        _boundsLength == points.length &&
        _boundsSize == options.size) {
      return _boundsCache!;
    }
    final line = centerPoints;
    if (line.isEmpty) return Rect.zero;
    var box = Rect.fromPoints(line.first, line.first);
    for (final p in line) {
      box = box.expandToInclude(Rect.fromPoints(p, p));
    }
    final result = box.inflate(options.size / 2);
    if (points.isNotEmpty) {
      _boundsCache = result;
      _boundsVersion = _version;
      _boundsLength = points.length;
      _boundsSize = options.size;
    }
    return result;
  }

  Rect? _boundsCache;
  int? _boundsVersion, _boundsLength;
  double? _boundsSize;

  void addPoints(List<Offset> points) {
    for (final point in points) {
      addPoint(point);
    }
  }

  void popFirstPoint() {
    points.removeAt(0);
    markPolygonNeedsUpdating();
  }

  /// Points that are closer than this
  /// threshold multiplied by the stroke's size
  /// will be counted as duplicates.
  static const _optimisePointsThreshold = 0.1;

  /// Removes points that are too close together. See [_optimisePointsThreshold].
  ///
  /// This function is idempotent, so running it multiple times
  /// will not change the result.
  ///
  /// This function does not change [_polygonNeedsUpdating].
  void optimisePoints({double thresholdMultiplier = _optimisePointsThreshold}) {
    if (points.length <= 3) return;

    final minDistance = options.size * thresholdMultiplier;

    // Remove points with null pressure because they were duplicates
    points.removeWhere((point) => point.pressure == null);

    for (int i = 1; i < points.length - 1; i++) {
      final point = points[i];
      final prev = points[i - 1];
      final next = points[i + 1];

      if (prev.distanceSquaredTo(point) < minDistance * minDistance &&
          point.distanceSquaredTo(next) < minDistance * minDistance) {
        points.removeAt(i);
        i--;
      }
    }
  }

  @protected
  List<Offset> getPolygon({required StrokeQuality quality}) {
    if (!pressureEnabled) {
      options.simulatePressure = false;
    }
    if (toolId == .calligraphyPen) return _chiselPolygon();
    // A brush steadied too since [nib2]: its outline around the hand's raw
    // points had lumps where it moved slowly, and trailed far behind the pen
    // at high stabilization.
    final steady =
        (toolId == .fountainPen ||
            toolId == .pencil ||
            (nib2 && toolId == .brushPen)) &&
        !quality.isLowQuality;
    // The steadied points are a different list to [points], so the pressure
    // can't be kept on them: it's worked out again whenever it's needed.
    final rememberSimulatedPressure =
        !steady &&
        quality == .high &&
        options.simulatePressure &&
        options.isComplete;

    final predicted = _predictedPoint;
    final ownLine = _steadiesOwnLine && !quality.isLowQuality;
    final line = steady
        ? _steadiedPoints()
        : ownLine
        ? _steadiedLine()
        : skipPoints(points, quality.N);
    // Reduce latency: the steadied line runs a little behind the pen; the ink
    // reaches where the pen is, then any guess beyond.
    final pen = points.last;
    final polygon = getStroke(
      predicted != null && !options.isComplete
          ? [
              ...line,
              if ((steady || ownLine) &&
                  (line.last.x - pen.x).abs() + (line.last.y - pen.y).abs() >
                      0.01)
                PointVector(pen.x, pen.y, line.last.pressure),
              PointVector(predicted.dx, predicted.dy, line.last.pressure),
            ]
          : line,
      options: _opened(
        quality.isLowQuality
            ? options.copyWith(
                simulatePressure: false,
                smoothing: 0,
                streamline: 0,
              )
            : steady
            ? _nibOptions()
            : ownLine
            // already steadied
            ? options.copyWith(streamline: 0)
            : options,
      ),
      rememberSimulatedPressure: rememberSimulatedPressure && !ownLine,
    );

    if (rememberSimulatedPressure && !ownLine) {
      // Ensure we don't simulate pressure again
      options.simulatePressure = false;
      // Remove points that are too close together
      optimisePoints();
    }

    return polygon;
  }

  /// Whether this is a piece of a longer live stroke ([livePiece]) that
  /// goes on before its first point, or after its last: that end is round
  /// instead of narrowing, so the pieces join without a seam.
  bool _openStart = false, _openEnd = false;

  StrokeOptions _opened(StrokeOptions options) => !_openStart && !_openEnd
      ? options
      : options.copyWith(
          start: _openStart
              ? StrokeEndOptions.start(cap: true, taperEnabled: false)
              : null,
          end: _openEnd
              ? StrokeEndOptions.end(cap: true, taperEnabled: false)
              : null,
        );

  /// The ink as triangles, ready for the GPU, or null for a stroke drawn as
  /// its outline path. An outline is a shape the GPU has to cut into
  /// triangles itself every time it's drawn: into each image and each tile
  /// of a zoomed page. On a page full of writing that took up to half a
  /// second; the triangles are worked out once, here.
  ///
  /// The ballpoint, fountain and brush pens: the calligraphy pen's chisel
  /// and the pencil's grains are their own shapes.
  ui.Vertices? get inkVertices {
    if (!inkAsTriangles ||
        !const {
          ToolId.ballpointPen,
          ToolId.fountainPen,
          ToolId.brushPen,
        }.contains(toolId) ||
        _inkLine != .solid ||
        points.isEmpty ||
        // A fountain or brush pen's handwriting is drawn as its outline: the
        // outline's round turns cancel out where they wind the other way,
        // which triangles can't do, and its sharp turns came out as knobs
        // (beads). Only a very long line (ten seconds or so), where drawing
        // it again and again took the GPU a long time, is triangles.
        (toolId != .ballpointPen && points.length < trianglesFrom)) {
      return null;
    }
    return _inkVertices ??= () {
      final reused = _tri == null ? _reusedTriangles() : null;
      if (reused != null) inkFromCut = true;
      final made = _tri ??= reused ?? _triangles();
      // nothing to draw yet (the pen down, not moved): nothing, not the
      // outline instead
      if (made == null) {
        return ui.Vertices.raw(ui.VertexMode.triangles, Float32List(0));
      }
      return ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.sublistView(made.buf, 0, made.used),
      );
    }();
  }

  /// The triangles of [inkVertices], and for each step along the line where
  /// its triangles start in [_Triangles.buf] and which of [points] it's
  /// from: a piece the eraser leaves takes its middle from here.
  _Triangles? _tri;

  /// Whether [inkVertices] came from the stroke this was cut from.
  @visibleForTesting
  var inkFromCut = false;

  /// The stroke this was cut from by the eraser, and for each of [points]
  /// the index of the same point in it (-1 for one the eraser added).
  ({Stroke parent, Int32List src})? _cutFrom;

  /// A piece the eraser cut: its triangles away from the cuts are the
  /// stroke's it was cut from, as they were; only the ends are worked out.
  /// Worked out whole, every piece the eraser left of a long scribble took
  /// 20-45 ms on each move of the eraser, and the ink left could shift a
  /// little where its line was steadied afresh.
  _Triangles? _reusedTriangles() {
    final cut = _cutFrom;
    if (cut == null || cut.src.length != points.length) return null;
    final from = cut.parent._tri;
    if (from == null) return null;
    const keep = 40, overlap = 6;
    final n = points.length;
    if (n < 2 * keep + 4 * overlap + 10) return null;
    final a = cut.src[keep], b = cut.src[n - 1 - keep];
    // the middle has to be the parent's points, one for one
    if (a < 0 || b < 0 || b - a != n - 1 - 2 * keep) return null;
    var j0 = -1, j1 = -1;
    for (int j = 0; j < from.steps; j++) {
      final at = from.stepSrc[j];
      if (j0 < 0 && at >= a) j0 = j;
      if (at <= b) j1 = j;
    }
    if (j0 < 0 || j1 - j0 < 3) return null;
    int here(int parentIndex) => keep + parentIndex - a;
    final headEnd = min(here(from.stepSrc[j0]) + overlap + 1, n);
    final tailStart = max(here(from.stepSrc[j1]) - overlap, 0);
    final head = livePiece(0, headEnd)._triangles();
    final tail = livePiece(tailStart, n)._triangles();
    if (head == null || tail == null) return null;
    final middleFrom = from.stepAt[j0 + 1], middleTo = from.stepAt[j1 + 1];
    final middle = middleTo - middleFrom;
    final used = head.used + middle + tail.used;
    final buf = Float32List(used)
      ..setRange(0, head.used, head.buf)
      ..setRange(head.used, head.used + middle, from.buf, middleFrom)
      ..setRange(head.used + middle, used, tail.buf);
    final steps = head.steps + (j1 - j0) + tail.steps;
    final stepAt = Int32List(steps + 1), stepSrc = Int32List(steps);
    var k = 0;
    for (int j = 0; j < head.steps; j++, k++) {
      stepAt[k] = head.stepAt[j];
      stepSrc[k] = head.stepSrc[j];
    }
    for (int j = j0 + 1; j <= j1; j++, k++) {
      stepAt[k] = from.stepAt[j] - middleFrom + head.used;
      stepSrc[k] = here(from.stepSrc[j]);
    }
    for (int j = 0; j < tail.steps; j++, k++) {
      stepAt[k] = tail.stepAt[j] + head.used + middle;
      stepSrc[k] = tail.stepSrc[j] + tailStart;
    }
    stepAt[steps] = used;
    return (
      buf: buf,
      used: used,
      steps: steps,
      stepAt: stepAt,
      stepSrc: stepSrc,
    );
  }

  ui.Vertices? _inkVertices;

  /// Points a fountain or brush pen line has before it's drawn as triangles:
  /// ten seconds of writing without lifting the pen (the user's tablet gives
  /// about 200 points a second; a long row of loops was ~1200).
  static const trianglesFrom = 2000;

  /// Off in tests that compare pixels drawn at different sizes: the test
  /// renderer doesn't smooth the edges of triangles (the app's does, with
  /// multisampling), so they came out jagged differently at each size.
  @visibleForTesting
  static var inkAsTriangles = true;

  bool get hasInkVertices => _inkVertices != null;

  _Triangles? _triangles() {
    if (!pressureEnabled) options.simulatePressure = false;
    // the same line and settings [getPolygon] outlines
    final steady = toolId == .fountainPen || (nib2 && toolId == .brushPen);
    final ownLine = !steady && _steadiesOwnLine;
    final opts = _opened(
      steady
          ? _nibOptions()
          : ownLine
          ? options.copyWith(streamline: 0)
          : options,
    );
    final lineSrc = <int>[];
    final List<PointVector> line;
    if (steady) {
      line = _steadiedPoints();
      lineSrc.addAll(_steadiedSrc ?? [for (int i = 0; i < line.length; i++) i]);
    } else if (ownLine) {
      line = _steadiedLine(src: lineSrc);
    } else {
      line = skipPoints(points, StrokeQuality.high.N);
      lineSrc.addAll([for (int i = 0; i < line.length; i++) i]);
    }
    if (line.isEmpty || lineSrc.length != line.length) return null;
    final predicted = _predictedPoint;
    final pen = points.last;
    final input = predicted != null && !opts.isComplete
        ? [
            ...line,
            if ((steady || ownLine) &&
                (line.last.x - pen.x).abs() + (line.last.y - pen.y).abs() >
                    0.01)
              PointVector(pen.x, pen.y, line.last.pressure),
            PointVector(predicted.dx, predicted.dy, line.last.pressure),
          ]
        : line;
    if (input.isEmpty || opts.size <= 0) return null;

    // The points the pen library outlines ([getStrokePoints]), worked out
    // the same way but into plain lists: an object, a vector and a closure
    // for each point made the first cut of a long fountain pen scribble by
    // the eraser take over 100 ms.
    final rawX = <double>[], rawY = <double>[], rawP = <double>[];
    final rawSrc = <int>[];
    for (final (i, point) in input.indexed) {
      rawX.add(point.x);
      rawY.add(point.y);
      rawP.add(point.pressure ?? 0.5);
      rawSrc.add(i < lineSrc.length ? lineSrc[i] : points.length - 1);
    }
    if (rawX.length == 2 &&
        rawX[0] == rawX[1] &&
        rawY[0] == rawY[1] &&
        rawP[0] == rawP[1]) {
      rawX.removeLast();
      rawY.removeLast();
      rawP.removeLast();
      rawSrc.removeLast();
    }
    if (rawX.length == 2) {
      final (x0, y0, p0) = (rawX[0], rawY[0], rawP[0]);
      final (x1, y1, p1) = (rawX[1], rawY[1], rawP[1]);
      final s1 = rawSrc[1];
      rawX.removeLast();
      rawY.removeLast();
      rawP.removeLast();
      rawSrc.removeLast();
      for (int k = 1; k < 5; k++) {
        final t = k / 4;
        rawX.add(x0 + (x1 - x0) * t);
        rawY.add(y0 + (y1 - y0) * t);
        rawP.add(p0 + (p1 - p0) * t);
        rawSrc.add(k == 4 ? s1 : rawSrc[0]);
      }
    }
    if (rawX.length == 1) {
      rawX.add(rawX[0] + 1);
      rawY.add(rawY[0] + 1);
      rawP.add(rawP[0]);
      rawSrc.add(rawSrc[0]);
    }
    final follow = 0.15 + (1 - opts.streamline) * 0.85;
    final count = rawX.length;
    final xs = Float64List(count), ys = Float64List(count);
    final ps = Float64List(count), gaps = Float64List(count);
    final runs = Float64List(count);
    final vxs = Float64List(count), vys = Float64List(count);
    final stepSrc = Int32List(count);
    stepSrc[0] = rawSrc[0];
    xs[0] = rawX[0];
    ys[0] = rawY[0];
    ps[0] = rawP[0];
    var m = 1;
    // The pen library leaves out the first points until the line is as long
    // as the pen is wide. While writing that showed as a speck where the pen
    // went down, and then the line jumped out of it: the ink starts at once
    // then. The finished line is as the library has it.
    var reached = !opts.isComplete;
    var running = 0.0;
    final lastIndex = count - 1;
    for (int i = 0; i < count; i++) {
      final px = xs[m - 1], py = ys[m - 1], pp = ps[m - 1];
      final double x, y, pressure;
      if (opts.isComplete && i == lastIndex) {
        (x, y, pressure) = (rawX[i], rawY[i], rawP[i]);
      } else {
        x = px + (rawX[i] - px) * follow;
        y = py + (rawY[i] - py) * follow;
        pressure = pp + (rawP[i] - pp) * follow;
      }
      if (x == px && y == py && pressure == pp) continue;
      final dx = px - x, dy = py - y;
      final gap = sqrt(dx * dx + dy * dy);
      running += gap;
      if (i < lastIndex && !reached) {
        if (running < opts.size) continue;
        reached = true;
      }
      xs[m] = x;
      ys[m] = y;
      ps[m] = pressure;
      stepSrc[m] = rawSrc[i];
      gaps[m] = gap;
      runs[m] = running;
      // towards the point before, as the pen library's vectors
      if (gap > 0) {
        vxs[m] = dx / gap;
        vys[m] = dy / gap;
      }
      m++;
    }
    if (m > 1) {
      vxs[0] = vxs[1];
      vys[0] = vys[1];
    } else if (!opts.isComplete) {
      // the pen down but not moved yet: no speck before the line
      return null;
    }

    // The outline exactly as the pen library works it out
    // ([getStrokeOutlinePoints]: its left and right sides, the round turns
    // at sharp corners and the caps), only kept as triangles between the two
    // sides instead of one shape. A strip of its own around the line had
    // round dots at every bend and a different width, which showed as beads.
    final size = opts.size;
    final total = runs[m - 1];
    final taperStart = opts.start.taperEnabled
        ? opts.start.customTaper ?? max(size, total)
        : 0.0;
    final taperEnd = opts.end.taperEnabled
        ? opts.end.customTaper ?? max(size, total)
        : 0.0;
    final minDistance = pow(size * opts.smoothing, 2);
    double simulated(int i, double before) {
      final speed = min(1.0, gaps[i] / size);
      final rate = min(1.0, 1.0 - speed);
      return min(1.0, before + (rate - before) * (speed * 0.275));
    }

    double radiusAt(double pressure) =>
        size * opts.easing(0.5 - opts.thinning * (0.5 - pressure));

    var prevPressure = () {
      var smoothed = ps[0];
      for (int i = 0; i < min(10, m - 1); i++) {
        final pressure = opts.simulatePressure ? simulated(i, smoothed) : ps[i];
        smoothed = (smoothed + pressure) / 2;
      }
      return smoothed;
    }();
    var radius = radiusAt(ps[m - 1]);
    double? firstRadius;
    var prevVx = vxs[0], prevVy = vys[0];
    var plx = xs[0], ply = ys[0], prx = xs[0], pry = ys[0];
    var prevSharp = false;
    final lx = <double>[], ly = <double>[], rx = <double>[], ry = <double>[];
    // how many left and right points there were after each step
    final leftAfter = Int32List(m), rightAfter = Int32List(m);

    (double, double) rotate(
      double x,
      double y,
      double cx,
      double cy,
      double r,
    ) {
      final sn = sin(r), cs = cos(r);
      final px = x - cx, py = y - cy;
      return (px * cs - py * sn + cx, px * sn + py * cs + cy);
    }

    for (int i = 0; i < m; i++) {
      leftAfter[i] = i == 0 ? 0 : leftAfter[i - 1];
      rightAfter[i] = i == 0 ? 0 : rightAfter[i - 1];
      final x = xs[i], y = ys[i], vx = vxs[i], vy = vys[i];
      final run = runs[i];
      // noise at the end of a finished line
      if (i < m - 1 &&
          opts.isComplete &&
          !prevSharp &&
          total - run < size / 2) {
        continue;
      }
      if (opts.thinning != 0) {
        final double pressure;
        if (opts.simulatePressure) {
          pressure = simulated(i, prevPressure);
          prevPressure = pressure;
        } else {
          pressure = ps[i];
        }
        radius = radiusAt(pressure);
      } else {
        radius = size / 2;
      }
      firstRadius ??= radius;
      final ts = run < taperStart ? opts.start.easing(run / taperStart) : 1.0;
      final te = total - run < taperEnd
          ? opts.end.easing((total - run) / taperEnd)
          : 1.0;
      radius = max(0.01, radius * min(ts, te));

      final last = i == m - 1;
      final nvx = last ? vx : vxs[i + 1], nvy = last ? vy : vys[i + 1];
      final nextDpr = last ? 1.0 : vx * nvx + vy * nvy;
      final prevDpr = vx * prevVx + vy * prevVy;
      final maxDpr = size / 128;
      final pointSharp = prevDpr < maxDpr && !prevSharp;
      final nextSharp = nextDpr < maxDpr;
      if (pointSharp || nextSharp) {
        // A sharp turn. The pen library puts half a circle on each side
        // here; filled as one outline, the two cancel out where they wind
        // the other way, and the turn comes to a point. As triangles they
        // don't cancel, and every turn got a round knob: beads. So: a
        // point where the line doubles back, a cut corner elsewhere.
        final n1x = prevVy, n1y = -prevVx, n2x = nvy, n2y = -nvx;
        final double tlx, tly, trx, try_;
        if (prevVx * nvx + prevVy * nvy < -0.5) {
          // doubling back: both sides meet a little ahead of the turn
          final tipX = x - prevVx * radius * 0.6;
          final tipY = y - prevVy * radius * 0.6;
          lx.add(tipX);
          ly.add(tipY);
          rx.add(tipX);
          ry.add(tipY);
          (tlx, tly, trx, try_) = (tipX, tipY, tipX, tipY);
        } else {
          lx
            ..add(x - n1x * radius)
            ..add(x - n2x * radius);
          ly
            ..add(y - n1y * radius)
            ..add(y - n2y * radius);
          rx
            ..add(x + n1x * radius)
            ..add(x + n2x * radius);
          ry
            ..add(y + n1y * radius)
            ..add(y + n2y * radius);
          (tlx, tly) = (x - n2x * radius, y - n2y * radius);
          (trx, try_) = (x + n2x * radius, y + n2y * radius);
        }
        (plx, ply, prx, pry) = (tlx, tly, trx, try_);
        if (nextSharp) prevSharp = true;
        leftAfter[i] = lx.length;
        rightAfter[i] = rx.length;
        continue;
      }
      prevSharp = false;
      if (last) {
        final ox = vy * radius, oy = -vx * radius;
        lx.add(x - ox);
        ly.add(y - oy);
        rx.add(x + ox);
        ry.add(y + oy);
      } else {
        final bx = nvx + (vx - nvx) * nextDpr, by = nvy + (vy - nvy) * nextDpr;
        final ox = by * radius, oy = -bx * radius;
        final tlx = x - ox, tly = y - oy;
        if (i <= 1 || pow(plx - tlx, 2) + pow(ply - tly, 2) > minDistance) {
          lx.add(tlx);
          ly.add(tly);
          (plx, ply) = (tlx, tly);
        }
        final trx = x + ox, try_ = y + oy;
        if (i <= 1 || pow(prx - trx, 2) + pow(pry - try_, 2) > minDistance) {
          rx.add(trx);
          ry.add(try_);
          (prx, pry) = (trx, try_);
        }
        prevVx = vx;
        prevVy = vy;
      }
      leftAfter[i] = lx.length;
      rightAfter[i] = rx.length;
    }

    var out = Float32List(max(64, (lx.length + rx.length) * 6 + 400));
    var used = 0;
    void triangle(
      double ax,
      double ay,
      double bx,
      double by,
      double cx,
      double cy,
    ) {
      if (used + 6 > out.length) {
        out = Float32List(out.length * 2)..setRange(0, used, out);
      }
      out[used++] = ax;
      out[used++] = ay;
      out[used++] = bx;
      out[used++] = by;
      out[used++] = cx;
      out[used++] = cy;
    }

    // Between the left side from point [l0] to [l1] and the right from [r0]
    // to [r1], stepping along whichever is behind.
    void zip(int l0, int l1, int r0, int r1) {
      if (l0 < 0 || r0 < 0) return;
      var i = l0, j = r0;
      final ln = max(l1 - l0, 1), rn = max(r1 - r0, 1);
      while (i < l1 || j < r1) {
        if (j >= r1 || (i < l1 && (i + 1 - l0) / ln <= (j + 1 - r0) / rn)) {
          triangle(lx[i], ly[i], rx[j], ry[j], lx[i + 1], ly[i + 1]);
          i++;
        } else {
          triangle(lx[i], ly[i], rx[j], ry[j], rx[j + 1], ry[j + 1]);
          j++;
        }
      }
    }

    final stepAt = Int32List(m + 1);
    for (int i = 0; i < m; i++) {
      stepAt[i] = used;
      if (i == 0) continue;
      zip(
        leftAfter[i - 1] - 1,
        leftAfter[i] - 1,
        rightAfter[i - 1] - 1,
        rightAfter[i] - 1,
      );
    }
    stepAt[m] = used;

    // the caps, as fans around the line's ends
    final fx = xs[0], fy = ys[0];
    final (ex, ey) = m > 1
        ? (xs[m - 1], ys[m - 1])
        : (fx + vxs[0], fy + vys[0]);
    void fan(double cx, double cy, List<double> px, List<double> py) {
      for (int k = 0; k + 1 < px.length; k++) {
        triangle(cx, cy, px[k], py[k], px[k + 1], py[k + 1]);
      }
    }

    if (m == 1 || lx.isEmpty || rx.isEmpty) {
      if (!(taperStart > 0 || taperEnd > 0) || opts.isComplete) {
        // a dot
        var dx = fx - ex, dy = fy - ey;
        final length = sqrt(dx * dx + dy * dy);
        (dx, dy) = length == 0 ? (0.0, 0.0) : (dx / length, dy / length);
        final r = firstRadius ?? radius;
        final (sx, sy) = (fx - dy * r, fy + dx * r);
        final px = <double>[], py = <double>[];
        for (double t = 0; t <= 1.0001; t += 1 / 13) {
          final (ax, ay) = rotate(sx, sy, fx, fy, pi * 2 * t);
          px.add(ax);
          py.add(ay);
        }
        fan(fx, fy, px, py);
      }
    } else {
      // start
      if (!(taperStart > 0) && opts.start.cap) {
        final px = <double>[rx.first], py = <double>[ry.first];
        for (double t = 1 / 13; t <= 1; t += 1 / 13) {
          final (ax, ay) = rotate(rx.first, ry.first, fx, fy, pi * t);
          px.add(ax);
          py.add(ay);
        }
        px.add(lx.first);
        py.add(ly.first);
        fan(fx, fy, px, py);
      } else if (!(taperStart > 0)) {
        triangle(fx, fy, rx.first, ry.first, lx.first, ly.first);
      }
      // end
      final dirx = -vys[m - 1], diry = vxs[m - 1];
      if (taperEnd > 0) {
        triangle(ex, ey, lx.last, ly.last, rx.last, ry.last);
      } else if (opts.end.cap) {
        final (sx, sy) = (ex + dirx * radius, ey + diry * radius);
        final px = <double>[lx.last], py = <double>[ly.last];
        for (double t = 1 / 29; t <= 1; t += 1 / 29) {
          final (ax, ay) = rotate(sx, sy, ex, ey, pi * 3 * t);
          px.add(ax);
          py.add(ay);
        }
        px.add(rx.last);
        py.add(ry.last);
        fan(ex, ey, px, py);
      } else {
        triangle(ex, ey, lx.last, ly.last, rx.last, ry.last);
      }
    }

    return (
      buf: out,
      used: used,
      steps: m,
      stepAt: stepAt,
      stepSrc: Int32List.sublistView(stepSrc, 0, m),
    );
  }

  /// [highQualityPath] of a big stroke in pieces, each with where it is,
  /// or null for a stroke too small to need it. Zoomed in, the page is drawn
  /// in tiles: a stroke across the page (a scribble of thousands of points)
  /// was drawn whole into every tile, which made each slow to come and the
  /// page stayed blurry. A tile draws only the pieces on it.
  List<({Rect area, Path path})>? get areaPieces {
    if (points.length < 240 ||
        _inkLine != .solid ||
        clips.isNotEmpty ||
        !const {
          ToolId.fountainPen,
          ToolId.ballpointPen,
          ToolId.brushPen,
          ToolId.calligraphyPen,
        }.contains(toolId)) {
      return null;
    }
    // by version: working out the whole outline only to tell if the pieces
    // are still right doubled the time each piece of an erased scribble took
    if (_areaPiecesOf == _version) return _areaPieces;
    const piece = 120, overlap = 6;
    final pieces = <({Rect area, Path path})>[];
    for (var at = 0; at < points.length - overlap; at += piece) {
      final to = min(at + piece, points.length);
      final path = livePiece(
        max(at - overlap, 0),
        points.length - to < overlap * 2 ? points.length : to,
      ).highQualityPath;
      pieces.add((area: path.getBounds(), path: path));
      if (points.length - to < overlap * 2) break;
    }
    _areaPiecesOf = _version;
    return _areaPieces = pieces;
  }

  int? _areaPiecesOf;
  List<({Rect area, Path path})>? _areaPieces;

  /// Points [from] to [to] of this live stroke as a stroke of their own. A
  /// long stroke being written is drawn a piece at a time: the pieces
  /// written already are kept as pictures, and only the last is worked out
  /// again as the pen moves. Worked out whole on every move, a stroke written
  /// for half a minute took 30 ms a frame and fell far behind the pen.
  Stroke livePiece(int from, int to) {
    final piece = copy()
      ..points.clear()
      ..points.addAll(points.sublist(from, to));
    piece._openStart = from > 0;
    piece._openEnd = to < points.length;
    if (nib2 && toolId == .fountainPen && (from > 0 || to < points.length)) {
      piece._widthsGiven = nibPressures.sublist(from, to);
    }
    if (from > 0 && points.length >= 3) {
      // steadied on from where the whole line's steadying is there: started
      // afresh at the pen's own point, each piece jumped ahead of the line
      // before it, a break at every join at high stabilization
      // ponytail: O(points) per piece; cache by [_version] if it shows up
      final bySpeed = toolId != .highlighter && toolId != .tape;
      piece._steadyFrom = _steadiedOffsets(bySpeed: bySpeed)[from];
    }
    if (to == points.length) piece._predictedPoint = _predictedPoint;
    return piece;
  }

  /// The shape swept by a broad nib held at one slant: thick when moving across
  /// the nib, a hairline when moving along it, with slanted ends. Where the two
  /// sides cross, the path's winding still fills the shape.
  List<Offset> _chiselPolygon() {
    final line = _steadiedPoints();
    if (line.isEmpty) return const [];
    const slant = -pi / 4;
    final along = Offset(cos(slant), sin(slant));
    final across = Offset(-along.dy, along.dx);
    // the nib's own thickness keeps a stroke along the slant from vanishing
    final thickness = options.size * 0.06;
    // Since [nib2], tip sharpness is how much the pressure widens the nib:
    // the setting was there but did nothing.
    final pressureWidens = nib2 ? 1.6 * _sharpness : 0.6;
    double halfWidth(PointVector point) => nib2
        ? options.size /
              2 *
              max(1 + pressureWidens * ((point.pressure ?? 0.5) - 0.5), 0.35)
        : options.size / 2 * (0.7 + 0.6 * (point.pressure ?? 0.5));

    if (line.length == 1) {
      final point = Offset(line.first.x, line.first.y);
      final half = along * halfWidth(line.first);
      final edge = across * thickness;
      return [
        point + half + edge,
        point + half - edge,
        point - half - edge,
        point - half + edge,
      ];
    }

    final left = <Offset>[], right = <Offset>[];
    for (int i = 0; i < line.length; i++) {
      // the direction over a few points: single samples jitter
      final before = line[max(i - 2, 0)];
      final after = line[min(i + 2, line.length - 1)];
      final normal = Offset(before.y - after.y, after.x - before.x);
      final facing =
          (normal.dx * along.dx + normal.dy * along.dy) *
          (normal.dx * across.dx + normal.dy * across.dy);
      final reach =
          along * halfWidth(line[i]) +
          across * (facing < 0 ? -thickness : thickness);
      final point = Offset(line[i].x, line[i].y);
      left.add(point + reach);
      right.add(point - reach);
    }
    return [...left, ...right.reversed];
  }

  /// Returns a [Path] that represents the stroke.
  ///
  /// If [smooth] is true, and the stroke is complete,
  /// the path will be a smooth curve between the points in [polygon].
  ///
  /// Otherwise, the path will use straight lines between each point
  /// in [polygon] for performance.
  @protected
  Path getPath(List<Offset> polygon, {bool smooth = true}) {
    // smooth the live stroke too, not only finished ones
    if (smooth && polygon.length > 2) {
      return smoothPathFromPolygon(polygon);
    }

    return Path()..addPolygon(polygon, true);
  }

  /// Returns a list with every Nth point in [points].
  static List<PointVector> skipPoints(List<PointVector> points, int N) {
    // Nothing is being skipped, just return [points].
    if (N <= 1) return points;

    // If we have too few points, skip less points
    final divided = points.length / N;
    const minDivided = 8;
    if (divided < minDivided) {
      N = (N * divided / minDivided).floor();
      if (N <= 1) return points;
    }

    return [
      for (int i = 0; i < points.length - 1; i += N) points[i],
      points.last,
    ];
  }

  static Path smoothPathFromPolygon(List<Offset> polygon) {
    final path = Path();
    path.moveTo(polygon.first.dx, polygon.first.dy);
    for (int i = 1; i < polygon.length - 1; i++) {
      final p1 = polygon[i];
      final p2 = polygon[i + 1];
      final mid = (p1 + p2) / 2;
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    return path..close();
  }

  String toSvgPath() {
    String toSvgPoint(Offset point) {
      return '${point.dx} '
          '${page.size.height - point.dy}';
    }

    // Remove NaN points, and convert to SVG coordinates
    final svgPoints = highQualityPolygon
        .where((offset) => offset.isFinite)
        .map(toSvgPoint);

    return svgPoints.isNotEmpty ? 'M${svgPoints.join('L')}' : '';
  }

  double get maxY {
    return points.isEmpty ? 0 : points.map((point) => point.y).reduce(max);
  }

  /// Uses the one_dollar_unistroke_recognizer package
  /// only to recognize straight lines.
  ///
  /// In addition, the line must be sufficiently long
  /// relative to [options.size].
  bool isStraightLine([int minLength = 5]) {
    if (points.length < 3) return false;

    final recognized = recognizeUnistroke(
      points,
      overrideReferenceUnistrokes: default$1Unistrokes
          .where((unistroke) => unistroke.name == DefaultUnistrokeNames.line)
          .toList(),
    );
    if (recognized == null) return false;
    assert(recognized.name == DefaultUnistrokeNames.line);
    if (recognized.score < 0.7) return false;

    final sqrLength = points.first.distanceSquaredTo(points.last);
    final sqrMinLength = minLength * minLength * options.size * options.size;
    return sqrLength >= sqrMinLength;
  }

  /// Replaces the points in this stroke with a straight line.
  ///
  /// If the resulting line is close to horizontal or vertical,
  /// it will be snapped to be exactly horizontal or vertical.
  void convertToLine() {
    assert(points.length >= 2);

    // Use the average pressure
    final pressure = points.map((point) => point.pressure ?? 0.5).average;
    var firstPoint = PointVector.fromOffset(
      offset: points.first,
      pressure: pressure,
    );
    var lastPoint = PointVector.fromOffset(
      offset: points.last,
      pressure: pressure,
    );

    // Snap to the horizontal or vertical axis
    (firstPoint, lastPoint) = snapLine(firstPoint, lastPoint);

    points.clear();
    points.add(firstPoint);
    points.add(lastPoint);
    points.add(lastPoint);
    options.isComplete = true;
    options.start.taperEnabled = false;
    options.end.taperEnabled = false;
  }

  /// Snaps a line to either horizontal or vertical
  /// if the angle is close enough.
  static (PointVector firstPoint, PointVector lastPoint) snapLine(
    PointVector firstPoint,
    PointVector lastPoint,
  ) {
    final dx = (lastPoint.dx - firstPoint.dx).abs();
    final dy = (lastPoint.dy - firstPoint.dy).abs();
    final angle = atan2(dy, dx);

    const snapAngle = 5 * pi / 180; // 5 degrees
    if (angle < snapAngle) {
      // snap to horizontal
      return (
        firstPoint,
        PointVector(lastPoint.dx, firstPoint.dy, lastPoint.pressure),
      );
    } else if (angle > pi / 2 - snapAngle) {
      // snap to vertical
      return (
        firstPoint,
        PointVector(firstPoint.dx, lastPoint.dy, lastPoint.pressure),
      );
    } else {
      return (firstPoint, lastPoint);
    }
  }

  /// The points the pen went through, or the outline for shapes without any.
  List<Offset> get centerPoints => points.isEmpty
      ? lowQualityPolygon
      : [for (final p in points) Offset(p.x, p.y)];

  /// Whether this stroke's longest side is at least [minLength] times its size,
  /// so a paused letter doesn't count as a shape for draw and hold.
  bool isLongEnoughForShape([int minLength = 5]) =>
      points.isNotEmpty &&
      _pointsBounds.size.longestSide >= minLength * options.size;

  Rect get _pointsBounds {
    var left = points.first.x, right = left;
    var top = points.first.y, bottom = top;
    for (final p in points) {
      left = min(left, p.x);
      right = max(right, p.x);
      top = min(top, p.y);
      bottom = max(bottom, p.y);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Whether this stroke goes back and forth like a scribble: a few reversals,
  /// and longer than the area it covers. Handwriting like "www" can pass too,
  /// which is why erasing also asks for [shareOver] of existing ink.
  bool get isScribble {
    if (points.length < 10) return false;
    final diagonal = _pointsBounds.size.bottomRight(Offset.zero).distance;
    if (diagonal == 0) return false;

    // measure in steps so hand jitter doesn't count as a reversal
    final step = diagonal / 20;
    var anchor = Offset(points.first.x, points.first.y);
    Offset? direction;
    var length = 0.0;
    var reversals = 0;
    for (final p in points) {
      final d = Offset(p.x, p.y) - anchor;
      if (d.distance < step) continue;
      length += d.distance;
      if (direction != null) {
        final cosine =
            (direction.dx * d.dx + direction.dy * d.dy) /
            (direction.distance * d.distance);
        if (cosine < -0.3) reversals++;
      }
      direction = d;
      anchor = Offset(p.x, p.y);
    }
    if (length < 2.6 * diagonal) return false;
    return reversals >= 3 || _passesBackAndForth() >= 4;
  }

  /// How many times this line goes across itself and back along the way it
  /// mostly goes, each time over at least half of it: a scribble rubbing
  /// out a wide area. Its turns are round, spread over several of the
  /// steps [isScribble] measures, so no one step turned back and it wasn't
  /// taken for a scribble. A word's loops go back only a little.
  int _passesBackAndForth() {
    var mx = 0.0, my = 0.0;
    for (final p in points) {
      mx += p.x;
      my += p.y;
    }
    mx /= points.length;
    my /= points.length;
    var sxx = 0.0, syy = 0.0, sxy = 0.0;
    for (final p in points) {
      final dx = p.x - mx, dy = p.y - my;
      sxx += dx * dx;
      syy += dy * dy;
      sxy += dx * dy;
    }
    final angle = 0.5 * atan2(2 * sxy, sxx - syy);
    final ax = cos(angle), ay = sin(angle);
    final along = [for (final p in points) (p.x - mx) * ax + (p.y - my) * ay];
    final extent = along.reduce(max) - along.reduce(min);
    if (extent == 0) return 0;
    final noise = extent * 0.08;
    var passes = 0;
    var direction = 0;
    var from = along.first, furthest = along.first;
    void endPass() {
      if ((furthest - from).abs() >= extent * 0.5) passes++;
      from = furthest;
    }

    for (final t in along) {
      if (direction == 0) {
        if ((t - from).abs() > noise) {
          direction = t > from ? 1 : -1;
          furthest = t;
        }
      } else if ((t - furthest) * direction > 0) {
        furthest = t;
      } else if ((furthest - t).abs() > noise) {
        endPass();
        direction = -direction;
        furthest = t;
      }
    }
    if (direction != 0) endPass();
    return passes;
  }

  /// How much of this stroke runs over [others], from 0 to 1. Also over
  /// where [alsoOver] says, e.g. inside a shape being rubbed out.
  double shareOver(List<Stroke> others, {bool Function(Offset)? alsoOver}) {
    final radius = max(options.size / 2, 4.0);
    var over = 0, total = 0;
    for (int i = 1; i < points.length; i += 2) {
      final a = Offset(points[i - 1].x, points[i - 1].y);
      final b = Offset(points[i].x, points[i].y);
      total++;
      if ((alsoOver?.call(a) ?? false) ||
          others.any((other) => other.touchedBy(a, b, radius))) {
        over++;
      }
    }
    return total == 0 ? 0 : over / total;
  }

  /// Whether [p] is inside this, a shape pen line that closes
  /// ([isClosedShape]): a circle, a box, not a line or an arc.
  bool hasInside(Offset p) {
    if (toolId != .shapePen || !bounds.contains(p) || !isClosedShape) {
      return false;
    }
    // even-odd: how many sides a line from p to the right crosses
    final line = centerPoints;
    var inside = false;
    for (int i = 0, j = line.length - 1; i < line.length; j = i++) {
      final a = line[i], b = line[j];
      if ((a.dy > p.dy) != (b.dy > p.dy) &&
          p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Whether this stroke's path touches [other].
  bool drawnOver(Stroke other) {
    final radius = max(options.size / 2, 4.0);
    if (!bounds.inflate(radius).overlaps(other.bounds)) return false;
    for (int i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      if (other.touchedBy(Offset(a.x, a.y), Offset(b.x, b.y), radius)) {
        return true;
      }
    }
    return false;
  }

  /// Whether segments [a]-[b] and [c]-[d] cross.
  static bool segmentsCross(Offset a, Offset b, Offset c, Offset d) {
    double side(Offset p, Offset q, Offset r) =>
        (q.dx - p.dx) * (r.dy - p.dy) - (q.dy - p.dy) * (r.dx - p.dx);
    return side(a, b, c) * side(a, b, d) < 0 &&
        side(c, d, a) * side(c, d, b) < 0;
  }

  /// Squared distance from [p] to the segment [a]-[b].
  static double sqrDistanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.distanceSquared;
    final t = len2 == 0
        ? 0.0
        : (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distanceSquared;
  }

  /// Whether the eraser moving from [a] to [b] with [radius] touches the
  /// outline of this stroke. Checks every outline edge, so long straight
  /// segments and fast eraser moves aren't missed.
  bool touchedBy(Offset a, Offset b, double radius) {
    // Far from the eraser: most strokes on a full page. Checking their outline
    // on every move of the eraser (and working the outline out, the first
    // time) made erasing on a page full of writing slow.
    if (!_maybeNear(a, b, radius)) return false;
    if (toolId == .tape) {
      // painted at its full width, unlike the outline below
      final line = centerPoints;
      final reach = radius + options.size / 2;
      final r2 = reach * reach;
      for (int i = 0; i < line.length; i++) {
        final p = line[i];
        final q = line[min(i + 1, line.length - 1)];
        if (segmentsCross(a, b, p, q) ||
            sqrDistanceToSegment(p, a, b) <= r2 ||
            sqrDistanceToSegment(a, p, q) <= r2 ||
            sqrDistanceToSegment(b, p, q) <= r2) {
          return true;
        }
      }
      return false;
    }
    if (points.length >= 2) {
      // Along the drawn line, as wide as the stroke at its widest: no
      // outline needed. Pieces the eraser has just cut are right next to it,
      // and working out their outlines here, on every move, made erasing a
      // page of writing lag.
      final reach = radius + options.size / 2;
      final r2 = reach * reach;
      final left = min(a.dx, b.dx) - reach, right = max(a.dx, b.dx) + reach;
      final top = min(a.dy, b.dy) - reach, bottom = max(a.dy, b.dy) + reach;
      for (int i = 1; i < points.length; i++) {
        final p0 = points[i - 1], p1 = points[i];
        if ((p0.x < left && p1.x < left) ||
            (p0.x > right && p1.x > right) ||
            (p0.y < top && p1.y < top) ||
            (p0.y > bottom && p1.y > bottom)) {
          continue;
        }
        final p = Offset(p0.x, p0.y), q = Offset(p1.x, p1.y);
        if (!p.isFinite || !q.isFinite) continue;
        if (segmentsCross(a, b, p, q) ||
            sqrDistanceToSegment(p, a, b) <= r2 ||
            sqrDistanceToSegment(q, a, b) <= r2 ||
            sqrDistanceToSegment(a, p, q) <= r2 ||
            sqrDistanceToSegment(b, p, q) <= r2) {
          return true;
        }
      }
      return false;
    }
    final polygon = lowQualityPolygon;
    if (polygon.isEmpty) return false;
    if (lowQualityPath.contains(b)) return true;
    final r2 = radius * radius;
    // only the outline's sides near the eraser's way are looked at closely
    final left = min(a.dx, b.dx) - radius, right = max(a.dx, b.dx) + radius;
    final top = min(a.dy, b.dy) - radius, bottom = max(a.dy, b.dy) + radius;
    for (int i = 0; i < polygon.length; i++) {
      final p = polygon[i];
      final q = polygon[(i + 1) % polygon.length];
      if ((p.dx < left && q.dx < left) ||
          (p.dx > right && q.dx > right) ||
          (p.dy < top && q.dy < top) ||
          (p.dy > bottom && q.dy > bottom)) {
        continue;
      }
      if (!p.isFinite || !q.isFinite) continue;
      if (segmentsCross(a, b, p, q) ||
          sqrDistanceToSegment(p, a, b) <= r2 ||
          sqrDistanceToSegment(a, p, q) <= r2 ||
          sqrDistanceToSegment(b, p, q) <= r2) {
        return true;
      }
    }
    return false;
  }

  /// The pieces left of this stroke once cut (as long as [first] and [last]
  /// of the points they were cut from weren't, each piece's first and last
  /// points are those), with the shape style of each: an arrowhead stays only
  /// at an end of the shape that's still there, not where it was cut. A closed
  /// shape has no ends: cut open, it gets no arrowheads, and the two pieces
  /// meeting where it was started are one again.
  List<(List<PointVector>, ShapeStyle?)> _pieceStyles(
    List<List<PointVector>> pieces,
    PointVector first,
    PointVector last,
  ) {
    final closed = isClosedShape;
    final keepsStart =
        pieces.first.isNotEmpty && identical(pieces.first.first, first);
    final keepsEnd =
        pieces.last.isNotEmpty && identical(pieces.last.last, last);
    var kept = [
      for (final piece in pieces)
        if (piece.length >= 2) piece,
    ];
    if (closed &&
        keepsStart &&
        keepsEnd &&
        kept.length >= 2 &&
        identical(kept.first, pieces.first) &&
        identical(kept.last, pieces.last)) {
      kept = [
        [...kept.last, ...kept.first.skip(1)],
        ...kept.sublist(1, kept.length - 1),
      ];
    }
    final style = shapeStyle;
    return [
      for (final piece in kept)
        (
          piece,
          style == null
              ? null
              : style.copyWith(
                  arrowStart:
                      !closed && keepsStart && identical(piece, pieces.first)
                      ? style.arrowStart
                      : ShapeArrow.none,
                  arrowEnd: !closed && keepsEnd && identical(piece, pieces.last)
                      ? style.arrowEnd
                      : ShapeArrow.none,
                ),
        ),
    ];
  }

  /// Precise erase: removes the parts of this stroke within [radius] of the
  /// eraser path [a]-[b]. Returns the pieces left over (maybe empty),
  /// or null if the stroke wasn't touched.
  List<Stroke>? eraseAlong(Offset a, Offset b, double radius) {
    if (points.length < 2) return touchedBy(a, b, radius) ? [] : null;
    // Points this close to the eraser go. Half the stroke's width beyond
    // its edge took away a whole thick highlighter's neighbouring rows the
    // eraser never touched; a quarter, with round ends, cuts about where
    // the eraser went.
    final r = radius + options.size / 4;
    final r2 = r * r;

    // resample so no gap between points is wider than the eraser, but only
    // near the eraser: the rest of the stroke keeps its points exactly, so
    // what isn't erased isn't changed
    final step = max(r / 2, 0.5);
    final dense = <PointVector>[points.first];
    // where each dense point is in [points], -1 for one added
    final denseSrc = <int>[0];
    for (int i = 1; i < points.length; i++) {
      final p = points[i - 1], q = points[i];
      final length = sqrt(p.distanceSquaredTo(q));
      final near = sqrDistanceToSegment(
        Offset((p.x + q.x) / 2, (p.y + q.y) / 2),
        a,
        b,
      );
      final reach = r + length / 2;
      final n = near > reach * reach ? 1 : (length / step).ceil();
      for (int k = 1; k <= n; k++) {
        final t = k / n;
        dense.add(
          PointVector(
            p.x + (q.x - p.x) * t,
            p.y + (q.y - p.y) * t,
            p.pressure == null || q.pressure == null
                ? q.pressure
                : p.pressure! + (q.pressure! - p.pressure!) * t,
          ),
        );
        denseSrc.add(k == n ? i : -1);
      }
    }

    final pieces = <List<PointVector>>[[]];
    final piecesSrc = <List<int>>[[]];
    var erasedAny = false;
    for (final (j, p) in dense.indexed) {
      if (sqrDistanceToSegment(Offset(p.x, p.y), a, b) <= r2) {
        erasedAny = true;
        if (pieces.last.isNotEmpty) {
          pieces.add([]);
          piecesSrc.add([]);
        }
      } else {
        pieces.last.add(p);
        piecesSrc.last.add(denseSrc[j]);
      }
    }
    if (!erasedAny) return null;

    final made = _eraserPieces(pieces, dense);
    // each piece's ink away from the cuts is this stroke's, as it was
    if (shapeStyle == null && !isClosedShape) {
      final kept = [
        for (final (j, piece) in pieces.indexed)
          if (piece.length >= 2) piecesSrc[j],
      ];
      if (kept.length == made.length) {
        for (final (j, stroke) in made.indexed) {
          stroke._cutFrom = (parent: this, src: Int32List.fromList(kept[j]));
        }
      }
    }
    return made;
  }

  List<Stroke> _eraserPieces(
    List<List<PointVector>> pieces,
    List<PointVector> dense,
  ) {
    return [
      for (final (piece, style) in _pieceStyles(
        pieces,
        dense.first,
        dense.last,
      ))
        Stroke(
            color: color,
            pressureEnabled: pressureEnabled,
            options: options.copyWith(isComplete: true),
            pageIndex: pageIndex,
            page: page,
            toolId: toolId,
          )
          ..layer = layer
          ..tapePattern = tapePattern
          ..tapeCustom = tapeCustom
          ..inkLine = inkLine
          ..shapeStyle = style
          // places the precision eraser had cut stay cut in every piece
          ..holes = holes
          ..clips = clips
          ..speedInk = speedInk
          ..nib2 = nib2
          ..steadyLine = steadyLine
          ..steady2 = steady2
          ..onFrontImage = onFrontImage
          ..afterImage = afterImage
          ..flatEnds = flatEnds
          ..drawOrder = drawOrder
          .._lineage = _lineage
          ..points.addAll(piece),
    ];
  }

  /// This stroke cut into pieces where an older version of the eraser cut
  /// holes across it, wider than the stroke: those holes each had to be
  /// drawn around, and a note with hundreds of them took over a second to
  /// show. Holes narrower than the stroke stay holes.
  /// Returns `[this]` when there's nothing to cut.
  List<Stroke> withoutWideHoles() {
    if (this is CircleStroke || this is RectangleStroke) return [this];
    // highlighter's holes are drawn once, into its layer: quick, and exact
    if (toolId == .highlighter) return [this];
    final half = options.size / 2;
    final wide = [
      for (final h in _holes)
        if (h.radius >= half) h,
    ];
    if (wide.isEmpty || points.length < 2) return [this];
    final narrow = [
      for (final h in _holes)
        if (h.radius < half) h,
    ];

    bool cut(double x, double y) {
      for (final h in wide) {
        final dx = x - h.center.dx, dy = y - h.center.dy;
        if (dx * dx + dy * dy <= h.radius * h.radius) return true;
      }
      return false;
    }

    // close enough together that no gap between holes is stepped over
    final step = max(half * 0.3, 0.5);
    final pieces = <List<PointVector>>[[]];
    void add(PointVector p) {
      if (cut(p.x, p.y)) {
        if (pieces.last.isNotEmpty) pieces.add([]);
      } else {
        pieces.last.add(p);
      }
    }

    add(points.first);
    for (int i = 1; i < points.length; i++) {
      final p = points[i - 1], q = points[i];
      final n = max(1, (sqrt(p.distanceSquaredTo(q)) / step).ceil());
      for (int k = 1; k <= n; k++) {
        final t = k / n;
        add(
          PointVector(
            p.x + (q.x - p.x) * t,
            p.y + (q.y - p.y) * t,
            p.pressure == null || q.pressure == null
                ? q.pressure
                : p.pressure! + (q.pressure! - p.pressure!) * t,
          ),
        );
      }
    }
    // no point was cut: the holes only nibbled the edges
    if (pieces.length == 1 && pieces.single.length >= points.length) {
      return [this];
    }
    return [
      for (final (piece, style) in _pieceStyles(
        pieces,
        points.first,
        points.last,
      ))
        Stroke(
            color: color,
            pressureEnabled: pressureEnabled,
            options: options.copyWith(isComplete: true),
            pageIndex: pageIndex,
            page: page,
            toolId: toolId,
          )
          ..layer = layer
          ..tapePattern = tapePattern
          ..tapeCustom = tapeCustom
          ..inkLine = inkLine
          ..shapeStyle = style
          ..holes = narrow
          ..clips = clips
          ..speedInk = speedInk
          ..nib2 = nib2
          ..steadyLine = steadyLine
          ..steady2 = steady2
          ..onFrontImage = onFrontImage
          ..afterImage = afterImage
          ..flatEnds = flatEnds || toolId == .highlighter
          ..drawOrder = drawOrder
          ..points.addAll(piece),
    ];
  }

  /// The first [part] (0 to 1) of this stroke, as the pen had drawn it then;
  /// null when that's less than two points. For a recording playing back.
  Stroke? firstPart(double part) {
    final count = (points.length * part.clamp(0.0, 1.0)).ceil();
    if (count < 2) return null;
    return copy()
      ..points.removeRange(count, points.length)
      ..markPolygonNeedsUpdating();
  }

  Stroke copy() =>
      Stroke(
          color: color,
          pressureEnabled: pressureEnabled,
          options: options.copyWith(),
          pageIndex: pageIndex,
          page: page,
          toolId: toolId,
        )
        ..layer = layer
        ..points.addAll(points)
        ..tapePattern = tapePattern
        ..tapeCustom = tapeCustom
        ..inkLine = inkLine
        ..shapeStyle = shapeStyle
        ..holes = holes
        ..clips = clips
        ..onFrontImage = onFrontImage
        ..afterImage = afterImage
        .._lineage = _lineage
        // the same holes in the same place: what's worked out of them still fits
        .._kept = _kept
        .._keptArea = _keptArea
        .._keptHoles = _keptHoles
        ..flatEnds = flatEnds
        ..speedInk = speedInk
        ..nib2 = nib2
        ..steadyLine = steadyLine
        ..steady2 = steady2;
}

/// The pencil grains along the start of a live stroke, see
/// [Stroke._buildPencilGrain].
class _GrainProgress {
  new(this.firstPoint, this.cell);

  final PointVector firstPoint;
  final double cell;
  final grain = <double>[];
  final seen = <(int, int)>{};

  /// Segments of the steadied line walked so far.
  var segments = 0;

  /// How far into the next segment the next step is.
  var at = 0.0;

  /// Length of the line walked so far.
  var length = 0.0;
  PointVector? lastPoint;

  static bool _same(PointVector a, PointVector b) =>
      a.x == b.x && a.y == b.y && a.pressure == b.pressure;

  /// Whether [line] still starts with the part walked so far. Pressure first
  /// showing up, for one, changes the whole line.
  bool fits(List<PointVector> line, double cell) {
    final last = lastPoint;
    return cell == this.cell &&
        last != null &&
        line.length > segments &&
        _same(line.first, firstPoint) &&
        _same(line[segments], last);
  }
}

class StrokeQuality {
  @visibleForTesting
  const new(this.N);

  /// We use every Nth point for this quality level.
  final int N;

  static const low = StrokeQuality(4);
  static const high = StrokeQuality(1);

  bool get isLowQuality => N > 1;
}

/// Triangles of a stroke's ink ([Stroke.inkVertices]): [buf] up to [used],
/// and for each of [steps] along the line, where its triangles start
/// ([stepAt], with the end after the last) and which point it's from.
typedef _Triangles = ({
  Float32List buf,
  int used,
  int steps,
  Int32List stepAt,
  Int32List stepSrc,
});
