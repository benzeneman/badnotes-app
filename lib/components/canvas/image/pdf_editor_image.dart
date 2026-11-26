part of 'editor_image.dart';

/// One page of a PDF, shown as a picture: usually a page's background after
/// a PDF was imported. The PDF itself is opened once per note and shared by
/// all of its pages (see [AssetCache.pdfDocumentCache]).
class PdfEditorImage extends EditorImage {
  /// The PDF file's bytes, when they are held in memory rather than read
  /// from [pdfFile].
  Uint8List? pdfBytes;

  /// Which page of the PDF this shows, counting from 0.
  final int pdfPage;

  /// The PDF's file beside the note, when it is read from disk.
  final File? pdfFile;

  /// Whether the page is shown with its colors inverted.
  var darkMode = false;

  /// The opened PDF, null until [firstLoad] has opened it.
  final _pdfDocument = ValueNotifier<PdfDocument?>(null);

  static final log = Logger('PdfEditorImage');

  new({
    required super.id,
    required super.assetCache,
    required this.pdfBytes,
    required this.pdfFile,
    required this.pdfPage,
    required super.pageIndex,
    required super.pageSize,
    required super.naturalSize,
    required super.onMoveImage,
    required super.onDeleteImage,
    required super.onMiscChange,
    super.onLoad,
    super.invertible,
    super.backgroundFit,
    super.newImage,
    super.dstRect,
    super.isThumbnail,
  }) : assert(!naturalSize.isEmpty, 'a PDF page must know its size'),
       assert(
         pdfBytes != null || pdfFile != null,
         'a PDF page needs the PDF\'s bytes or its file',
       ),
       // the whole page is always shown
       super(extension: '.pdf', srcRect: .zero);

  factory fromJson(
    Map<String, dynamic> json, {
    required List<Uint8List>? inlineAssets,
    bool isThumbnail = false,
    required String sbnPath,
    required AssetCache assetCache,
  }) {
    assert(const {null, '.pdf'}.contains(json['e'] as String?));

    final asset = _assetIn(json, inlineAssets, sbnPath);
    final file = asset?.file;

    final Uint8List? bytes;
    if (asset != null) {
      // read ahead by the asset cache, or else opened from the file
      bytes = file == null ? asset.inline : assetCache.get(file);
    } else {
      if (kDebugMode) {
        throw Exception('PdfEditorImage.fromJson: the entry has no PDF');
      }
      bytes = Uint8List(0);
    }

    final pdfPage = jsonInt(json['pdfi']);
    if (pdfPage == null) {
      log.warning('fromJson: the page of the pdf is missing, using the first');
    }

    final at = _Placement(json);
    return PdfEditorImage(
      id: at.id,
      assetCache: assetCache,
      pdfBytes: bytes,
      pdfFile: file,
      pdfPage: pdfPage ?? 0,
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
      naturalSize: at.naturalSize,
      isThumbnail: isThumbnail,
    )..darkMode = json['dark'] ?? false;
  }

  @override
  Map<String, dynamic> toJson(OrderedAssetCache assets) {
    final json = super.toJson(assets);
    assert(!json.containsKey('a'));
    json
      ..['a'] = pdfFile == null
          ? assets.addBytes(pdfBytes!)
          : assets.addFile(pdfFile!)
      ..['pdfi'] = pdfPage;
    if (darkMode) json['dark'] = true;
    return json;
  }

  /// The PDF this page is from, opened through the note's shared cache the
  /// first time it is needed.
  Future<PdfDocument> _openDocument() async =>
      _pdfDocument.value ??= await assetCache.pdfDocumentCache.load(
        pdfFile?.path ?? 'inline_pdf_$id.pdf',
        pdfBytes: pdfBytes,
      );

  /// Gives the page its place if the note has none for it yet, then opens
  /// the PDF and loads this page of it.
  @override
  Future<void> firstLoad() async {
    assert(srcRect.isEmpty);
    assert(!naturalSize.isEmpty);

    if (dstRect.isEmpty) {
      final fitted = pageSize == null
          ? naturalSize
          : EditorImage.resize(naturalSize, pageSize!);
      dstRect = dstRect.topLeft & fitted;
    }

    assert(id != -1, 'the image needs its id before it can load');
    final document = await _openDocument();
    await document.pages[pdfPage].ensureLoaded();
  }

  /// The text on this page of the pdf. Empty for a scan, which has only images.
  Future<String> loadText() async {
    final page = (await _openDocument()).pages[pdfPage];
    await page.ensureLoaded();
    return (await page.loadText())?.fullText ?? '';
  }

  /// Where [query] is on this page of the pdf, within [area] of the note's page.
  /// Nothing if the pdf page is turned.
  Future<List<Rect>> findText(String query, Rect area) async {
    if (rotation != 0) return const [];
    final words = query.trim().split(RegExp(r'\s+'));
    if (words.first.isEmpty) return const [];
    final page = (await _openDocument()).pages[pdfPage];
    await page.ensureLoaded();
    final text = await page.loadText();
    if (text == null) return const [];
    final pattern = RegExp(
      words.map(RegExp.escape).join(r'\s+'),
      caseSensitive: false,
    );
    final rects = <Rect>[];
    for (final match in pattern.allMatches(text.fullText).take(50)) {
      final chars = <Rect>[];
      for (
        var i = match.start;
        i < match.end && i < text.charRects.length;
        i++
      ) {
        final r = text.charRects[i];
        chars.add(
          Rect.fromLTRB(
            area.left + r.left / page.width * area.width,
            area.top + (page.height - r.top) / page.height * area.height,
            area.left + r.right / page.width * area.width,
            area.top + (page.height - r.bottom) / page.height * area.height,
          ),
        );
      }
      rects.addAll(mergeIntoLines(chars));
    }
    return rects;
  }

  /// The characters of a piece of text, as one box for each line it's on.
  @visibleForTesting
  static List<Rect> mergeIntoLines(List<Rect> chars) {
    final lines = <Rect>[];
    for (final char in chars) {
      if (char.isEmpty) continue;
      final line = lines.isEmpty ? null : lines.last;
      if (line != null &&
          char.center.dy > line.top &&
          char.center.dy < line.bottom) {
        lines.last = line.expandToInclude(char);
      } else {
        lines.add(char);
      }
    }
    return lines;
  }

  @override
  Future<void> loadIn() async => await super.loadIn();

  @override
  Future<bool> loadOut() async => await super.loadOut();

  /// Finishes once the PDF has been opened (straight away if it already
  /// is); [firstLoad] does the opening.
  @override
  Future<void> precache(BuildContext context) {
    if (_pdfDocument.value != null) return Future.value();

    final opened = Completer<void>();
    void whenOpened() {
      if (_pdfDocument.value == null || opened.isCompleted) return;
      opened.complete();
      _pdfDocument.removeListener(whenOpened);
    }

    _pdfDocument.addListener(whenOpened);
    return opened.future;
  }

  /// An empty box of the page's size until the PDF is open, then the page.
  @override
  Widget buildImageWidget({
    required BuildContext context,
    required BoxFit? overrideBoxFit,
    required bool isBackground,
    required bool invert,
  }) {
    return ValueListenableBuilder(
      valueListenable: _pdfDocument,
      builder: (context, document, _) => document == null
          ? SizedBox.fromSize(size: srcRect.size)
          : InvertWidget(
              invert: invert || darkMode,
              child: PdfPageView(
                document: document,
                pageNumber: pdfPage + 1, // pdfrx counts pages from 1
                decoration: const BoxDecoration(),
                pageSizeCallback: _renderSizeFor(context),
              ),
            ),
    );
  }

  /// Biggest page drawn, in pixels, as with [InkCache.maxPixels].
  static const _maxRenderPixels = 6000000;

  /// How big to draw the pdf page, in pixels: as big as it shows on screen,
  /// not as big as its full size on the page. Each page used to be drawn at up
  /// to 300 dpi, around 9M pixels, even as a small thumbnail; now it's drawn
  /// again more sharply when zoomed in.
  PdfPageViewSizeCallback? _renderSizeFor(BuildContext context) {
    final pixelScale = InkPixelScale.of(context);
    if (pixelScale == null || pixelScale <= 0 || !pixelScale.isFinite) {
      return null;
    }
    final scale = InkCache.renderScale(pixelScale);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return (biggestSize, page, rotationOverride) {
      final swapWH =
          ((rotationOverride ?? page.rotation).index - page.rotation.index) &
              1 ==
          1;
      final w = swapWH ? page.height : page.width;
      final h = swapWH ? page.width : page.height;
      // [biggestSize] is the laid out size in device pixels
      var fit =
          min(biggestSize.width / w, biggestSize.height / h) *
          scale /
          devicePixelRatio;
      fit = min(fit, 300 / 72);
      fit = min(fit, sqrt(_maxRenderPixels / (w * h)));
      return Size(w * fit, h * fit);
    };
  }

  @override
  PdfEditorImage copy() {
    final twin = PdfEditorImage(
      id: id,
      assetCache: assetCache,
      pdfBytes: pdfBytes,
      pdfFile: pdfFile,
      pdfPage: pdfPage,
      pageIndex: pageIndex,
      pageSize: .infinite,
      naturalSize: naturalSize,
      invertible: invertible,
      backgroundFit: backgroundFit,
      onMoveImage: onMoveImage,
      onDeleteImage: onDeleteImage,
      onMiscChange: onMiscChange,
      onLoad: onLoad,
      newImage: true,
      dstRect: dstRect,
      isThumbnail: isThumbnail,
    );
    twin
      ..darkMode = darkMode
      ..rotation = rotation;
    return twin;
  }

  /// Lets go of the PDF's bytes and stops listening for the document.
  @override
  void dispose() {
    _pdfDocument.dispose();
    pdfBytes = null;
    super.dispose();
  }
}
