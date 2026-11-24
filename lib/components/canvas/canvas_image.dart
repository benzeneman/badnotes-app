import 'dart:math';

import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:badnotes/components/canvas/canvas_image_dialog.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/theming/adaptive_alert_dialog.dart';
import 'package:badnotes/data/extensions/change_notifier_extensions.dart';
import 'package:badnotes/i18n/strings.g.dart';

/// A picture on a page, where its [EditorImage] says, or filling the page
/// as its background.
class CanvasImage extends StatefulHookWidget {
  CanvasImage({
    required this.filePath,
    required this.image,
    this.overrideBoxFit,
    required this.pageSize,
    required this.setAsBackground,
    this.isBackground = false,
    this.readOnly = false,
    this.selected = false,
  }) : super(key: Key('CanvasImage$filePath/${image.id}'));

  /// The path to the note that this image is in.
  final String filePath;
  final EditorImage image;
  final BoxFit? overrideBoxFit;
  final Size pageSize;
  final void Function(EditorImage image)? setAsBackground;
  final bool isBackground;
  final bool readOnly;
  final bool selected;

  /// Told when a picture is picked, so every other one is unpicked.
  static var activeListener = ChangeNotifier();

  /// The smallest a picture's touch area gets, however small the picture.
  static double minInteractiveSize = 50;

  /// The smallest a picture itself is shown, inside its touch area.
  static double minImageSize = 10;

  @override
  State<CanvasImage> createState() => _CanvasImageState();
}

class _CanvasImageState extends State<CanvasImage> {
  var _active = false;

  /// Whether this picture is the one picked: it gets a ring, and picking it
  /// unpicks every other.
  bool get active => _active;
  set active(bool value) {
    if (_active == value) return;
    if (value) CanvasImage.activeListener.notifyListenersPlease();
    _active = value;
    if (!mounted) return;
    try {
      setState(() {});
    } catch (_) {
      // can't rebuild while already building; the build in progress shows it
    }
  }

  void _unpick() => active = false;

  @override
  void initState() {
    widget.image.loadIn();
    // a picture just put in starts picked
    if (widget.image.newImage) {
      active = true;
      widget.image.newImage = false;
    }
    CanvasImage.activeListener.addListener(_unpick);
    super.initState();
  }

  @override
  void dispose() {
    widget.image.loadOut();
    CanvasImage.activeListener.removeListener(_unpick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    useListenable(widget.image);
    if (widget.readOnly) active = false;
    final accent = ColorScheme.of(context).primary;
    final image = widget.image;
    final dst = image.dstRect;

    // A rotated page turns its background, which then fills the page sideways.
    final backgroundTurns = (image.rotation / (pi / 2)).round();
    final backgroundSize = backgroundTurns.isOdd
        ? widget.pageSize.flipped
        : widget.pageSize;
    final shownSize = widget.isBackground
        ? backgroundSize
        : Size(
            max(dst.width, CanvasImage.minImageSize),
            max(dst.height, CanvasImage.minImageSize),
          );

    // the part of the picture that's shown ([EditorImage.srcRect]), at its
    // size on the page
    final picture = SizedBox.fromSize(
      size: shownSize,
      child: SizedOverflowBox(
        size: image.srcRect.size,
        child: Transform.translate(
          offset: -image.srcRect.topLeft,
          // pictures keep their own colours, in dark mode too
          child: image.buildImageWidget(
            context: context,
            overrideBoxFit: widget.overrideBoxFit,
            isBackground: widget.isBackground,
            invert: false,
          ),
        ),
      ),
    );

    final Widget body = IgnorePointer(
      ignoring: widget.readOnly,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MouseRegion(
            cursor: MouseCursor.defer,
            // Moving, resizing and turning go through the lasso tool (tap a
            // picture to select it): handling drags here fought the canvas's
            // own gestures. A long press opens the picture's menu.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: showModal,
              onSecondaryTap: showModal,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: active ? accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(child: picture),
              ),
            ),
          ),
          // selected: an outline, not a tint, so the colours stay true
          if (widget.selected)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: accent, width: 3),
              ),
            ),
        ],
      ),
    );

    const slide = Duration(milliseconds: 300);
    if (widget.isBackground) {
      return AnimatedPositioned(
        duration: slide,
        curve: Curves.fastLinearToSlowEaseIn,
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        child: RotatedBox(quarterTurns: backgroundTurns, child: body),
      );
    }
    return AnimatedPositioned(
      // no sliding while the picture is being moved
      duration: widget.selected ? Duration.zero : slide,
      curve: Curves.fastLinearToSlowEaseIn,
      left: dst.left,
      top: dst.top,
      width: max(dst.width, CanvasImage.minInteractiveSize),
      height: max(dst.height, CanvasImage.minInteractiveSize),
      child: image.rotation == 0
          ? body
          : Transform.rotate(angle: image.rotation, child: body),
    );
  }

  void showModal() {
    showAppleDialog(
      context: context,
      builder: (context) => AdaptiveAlertDialog(
        title: Text(t.editor.imageOptions.title),
        content: CanvasImageDialog(
          filePath: widget.filePath,
          image: widget.image,
          redrawImage: () => setState(() {}),
          isBackground: false,
          toggleAsBackground: () => widget.setAsBackground?.call(widget.image),
        ),
        actions: const [],
      ),
    );
  }
}
