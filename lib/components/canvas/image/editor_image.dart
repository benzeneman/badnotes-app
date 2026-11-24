import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:badnotes/components/canvas/_asset_cache.dart';
import 'package:badnotes/components/canvas/_ink_cache.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/components/canvas/canvas_image.dart';
import 'package:badnotes/components/canvas/invert_widget.dart';
import 'package:badnotes/components/editor/page_pins.dart';
import 'package:badnotes/components/editor/sticky_note_dialog.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/pages/editor/editor.dart';

part 'png_editor_image.dart';
part 'pdf_editor_image.dart';
part 'svg_editor_image.dart';

/// The data for an image in the editor.
/// This is listenable for changes to the image's position ([dstRect]).
sealed class EditorImage extends ChangeNotifier {
  /// id for this image, unique within a note
  int id;

  /// The image's file extension, e.g. [".jpg"].
  /// This is used when "downloading" the image to the user's photo gallery.
  final String extension;

  final AssetCache assetCache;

  var _isThumbnail = false;
  bool get isThumbnail => _isThumbnail;
  @mustCallSuper
  set isThumbnail(bool isThumbnail) {
    _isThumbnail = isThumbnail;
  }

  int pageIndex;
  void Function(EditorImage, Rect)? onMoveImage;
  void Function(EditorImage)? onDeleteImage;
  void Function()? onMiscChange;
  final VoidCallback? onLoad;

  Rect srcRect = .zero;

  late var _dstRect = Rect.fromLTWH(
    0,
    0,
    CanvasImage.minImageSize,
    CanvasImage.minImageSize,
  );
  Rect get dstRect => _dstRect;
  set dstRect(Rect dstRect) {
    _dstRect = _scaledUpToMinimum(dstRect);
    notifyListeners();
  }

  /// [rect], made bigger (keeping its shape and its top left corner) if
  /// either side is under [CanvasImage.minImageSize].
  static Rect _scaledUpToMinimum(Rect rect) {
    final least = CanvasImage.minImageSize;
    if (rect.width >= least && rect.height >= least) return rect;
    final grow = max(least / rect.width, least / rect.height);
    return Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width * grow,
      rect.height * grow,
    );
  }

  /// Defines the aspect ratio of the image.
  Size naturalSize;

  /// The size of the page this image is on,
  /// used to make sure the image isn't too big.
  Size? pageSize;

  /// If the image is new, it will be [active] (draggable) when loaded
  var newImage = false;

  /// Whether this image is inverted if Prefs.editorAutoInvert.value
  bool invertible;

  /// The BoxFit used if this is a page's background image
  BoxFit backgroundFit;

  /// Clockwise rotation in radians around the image's center.
  double rotation = 0;

  @protected
  new({
    required this.id,
    required this.assetCache,
    required this.extension,
    required this.pageIndex,
    required this.pageSize,
    this.naturalSize = .zero,
    this.invertible = true,
    this.backgroundFit = .contain,
    required this.onMoveImage,
    required this.onDeleteImage,
    required this.onMiscChange,
    this.onLoad,
    this.newImage = true,
    this._dstRect = .zero,
    this.srcRect = .zero,
    this._isThumbnail = false,
  }) : assert(extension.startsWith('.'));

  /// The id of the [PageLayer] this image is on.
  int layer = 0;

  /// Drawn over the ink, like a picture stuck on the page. New pictures and
  /// sticky notes are; ones from older notes stay under the ink.
  bool inFront = false;

  /// When it was put over the writing (microseconds since 1970): writing
  /// done after it is over it, writing done before is under it, and so
  /// are pictures and text boxes put on before and after it. 0 in notes
  /// saved before this was kept.
  int order = 0;

  /// Put on a tape after it was put down (a text box written on the tape,
  /// say): drawn over the tape, and hidden while the tape is peeked under.
  bool onTape = false;

  factory fromJson(
    Map<String, dynamic> json, {
    required List<Uint8List>? inlineAssets,
    bool isThumbnail = false,
    required String sbnPath,
    required AssetCache assetCache,
  }) {
    // the kind of picture is its file extension; anything else is a bitmap
    final build = switch (json['e'] as String?) {
      '.svg' => SvgEditorImage.fromJson,
      '.pdf' => PdfEditorImage.fromJson,
      _ => PngEditorImage.fromJson,
    };
    final EditorImage image = build(
      json,
      inlineAssets: inlineAssets,
      isThumbnail: isThumbnail,
      sbnPath: sbnPath,
      assetCache: assetCache,
    );
    image
      ..rotation = (json['r'] as num?)?.toDouble() ?? 0
      ..inFront = json['fr'] == true
      ..order = json['io'] as int? ?? 0
      ..onTape = json['ot'] == true;
    return image;
  }

  @mustBeOverridden
  @mustCallSuper
  Map<String, dynamic> toJson(OrderedAssetCache assets) {
    final json = <String, dynamic>{
      'id': id,
      'e': extension,
      'i': pageIndex,
      'v': invertible,
      'f': backgroundFit.index,
      'x': dstRect.left,
      'y': dstRect.top,
      'w': dstRect.width,
      'h': dstRect.height,
    };
    // left out when they have their usual value, to keep notes small
    void keep(String key, num value) {
      if (value != 0) json[key] = value;
    }

    keep('r', rotation);
    if (inFront) json['fr'] = true;
    keep('io', order);
    if (onTape) json['ot'] = true;
    keep('sx', srcRect.left);
    keep('sy', srcRect.top);
    keep('sw', srcRect.width);
    keep('sh', srcRect.height);
    keep('nw', naturalSize.width);
    keep('nh', naturalSize.height);
    return json;
  }

  /// Images are loaded out after 5 seconds of not being visible.
  ///
  /// Set this to true to load out immediately.
  ///
  /// This is useful for tests that can't have pending timers.
  @visibleForTesting
  static var shouldLoadOutImmediately = false;

  /// The first [firstLoad], started by the first [loadIn] and shared by
  /// the ones after it.
  Future<void>? _firstLoad;

  /// The verdict of the countdown a [loadOut] started: true to unload, false
  /// if the image was asked for again ([loadIn]) before it ended.
  Completer<bool>? _unloadVerdict;
  var _loadedIn = false;
  bool get loadedIn => _loadedIn;

  Future<void> firstLoad();

  /// Called when the image becomes visible; often reads the image from
  /// disk.
  ///
  /// The first call starts [firstLoad] (and doesn't wait for it); the calls
  /// after it wait until it has finished.
  ///
  /// See also:
  /// * [loadOut], which frees the image's memory again
  /// * [precache], which adds the image to Flutter's image cache
  /// * [loadedIn], true after [loadIn] and false after [loadOut]
  @mustBeOverridden
  @mustCallSuper
  Future<void> loadIn() async {
    // wanted again: cancels a countdown to unloading
    final countdown = _unloadVerdict;
    if (countdown != null && !countdown.isCompleted) countdown.complete(false);

    final firstCall = _firstLoad == null;
    _firstLoad ??= firstLoad();
    if (!firstCall) await _firstLoad;

    _loadedIn = true;
  }

  /// Frees memory once the image has been out of sight for 5 seconds (or at
  /// once, in tests that can't have timers pending). Returns whether it did;
  /// a [loadIn] in between cancels it.
  ///
  /// See also:
  /// * [loadIn], which brings the image back
  /// * [loadedIn], true after [loadIn] and false after [loadOut]
  @mustBeOverridden
  @mustCallSuper
  Future<bool> loadOut() async {
    final verdict = _unloadVerdict ??= _startUnloadCountdown();
    final unload = await verdict.future;
    _unloadVerdict = null;
    if (unload) _loadedIn = false;
    return unload;
  }

  Completer<bool> _startUnloadCountdown() {
    final verdict = Completer<bool>();
    if (shouldLoadOutImmediately) {
      verdict.complete(true);
    } else {
      Future.delayed(const Duration(seconds: 5), () {
        if (!verdict.isCompleted) verdict.complete(true);
      });
    }
    return verdict;
  }

  /// How the picture fills its box: [override] if given, else the page's
  /// fit for a background, else stretched to the box.
  @protected
  BoxFit fitFor(BoxFit? override, bool isBackground) =>
      override ?? (isBackground ? backgroundFit : BoxFit.fill);

  /// Fills in the source and target rectangles of a picture that has
  /// neither yet, from [naturalSize] (and the page it has to fit on).
  @protected
  void settleRects() {
    if (srcRect.shortestSide == 0) srcRect = srcRect.topLeft & naturalSize;
    if (dstRect.shortestSide == 0) {
      final size = pageSize == null
          ? naturalSize
          : resize(naturalSize, pageSize!);
      dstRect = dstRect.topLeft & size;
    }
  }

  /// Adds the image to Flutter's image cache.
  Future<void> precache(BuildContext context);

  Widget buildImageWidget({
    required BuildContext context,
    required BoxFit? overrideBoxFit,
    required bool isBackground,
    required bool invert,
  });

  EditorImage copy();

  /// This image's file, to put into another note. Null if it can't be.
  Future<Uint8List?> fileBytes() async => null;

  /// Resizes [before] to fit inside [max] while maintaining aspect ratio.
  ///
  /// The image is allowed to be 1px over [max] for rounding tolerance.
  @visibleForTesting
  static Size resize(Size before, Size max) {
    final ratio = before.width / before.height;
    var size = before;
    // one pixel over is let through, so rounding can't shrink a picture
    if (size.width > max.width + 1) {
      size = Size(max.width, max.width / ratio);
    }
    if (size.height > max.height + 1) {
      size = Size(max.height * ratio, max.height);
    }
    return size;
  }
}

/// What a picture's entry in a note says about where it is and how it is
/// shown, whatever kind of picture it is. Missing keys have their usual
/// values.
class _Placement {
  _Placement(Map<String, dynamic> json)
    // -1 is replaced by [EditorCoreInfo._handleEmptyImageIds()]
    : id = json['id'] ?? -1,
      pageIndex = json['i'] ?? 0,
      invertible = json['v'] ?? true,
      backgroundFit = json['f'] == null
          ? BoxFit.contain
          : BoxFit.values[json['f']],
      dstRect = Rect.fromLTWH(
        json['x'] ?? 0,
        json['y'] ?? 0,
        json['w'] ?? 0,
        json['h'] ?? 0,
      ),
      srcRect = Rect.fromLTWH(
        json['sx'] ?? 0,
        json['sy'] ?? 0,
        json['sw'] ?? 0,
        json['sh'] ?? 0,
      ),
      naturalSize = Size(json['nw'] ?? 0, json['nh'] ?? 0);

  final int id;
  final int pageIndex;
  final bool invertible;
  final BoxFit backgroundFit;
  final Rect dstRect;
  final Rect srcRect;
  final Size naturalSize;
}
