part of 'editor_image.dart';

/// A bitmap picture on a page (a photo, a screenshot, a pasted image).
///
/// Big pictures are shrunk once when they are first loaded (see
/// [stows.maxImageSize]) and decoded only as big as they show on the page.
class PngEditorImage extends EditorImage {
  /// Where the picture's encoded bytes come from: memory, or the asset file
  /// beside the note.
  ImageProvider imageProvider;

  new({
    required super.id,
    required super.assetCache,
    required super.extension,
    required this.imageProvider,
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
  });

  factory fromJson(
    Map<String, dynamic> json, {
    required List<Uint8List>? inlineAssets,
    bool isThumbnail = false,
    required String sbnPath,
    required AssetCache assetCache,
  }) {
    final asset = _assetIn(json, inlineAssets, sbnPath);
    final file = asset?.file;

    final Uint8List? bytes;
    if (asset != null) {
      // read ahead by the asset cache, or else left for [FileImage] to read
      bytes = file == null ? asset.inline : assetCache.get(file);
    } else if (json['b'] != null) {
      // very old notes kept the bytes right in the entry
      bytes = Uint8List.fromList((json['b'] as List<dynamic>).cast<int>());
    } else {
      if (kDebugMode) {
        throw Exception('PngEditorImage.fromJson: the entry has no picture');
      }
      bytes = Uint8List(0);
    }
    assert(bytes != null || file != null, 'a picture needs bytes or a file');

    final at = _Placement(json);
    return PngEditorImage(
      id: at.id,
      assetCache: assetCache,
      extension: json['e'] ?? '.jpg',
      imageProvider: bytes == null
          ? FileImage(file!)
          : MemoryImage(bytes) as ImageProvider,
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
    return json..['a'] = assets.addImage(imageProvider);
  }

  @override
  void moveFile(File? Function(File file) moved) {
    if (imageProvider case FileImage(:final file)) {
      if (moved(file) case final to?) {
        // what was decoded from that file before may be another picture
        final next = FileImage(to);
        unawaited(next.evict());
        imageProvider = next;
      }
    }
  }

  /// Works out the picture's size when the note doesn't say how it is
  /// placed yet (a picture just added), shrinking it first if it is bigger
  /// than the user's largest picture size.
  @override
  Future<void> firstLoad() async {
    assert(Isolate.current.debugName == 'main');

    if (srcRect.shortestSide == 0 || dstRect.shortestSide == 0) {
      final encoded = await _encodedBytes();
      naturalSize = await _pixelSizeOf(encoded);
      await _shrinkToMaxSize(encoded);
      settleRects();
    }

    // older notes didn't keep the size: the cropped part is close enough
    if (naturalSize.shortestSide == 0) naturalSize = srcRect.size;
  }

  /// The picture file's bytes, from memory or from disk.
  Future<Uint8List> _encodedBytes() async => switch (imageProvider) {
    final MemoryImage memory => memory.bytes,
    final FileImage file => await file.file.readAsBytes(),
    final other => throw Exception(
      'PngEditorImage: can\'t read bytes from a ${other.runtimeType}',
    ),
  };

  /// The width and height of the encoded picture, read from its header
  /// without decoding it.
  static Future<Size> _pixelSizeOf(Uint8List encoded) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(encoded);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    return Size(descriptor.width.toDouble(), descriptor.height.toDouble());
  }

  /// Swaps [imageProvider] for a smaller copy when [naturalSize] is over
  /// [stows.maxImageSize]. Thumbnails are left as they are.
  Future<void> _shrinkToMaxSize(Uint8List encoded) async {
    if (!stows.maxImageSize.loaded) await stows.maxImageSize.waitUntilRead();
    final allowed = EditorImage.resize(
      naturalSize,
      .square(stows.maxImageSize.value),
    );
    if (isThumbnail || allowed.width == naturalSize.width) return;

    await null; // let the event loop breathe before the slow re-encode
    final smaller = await _resizeImage(
      encoded,
      width: allowed.width.round(),
      height: allowed.height.round(),
    );
    if (smaller != null) imageProvider = MemoryImage(smaller);
    naturalSize = allowed;
  }

  @override
  Future<void> loadIn() async => await super.loadIn();

  @override
  Future<bool> loadOut() async => await super.loadOut();

  @override
  Future<void> precache(BuildContext context) =>
      precacheImage(_shownProvider, context);

  /// Picture pixels for each unit of the page: sharp up to about 2.5x zoom on a
  /// phone, and further on a tablet.
  static const _pixelsPerUnit = 2.5;

  /// [imageProvider] decoded only as big as it shows on the page. A photo
  /// straight from the camera took 50 MB or more of memory at its full size.
  ImageProvider get _shownProvider {
    final width = dstRect.width;
    if (!width.isFinite || width <= 0) return imageProvider;
    // in steps, so resizing the picture doesn't decode it again on every move
    final target = ((width * _pixelsPerUnit) / 256).ceil() * 256;
    if (naturalSize.width > 0 && target >= naturalSize.width) {
      return imageProvider;
    }
    return ResizeImage.resizeIfNeeded(target, null, imageProvider);
  }

  @override
  Widget buildImageWidget({
    required BuildContext context,
    required BoxFit? overrideBoxFit,
    required bool isBackground,
    required bool invert,
  }) {
    return InvertWidget(
      invert: invert,
      child: Image(
        image: _shownProvider,
        fit: fitFor(overrideBoxFit, isBackground),
        // the old size stays up while a resized picture decodes
        gaplessPlayback: true,
      ),
    );
  }

  @override
  Future<Uint8List?> fileBytes() async => switch (imageProvider) {
    final MemoryImage image => image.bytes,
    final FileImage image => image.file.readAsBytes(),
    _ => null,
  };

  /// A copy for pasting: the same picture and place, new to the page.
  @override
  PngEditorImage copy() => PngEditorImage(
    id: id,
    assetCache: assetCache,
    extension: extension,
    imageProvider: imageProvider,
    naturalSize: naturalSize,
    srcRect: srcRect,
    dstRect: dstRect,
    pageIndex: pageIndex,
    pageSize: .infinite,
    isThumbnail: isThumbnail,
    invertible: invertible,
    backgroundFit: backgroundFit,
    newImage: true,
    onLoad: onLoad,
    onMoveImage: onMoveImage,
    onMiscChange: onMiscChange,
    onDeleteImage: onDeleteImage,
  )..rotation = rotation;
}

/// The asset a picture's note entry points at (its `'a'` index), shared by
/// every kind of picture. When the note was read in one piece its assets
/// came with it ([inline]); otherwise the asset is the [file] next to the
/// note. Null for an entry that names no asset.
({File? file, Uint8List? inline})? _assetIn(
  Map<String, dynamic> json,
  List<Uint8List>? inlineAssets,
  String sbnPath,
) {
  final index = jsonInt(json['a']);
  if (index == null) return null;
  if (inlineAssets != null) return (file: null, inline: inlineAssets[index]);
  return (
    file: FileManager.getFile('$sbnPath${Editor.extension}.$index'),
    inline: null,
  );
}

/// [encoded] decoded at [width] x [height] and encoded again as a PNG, or
/// null if the engine couldn't encode it. Every engine object made on the
/// way is released, whatever happens.
Future<Uint8List?> _resizeImage(
  Uint8List encoded, {
  required int width,
  required int height,
}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(encoded);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? frame;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    codec = await descriptor.instantiateCodec(
      targetWidth: width,
      targetHeight: height,
    );
    frame = (await codec.getNextFrame()).image;
    final png = await frame.toByteData(format: ui.ImageByteFormat.png);
    return png?.buffer.asUint8List();
  } finally {
    frame?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}
