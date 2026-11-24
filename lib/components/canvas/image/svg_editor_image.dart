part of 'editor_image.dart';

/// A vector picture on a page. Typed text boxes and sticky notes are kept
/// as these too, with their text in a comment inside the SVG.
class SvgEditorImage extends EditorImage {
  /// The SVG itself: a string in memory, or the asset file beside the note.
  SvgLoader svgLoader;

  static final log = Logger('SvgEditorImage');

  /// Not needed by vector pictures: their file is read through [svgLoader].
  @override
  @Deprecated('Use the file directly instead')
  AssetCache get assetCache => super.assetCache;

  new({
    required super.id,
    required super.assetCache,
    required String? svgString,
    required File? svgFile,
    required super.pageIndex,
    required super.pageSize,
    required super.onMoveImage,
    required super.onDeleteImage,
    required super.onMiscChange,
    super.onLoad,
    super.invertible,
    super.backgroundFit,
    super.newImage,
    super.dstRect,
    super.srcRect,
    super.naturalSize,
    super.isThumbnail,
  }) : assert(
         svgString != null || svgFile != null,
         'a vector picture needs its SVG text or its file',
       ),
       svgLoader = svgString == null
           ? SvgFileLoader(svgFile!)
           : SvgStringLoader(svgString),
       super(extension: '.svg');

  factory fromJson(
    Map<String, dynamic> json, {
    required List<Uint8List>? inlineAssets,
    bool isThumbnail = false,
    required String sbnPath,
    required AssetCache assetCache,
  }) {
    assert(const {null, '.svg'}.contains(json['e'] as String?));

    final asset = _assetIn(json, inlineAssets, sbnPath);
    final file = asset?.file;

    final String? svgString;
    if (asset != null) {
      // read ahead by the asset cache, or else left for [SvgFileLoader]
      svgString = file == null
          ? utf8.decode(asset.inline!)
          : assetCache.get(file);
    } else if (json['b'] != null) {
      // very old notes kept the SVG right in the entry
      svgString = json['b'] as String;
    } else {
      log.warning('fromJson: the entry has no SVG, showing nothing');
      svgString = '';
    }

    final at = _Placement(json);
    return SvgEditorImage(
      id: at.id,
      assetCache: assetCache,
      svgString: svgString,
      svgFile: file,
      pageIndex: at.pageIndex,
      pageSize: .infinite,
      invertible: at.invertible,
      backgroundFit: at.backgroundFit,
      onMoveImage: null,
      onDeleteImage: null,
      onMiscChange: null,
      onLoad: null,
      newImage: false,
      dstRect: at.dstRect,
      srcRect: at.srcRect,
      naturalSize: at.naturalSize,
      isThumbnail: isThumbnail,
    );
  }

  @override
  Map<String, dynamic> toJson(OrderedAssetCache assets) {
    final json = super.toJson(assets);
    assert(!json.containsKey('a'));
    final (:string, :file) = _extractSvg();
    return json
      ..['a'] = string == null
          ? assets.addFile(file!)
          : assets.addString(string);
  }

  /// The SVG as text if it is held in memory, else the file it is read from.
  ({String? string, File? file}) _extractSvg() => switch (svgLoader) {
    final SvgFileLoader loader => (string: null, file: loader.file),
    final SvgStringLoader loader => (
      string: loader.provideSvg(null),
      file: null,
    ),
    final other => throw ArgumentError.value(
      other,
      'svgLoader',
      'SvgEditorImage: only SVG strings and files can be saved',
    ),
  };

  /// Parses the SVG once to learn its size, then lets the parsed picture go.
  Future<Size> _parsedSize() async {
    final parsed = await vg.loadPicture(svgLoader, null);
    parsed.picture.dispose();
    return parsed.size;
  }

  /// Works out the picture's size when the note doesn't say how it is
  /// placed yet (a picture just added).
  @override
  Future<void> firstLoad() async {
    if (srcRect.shortestSide == 0 || dstRect.shortestSide == 0) {
      naturalSize = await _parsedSize();
      settleRects();
    }
    // older notes didn't keep the size: the cropped part is close enough
    if (naturalSize == .zero) naturalSize = srcRect.size;
  }

  @override
  Future<void> loadIn() async => await super.loadIn();

  @override
  Future<bool> loadOut() async => await super.loadOut();

  /// Parses the SVG ahead of time, so flutter_svg has it cached.
  @override
  Future<void> precache(BuildContext context) => _parsedSize();

  @override
  Widget buildImageWidget({
    required BuildContext context,
    required BoxFit? overrideBoxFit,
    required bool isBackground,
    required bool invert,
  }) {
    return InvertWidget(
      // typed text is ink: dark text on a page turned dark couldn't be read
      invert: invert || (_isTextBox && InkPixelScale.invertsInkOf(context)),
      child: SvgPicture(svgLoader, fit: fitFor(overrideBoxFit, isBackground)),
    );
  }

  /// Whether this is a text box: typed text with no paper behind it.
  bool get isTextBox => _isTextBox;

  /// Whether this is a sticky note: typed text on colored paper.
  bool get isStickyNote => _stickyNote ??= switch (svgLoader) {
    final SvgStringLoader loader => switch (loader.provideSvg(null)) {
      final svg when svg.contains('<!--badnotes-note:') =>
        stickyNoteFromSvg(svg)?.color != null,
      _ => false,
    },
    _ => false,
  };
  bool? _stickyNote;

  /// A link to a page or note from a build that had them (taken out).
  bool get isRemovedLink => switch (svgLoader) {
    final SvgStringLoader loader => isRemovedNotesLink(loader.provideSvg(null)),
    _ => false,
  };

  /// What this sticky note or text box was made from, if it's one.
  StickyNoteResult? get note => switch (svgLoader) {
    final SvgStringLoader loader => stickyNoteFromSvg(loader.provideSvg(null)),
    _ => null,
  };

  bool get _isTextBox => _textBox ??= switch (svgLoader) {
    final SvgStringLoader loader => switch (loader.provideSvg(null)) {
      final svg
          when svg.contains('<!--badnotes-note:') ||
              svg.contains('<!--badnotes-text:') =>
        stickyNoteFromSvg(svg)?.color == null,
      _ => false,
    },
    _ => false,
  };
  bool? _textBox;

  /// Swaps the picture for [svg] of [size], at the same scale it was showing.
  void replaceSvg(String svg, Size size) {
    final scale = naturalSize.height == 0
        ? 1.0
        : dstRect.height / naturalSize.height;
    final widthScale = naturalSize.width == 0
        ? 1.0
        : dstRect.width / naturalSize.width;
    svgLoader = SvgStringLoader(svg);
    _textBox = null;
    naturalSize = size;
    srcRect = Offset.zero & size;
    dstRect =
        dstRect.topLeft & Size(size.width * widthScale, size.height * scale);
  }

  @override
  Future<Uint8List?> fileBytes() async => switch (_extractSvg()) {
    (string: final String svg, file: _) => utf8.encode(svg),
    (string: null, :final file) => file?.readAsBytes(),
  };

  /// A copy for pasting, sharing this one's SVG text or file.
  @override
  SvgEditorImage copy() {
    final (:string, :file) = _extractSvg();
    return SvgEditorImage(
      id: id,
      // ignore: deprecated_member_use_from_same_package
      assetCache: assetCache,
      svgString: string,
      svgFile: file,
      naturalSize: naturalSize,
      srcRect: srcRect,
      dstRect: dstRect,
      pageIndex: pageIndex,
      pageSize: .infinite,
      isThumbnail: isThumbnail,
      invertible: invertible,
      backgroundFit: backgroundFit,
      newImage: newImage,
      onLoad: onLoad,
      onMoveImage: onMoveImage,
      onMiscChange: onMiscChange,
      onDeleteImage: onDeleteImage,
    )..rotation = rotation;
  }
}
