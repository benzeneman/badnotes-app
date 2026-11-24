import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Draws [child] once, into a picture of its pixels, and shows that picture
/// from then on. For previews that are drawn from many shapes (paper
/// patterns, covers, vector art): drawn afresh on every frame of a scroll,
/// a list of them lagged. [cacheKey] must change whenever [child] would
/// look different; pictures are shared between widgets with the same key.
class FrozenPicture extends StatefulWidget {
  const FrozenPicture({super.key, required this.cacheKey, required this.child});

  final Object cacheKey;
  final Widget child;

  /// The pictures kept, latest used last.
  static final _cache = LinkedHashMap<Object, ui.Image>();
  // A cover is kept per size it is shown at (tile, preview, home card), so
  // the cover library alone holds dozens.
  static const _maxPictures = 192;

  static ui.Image? _get(Object key) {
    final image = _cache.remove(key);
    if (image != null) _cache[key] = image; // used most lately now
    return image;
  }

  static void _put(Object key, ui.Image image) {
    _cache.remove(key)?.dispose();
    _cache[key] = image;
    while (_cache.length > _maxPictures) {
      // shown pictures hold their own clone (RawImage), so this frees only
      // the cache's handle
      _cache.remove(_cache.keys.first)?.dispose();
    }
  }

  @override
  State<FrozenPicture> createState() => _FrozenPictureState();
}

class _FrozenPictureState extends State<FrozenPicture> {
  final _boundary = GlobalKey();

  /// The key a capture is already waiting for, so rebuilds don't queue more.
  Object? _pending;

  Object _fullKey(Size size, double ratio) => (widget.cacheKey, size, ratio);

  void _capture(Object key) {
    if (_pending == key) return;
    _pending = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pending != key) return;
      _pending = null;
      try {
        final box = _boundary.currentContext?.findRenderObject();
        if (box is! RenderRepaintBoundary || !box.hasSize) return;
        // debugNeedsPaint only works in debug builds (it throws in release,
        // which once meant nothing was ever kept); after the frame the
        // boundary has painted anyway
        if (kDebugMode && box.debugNeedsPaint) return;
        final ratio = MediaQuery.devicePixelRatioOf(context);
        FrozenPicture._put(key, box.toImageSync(pixelRatio: ratio));
        setState(() {});
      } catch (_) {
        // drawn live then, as it would be without this
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (!size.isFinite) return widget.child;
        final key = _fullKey(size, ratio);
        final image = FrozenPicture._get(key);
        if (image != null) {
          return RawImage(
            image: image,
            width: size.width,
            height: size.height,
            scale: ratio,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          );
        }
        _capture(key);
        return RepaintBoundary(key: _boundary, child: widget.child);
      },
    );
  }
}
