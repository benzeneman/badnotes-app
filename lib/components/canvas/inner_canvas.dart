import 'dart:math';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:badnotes/components/canvas/_canvas_background_painter.dart';
import 'package:badnotes/components/canvas/_canvas_painter.dart';
import 'package:badnotes/components/canvas/_ink_cache.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/canvas_image.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/select.dart';
import 'package:sbn/canvas_background_pattern.dart';
import 'package:sbn/quill_styles.dart';

/// What pictures on a page need to know about it: screen pixels per unit of
/// the page, to be drawn only as detailed as they show (see
/// [InnerCanvas.pixelScale]), and whether its ink is inverted.
class InkPixelScale extends InheritedWidget {
  const new({
    super.key,
    required this.pixelScale,
    required this.invertsInk,
    required super.child,
  });

  final double? pixelScale;
  final bool invertsInk;

  /// null when not on screen, as in exports, which want full detail.
  static double? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InkPixelScale>()?.pixelScale;

  /// Whether the page's ink is drawn inverted, see [InnerCanvas.invertsInk].
  static bool invertsInkOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InkPixelScale>()?.invertsInk ??
      false;

  @override
  bool updateShouldNotify(InkPixelScale oldWidget) =>
      pixelScale != oldWidget.pixelScale || invertsInk != oldWidget.invertsInk;
}

/// Draws one page at its own size, layer on layer: the paper and its ruling,
/// pictures, typed text, finished ink, the lasso's pick and the line being
/// written. [Canvas] wraps it with scaling and the page's shadow; previews
/// and exports use it on its own.
class InnerCanvas extends StatefulWidget {
  const new({
    super.key,
    required this.pageIndex,
    this.redrawPageListenable,
    required this.width,
    required this.height,
    this.showPageIndicator = true,
    this.textEditing = false,
    this.showTypedText = true,
    required this.coreInfo,
    required this.currentStroke,
    required this.currentSelection,
    this.setAsBackground,
    this.onRenderObjectChange,
    required this.currentToolIsSelect,
    required this.currentScale,
    this.pixelScale,
  });

  /// Which page of [coreInfo] is drawn.
  final int pageIndex;

  /// Fires when the page's ink must be painted again.
  final Listenable? redrawPageListenable;

  /// The page's size, in page units.
  final double width;
  final double height;

  /// Whether the page number is painted on the page itself.
  final bool showPageIndicator;

  /// Whether the typed text takes taps, for the text tool.
  final bool textEditing;

  /// False for a second view of a page: a page's text editor can only be
  /// on screen once, because it owns the page's focus node.
  final bool showTypedText;

  /// The note the page belongs to.
  final EditorCoreInfo coreInfo;

  /// The line being written now, if any.
  final Stroke? currentStroke;

  /// What the lasso has picked, if anything.
  final SelectResult? currentSelection;

  /// Offered on pictures, to make one the page's background.
  final void Function(EditorImage image)? setAsBackground;
  final ValueChanged<RenderObject>? onRenderObjectChange;

  /// Pictures can only be moved and resized with the lasso tool.
  final bool currentToolIsSelect;

  /// How far the editor is zoomed in.
  final double currentScale;

  /// Screen pixels per unit of the page. When given, finished ink is kept as
  /// images of that size, see [InkCache].
  final double? pixelScale;

  /// The paper colour when neither the page nor the note picked one: a
  /// white just soft enough not to glare.
  static const defaultBackgroundColor = Color(0xFFFCFCFC);

  /// While true, pages are drawn without their paper colour and lines (a
  /// PDF's page stays): for a frame, for the lasso's "No paper" screenshot.
  static final hidePaper = ValueNotifier(false);

  /// While true, pages drawn for an export leave out their paper colour and
  /// lines ("Include page paper" off). Read when built; nothing redraws
  /// for it.
  static var exportWithoutPaper = false;

  /// Whether the paper color of [page] was picked, for the page or the note.
  /// Dark mode only turns the default paper dark: a page made white stays
  /// white, with its ink as drawn. Whiteboards always get a color, so they
  /// keep following dark mode.
  static bool hasChosenColor(EditorPage page, EditorCoreInfo coreInfo) =>
      !page.isBoard &&
      (page.backgroundColor ?? coreInfo.backgroundColor) != null;

  /// Whether the ink on [page] is drawn with its lightness turned around, as
  /// on a page turned dark. The toolbar's colors follow the same rule, so a
  /// color looks the same in the toolbar as on the page.
  static bool invertsInk(
    EditorPage page,
    EditorCoreInfo coreInfo,
    Brightness brightness,
  ) {
    final background = page.backgroundImage;
    // ink has to stay readable on the page's pdf, whatever the app's theme
    if (background is PdfEditorImage) return background.darkMode;
    return stows.editorAutoInvert.value &&
        brightness == .dark &&
        // a paper color picked for the page is kept in dark mode
        !hasChosenColor(page, coreInfo);
  }

  @override
  State<InnerCanvas> createState() => _InnerCanvasState();
}

class _InnerCanvasState extends State<InnerCanvas>
    with SingleTickerProviderStateMixin {
  final _inkCache = InkCache();

  /// Runs the selection's dotted edge round, while something is picked.
  late final _ants = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  /// For the ink written on pictures and sticky notes over the ink.
  final _frontInkCache = InkCache();

  /// The ink in each gap over the first, between pictures and text boxes
  /// put over the writing, see [EditorPage.tierOf]: gap 1 is
  /// [_frontInkCache].
  final _tierCaches = <int, InkCache>{};

  InkCache _cacheOf(int tier) => switch (tier) {
    0 => _inkCache,
    1 => _frontInkCache,
    _ => _tierCaches.putIfAbsent(tier, InkCache.new),
  };

  /// The typed text never scrolls, but its editor needs a controller. A new
  /// one on every build was never disposed.
  final _quillScrollController = ScrollController();

  void _paperShownOrHidden() => setState(() {});

  @override
  void initState() {
    super.initState();
    InnerCanvas.hidePaper.addListener(_paperShownOrHidden);
  }

  @override
  void dispose() {
    InnerCanvas.hidePaper.removeListener(_paperShownOrHidden);
    _ants.dispose();
    _inkCache.dispose();
    _frontInkCache.dispose();
    for (final cache in _tierCaches.values) {
      cache.dispose();
    }
    _quillScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // the edge runs only while something is picked here
    final picked =
        widget.currentSelection != null && Select.currentSelect.doneSelecting;
    if (picked && !_ants.isAnimating) {
      _ants.repeat();
    } else if (!picked && _ants.isAnimating) {
      _ants.stop();
    }
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    if (widget.coreInfo.pages.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    final page = widget.coreInfo.pages[widget.pageIndex];
    // a whiteboard's paper is drawn behind it, only where the screen is
    final noPaper =
        InnerCanvas.hidePaper.value || InnerCanvas.exportWithoutPaper;
    final Color backgroundColor = page.isBoard || noPaper
        ? Colors.transparent
        : page.backgroundColor ??
              widget.coreInfo.backgroundColor ??
              InnerCanvas.defaultBackgroundColor;
    final invert = InnerCanvas.invertsInk(page, widget.coreInfo, brightness);

    // A text editor only for pages with typed text, or while typing: building
    // one for every page that came into view was much of the cost of
    // scrolling.
    final typed = page.quill;
    final noteLineHeight = widget.coreInfo.lineHeight;
    final quillEditor =
        widget.showTypedText &&
            (widget.textEditing || !typed.controller.document.isEmpty())
        ? QuillEditor(
            controller: typed.controller,
            focusNode: typed.focusNode,
            scrollController: _quillScrollController,
            config: QuillEditorConfig(
              customStyles: BadNotesQuillStyles.get(
                invert: invert,
                secondary: colorScheme.secondary,
                lineHeight: noteLineHeight,
              ),
              // the text fills the page and moves with it, never on its own
              expands: true,
              scrollable: false,
              autoFocus: false,
              showCursor: true,
              showCodeBlockLineNumbers: false,
              keyboardAppearance: invert ? .dark : .light,
              // room above the first line, as on ruled paper
              padding: EdgeInsets.fromLTRB(
                noteLineHeight * 0.5,
                noteLineHeight * 1.2,
                noteLineHeight * 0.5,
                noteLineHeight * 0.5,
              ),
            ),
          )
        : null;

    // A pdf or picture background brings its own look: plain white under
    // it, and no ruling. A whiteboard's ruling is drawn behind the page.
    final hasBackgroundImage = page.backgroundImage != null;
    final Color paperColor = noPaper
        ? Colors.transparent
        : hasBackgroundImage
        ? Colors.white
        : backgroundColor;
    final CanvasBackgroundPattern ruling =
        noPaper || hasBackgroundImage || page.isBoard
        ? .none
        : page.backgroundPattern ?? widget.coreInfo.backgroundPattern;

    Widget image(EditorImage image) => CanvasImage(
      filePath: widget.coreInfo.filePath,
      image: image,
      pageSize: Size(widget.width, widget.height),
      setAsBackground: widget.setAsBackground,
      readOnly: widget.coreInfo.readOnly || !widget.currentToolIsSelect,
      selected: widget.currentSelection?.images.contains(image) ?? false,
    );

    final severalLayers = page.hasSeveralLayers;
    // the pictures and text boxes over the writing of the first layer, in
    // the order put on: the writing goes between them in that order
    bool onFirstLayer(EditorImage img) =>
        page.isLayerVisible(img.layer) &&
        (!severalLayers ||
            page.drawnOnLayer(img.layer) == page.layers.first.id);
    final front = EditorPage.inOrder(
      page.images.where(
        (img) => img.inFront && !img.onTape && onFirstLayer(img),
      ),
    );
    // one image cache for each gap; ones no longer needed let go of
    for (final tier in [..._tierCaches.keys]) {
      if (tier > front.length) _tierCaches.remove(tier)!.dispose();
    }
    final caches = [
      for (int t = 0; t <= max(1, front.length); t++) _cacheOf(t),
    ];
    // also when an image put off to the next frame can be drawn
    for (final cache in caches) {
      cache.follow(page.visibleArea);
    }
    final inkRepaint = Listenable.merge([
      widget.redrawPageListenable,
      for (final cache in caches) cache.retry,
      // zoomed in far, the part on screen moved off the image of it
      for (final cache in caches) cache.viewMoved,
      // the tiles for a zoom are made once it stops changing
      InkCache.zoomStopped,
      // drawn from an image again once the eraser lifts
      InkCache.erasing,
      // sharp again once a zoom stops, see [InkCache.images]
      InkCache.moving,
      // pieces the eraser cut, drawn properly once their outlines are ready
      outlinesReady,
    ]);
    CanvasPainter inkPainter({
      required int? onlyLayer,
      required bool overlays,
      bool ink = true,
      bool? onFront,
      int? tier,
    }) => CanvasPainter(
      repaint: inkRepaint,
      invert: invert,
      strokes: page.strokes,
      laserStrokes: page.laserStrokes,
      currentStroke: widget.currentStroke,
      currentSelection: widget.currentSelection,
      primaryColor: colorScheme.primary,
      page: page,
      showPageIndicator: widget.showPageIndicator,
      pageIndex: widget.pageIndex,
      totalPages: widget.coreInfo.pages.length,
      currentScale: widget.currentScale,
      defaultTextStyle: theme.textTheme.bodyMedium!,
      paintCurrentStroke: false,
      onlyLayer: onlyLayer,
      paintInk: ink,
      paintOverlays: overlays,
      inkCache: tier != null
          ? _cacheOf(tier)
          : onFront == true
          ? _frontInkCache
          : _inkCache,
      pixelScale: widget.pixelScale,
      onFrontImages: onFront,
      tier: tier,
      frontImages: front,
      topTier: tier == null || tier == front.length,
    );

    // Layers, bottom to top: background, images, typed text, ink,
    // the stroke being drawn. Ink always stays on top of pictures.
    // ClipRect: ink never spills outside the page
    return InkPixelScale(
      pixelScale: widget.pixelScale,
      invertsInk: invert,
      child: RepaintBoundary(
        child: ClipRect(
          child: DeferredPointerHandler(
            child: Stack(
              children: [
                CustomPaint(
                  painter: CanvasBackgroundPainter(
                    invert: invert,
                    backgroundColor: paperColor,
                    backgroundPattern: ruling,
                    lineHeight: page.lineHeight ?? noteLineHeight,
                    lineThickness: widget.coreInfo.lineThickness,
                    primaryColor: colorScheme.primary,
                    secondaryColor: colorScheme.secondary,
                  ),
                  foregroundPainter: inkPainter(
                    onlyLayer: severalLayers ? page.layers.first.id : null,
                    overlays: !severalLayers,
                    // under all the pictures put over the writing
                    tier: front.isEmpty ? null : 0,
                  ),
                  // the ink comes from [InkCache]'s images, so the picture rarely changes
                  isComplex: true,
                  child: SizedBox(
                    width: widget.width,
                    height: widget.height,
                    child: Stack(
                      children: [
                        if (hasBackgroundImage)
                          CanvasImage(
                            filePath: widget.coreInfo.filePath,
                            image: page.backgroundImage!,
                            pageSize: Size(widget.width, widget.height),
                            setAsBackground: null,
                            isBackground: true,
                            readOnly: true,
                          ),
                        for (final img in page.images)
                          if (!img.inFront &&
                              page.isLayerVisible(img.layer) &&
                              (!severalLayers ||
                                  page.drawnOnLayer(img.layer) ==
                                      page.layers.first.id))
                            image(img),
                        // typed text above the pictures, like the handwriting
                        Positioned(
                          top: 0,
                          left: 0,
                          width: widget.width,
                          height: widget.height,
                          child: IgnorePointer(
                            // a page without typed text gets text boxes where tapped
                            ignoring:
                                widget.coreInfo.readOnly ||
                                !widget.textEditing ||
                                typed.controller.document.isEmpty(),
                            child: quillEditor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // pictures and text boxes stuck on over the ink of the first
                // layer, each with the writing done after it over it, in the
                // order they were put on; tapes over all that
                for (final (i, img) in front.indexed) ...[
                  SizedBox(
                    width: widget.width,
                    height: widget.height,
                    child: Stack(children: [image(img)]),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        foregroundPainter: inkPainter(
                          onlyLayer: severalLayers
                              ? page.layers.first.id
                              : null,
                          overlays: false,
                          tier: i + 1,
                        ),
                      ),
                    ),
                  ),
                ],
                // text boxes and pictures put on a tape: on it, and hidden
                // while the tape is peeked under
                if (page.images.any((img) => img.inFront && img.onTape))
                  SizedBox(
                    width: widget.width,
                    height: widget.height,
                    child: ListenableBuilder(
                      listenable: widget.redrawPageListenable ?? page,
                      builder: (context, _) => Stack(
                        children: [
                          for (final img in page.images)
                            if (img.inFront &&
                                img.onTape &&
                                page.isLayerVisible(img.layer) &&
                                (!severalLayers ||
                                    page.drawnOnLayer(img.layer) ==
                                        page.layers.first.id) &&
                                // a Positioned can't sit in an Offstage: left
                                // out while peeked under
                                !page.isUnderPeek(img))
                              image(img),
                        ],
                      ),
                    ),
                  ),
                // Each layer above the first: its images, then its ink over them.
                if (severalLayers) ...[
                  for (final layer in page.layers.skip(1))
                    if (layer.visible) ...[
                      if (page.images.any((img) => img.layer == layer.id))
                        SizedBox(
                          width: widget.width,
                          height: widget.height,
                          child: Stack(
                            children: [
                              for (final img in page.images)
                                if (img.layer == layer.id && !img.inFront)
                                  image(img),
                            ],
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            foregroundPainter: inkPainter(
                              onlyLayer: layer.id,
                              overlays: false,
                            ),
                          ),
                        ),
                      ),
                      if (page.images.any(
                        (img) => img.layer == layer.id && img.inFront,
                      ))
                        SizedBox(
                          width: widget.width,
                          height: widget.height,
                          child: Stack(
                            children: [
                              for (final img in page.images)
                                if (img.layer == layer.id && img.inFront)
                                  image(img),
                            ],
                          ),
                        ),
                    ],
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        foregroundPainter: inkPainter(
                          onlyLayer: null,
                          ink: false,
                          overlays: true,
                        ),
                      ),
                    ),
                  ),
                ],
                // the selection on a layer of its own, its edge moving
                if (widget.currentSelection != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: SelectionPainter(
                            repaint: Listenable.merge([
                              page,
                              page.currentStrokeTick,
                            ]),
                            ants: _ants,
                            currentSelection: widget.currentSelection,
                            invert: invert,
                            primaryColor: colorScheme.primary,
                            page: page,
                            currentScale: widget.currentScale,
                            defaultTextStyle: theme.textTheme.bodyMedium!,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: CurrentStrokePainter(
                          repaint: Listenable.merge([
                            page,
                            page.currentStrokeTick,
                          ]),
                          invert: invert,
                          primaryColor: colorScheme.primary,
                          page: page,
                          currentScale: widget.currentScale,
                          pixelScale: widget.pixelScale,
                          defaultTextStyle: theme.textTheme.bodyMedium!,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
