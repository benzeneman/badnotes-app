import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:badnotes/components/canvas/_asset_cache.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/data/editor/editor_exporter.dart';
import 'package:badnotes/data/tools/laser_pointer.dart';
import 'package:sbn/canvas_background_pattern.dart';
import 'package:sbn/has_size.dart';

typedef CanvasKey = GlobalKey<State<InnerCanvas>>;

/// One page of a note: its paper, the ink and pictures on it, its typed
/// text, and the layers all of that is spread over.
///
/// Listeners are told whenever the ink needs painting again.
class EditorPage extends ChangeNotifier implements HasSize {
  // ---------------------------------------------------------------------
  // Sizes
  // ---------------------------------------------------------------------

  static const double defaultWidth = 1000;
  static const double defaultHeight = defaultWidth * 1.4;
  static const defaultSize = Size(defaultWidth, defaultHeight);

  /// Every side of a whiteboard's single sheet, whose origin sits in the
  /// middle. Half of it either way is roughly 125 phone screens, more than
  /// anyone scrolls; past that, ink coordinates start to lose precision.
  static const boardSide = 200000.0;

  /// Where a quarter turn of the page's content (either way) has to pivot so
  /// the content ends up on the turned page rather than next to it.
  static Offset rotationPivot(Size size, {required bool clockwise}) {
    final half = (clockwise ? size.height : size.width) / 2;
    return Offset(half, half);
  }

  /// Only ever changed by rotating the page; see [rotationPivot].
  @override
  Size size;

  /// True for a whiteboard's sheet, which has no edges, is shown at its true
  /// size and gets its paper from [BoardPaperPainter].
  bool get isBoard => size.width >= boardSide;

  // ---------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------

  final List<Stroke> strokes;
  final List<LaserStroke> laserStrokes;
  final List<EditorImage> images;
  final QuillStruct quill;

  EditorImage? backgroundImage;

  /// The page's own ruling (lines, grid and so on), or null to follow the
  /// note's [EditorCoreInfo.backgroundPattern].
  CanvasBackgroundPattern? backgroundPattern;

  /// The page's own line spacing, or null to follow the note.
  int? lineHeight;

  /// The page's own paper colour, or null to follow the note.
  Color? backgroundColor;

  /// Set when the user bookmarks the page.
  var bookmarked = false;

  bool get isEmpty =>
      strokes.isEmpty &&
      images.isEmpty &&
      quill.controller.document.isEmpty() &&
      backgroundImage == null;
  bool get isNotEmpty => !isEmpty;

  // ---------------------------------------------------------------------
  // Short-lived state, never written to the file
  // ---------------------------------------------------------------------

  /// The eraser's position on this page while it is pressed down.
  Offset? eraserRing;

  /// Set when the page was sent to the note's trash on removal, as opposed
  /// to simply being blank.
  var wasTrashed = false;

  /// Rectangles (in page units) briefly marked as search hits.
  var searchHighlights = const <Rect>[];

  /// During a replay: the strokes reached so far.
  Set<Stroke>? replayShown;

  /// During playback of a recording: the strokes in progress right now,
  /// trimmed to where the pen has reached. They are painted on the top layer
  /// so each frame doesn't repaint the whole page.
  List<Stroke> replayPartial = const [];

  /// During Spotlight playback: the strokes still to come, shown faded on
  /// the top layer. Setting them drops [replayGhostPicture].
  List<Stroke> get replayGhosts => _ghosts;
  set replayGhosts(List<Stroke> ghosts) {
    _ghosts = ghosts;
    replayGhostPicture?.dispose();
    replayGhostPicture = null;
  }

  List<Stroke> _ghosts = const [];

  /// A recording of [replayGhosts] kept until they change, because painting
  /// a full page of them on every frame makes playback stutter.
  ui.Picture? replayGhostPicture;

  /// Bumped on every pen movement; only the layer showing the stroke being
  /// drawn listens.
  final currentStrokeTick = ValueNotifier(0);

  /// The part of the page that is on screen, in page units, when known.
  /// Updated on each scroll or zoom frame. Zoomed in beyond what a
  /// whole-page image can hold, only this part's ink is cached as an image.
  final visibleArea = ValueNotifier<Rect?>(null);

  // ---------------------------------------------------------------------
  // The canvas widget
  // ---------------------------------------------------------------------

  late final CanvasKey innerCanvasKey = CanvasKey();

  RenderBox? _cachedRenderBox;
  RenderBox? get renderBox => _cachedRenderBox ??=
      innerCanvasKey.currentState?.context.findRenderObject() as RenderBox?;

  var _rendered = false;
  bool get isRendered => _rendered;
  set isRendered(bool value) {
    if (value == _rendered) return;
    _rendered = value;
    // a different render object now, so look it up again next time
    _cachedRenderBox = null;
  }

  // ---------------------------------------------------------------------
  // Constructors
  // ---------------------------------------------------------------------

  new({
    Size? size,
    double? width,
    double? height,
    List<Stroke>? strokes,
    List<EditorImage>? images,
    QuillStruct? quill,
    this.backgroundImage,
  }) : assert(
         (size == null) || (width == null && height == null),
         "size and width/height shouldn't both be specified",
       ),
       size = size ?? Size(width ?? defaultWidth, height ?? defaultHeight),
       strokes = strokes ?? [],
       laserStrokes = [],
       images = images ?? [],
       quill = quill ?? QuillStruct._empty();

  factory fromJson(
    Map<String, dynamic> json, {
    required List<Uint8List>? inlineAssets,
    required bool readOnly,
    required int fileVersion,
    required String sbnPath,
    required AssetCache assetCache,
  }) {
    final size = Size(json['w'] ?? defaultWidth, json['h'] ?? defaultHeight);

    // read in this order: strokes, pictures, text, then the background
    final strokes = parseStrokesJson(
      json['s'] as List?,
      page: HasSize(size),
      onlyFirstPage: false,
      fileVersion: fileVersion,
    );
    final images = parseImagesJson(
      json['i'] as List?,
      inlineAssets: inlineAssets,
      isThumbnail: readOnly,
      onlyFirstPage: false,
      sbnPath: sbnPath,
      assetCache: assetCache,
    );
    final quill = QuillStruct._fromDelta(json['q']);
    final background = json['b'] == null
        ? null
        : parseImageJson(
            json['b'],
            inlineAssets: inlineAssets,
            isThumbnail: false,
            sbnPath: sbnPath,
            assetCache: assetCache,
          );

    final page = EditorPage(
      size: size,
      strokes: strokes,
      images: images,
      quill: quill,
      backgroundImage: background,
    );
    page.layers = _readLayers(json['la']);
    page.activeLayer = json['lac'] as int? ?? 0;
    page.backgroundColor = _readColor(json['bc']);
    page.lineHeight = json['lh'] as int?;
    page.bookmarked = json['fav'] == true;
    page.backgroundPattern = json['bp'] is String
        ? CanvasBackgroundPattern.fromName(json['bp'] as String)
        : null;
    return page;
  }

  static List<PageLayer> _readLayers(Object? saved) {
    if (saved is! List) return [PageLayer(0, 'Layer 1')];
    return [
      for (final layer in saved)
        PageLayer.fromJson(layer as Map<String, dynamic>),
    ];
  }

  /// Colours were written as plain ints; some decoders hand back an [Int64].
  static Color? _readColor(Object? saved) => switch (saved) {
    final int argb => Color(argb),
    final Int64 argb => Color(argb.toInt()),
    _ => null,
  };

  // ---------------------------------------------------------------------
  // Saving
  // ---------------------------------------------------------------------

  /// The page as written to the note file. The keys and their order are part
  /// of the file format, as is the order [assets] get filled in.
  Map<String, dynamic> toJson(OrderedAssetCache assets) {
    Map<String, dynamic> onLayer(Map<String, dynamic> item, int layer) => {
      ...item,
      if (layer != 0) 'ly': layer,
    };

    return {
      'w': size.width,
      'h': size.height,
      if (strokes.isNotEmpty)
        's': [for (final s in strokes) onLayer(s.toJson(), s.layer)],
      if (images.isNotEmpty)
        'i': [for (final i in images) onLayer(i.toJson(assets), i.layer)],
      if (layers.length > 1 || layers.any((layer) => !layer.editable))
        'la': [for (final layer in layers) layer.toJson()],
      if (activeLayer != 0) 'lac': activeLayer,
      if (!quill.controller.document.isEmpty())
        'q': quill.controller.document.toDelta().toJson(),
      if (backgroundImage != null) 'b': backgroundImage?.toJson(assets),
      if (backgroundPattern != null) 'bp': backgroundPattern!.name,
      if (backgroundColor != null) 'bc': backgroundColor!.toARGB32(),
      if (lineHeight != null) 'lh': lineHeight,
      if (bookmarked) 'fav': true,
    };
  }

  // ---------------------------------------------------------------------
  // Reading strokes and pictures
  // ---------------------------------------------------------------------

  static List<Stroke> parseStrokesJson(
    List<dynamic>? strokes, {
    required HasSize page,
    required bool onlyFirstPage,
    required int fileVersion,
  }) {
    final result = <Stroke>[];
    for (final entry in strokes ?? const []) {
      final map = entry as Map<String, dynamic>;
      final pageIndex = map['i'] ?? 0;
      if (onlyFirstPage && pageIndex > 0) continue;
      final stroke = Stroke.fromJson(
        map,
        fileVersion: fileVersion,
        pageIndex: pageIndex,
        page: page,
      )..layer = map['ly'] as int? ?? 0;
      // An older eraser punched holes right across strokes; those become
      // separate pieces here, since tracing hundreds of holes froze opening.
      result.addAll(stroke.withoutWideHoles());
    }
    return result;
  }

  static List<EditorImage> parseImagesJson(
    List<dynamic>? images, {
    required List<Uint8List>? inlineAssets,
    required bool isThumbnail,
    required bool onlyFirstPage,
    required String sbnPath,
    required AssetCache assetCache,
  }) {
    if (images == null) return [];
    final result = <EditorImage>[];
    for (final json in images.cast<Map<String, dynamic>>()) {
      if (onlyFirstPage && json['i'] > 0) continue;
      result.add(
        parseImageJson(
          json,
          inlineAssets: inlineAssets,
          isThumbnail: isThumbnail,
          sbnPath: sbnPath,
          assetCache: assetCache,
        )..layer = json['ly'] as int? ?? 0,
      );
    }
    return result;
  }

  static EditorImage parseImageJson(
    Map<String, dynamic> json, {
    required List<Uint8List>? inlineAssets,
    required bool isThumbnail,
    required String sbnPath,
    required AssetCache assetCache,
  }) => EditorImage.fromJson(
    json,
    inlineAssets: inlineAssets,
    isThumbnail: isThumbnail,
    sbnPath: sbnPath,
    assetCache: assetCache,
  );

  // ---------------------------------------------------------------------
  // Layers
  // ---------------------------------------------------------------------

  /// Bottom layer first.
  var layers = <PageLayer>[PageLayer(0, 'Layer 1')];

  /// Which layer new ink and pictures land on. Kept on an editable layer
  /// whenever one exists, by [updateActiveLayer].
  var activeLayer = 0;

  PageLayer? _findLayer(int id) =>
      layers.firstWhereOrNull((layer) => layer.id == id);

  /// More than one layer means painting them one at a time, pictures
  /// in between.
  bool get hasSeveralLayers => layers.length > 1;

  /// The layer content tagged [layer] is painted with. If that layer no
  /// longer exists (undo can bring such content back), it is the bottom one.
  int drawnOnLayer(int layer) =>
      _findLayer(layer) == null ? layers.first.id : layer;

  /// A missing layer reads as shown and unlocked, so nothing undone onto it
  /// gets stuck.
  bool isLayerVisible(int id) => _findLayer(id)?.visible ?? true;
  bool isLayerEditable(int id) => _findLayer(id)?.editable ?? true;

  void addLayer() {
    final id = layers.map((layer) => layer.id).reduce(max) + 1;
    layers.add(PageLayer(id, 'Layer ${id + 1}'));
    activeLayer = id;
  }

  /// Deletes layer [id] together with its content, handing that content
  /// back. A page always keeps at least one layer.
  ({List<Stroke> strokes, List<EditorImage> images}) removeLayer(int id) {
    if (layers.length <= 1) return (strokes: const [], images: const []);
    layers.removeWhere((layer) => layer.id == id);
    final goneStrokes = [
      for (final stroke in strokes)
        if (stroke.layer == id) stroke,
    ];
    final goneImages = [
      for (final image in images)
        if (image.layer == id) image,
    ];
    strokes.removeWhere(goneStrokes.contains);
    images.removeWhere(goneImages.contains);
    updateActiveLayer();
    return (strokes: goneStrokes, images: goneImages);
  }

  /// Moves the layer at index [from] of [layers] to index [to].
  void moveLayer(int from, int to) {
    final layer = layers.removeAt(from);
    layers.insert(to, layer);
    sortStrokes();
  }

  /// If the active layer is hidden or locked, switches to the topmost
  /// editable layer (or the top layer when none is editable).
  void updateActiveLayer() {
    final current = _findLayer(activeLayer);
    if (current != null && current.editable) return;
    final topEditable = layers.lastWhereOrNull((layer) => layer.editable);
    activeLayer = (topEditable ?? layers.last).id;
  }

  /// False when hiding or locking [layer] would leave nothing to draw on.
  bool canDisableLayer(PageLayer layer) {
    if (!layer.editable) return true;
    return layers.any((other) => other != layer && other.editable);
  }

  // ---------------------------------------------------------------------
  // Pictures in front of the ink
  // ---------------------------------------------------------------------

  bool get _hasFrontImages => images.any((image) => image.inFront);

  /// Whether [stroke] was written on a picture or sticky note that sits over
  /// the ink. If so it is painted above that picture; anything written
  /// before the picture arrived stays hidden beneath it.
  bool isOnFrontImage(Stroke stroke) {
    if (!_hasFrontImages) return false;
    return stroke.onFrontImage ?? liesOnFrontImage(stroke);
  }

  /// Whether [stroke] fits entirely inside a picture on its layer that sits
  /// over the ink. Tape never counts.
  bool liesOnFrontImage(Stroke stroke) {
    if (!_hasFrontImages) return false;
    if (stroke.toolId == .tape) return false;
    final inner = stroke.bounds.deflate(stroke.options.size / 2);
    return images.any((image) {
      if (!image.inFront || image.layer != stroke.layer) return false;
      final target = image.dstRect.inflate(2);
      return target.contains(inner.topLeft) &&
          target.contains(inner.bottomRight);
    });
  }

  /// Whether a stroke made now is painted above the pictures and text boxes
  /// of its layer. Ink keeps the order it was made in, so highlighting over
  /// a text box covers it and a text box dropped on ink later covers that.
  /// Tape is painted above everything by itself, so it never does.
  bool drawsOverFrontImages(Stroke stroke) {
    if (stroke.toolId == .tape) return false;
    return images.any((image) => image.inFront && image.layer == stroke.layer);
  }

  /// [Stroke.afterImage] for [stroke], filled in for strokes saved before
  /// that field existed: above the pictures of the time (0), or below (-1).
  int afterImageOf(Stroke stroke) {
    final saved = stroke.afterImage;
    if (saved != null) return saved;
    return isOnFrontImage(stroke) ? 0 : -1;
  }

  /// The newest [EditorImage.order] among front pictures and text boxes on
  /// [layer], or -1 if there are none. Fresh ink goes above them.
  int latestFrontOrder(int layer) => images
      .where((image) => image.inFront && image.layer == layer)
      .fold(-1, (newest, image) => max(newest, image.order));

  /// [front] sorted by when each was placed; ties keep their given order.
  static List<EditorImage> inOrder(Iterable<EditorImage> front) {
    final sorted = front.toList();
    mergeSort(sorted, compare: (a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  /// The slot among [front] (already sorted by placement) that [stroke] is
  /// painted in: 0 below all of them, n above the first n. A stroke rises
  /// above each picture it touches that was placed before it was written,
  /// and stays below the ones placed afterwards.
  int tierOf(Stroke stroke, List<EditorImage> front) {
    if (front.isEmpty) return 0;
    final after = afterImageOf(stroke);
    if (after < 0) return 0;
    final reach = stroke.bounds.inflate(stroke.options.size / 2);
    var tier = 0;
    for (var i = 0; i < front.length; i++) {
      final image = front[i];
      if (image.order > after) break;
      if (image.dstRect.overlaps(reach)) tier = i + 1;
    }
    return tier;
  }

  /// Lays [added] on [layer] above the ink, the way a real photo or sticky
  /// note would sit.
  ///
  /// Ink already there ends up underneath: deciding only by position used to
  /// let words show through a picture placed on top of them. A picture laid
  /// on tape belongs to that tape and moves with what is written on it.
  void putImagesInFront(List<EditorImage> added, {required int layer}) {
    _pinDownExistingStrokes();
    // each new one is placed after every picture already there
    var order = max(
      DateTime.now().microsecondsSinceEpoch,
      latestFrontOrder(layer) + 1,
    );
    for (final image in added) {
      image
        ..layer = layer
        ..inFront = true
        ..order = order++;
      image.onTape = strokes.any((tape) => _tapeTouches(tape, layer, image));
      _coverStrokesUnder(image, layer);
    }
    images.addAll(added);
  }

  /// Records, for every stroke, where it sits right now, so pictures added
  /// afterwards don't move it.
  void _pinDownExistingStrokes() {
    for (final stroke in strokes) {
      final onFront = stroke.onFrontImage ??= liesOnFrontImage(stroke);
      stroke.afterImage ??= onFront ? 0 : -1;
    }
  }

  /// Ink written since the previous picture that [image] overlaps now lies
  /// under it, unless it is still wholly on an earlier front picture.
  void _coverStrokesUnder(EditorImage image, int layer) {
    for (final stroke in strokes) {
      if (stroke.layer != layer || stroke.onFrontImage != true) continue;
      if (!stroke.bounds.overlaps(image.dstRect)) continue;
      if (liesOnFrontImage(stroke)) continue;
      stroke.onFrontImage = false;
    }
  }

  static bool _tapeTouches(Stroke tape, int layer, EditorImage image) =>
      tape.toolId == .tape &&
      tape.layer == layer &&
      tape.bounds.inflate(tape.options.size / 2).overlaps(image.dstRect);

  /// Whether [image] sits on a tape that is currently lifted for a peek,
  /// which hides it.
  bool isUnderPeek(EditorImage image) {
    if (!image.onTape) return false;
    return strokes.any(
      (tape) => tape.tapeRevealed && _tapeTouches(tape, image.layer, image),
    );
  }

  // ---------------------------------------------------------------------
  // Stroke order
  // ---------------------------------------------------------------------

  /// Highlighter from notes saved before strokes remembered their order is
  /// painted first, sorted by colour, just as it always was. All other ink
  /// follows the order it was drawn in ([Stroke.nib2]), so highlighting over
  /// ink covers it, ink over highlighting covers that, and a later
  /// highlighter colour lies over an earlier one (sorting by colour used to
  /// put red under yellow even when drawn after it).
  static int compareStrokes(Stroke a, Stroke b) {
    final aLegacy = _isLegacyHighlighter(a);
    final bLegacy = _isLegacyHighlighter(b);
    if (aLegacy != bLegacy) return aLegacy ? -1 : 1;
    return aLegacy
        ? a.color.toARGB32().compareTo(b.color.toARGB32())
        : a.drawOrder.compareTo(b.drawOrder);
  }

  static bool _isLegacyHighlighter(Stroke stroke) =>
      stroke.toolId == .highlighter && !stroke.nib2;

  /// By layer from the bottom up, then by [compareStrokes].
  int _paintOrder(Stroke a, Stroke b) {
    int depth(Stroke stroke) =>
        layers.indexWhere((layer) => layer.id == stroke.layer);
    final byDepth = depth(a).compareTo(depth(b));
    return byDepth == 0 ? compareStrokes(a, b) : byDepth;
  }

  /// Adds [newStroke] in its place among the (sorted) [strokes]: after
  /// every stroke that doesn't paint later than it.
  void insertStroke(Stroke newStroke) {
    final at = strokes.indexWhere((s) => _paintOrder(s, newStroke) > 0);
    strokes.insert(at == -1 ? strokes.length : at, newStroke);
  }

  /// Brings [chosenStrokes] and [chosenImages] to the front (or sends them
  /// to the back) of their own kind, keeping them in their current order
  /// relative to each other. Highlighter still stays below other ink and
  /// pictures below all ink, since each layer is painted separately.
  void reorder(
    Iterable<Stroke> chosenStrokes,
    Iterable<EditorImage> chosenImages, {
    required bool toFront,
  }) {
    void regroup<T>(List<T> items, Iterable<T> chosen) {
      final picked = chosen.toSet();
      final moving = <T>[], staying = <T>[];
      for (final item in items) {
        (picked.contains(item) ? moving : staying).add(item);
      }
      items
        ..clear()
        ..addAll(toFront ? staying : moving)
        ..addAll(toFront ? moving : staying);
    }

    regroup(strokes, chosenStrokes);
    regroup(images, chosenImages);
    // the new order is the one they are drawn in from here on
    for (final stroke in strokes) {
      stroke.drawOrder = Stroke.nextDrawOrder();
    }
    sortStrokes();
  }

  /// Sorts [strokes] into painting order. Must be a stable sort; see
  /// [compareStrokes].
  void sortStrokes() => mergeSort(strokes, compare: _paintOrder);

  // ---------------------------------------------------------------------
  // Misc
  // ---------------------------------------------------------------------

  /// How tall the page looks when cut off just below its content.
  double previewHeight({required int lineHeight}) {
    // a zero-sized page shouldn't exist; guard against dividing by zero
    assert(size.height != 0);
    assert(size.width != 0);
    if (size.height == 0 || size.width == 0) return 0;

    // a background picture fills the page, so show all of it
    if (backgroundImage != null) return size.height;

    var bottom = 0.0;
    for (final stroke in strokes) {
      bottom = max(bottom, stroke.maxY);
    }
    for (final image in images) {
      bottom = max(bottom, image.dstRect.bottom);
    }
    final document = quill.controller.document;
    if (!document.isEmpty()) {
      // counts lines only; wrapped text isn't measured, hence the extra 50%
      final lines = document.toPlainText().split('\n').length;
      bottom = max(bottom, lines * lineHeight * 1.5);
    }

    // a 10% margin below the content, never taller than the page itself
    final fullHeight = size.height;
    return min(fullHeight, max(bottom, 0) + 0.1 * fullHeight);
  }

  /// Asks for the ink to be painted again. Pictures need [setState] instead.
  void redrawStrokes() => notifyListeners();

  /// Writes [pageIndex] into everything on this page that remembers it.
  void updatePageIndex(int pageIndex) {
    for (final stroke in strokes) stroke.pageIndex = pageIndex;
    for (final stroke in laserStrokes) stroke.pageIndex = pageIndex;
    for (final image in images) image.pageIndex = pageIndex;
    backgroundImage?.pageIndex = pageIndex;
  }

  @override
  void dispose() {
    currentStrokeTick.dispose();
    quill.dispose();
    isRendered = false;
    for (final image in images) {
      image.dispose();
    }
    backgroundImage?.dispose();
    super.dispose();
  }

  /// The counterpart of [dispose] for a page made by
  /// [cloneForRasterization]: it frees only what the clone created for
  /// itself, leaving alone the pictures and other parts it still shares
  /// with the original.
  void disposeClonedData() {
    quill.dispose();
    isRendered = false;
    super.dispose();
  }

  EditorPage copyWith({
    Size? size,
    List<Stroke>? strokes,
    List<EditorImage>? images,
    QuillStruct? quill,
    EditorImage? backgroundImage,
  }) {
    final copy = EditorPage(
      size: size ?? this.size,
      strokes: strokes ?? this.strokes,
      images: images ?? this.images,
      quill: quill ?? this.quill,
      backgroundImage: backgroundImage ?? this.backgroundImage,
    );
    copy.layers = [for (final layer in layers) layer.copy()];
    copy.activeLayer = activeLayer;
    copy.backgroundPattern = backgroundPattern;
    copy.lineHeight = lineHeight;
    copy.backgroundColor = backgroundColor;
    return copy;
  }

  /// A copy of this page for taking a picture of it: it gets its own text
  /// editor (one editor can't be attached in two places) and leaves out
  /// hidden layers and, unless [rasterizeAllStrokes], strokes that the
  /// exporter draws as vectors.
  ///
  /// Free it with [disposeClonedData] afterwards.
  EditorPage cloneForRasterization({bool rasterizeAllStrokes = false}) {
    final visibleStrokes = strokes.where((s) => isLayerVisible(s.layer));
    return copyWith(
      strokes:
          (rasterizeAllStrokes
                  ? visibleStrokes
                  : visibleStrokes.where(EditorExporter.shouldRasterizeStroke))
              .toList(),
      images: images.where((image) => isLayerVisible(image.layer)).toList(),
      quill: quill.cloneForScreenshot(),
    );
  }
}

/// A sheet of the page holding ink and pictures. Higher layers are painted
/// over lower ones; inside one layer the pictures go under the ink.
class PageLayer {
  PageLayer(this.id, this.name, {this.visible = true, this.locked = false});

  /// Reads `id`, `n` (name), `v` (false when hidden) and `lk` (true when
  /// locked).
  factory PageLayer.fromJson(Map<String, dynamic> json) => PageLayer(
    json['id'] as int,
    json['n'] as String,
    visible: json['v'] != false,
    locked: json['lk'] == true,
  );

  final int id;
  String name;
  bool visible;
  bool locked;

  /// Shown and not locked, so it can be drawn on.
  bool get editable => visible && !locked;

  /// Hidden and locked are only written when set.
  Map<String, dynamic> toJson() => {
    'id': id,
    'n': name,
    if (!visible) 'v': false,
    if (locked) 'lk': true,
  };

  PageLayer copy() => PageLayer(id, name, visible: visible, locked: locked);
}

/// The typed text of a page: its editor controller and focus, plus the
/// subscription that listens for edits.
class QuillStruct {
  final QuillController controller;
  late final FocusNode focusNode;
  StreamSubscription? changeSubscription;

  new({required this.controller, required this.focusNode});

  /// A blank text editor for a new page.
  factory _empty() => QuillStruct(
    controller: QuillController.basic(),
    focusNode: FocusNode(debugLabel: 'Quill Focus Node'),
  );

  /// The text saved under a page's `q` key, or blank when there is none.
  factory _fromDelta(Object? delta) => QuillStruct(
    controller: delta != null
        ? QuillController(
            document: Document.fromJson(delta as List),
            selection: const TextSelection.collapsed(offset: 0),
          )
        : QuillController.basic(),
    focusNode: FocusNode(debugLabel: 'Quill Focus Node'),
  );

  void dispose() {
    changeSubscription?.cancel();
    focusNode.dispose();
    controller.dispose();
  }

  /// A separate editor holding the same text, for screenshots.
  QuillStruct cloneForScreenshot() => QuillStruct(
    controller: QuillController(
      document: Document.fromDelta(controller.document.toDelta()),
      selection: const TextSelection.collapsed(offset: 0),
    ),
    focusNode: FocusNode(debugLabel: 'Screenshot Quill Focus Node'),
  );
}
