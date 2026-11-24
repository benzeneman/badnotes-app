import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/extensions/list_extensions.dart';
import 'package:badnotes/data/prefs.dart';

/// A still, read-only drawing of one page of a note, used for thumbnails and
/// when exporting. Nothing on it can be selected or drawn on.
class CanvasPreview extends StatelessWidget implements PreferredSizeWidget {
  new({
    super.key,
    this.pageIndex = 0,
    required this.height,
    required this.coreInfo,
    this.pixelScale,
  });

  final int pageIndex;

  /// Overrides the page's own height when given (e.g. to crop it).
  final double? height;
  final EditorCoreInfo coreInfo;

  /// How many screen pixels make one page unit when this is shown on screen.
  /// Given, it lets the ink be cached as a small picture rather than redrawn
  /// line by line every frame; exports leave it null to draw at full quality.
  final double? pixelScale;

  /// The page's own size, or the usual size if the page doesn't exist.
  late final Size pageSize = switch (coreInfo.pages.getOrNull(pageIndex)) {
    final page? => page.size,
    null => EditorPage.defaultSize,
  };

  @override
  late final preferredSize = Size(pageSize.width, height ?? pageSize.height);

  @override
  Widget build(BuildContext context) => InnerCanvas(
    coreInfo: coreInfo,
    pageIndex: pageIndex,
    width: preferredSize.width,
    height: preferredSize.height,
    pixelScale: pixelScale,
    showPageIndicator: stows.printPageIndicators.value,
    currentScale: double.maxFinite,
    currentToolIsSelect: false,
    currentStroke: null,
    currentSelection: null,
  );
}
