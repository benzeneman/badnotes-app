import 'dart:math';

import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/tools/_tool.dart';
import 'package:badnotes/data/tools/select.dart';
import 'package:sbn/tool_id.dart';

/// One page of a note as the editor shows it: the paper with its shadow,
/// scaled to fit, holding the [InnerCanvas] that draws the page.
class Canvas extends StatelessWidget {
  const new({
    super.key,
    required this.path,
    required this.page,
    required this.pageIndex,
    required this.textEditing,
    required this.coreInfo,
    required this.currentStroke,
    required this.currentSelection,
    required this.setAsBackground,
    required this.currentTool,
    required this.currentScale,
    this.placeholder = false,
  });

  /// Where the note is stored.
  final String path;

  /// The page shown, and its place in the note.
  final EditorPage page;
  final int pageIndex;

  /// Whether taps go to the typed text instead of the pen.
  final bool textEditing;
  final EditorCoreInfo coreInfo;

  /// The line being written now, if any.
  final Stroke? currentStroke;

  /// What the lasso has picked, if anything.
  final SelectResult? currentSelection;

  /// Called to make a picture the page's background.
  final void Function(EditorImage image)? setAsBackground;

  final Tool currentTool;
  final double currentScale;

  /// When true nothing is drawn: only an empty sheet of the page's size is
  /// laid out, standing in for the page.
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    if (placeholder) return _build(context, null);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // as much as the FittedBox below shrinks the page
        var fit = 1.0;
        if (constraints.maxWidth.isFinite) {
          fit = min(fit, constraints.maxWidth / page.size.width);
        }
        if (constraints.maxHeight.isFinite) {
          fit = min(fit, constraints.maxHeight / page.size.height);
        }
        return _build(context, devicePixelRatio * fit * currentScale);
      },
    );
  }

  Widget _build(BuildContext context, double? pixelScale) {
    return Center(
      child: FittedBox(
        child: DecoratedBox(
          decoration: BoxDecoration(
            // A thin edge with no blur: a blurred shadow round every page was
            // drawn again on every frame of a scroll, which lagged. None on a
            // whiteboard: its page is see-through (the paper is drawn behind
            // it), and the shadow, filled in under it, made white look grey.
            boxShadow: page.isBoard
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      offset: const Offset(0, 2),
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: !placeholder
              ? SizedBox(
                  width: page.size.width,
                  height: page.size.height,
                  child: InnerCanvas(
                    key: page.innerCanvasKey,
                    pageIndex: pageIndex,
                    redrawPageListenable: page,
                    // the editor shows one that stays in the screen's corner
                    showPageIndicator: false,
                    width: page.size.width,
                    height: page.size.height,
                    textEditing: textEditing,
                    coreInfo: coreInfo,
                    currentStroke: currentStroke,
                    currentSelection: currentSelection,
                    setAsBackground: setAsBackground,
                    currentToolIsSelect: currentTool.toolId == ToolId.select,
                    currentScale: currentScale,
                    pixelScale: pixelScale,
                  ),
                )
              : SizedBox(width: page.size.width, height: page.size.height),
        ),
      ),
    );
  }
}
