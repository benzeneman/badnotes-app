import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/data/lag_recorder.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:keybinder/keybinder.dart';
import 'package:badnotes/components/canvas/hud/canvas_hud.dart';
import 'package:badnotes/components/canvas/_ink_cache.dart';
import 'package:badnotes/components/canvas/finger_taps.dart';
import 'package:badnotes/components/canvas/interactive_canvas.dart';
import 'package:badnotes/components/canvas/palm_rejection.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/extensions/change_notifier_extensions.dart';
import 'package:badnotes/data/extensions/matrix4_extensions.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:vector_math/vector_math_64.dart';

/// The scrolling, zooming surface a note's pages sit on.
///
/// It watches every pointer (for pen pressure, the pen's side button, palm
/// rejection and finger taps), hands drawing strokes on to the editor and
/// lets everything else move the view. It also owns the zoom and pan locks,
/// the keyboard zoom and arrow-key panning, and the pull past either end of
/// the note that adds a page.
class CanvasGestureDetector extends StatefulWidget {
  new({
    super.key,
    required this.filePath,
    required this.isDrawGesture,
    this.onInteractionEnd,
    required this.onDrawStart,
    required this.onDrawUpdate,
    required this.onDrawEnd,
    required this.updatePointerData,
    required this.onHovering,
    this.onTwoFingerTap,
    this.onThreeFingerTap,
    required this.onHoveringEnd,
    required this.onStylusButtonChanged,
    required this.undo,
    required this.redo,
    required this.pages,
    required this.initialPageIndex,
    required this.pageBuilder,
    required this.placeholderPageBuilder,
    required this.isTextEditing,
    this.onPullPastLastPage,
    this.onPullPastFirstPage,
    this.scrollWithFinger = false,
    this.board = false,
    TransformationController? transformationController,
  }) : _transformationController =
           transformationController ?? TransformationController();

  /// The note on show. Empty until the note has loaded; also the key its
  /// last view is remembered under ([CanvasTransformCache]).
  final String filePath;

  /// Decides, as a gesture begins, whether it draws or moves the view.
  final bool Function(ScaleStartDetails scaleDetails) isDrawGesture;

  /// Told when a move or zoom of the view ends.
  final ValueChanged<ScaleEndDetails>? onInteractionEnd;

  /// The three stages of a stroke that [isDrawGesture] claimed.
  final ValueChanged<ScaleStartDetails> onDrawStart;
  final ValueChanged<ScaleUpdateDetails> onDrawUpdate;
  final ValueChanged<ScaleEndDetails> onDrawEnd;

  /// Gets the kind of every pointer that goes down or moves, with how hard a
  /// pen presses as a share from 0 to 1, or null when it can't tell.
  final void Function(PointerDeviceKind kind, double? pressure)
  updatePointerData;

  /// A pen is held just above the screen.
  final VoidCallback onHovering;

  /// A quick tap with two fingers, for undo.
  final VoidCallback? onTwoFingerTap;

  /// A quick tap with three fingers, for redo.
  final VoidCallback? onThreeFingerTap;

  /// The pen has touched down, or gone out of range, after hovering.
  final VoidCallback onHoveringEnd;

  /// The pen's side button (or its eraser end) was pressed or let go.
  final ValueChanged<bool> onStylusButtonChanged;

  final VoidCallback undo;
  final VoidCallback redo;

  final List<EditorPage> pages;

  /// The page to open the note at, when there's no remembered view for it.
  final int? initialPageIndex;

  /// Builds a page that is on screen or close to it.
  final Widget Function(BuildContext context, int pageIndex) pageBuilder;

  /// Builds the cheap stand-in for a page far out of view.
  final Widget Function(BuildContext context, int pageIndex)
  placeholderPageBuilder;

  /// While text is being typed the arrow keys move the caret, not the view.
  final bool Function() isTextEditing;

  /// Called when the user pulls up past the end of the note far enough
  /// and lets go (GoodNotes-style).
  ///
  /// Completes with whether a page was added.
  final Future<bool> Function()? onPullPastLastPage;

  /// The same above the first page. That page is then already in view, since
  /// the note's top doesn't move.
  final VoidCallback? onPullPastFirstPage;

  /// A finger scrolls even with single-finger panning locked. That lock is for
  /// writing with a finger, so it has no use when nothing can be written.
  final bool scrollWithFinger;

  /// The one page is a whiteboard's sheet: shown at its real size, moving
  /// freely in every direction, with nothing but its own edges to stop it.
  final bool board;

  /// The view with the whole of a page in the middle of a [viewport].
  static Matrix4 fitPage({
    required int pageIndex,
    required List<EditorPage> pages,
    required Size viewport,
  }) {
    final page = pages[pageIndex];
    final width = min(page.size.width, viewport.width);
    final height = page.size.height * width / page.size.width;
    final scale = min(viewport.width / width, viewport.height / height);
    final top = getTopOfPage(
      pageIndex: pageIndex,
      pages: pages,
      screenWidth: viewport.width,
    );
    final sideways = horizontal ? top * scale : 0.0;
    final down = horizontal ? 0.0 : top * scale;
    return Matrix4.translationValues(
      (viewport.width - width * scale) / 2 - sideways,
      (viewport.height - height * scale) / 2 - down,
      0,
    )..scaleByDouble(scale, scale, scale, 1);
  }

  /// How far a whiteboard zooms out.
  static const _boardMinScale = 0.1;

  late final TransformationController _transformationController;

  @override
  State<CanvasGestureDetector> createState() => CanvasGestureDetectorState();

  /// The furthest out and in a note can be zoomed.
  static const kMinScale = 0.3;
  static const kMaxScale = 10.0;

  /// Whether pages are side by side and scroll sideways.
  static bool get horizontal => stows.editorHorizontalScroll.value;

  /// Whether the note open shows two pages to a row (set by the editor,
  /// from [stows.twoPagesNotes]).
  static var twoPages = false;

  /// Whether pages show two to a row, like a book: when it's on for this
  /// note, the pages scroll down and the screen is wide enough.
  static bool spread(double screenWidth) =>
      twoPages && !horizontal && screenWidth >= 900;

  /// How wide each page's place is in a row of two.
  static double spreadCell(double screenWidth) =>
      (screenWidth - Editor.gapBetweenPages) / 2;

  /// The height of the row of two pages starting at [first], fitted.
  static double _rowHeight(List<EditorPage> pages, int first, double cell) {
    double height = 0;
    for (int i = first; i < first + 2 && i < pages.length; i++) {
      final size = pages[i].size;
      final width = min(size.width, cell);
      height = max(height, size.height * width / size.width);
    }
    return height;
  }

  /// Where the page starts along the scroll direction: its top, or its left
  /// side when [horizontal].
  static double getTopOfPage({
    required int pageIndex,
    required List<EditorPage> pages,
    required double screenWidth,
  }) {
    if (pageIndex <= 0) return 0;

    double top = 0;

    if (spread(screenWidth)) {
      final cell = spreadCell(screenWidth);
      // the rows before the one this page is in
      for (int i = 0; i < pageIndex - pageIndex % 2; i += 2) {
        top += 16 + _rowHeight(pages, i, cell);
      }
      return top;
    }

    final sideways = horizontal;
    final before = min(pageIndex, pages.length);
    for (var i = 0; i < before; i++) {
      final size = pages[i].size;
      // a page shrinks to fit the screen's width but never grows past its own
      final shownWidth = min(size.width, screenWidth);
      top += 16;
      top += sideways ? shownWidth : size.height * (shownWidth / size.width);
    }
    return top;
  }

  /// Moves the view, at 100%, to the start of page [pageIndex].
  ///
  /// With [glide] (a page picked from a list, a search result) the view
  /// glides there and keeps its zoom: it jumped, and came back at 100%.
  static void scrollToPage({
    required int pageIndex,
    required List<EditorPage> pages,
    required double screenWidth,
    required TransformationController transformationController,
    bool glide = false,
  }) {
    final offset = -getTopOfPage(
      pageIndex: pageIndex,
      pages: pages,
      screenWidth: screenWidth,
    );
    if (!glide) {
      transformationController.value = horizontal
          ? Matrix4.translationValues(offset, 0, 0)
          // 50 px of the page before shows above it, so it isn't jammed
          // against the top of the screen
          : Matrix4.translationValues(0, offset + 50, 0);
      return;
    }
    final now = transformationController.value;
    final scale = now.approxScale;
    final at = now.getTranslation();
    glideTo(
      transformationController,
      horizontal
          ? _view(offset * scale, at.y, scale)
          : _view(at.x, offset * scale + 50, scale),
    );
  }

  /// A view moved by [x], [y] on screen and zoomed to [scale].
  static Matrix4 _view(double x, double y, double scale) =>
      Matrix4.translationValues(x, y, 0)..scaleByDouble(scale, scale, 1, 1);

  /// Which [glideTo] is running: a newer one stops the one before.
  static var _glideRun = 0;

  /// Moves [controller] to [to] over [BnMotion.normal], frame by frame. It
  /// stops as soon as anything else moves the view (a finger, a newer
  /// glide), and is a jump with the system's reduce motion on. Far away,
  /// it jumps to near the place first: gliding past dozens of pages drew
  /// each of them on the way.
  static void glideTo(TransformationController controller, Matrix4 to) {
    final run = ++_glideRun;
    final reduced = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduced) {
      controller.value = to;
      return;
    }
    final from = controller.value;
    final f = from.getTranslation(), t = to.getTranslation();
    const reach = 1200.0;
    final fx = t.x + (f.x - t.x).clamp(-reach, reach);
    final fy = t.y + (f.y - t.y).clamp(-reach, reach);
    final s0 = from.approxScale, s1 = to.approxScale;
    Duration? start;
    // a finger before the first frame stops it too
    Matrix4? last = from;
    void frame(Duration time) {
      if (run != _glideRun) return;
      if (last != null && controller.value != last) return;
      start ??= time;
      final x =
          ((time - start!).inMicroseconds / BnMotion.normal.inMicroseconds)
              .clamp(0.0, 1.0);
      final k = BnMotion.curve.transform(x);
      controller.value = last = _view(
        fx + (t.x - fx) * k,
        fy + (t.y - fy) * k,
        s0 + (s1 - s0) * k,
      );
      if (x < 1) SchedulerBinding.instance.scheduleFrameCallback(frame);
    }

    SchedulerBinding.instance.scheduleFrameCallback(frame);
  }

  /// The page at [scrollY] down the note, in unzoomed note units: the last
  /// page when it's past the end.
  static int getPageIndex({
    required double scrollY,
    required List<EditorPage> pages,
    required double screenWidth,
  }) {
    if (scrollY <= 0) return 0;

    double top = 0;

    if (spread(screenWidth)) {
      final cell = spreadCell(screenWidth);
      for (int i = 0; i < pages.length; i += 2) {
        top += 16 + _rowHeight(pages, i, cell);
        if (top > scrollY) return i;
      }
      return pages.length - 1;
    }

    for (var i = 0; i < pages.length; i++) {
      final size = pages[i].size;
      final shownWidth = min(size.width, screenWidth);
      top += 16;
      top += size.height * (shownWidth / size.width);
      // the gap above a page counts as part of it
      if (top > scrollY) return i;
    }
    return pages.length - 1;
  }
}

class CanvasGestureDetectorState extends State<CanvasGestureDetector>
    with TickerProviderStateMixin {
  /// The space the pages are shown in, from the last layout.
  late var containerBounds = const BoxConstraints();

  /// The zoom the view is held at, or null when zooming is free.
  late double? zoomLockedValue = stows.lastZoomLock.value
      ? widget._transformationController.value.approxScale
      : null;

  /// When true, one finger can't move the view (two always can). Starts off
  /// every time: the setting for it is no longer in the app.
  late bool singleFingerPanLock = false;

  /// When true, a drag moves the view straight across or straight down,
  /// never at a slant.
  late bool axisAlignedPanLock = stows.lastAxisAlignedPanLock.value;

  /// Holds the zoom at [scale], or lets it go with null.
  void holdZoom(double? scale) => setState(() => zoomLockedValue = scale);

  /// A finger can't scroll while single-finger panning is locked.
  void unlockSingleFingerPan() {
    if (!singleFingerPanLock) return;
    setState(() => singleFingerPanLock = false);
    stows.lastSingleFingerPanLock.value = false;
  }

  /// Ctrl and + (or =): one step closer.
  void zoomIn() => _zoomBy(0.1);

  /// Ctrl and -: one step further out.
  void zoomOut() => _zoomBy(-0.1);

  /// Zooms about the middle of the view by [step], unless that would go past
  /// [CanvasGestureDetector.kMinScale] or [CanvasGestureDetector.kMaxScale].
  void _zoomBy(double step) {
    // the zoom is locked: a pinch went back to it right after
    if (zoomLockedValue != null) return;
    final controller = widget._transformationController;
    final zoomed = setZoom(
      scaleDelta: step,
      transformation: controller.value,
      containerBounds: containerBounds,
    );
    if (zoomed != null) controller.value = zoomed;
  }

  /// The view [transformation] zoomed by [scaleDelta] while the point
  /// [around] (the middle of [containerBounds] if not given) stays where it
  /// is on screen. Null when the new zoom would be out of range.
  @visibleForTesting
  static Matrix4? setZoom({
    required double scaleDelta,
    required Matrix4 transformation,
    required BoxConstraints containerBounds,
    Offset? around,
  }) {
    final from = transformation.approxScale;
    final to = from + scaleDelta;
    if (to < CanvasGestureDetector.kMinScale ||
        to > CanvasGestureDetector.kMaxScale) {
      return null;
    }

    final pivot = Vector3(
      around?.dx ?? containerBounds.maxWidth / 2,
      around?.dy ?? containerBounds.maxHeight / 2,
      0,
    );
    // every point moves away from (or toward) the pivot by the zoom's ratio
    final shifted = (transformation.getTranslation() - pivot) * (to / from);
    return Matrix4.translation(shifted + pivot)..scaleByDouble(to, to, to, 1);
  }

  /// How far one arrow-key step moves the view, in screen pixels.
  static const _keyPanStep = 50.0;

  /// A held arrow key moves once at once, then again after this...
  static const _keyRepeatDelay = Duration(milliseconds: 200);

  /// ...and then at this pace until it's let go.
  static const _keyRepeatEvery = Duration(milliseconds: 100);

  /// The timer of each arrow key being held.
  final _heldArrowKeys = <AxisDirection, Timer>{};

  /// An arrow key in [direction] went down ([pressed]) or up.
  void arrowKeyPan(AxisDirection direction, bool pressed) {
    _heldArrowKeys.remove(direction)?.cancel();
    if (!pressed || widget.isTextEditing()) return;

    _panOneStep(direction);
    _heldArrowKeys[direction] = Timer(_keyRepeatDelay, () {
      _heldArrowKeys[direction] = Timer.periodic(
        _keyRepeatEvery,
        (_) => _panOneStep(direction),
      );
    });
  }

  void _panOneStep(AxisDirection direction) {
    final controller = widget._transformationController;
    final (dx, dy) = switch (direction) {
      .left => (_keyPanStep, 0.0),
      .right => (-_keyPanStep, 0.0),
      .up => (0.0, _keyPanStep),
      .down => (0.0, -_keyPanStep),
    };
    controller.value.leftTranslateByDouble(dx, dy, 0, 1);
    controller.notifyListenersPlease();
  }

  /// The key combinations bound in [_bindKeys], to let go of in
  /// [_unbindKeys].
  final _boundKeys = <Keybinding>[];

  void _bindKey(List<KeyCode> keys, Function onPress) {
    final binding = Keybinding(keys, inclusive: true);
    Keybinder.bind(binding, onPress);
    _boundKeys.add(binding);
  }

  void _bindKeys() {
    _bindKey([KeyCode.ctrl, KeyCode.from(LogicalKeyboardKey.add)], zoomIn);
    _bindKey([KeyCode.ctrl, KeyCode.from(LogicalKeyboardKey.equal)], zoomIn);
    _bindKey([KeyCode.ctrl, KeyCode.from(LogicalKeyboardKey.minus)], zoomOut);

    const arrows = {
      AxisDirection.left: LogicalKeyboardKey.arrowLeft,
      AxisDirection.right: LogicalKeyboardKey.arrowRight,
      AxisDirection.up: LogicalKeyboardKey.arrowUp,
      AxisDirection.down: LogicalKeyboardKey.arrowDown,
    };
    for (final MapEntry(key: direction, value: key) in arrows.entries) {
      _bindKey([
        KeyCode.from(key),
      ], (bool pressed) => arrowKeyPan(direction, pressed));
    }
  }

  void _unbindKeys() {
    for (final binding in _boundKeys) {
      Keybinder.remove(binding);
    }
    _boundKeys.clear();
    for (final timer in _heldArrowKeys.values) {
      timer.cancel();
    }
  }

  @override
  void initState() {
    // placed before listening, so opening at a page isn't "corrected"
    setInitialTransform();
    widget._transformationController.addListener(onTransformChanged);
    _bindKeys();
    _overscroll.addListener(_onOverscrollChanged);
    _topOverscroll.addListener(_onOverscrollChanged);
    _springBack.addListener(() {
      _springing.value =
          _springFrom * (1 - Curves.easeOutCubic.transform(_springBack.value));
    });
    _scrollToNewPage.addListener(() {
      final start = _scrollStart;
      if (start == null) return;
      final t = Curves.easeInOutCubic.transform(_scrollToNewPage.value);
      final tr = start.getTranslation();
      widget._transformationController.value = start.clone()
        ..setTranslationRaw(
          CanvasGestureDetector.horizontal ? tr.x - _scrollBy * t : tr.x,
          CanvasGestureDetector.horizontal ? tr.y : tr.y - _scrollBy * t,
          tr.z,
        );
    });
    super.initState();
  }

  /// The first build comes before the note has loaded (no path yet), so the
  /// opening view is set once it arrives, or when another note is opened.
  @override
  void didUpdateWidget(CanvasGestureDetector oldWidget) {
    _pageCache.clear(); // the editor rebuilt: pages may have changed
    if (oldWidget.initialPageIndex != widget.initialPageIndex ||
        oldWidget.filePath != widget.filePath) {
      setInitialTransform();
    }
    super.didUpdateWidget(oldWidget);
  }

  /// Opens the note where it was left: at the view it had when it was last
  /// closed in this run of the app, or else at [initialPageIndex]. Does
  /// nothing before the note has loaded or once the view has been moved.
  void setInitialTransform() {
    final controller = widget._transformationController;
    if (widget.filePath.isEmpty || !controller.value.isIdentity()) return;

    final remembered = CanvasTransformCache.get(widget.filePath)?.transform;
    if (remembered != null) {
      controller.value = remembered;
      // a held zoom follows the remembered view's zoom
      if (zoomLockedValue != null) zoomLockedValue = remembered.approxScale;
      return;
    }

    final page = widget.initialPageIndex;
    if (page == null || widget.board) return;
    CanvasGestureDetector.scrollToPage(
      pageIndex: page,
      pages: widget.pages,
      screenWidth: MediaQuery.sizeOf(context).width,
      transformationController: controller,
    );
  }

  Timer? _snapZoomTimer;

  /// The zoom on the last change, to tell zooming from scrolling.
  double? _lastScale;

  /// Moves the pages back into view after a pinch, see [_settle].
  late final _settleAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );
  var _settling = false;

  /// Corrects the transform if it's out of bounds: a page narrower than the
  /// screen is kept in the middle, a wider one can't be scrolled past its
  /// edges. Not while two fingers zoom: the page follows them then, and is
  /// moved into view smoothly when they lift ([_settle]).
  void onTransformChanged() {
    InkCache.markMoving();
    final zoom = widget._transformationController.value.approxScale;
    if (zoom != _lastScale) {
      _lastScale = zoom;
      InkCache.markZooming();
    }
    _sharpenAfterZoom(widget._transformationController.value.approxScale);
    if (widget.board) return;
    // A snap to 100% still due from the start of a pinch (passing near 100%
    // before the fingers had zoomed far enough to count as zooming) went off
    // mid-pinch: the zoom jumped back to 100%, then to the fingers' zoom on
    // their next move, 100% -> 200% -> 100% -> 250%. The fingers have it.
    _snapZoomTimer?.cancel();
    if (InteractiveCanvasViewer.pinching || _settling) return;
    final scale = widget._transformationController.value.approxScale;

    // a zoom that ends up just off 100% goes to exactly 100% a moment later;
    // within 0.001 of it is rounding, not a real difference
    final diffFrom1 = (scale - 1).abs();
    if (zoomLockedValue == null && diffFrom1 < 0.03 && diffFrom1 > 0.001) {
      _snapZoomTimer = Timer(const Duration(milliseconds: 200), () {
        if (!InteractiveCanvasViewer.fingersDown) resetZoom();
      });
    }

    final (adjustmentX, adjustmentY) = _intoView(
      widget._transformationController.value,
    );
    if (adjustmentX.abs() > 0.1 || adjustmentY.abs() > 0.1) {
      widget._transformationController.value.leftTranslateByDouble(
        adjustmentX,
        adjustmentY,
        0,
        1,
      );
    }
  }

  /// How far to move the pages, transformed by [transformation], so they're
  /// in view.
  (double, double) _intoView(Matrix4 transformation) {
    final scale = transformation.approxScale;
    final translation = transformation.getTranslation();
    final width = containerBounds.maxWidth;

    if (CanvasGestureDetector.horizontal) {
      final length = CanvasGestureDetector.getTopOfPage(
        pageIndex: widget.pages.length,
        pages: widget.pages,
        screenWidth: width,
      );
      final height = widget.pages.fold(0.0, (tallest, page) {
        final fitted = min(page.size.width, width);
        return max(tallest, page.size.height * fitted / page.size.width);
      });
      // the row of pages has a gap at each end as well
      return (
        _keepInView(
          translation.x,
          (length + Editor.gapBetweenPages * 3) * scale,
          width,
        ),
        _keepInView(translation.y, height * scale, containerBounds.maxHeight),
      );
    }

    // The pages are in the middle of a column as wide as the screen, and
    // can be narrower than it (a tablet held sideways): it's their edges that
    // are kept at the screen's edges, not the column's. The column's, and
    // zoomed in at a side there was a dark band beside the page.
    final pagesWidth = widget.pages.fold(
      0.0,
      (widest, page) => max(widest, min(page.size.width, width)),
    );
    final margin = (width - (pagesWidth > 0 ? pagesWidth : width)) / 2;
    final shown = (pagesWidth > 0 ? pagesWidth : width) * scale;
    final x = _keepInView(translation.x + margin * scale, shown, width);
    // zoomed in, not past the top of the first page
    final y = scale >= 1 && translation.y > 0 ? -translation.y : 0.0;
    return (x, y);
  }

  /// After a pinch: snaps to 100% if near it, and moves the pages into view
  /// over a moment instead of all at once.
  void _settle() {
    if (widget.board || !mounted) return;
    final controller = widget._transformationController;
    final scale = controller.value.approxScale;
    final diffFrom1 = (scale - 1).abs();
    if (zoomLockedValue == null && diffFrom1 < 0.03 && diffFrom1 > 0.001) {
      _settling = true;
      resetZoom();
      _settling = false;
    }
    final (dx, dy) = _intoView(controller.value);
    if (dx.abs() <= 0.5 && dy.abs() <= 0.5) return;
    _settling = true;
    _settleAnimation
      ..stop()
      ..value = 0;
    // moved a step at a time, so a finger scrolling meanwhile moves them too
    var done = 0.0;
    void step() {
      if (InteractiveCanvasViewer.pinching) {
        // zooming again: the fingers have it
        _settleAnimation.stop();
        return;
      }
      final t = Curves.easeOutCubic.transform(_settleAnimation.value);
      final part = t - done;
      done = t;
      controller.value = controller.value.clone()
        ..leftTranslateByDouble(dx * part, dy * part, 0, 1);
    }

    _settleAnimation.addListener(step);
    final run = _settleAnimation.forward();
    run.whenCompleteOrCancel(() {
      _settleAnimation.removeListener(step);
      _settling = false;
    });
    run.then((_) {
      if (mounted) onTransformChanged();
    });
  }

  /// How far to move content of size [content] at [position] so it stays in a
  /// viewport of size [viewport]: centered if it fits, otherwise no gaps at
  /// the edges.
  static double _keepInView(double position, double content, double viewport) {
    if (content <= viewport) return (viewport - content) / 2 - position;
    if (position > 0) return -position;
    if (position < viewport - content) return viewport - content - position;
    return 0;
  }

  /// Zooms to exactly 100%, keeping still the spot the fingers last zoomed
  /// around (or else the middle of the view).
  void resetZoom() {
    final transformation = widget._transformationController.value;
    final scale = transformation.approxScale;
    if (scale == 1) return;

    widget._transformationController.value =
        setZoom(
          scaleDelta: 1 - scale,
          transformation: transformation,
          containerBounds: containerBounds,
          around: InteractiveCanvasViewer.lastZoomFocalPoint,
        ) ??
        transformation;
  }

  /// The zoom the cached pages were built at, see [_pageCache].
  double? _builtScale;
  Timer? _sharpenTimer;

  /// Builds the pages again for the zoom they're shown at, so the ink is
  /// drawn sharp: soon after zooming stops (by pinch, wheel, keys or the
  /// snap to 100%), or right away once zoomed in a good deal further.
  void _sharpenAfterZoom(double scale) {
    final built = _builtScale ??= scale;
    if ((scale - built).abs() < 0.001) return;
    void sharpen() {
      if (!mounted) return;
      _builtScale = widget._transformationController.value.approxScale;
      if (_pageCache.isNotEmpty) setState(_pageCache.clear);
    }

    _sharpenTimer?.cancel();
    if (scale / built > 1.35) return sharpen();
    _sharpenTimer = Timer(const Duration(milliseconds: 140), sharpen);
  }

  late final _fingerTaps = FingerTaps(
    onTwoFingerTap: () => widget.onTwoFingerTap?.call(),
    onThreeFingerTap: () => widget.onThreeFingerTap?.call(),
  );

  void _listenerPointerEvent(PointerEvent event) {
    PointerPressureLog.see(event);
    PalmRejection.track(event);
    // a resting palm mustn't take over the pen's pressure or pointer kind
    if (PalmRejection.rejects(event)) {
      PalmRejection.noteIgnored(event);
      _fingerTaps.ignore(event);
      return;
    }
    // after the palm check: a palm's touches aren't a two-finger undo
    _fingerTaps.handle(event);
    final isStylus = PalmRejection.isStylus(event);
    if (isStylus && event is PointerDownEvent) {
      _detectStylusButton(event);
    }

    // Some pens (a tablet's own active pen) come in as touch, not stylus,
    // with real pressure: taken from any pointer that has a pressure range,
    // or the pressure sensitivity did nothing with them. A pointer whose
    // range is a single value reports no pressure at all.
    final double? pressure =
        (isStylus || event.kind == PointerDeviceKind.touch) &&
            event.pressureMin != event.pressureMax
        ? _shareOfRange(event.pressure, event.pressureMin, event.pressureMax)
        : null;
    widget.updatePointerData(event.kind, pressure);

    if (isStylus &&
        event is PointerDownEvent &&
        stows.editorFingerDrawing.value &&
        stows.autoDisableFingerDrawingWhenStylusDetected.value &&
        // left alone when the finger-drawing choice is fixed in settings
        !stows.hideFingerDrawingToggle.value) {
      stows.editorFingerDrawing.value = false;
    }
  }

  /// Whether the pen's button was down at the last event that said.
  var stylusButtonWasPressed = false;

  void _listenerPointerHoverEvent(PointerEvent event) {
    PalmRejection.track(event);
    if (event.kind != .stylus && event.kind != .invertedStylus) return;

    // Flutter makes up a hover event of its own when the pen touches down:
    // that one marks the end of hovering
    if (event.synthesized) {
      widget.onHoveringEnd();
    } else {
      widget.onHovering();
    }

    _detectStylusButton(event);
  }

  /// Tells [CanvasGestureDetector.onStylusButtonChanged] when the pen's
  /// side button, or its eraser end, changes. Only changes are passed on.
  void _detectStylusButton(PointerEvent event) {
    final isDown =
        event.buttons == kSecondaryButton || event.kind == .invertedStylus;
    if (stylusButtonWasPressed == isDown) return;
    stylusButtonWasPressed = isDown;
    widget.onStylusButtonChanged(isDown);
  }

  void _listenerPointerUpEvent(PointerEvent event) {
    PalmRejection.track(event);
    if (PalmRejection.rejects(event)) return _fingerTaps.ignore(event);
    _fingerTaps.handle(event);
    widget.updatePointerData(event.kind, null);
    if (stylusButtonWasPressed) {
      stylusButtonWasPressed = false;
      widget.onStylusButtonChanged(false);
    }
  }

  /// Page widgets reused while panning/zooming. The viewer rebuilds its
  /// children on every transform frame; rebuilding every visible page
  /// (painters, text editor, images) each frame is what made zoom lag.
  /// Cleared when the editor rebuilds and once a gesture ends.
  final _pageCache = <int, Widget>{};

  /// Finger travel needed past the bottom before releasing adds a page.
  static const _pullThreshold = 180.0;

  /// How long to stay past [_pullThreshold] before releasing adds a page.
  static const _pullHold = Duration(milliseconds: 500);

  /// Screen pixels dragged past the bottom of the note.
  final _overscroll = ValueNotifier<double>(0);

  /// Screen pixels dragged past the top of the note.
  final _topOverscroll = ValueNotifier<double>(0);

  /// Whichever of the two is springing back.
  late var _springing = _overscroll;

  double get _pulled => max(_overscroll.value, _topOverscroll.value);

  /// Whether releasing now adds a page. A page is only ever added while this
  /// is true, so "Release to add page" has always been on screen first.
  final _pullReady = ValueNotifier<bool>(false);
  Timer? _pullHoldTimer;
  late final _pullState = Listenable.merge([
    _overscroll,
    _topOverscroll,
    _pullReady,
  ]);
  late final _springBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  double _springFrom = 0;
  late final _scrollToNewPage = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  Matrix4? _scrollStart;
  double _scrollBy = 0;

  /// Pages are fitted to the width, so a narrower view makes them shorter and
  /// the same scroll position lands elsewhere in the note. This stays at the
  /// same place in it, when a split view opens or the screen turns.
  void _keepPlaceWhenResized(double oldWidth, double newWidth) {
    if (widget.board) return;
    if (oldWidth == newWidth || !oldWidth.isFinite || !newWidth.isFinite)
      return;
    if (oldWidth <= 0 || newWidth <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      double lengthAt(double width) => CanvasGestureDetector.getTopOfPage(
        pageIndex: widget.pages.length,
        pages: widget.pages,
        screenWidth: width,
      );
      final oldLength = lengthAt(oldWidth);
      if (oldLength <= 0) return;
      final ratio = lengthAt(newWidth) / oldLength;
      final controller = widget._transformationController;
      final tr = controller.value.getTranslation();
      final horizontal = CanvasGestureDetector.horizontal;
      controller.value = controller.value.clone()
        ..setTranslationRaw(
          horizontal ? tr.x * ratio : tr.x,
          horizontal ? tr.y : tr.y * ratio,
          tr.z,
        );
    });
  }

  void _onOverscrollChanged() {
    if (_pulled < _pullThreshold || _springBack.isAnimating) {
      _pullHoldTimer?.cancel();
      _pullHoldTimer = null;
      _pullReady.value = false;
    } else if (!_pullReady.value && _pullHoldTimer == null) {
      _pullHoldTimer = Timer(_pullHold, () {
        _pullHoldTimer = null;
        _pullReady.value = true;
        HapticFeedback.selectionClick();
      });
    }
  }

  void _releaseOverscroll() {
    if (_pulled <= 0) return;
    if (_topOverscroll.value > 0) {
      if (_pullReady.value && widget.onPullPastFirstPage != null) {
        HapticFeedback.mediumImpact();
        widget.onPullPastFirstPage!();
      }
      _springing = _topOverscroll;
    } else if (_pullReady.value && widget.onPullPastLastPage != null) {
      HapticFeedback.mediumImpact();
      widget.onPullPastLastPage!().then((added) {
        if (!added || !mounted) return;
        // glide down to the new page once it is laid out
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final start = widget._transformationController.value.clone();
          final last = widget.pages.last;
          final fittedWidth = min(last.size.width, containerBounds.maxWidth);
          final newPageHeight =
              last.size.height *
              fittedWidth /
              last.size.width *
              start.approxScale;
          _scrollStart = start;
          _scrollBy = CanvasGestureDetector.horizontal
              ? (fittedWidth + Editor.gapBetweenPages) * start.approxScale
              : min(containerBounds.maxHeight * 0.75, newPageHeight);
          _scrollToNewPage.forward(from: 0);
        });
      });
    }
    if (_topOverscroll.value <= 0) _springing = _overscroll;
    _springFrom = _springing.value;
    _springBack.forward(from: 0);
  }

  void _stopPullAnimations() {
    // A spring stopped halfway would leave the pull nearly complete, and the
    // next small drag, or even a pen stroke ending, would add a page.
    if (_springBack.isAnimating) {
      _springBack.stop();
      _overscroll.value = 0;
      _topOverscroll.value = 0;
    }
    _scrollToNewPage.stop();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final horizontal = CanvasGestureDetector.horizontal;

    return Stack(
      children: [
        Listener(
          onPointerDown: (event) {
            _stopPullAnimations();
            _listenerPointerEvent(event);
          },
          onPointerMove: _listenerPointerEvent,
          onPointerUp: _listenerPointerUpEvent,
          onPointerHover: _listenerPointerHoverEvent,
          onPointerCancel: (event) {
            _fingerTaps.handle(event);
            PalmRejection.track(event);
          },
          child: GestureDetector(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints containerBounds) {
                _keepPlaceWhenResized(
                  this.containerBounds.maxWidth,
                  containerBounds.maxWidth,
                );
                this.containerBounds = containerBounds;

                return InteractiveCanvasViewer.builder(
                  minScale:
                      zoomLockedValue ??
                      (widget.board
                          ? CanvasGestureDetector._boardMinScale
                          : CanvasGestureDetector.kMinScale),
                  maxScale: zoomLockedValue ?? CanvasGestureDetector.kMaxScale,
                  panEnabled: widget.scrollWithFinger || !singleFingerPanLock,
                  // sideways, a page only moves along one direction at a time,
                  // instead of the whole row wobbling with the finger
                  panAxis: !widget.board && (axisAlignedPanLock || horizontal)
                      ? PanAxis.aligned
                      : PanAxis.free,

                  // a flick glides further than Flutter's default
                  interactionEndFrictionCoefficient: 0.1,

                  // room around the pages, or zoomed out below 100% they
                  // couldn't get smaller than the screen
                  boundaryMargin: .symmetric(
                    // onTransformChanged keeps pages in view when horizontal
                    vertical: widget.board
                        ? 0
                        : horizontal
                        ? screenSize.height * 2
                        : 0,
                    horizontal: widget.board ? 0 : screenSize.width * 2,
                  ),
                  unboundedWidth: horizontal || widget.board,

                  transformationController: widget._transformationController,

                  isDrawGesture: widget.isDrawGesture,
                  bottomOverscroll: widget.onPullPastLastPage == null
                      ? null
                      : _overscroll,
                  topOverscroll: widget.onPullPastFirstPage == null
                      ? null
                      : _topOverscroll,
                  onInteractionEnd: (details) {
                    widget.onInteractionEnd?.call(details);
                    _releaseOverscroll();
                    _settle();
                    // pick up the new zoom level once, not every frame
                    _builtScale =
                        widget._transformationController.value.approxScale;
                    if (_pageCache.isNotEmpty) setState(_pageCache.clear);
                  },
                  onDrawStart: widget.onDrawStart,
                  onDrawUpdate: widget.onDrawUpdate,
                  onDrawEnd: widget.onDrawEnd,

                  builder: (BuildContext context, Quad viewport) {
                    if (widget.board && widget.pages.isNotEmpty) {
                      final page = widget.pages.first;
                      page.isRendered = true;
                      final onScreen = _axisAlignedBoundingBox(viewport)
                          .intersect(Offset.zero & page.size);
                      page.visibleArea.value = onScreen.isEmpty
                          ? null
                          : onScreen;
                      return SizedBox.fromSize(
                        size: page.size,
                        child: _pageCache[0] ??= widget.pageBuilder(context, 0),
                      );
                    }
                    return _PagesBuilder(
                      pages: widget.pages,
                      pageBuilder: (context, i) =>
                          _pageCache[i] ??= widget.pageBuilder(context, i),
                      placeholderPageBuilder: widget.placeholderPageBuilder,
                      boundingBox: _axisAlignedBoundingBox(viewport),
                      containerWidth: containerBounds.maxWidth,
                    );
                  },
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: _pullState,
              builder: (context, _) {
                final pulled = _overscroll.value;
                if (pulled <= 0) return const SizedBox.shrink();
                final progress = (pulled / _pullThreshold).clamp(0.0, 1.0);
                return Padding(
                  // rises with the finger, with a bit of rubber-band resistance
                  padding: EdgeInsets.only(bottom: 8 + 40 * progress),
                  child: _AddPageFooter(
                    ready: _pullReady.value,
                    progress: progress,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: _pullState,
              builder: (context, _) {
                final pulled = _topOverscroll.value;
                if (pulled <= 0) return const SizedBox.shrink();
                final progress = (pulled / _pullThreshold).clamp(0.0, 1.0);
                return Padding(
                  padding: EdgeInsets.only(top: 8 + 40 * progress),
                  child: _AddPageFooter(
                    ready: _pullReady.value,
                    progress: progress,
                    atStart: true,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: CanvasHud(
            transformationController: widget._transformationController,
            zoomLock: zoomLockedValue != null,
            setZoomLock: _setZoomLock,
            resetZoom: zoomLockedValue == null ? resetZoom : null,
            singleFingerPanLock: singleFingerPanLock,
            setSingleFingerPanLock: _setSingleFingerPanLock,
            axisAlignedPanLock: axisAlignedPanLock,
            setAxisAlignedPanLock: _setAxisAlignedPanLock,
          ),
        ),
      ],
    );
  }

  /// The HUD's three lock switches; each choice is kept for next time.
  void _setZoomLock(bool locked) {
    setState(() {
      zoomLockedValue = locked
          ? widget._transformationController.value.approxScale
          : null;
      stows.lastZoomLock.value = locked;
    });
  }

  void _setSingleFingerPanLock(bool locked) => setState(() {
    singleFingerPanLock = locked;
    stows.lastSingleFingerPanLock.value = locked;
  });

  void _setAxisAlignedPanLock(bool locked) => setState(() {
    axisAlignedPanLock = locked;
    stows.lastAxisAlignedPanLock.value = locked;
  });

  @override
  void dispose() {
    _sharpenTimer?.cancel();
    CanvasTransformCache.add(
      widget.filePath,
      widget._transformationController.value,
    );
    widget._transformationController.removeListener(onTransformChanged);
    widget._transformationController.dispose();
    _springBack.dispose();
    _scrollToNewPage.dispose();
    _settleAnimation.dispose();
    _overscroll.dispose();
    _topOverscroll.dispose();
    _pullHoldTimer?.cancel();
    _pullReady.dispose();
    _unbindKeys();
    super.dispose();
  }

  /// The smallest upright rectangle around [quad]: the part of the note in
  /// view, which the viewer gives as four corners in case it's turned.
  static Rect _axisAlignedBoundingBox(Quad quad) {
    final a = quad.point0, b = quad.point1, c = quad.point2, d = quad.point3;
    return .fromLTRB(
      min(min(min(a.x, b.x), c.x), d.x),
      min(min(min(a.y, b.y), c.y), d.y),
      max(max(max(a.x, b.x), c.x), d.x),
      max(max(max(a.y, b.y), c.y), d.y),
    );
  }
}

/// The note's pages in a column (or a row, or rows of two), each built in
/// full only when it's on screen, near it, or being typed in.
class _PagesBuilder extends StatelessWidget {
  const new({
    required this.pages,
    required this.pageBuilder,
    required this.placeholderPageBuilder,
    required this.boundingBox,
    required this.containerWidth,
  });

  final List<EditorPage> pages;
  final Widget Function(BuildContext context, int pageIndex) pageBuilder;
  final Widget Function(BuildContext context, int pageIndex)
  placeholderPageBuilder;

  /// The part of the note in view, in its own units.
  final Rect boundingBox;
  final double containerWidth;

  @override
  Widget build(BuildContext context) {
    final horizontal = CanvasGestureDetector.horizontal;
    final List<Widget> children = [
      const SizedBox.square(dimension: Editor.gapBetweenPages),
      const SizedBox.square(dimension: Editor.gapBetweenPages),
    ];

    double topOfPage = Editor.gapBetweenPages * 2;

    // two to a row, like a book
    if (!horizontal && CanvasGestureDetector.spread(containerWidth)) {
      final cell = CanvasGestureDetector.spreadCell(containerWidth);
      for (int first = 0; first < pages.length; first += 2) {
        final rowHeight = CanvasGestureDetector._rowHeight(pages, first, cell);
        final bottom = topOfPage + rowHeight;
        final ahead = boundingBox.height;
        final inView =
            boundingBox.bottom + ahead >= topOfPage &&
            boundingBox.top - ahead <= bottom;
        final cells = <Widget>[];
        for (int side = 0; side < 2; side++) {
          final pageIndex = first + side;
          if (side == 1) {
            cells.add(const SizedBox(width: Editor.gapBetweenPages));
          }
          if (pageIndex >= pages.length) {
            cells.add(SizedBox(width: cell));
            continue;
          }
          final page = pages[pageIndex];
          final pageWidth = min(page.size.width, cell);
          final pageHeight = pageWidth / page.size.width * page.size.height;
          final left =
              side * (cell + Editor.gapBetweenPages) + (cell - pageWidth) / 2;
          final onScreen = boundingBox.intersect(
            Rect.fromLTWH(left, topOfPage, pageWidth, pageHeight),
          );
          final fit = pageWidth / page.size.width;
          page.visibleArea.value = onScreen.isEmpty || fit <= 0
              ? null
              : Rect.fromLTWH(
                  (onScreen.left - left) / fit,
                  (onScreen.top - topOfPage) / fit,
                  onScreen.width / fit,
                  onScreen.height / fit,
                );
          final render = page.quill.focusNode.hasFocus || inView;
          page.isRendered = render;
          cells.add(
            SizedBox(
              width: cell,
              child: render
                  ? pageBuilder(context, pageIndex)
                  : placeholderPageBuilder(context, pageIndex),
            ),
          );
        }
        children
          ..add(
            Row(
              mainAxisSize: .min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cells,
            ),
          )
          ..add(const SizedBox.square(dimension: Editor.gapBetweenPages));
        topOfPage = bottom + Editor.gapBetweenPages;
      }
      children.add(const SizedBox.square(dimension: Editor.gapBetweenPages));
      return Column(children: children);
    }

    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final page = pages[pageIndex];
      // scaled down to the screen's width if it's wider, never up
      final pageWidth = min(page.size.width, containerWidth);
      final pageHeight = pageWidth / page.size.width * page.size.height;
      final bottomOfPage = topOfPage + (horizontal ? pageWidth : pageHeight);

      // the part of it on screen, in the page's own units
      if (horizontal) {
        page.visibleArea.value = null;
      } else {
        final left = (containerWidth - pageWidth) / 2;
        final onScreen = boundingBox.intersect(
          Rect.fromLTWH(left, topOfPage, pageWidth, pageHeight),
        );
        final fit = pageWidth / page.size.width;
        page.visibleArea.value = onScreen.isEmpty || fit <= 0
            ? null
            : Rect.fromLTWH(
                (onScreen.left - left) / fit,
                (onScreen.top - topOfPage) / fit,
                onScreen.width / fit,
                onScreen.height / fit,
              );
      }

      // a page with the caret in it stays built wherever it is
      final isFocused = page.quill.focusNode.hasFocus;
      // Pages a screen away are built already, so a scroll doesn't have to
      // build and draw each page in the frame it comes into view.
      final ahead = horizontal ? boundingBox.width : boundingBox.height;
      final isInViewport = horizontal
          ? boundingBox.right + ahead >= topOfPage &&
                boundingBox.left - ahead <= bottomOfPage
          : boundingBox.bottom + ahead >= topOfPage &&
                boundingBox.top - ahead <= bottomOfPage;
      final shouldRender = isFocused || isInViewport;

      page.isRendered = shouldRender;
      final pageWidget = shouldRender
          ? pageBuilder(context, pageIndex)
          : placeholderPageBuilder(context, pageIndex);
      children.add(
        horizontal
            // a Row has no width limit for the FittedBox to fit into
            ? SizedBox(width: pageWidth, height: pageHeight, child: pageWidget)
            : pageWidget,
      );

      children.add(const SizedBox.square(dimension: Editor.gapBetweenPages));

      topOfPage = bottomOfPage + Editor.gapBetweenPages;
    }

    children.add(const SizedBox.square(dimension: Editor.gapBetweenPages));
    return horizontal
        ? Row(mainAxisSize: .min, children: children)
        : Column(children: children);
  }
}

class const _AddPageFooter({
  required final bool ready,
  required final double progress,
  final bool atStart = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final holding = !ready && progress >= 1;
    final text = ready
        ? 'Release to add a page'
        : holding
        ? 'Hold to add a page'
        : CanvasGestureDetector.horizontal
        ? 'Pull ${atStart ? 'right' : 'left'} to add a page'
        : 'Pull ${atStart ? 'down' : 'up'} to add a page';
    return Center(
      child: RepaintBoundary(
        child: AnimatedContainer(
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          height: 44,
          padding: const EdgeInsets.only(left: 6, right: 16),
          decoration: BoxDecoration(
            color: ready ? colors.accentTint : colors.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(BnRadius.pill),
            ),
            border: Border.all(
              color: ready ? colors.accentTintBorder : colors.hairline,
            ),
            boxShadow: BnShadows.floating,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 32,
                child: CustomPaint(
                  painter: _PullRing(
                    // fills while pulling; full while holding and ready
                    progress: ready || holding ? 1 : progress,
                    track: colors.hairline,
                    fill: colors.accent,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: BnMotion.fast,
                      child: ready
                          ? Icon(
                              BnIcons.add,
                              key: const ValueKey('ready'),
                              size: 16,
                              color: colors.accentStrong,
                            )
                          : Icon(
                              BnIcons.addPage,
                              key: const ValueKey('page'),
                              size: 14,
                              color: colors.text2,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // shrinks to fit when the pages are zoomed out narrow
              Flexible(
                child: Text(
                  text,
                  style: BnType.body.copyWith(
                    color: ready ? colors.accentStrong : colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin ring that fills as the pull goes on.
class _PullRing extends CustomPainter {
  const _PullRing({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track, fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, paint..color = track);
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      paint..color = fill,
    );
  }

  @override
  bool shouldRepaint(_PullRing old) =>
      old.progress != progress || old.track != track || old.fill != fill;
}

/// The views of the last few notes closed, so reopening one puts it back
/// just as it was. Only kept while the app runs.
@visibleForTesting
class CanvasTransformCache {
  new _();

  /// How many notes are remembered; the one closed longest ago goes first.
  static const _keep = 5;

  /// Oldest first.
  static final _recent = <CanvasTransformCacheItem>[];

  /// Remembers [transform] as the view of [filePath], in place of any older
  /// one for it.
  static void add(String filePath, Matrix4 transform) {
    _recent
      ..removeWhere((item) => item.filePath == filePath)
      ..add(CanvasTransformCacheItem(filePath, transform));
    if (_recent.length > _keep) _recent.removeAt(0);
  }

  /// The remembered view of [filePath], if there is one.
  static CanvasTransformCacheItem? get(String filePath) {
    for (final item in _recent) {
      if (item.filePath == filePath) return item;
    }
    return null;
  }

  @visibleForTesting
  static void clear() => _recent.clear();
}

/// One note's remembered view.
@visibleForTesting
class CanvasTransformCacheItem {
  new(this.filePath, this.transform);

  final String filePath;
  final Matrix4 transform;
}

/// Where [value] sits between [low] and [high], from 0 at [low] to 1 at
/// [high]. The two must differ.
double _shareOfRange(double value, double low, double high) {
  assert(low <= high, 'the range $low to $high is backwards');
  assert(value >= low && value <= high, '$value is outside $low to $high');
  return (value - low) / (high - low);
}
