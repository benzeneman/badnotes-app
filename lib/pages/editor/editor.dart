import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:badnotes/data/pro/pro.dart';
import 'package:badnotes/components/editor/export_progress.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as flutter_quill;
import 'package:keybinder/keybinder.dart';
import 'package:logging/logging.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:badnotes/data/lag_recorder.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/components/editor_ui/paste_pill.dart';
import 'package:badnotes/components/editor_ui/color_panel.dart';
import 'package:badnotes/components/editor_ui/editor_ui_colors.dart';
import 'package:badnotes/components/editor_ui/floating_toolbar.dart';
import 'package:badnotes/components/editor/recording_ui.dart';
import 'package:badnotes/components/editor/lasso_shot.dart';
import 'package:badnotes/components/editor/sticker_art.dart';
import 'package:badnotes/components/editor_ui/insert_panels.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/components/editor_ui/screen_color_picker.dart';
import 'package:badnotes/components/editor_ui/selection_action_bar.dart';
import 'package:badnotes/components/editor_ui/text_format_bar.dart';
import 'package:badnotes/components/editor_ui/tool_chips.dart';
import 'package:badnotes/components/editor_ui/tool_bars.dart';
import 'package:badnotes/components/editor_ui/tool_panel.dart';
import 'package:badnotes/components/canvas/_asset_cache.dart';
import 'package:badnotes/components/canvas/_ink_cache.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/canvas.dart';
import 'package:badnotes/components/canvas/canvas_gesture_detector.dart';
import 'package:badnotes/components/canvas/canvas_image.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/components/canvas/save_indicator.dart';
import 'package:badnotes/components/editor/audio_notes.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/editor/canvas_tools_overlay.dart';
import 'package:badnotes/components/editor/board_kits.dart';
import 'package:badnotes/components/editor/board_map.dart';
import 'package:badnotes/components/editor/board_paper.dart';
import 'package:badnotes/components/editor/boards_panel.dart';
import 'package:badnotes/components/editor/share_export_card.dart';
import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/home/new_note_button.dart';
import 'package:badnotes/components/home/rename_note_button.dart';
import 'package:badnotes/components/home/trash.dart';
import 'package:badnotes/components/editor/go_live.dart';
import 'package:badnotes/components/editor/layers_sheet.dart';
import 'package:badnotes/components/editor/new_page_sheet.dart';
import 'package:badnotes/components/editor/reading_tools.dart';
import 'package:badnotes/components/editor/tape_quiz.dart';
import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/home/revision_plan.dart';
import 'package:badnotes/components/editor/note_split_view.dart';
import 'package:badnotes/components/editor/pages_panel.dart';
import 'package:badnotes/components/editor/note_clipboard.dart';
import 'package:badnotes/components/editor/note_tabs.dart';
import 'package:badnotes/components/editor/handwriting_ocr.dart';
import 'package:badnotes/components/editor/note_search_panel.dart';
import 'package:badnotes/components/canvas/palm_rejection.dart';
import 'package:badnotes/components/editor/page_pins.dart';
import 'package:badnotes/components/editor/save_template_sheet.dart';
import 'package:badnotes/data/my_templates.dart';
import 'package:badnotes/components/editor/version_history_sheet.dart';
import 'package:badnotes/data/file_manager/note_versions.dart';
import 'package:badnotes/components/home/note_tags.dart';
import 'package:badnotes/components/editor/screenshot_overlay.dart';
import 'package:badnotes/components/editor/read_only_banner.dart';
import 'package:badnotes/components/editor/pages_overview.dart';
import 'package:badnotes/components/editor/sticky_note_dialog.dart';
import 'package:badnotes/components/editor/sticky_note_paper.dart';
import 'package:badnotes/data/extensions/list_extensions.dart';
import 'package:badnotes/components/theming/adaptive_alert_dialog.dart';
import 'package:badnotes/components/theming/dynamic_material_app.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/data/editor/preset_colors.dart';
import 'package:badnotes/components/toolbar/editor_bottom_sheet.dart';
import 'package:badnotes/components/toolbar/editor_page_manager.dart';
import 'package:badnotes/components/toolbar/toolbar.dart';
import 'package:badnotes/data/is_this_a_test.dart';
import 'package:badnotes/data/locks.dart';
import 'package:badnotes/components/lock/lock_ui.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/editor_exporter.dart';
import 'package:badnotes/data/editor/editor_history.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/editor/thumbnail_marks.dart';
import 'package:badnotes/data/nextcloud/pdf_copies.dart';
import 'package:badnotes/data/extensions/change_notifier_extensions.dart';
import 'package:badnotes/data/extensions/matrix4_extensions.dart';
import 'package:badnotes/data/editor/note_start.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/recent_images.dart';
import 'package:badnotes/data/tools/_tool.dart';
import 'package:badnotes/data/tools/eraser.dart';
import 'package:badnotes/data/tools/highlighter.dart';
import 'package:badnotes/data/tools/laser_pointer.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/pencil.dart';
import 'package:badnotes/data/tools/select.dart';
import 'package:badnotes/data/tools/shape_pen.dart';
import 'package:badnotes/data/tools/tape.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/home/whiteboard.dart';
import 'package:printing/printing.dart';
import 'package:sbn/canvas_background_pattern.dart';
import 'package:sbn/change.dart';
import 'package:badnotes/components/editor/text_box_overlay.dart';
import 'package:sbn/tool_id.dart';
import 'package:super_clipboard/super_clipboard.dart';

class const _PhotoInfo(final Uint8List bytes, final String extension);

typedef _Spot = ({int pageIndex, Offset center});

class Editor extends StatefulWidget {
  /// Notes to open at a page, by path: set before opening one, e.g. from
  /// a search result; used once.
  static final openAtPage = <String, int>{};

  /// Words to light up on the page a note opens at, from a search.
  static final searchOnOpen = <String, String>{};

  /// Notes just closed and still being saved, by path: opening one again
  /// waits for it, or it was read as it was before (or empty) and its next
  /// save lost what was just written.
  static final closing = <String, Future<void>>{};

  /// The notes open in an editor now, by path (twice for one open in two
  /// panes). Sync doesn't write a cloud version over one of these: the
  /// editor's next save would put what it has back over it.
  static final openNotes = <String>[];

  /// Whether the note at [path] is open in an editor, or still saving as
  /// one closes.
  static bool isOpen(String path) =>
      openNotes.contains(path) || closing.containsKey(path);

  /// Whether opening waits for [closing]. Off in tests, whose fake clock
  /// never lets a closed editor's save finish; a test of it turns it on.
  @visibleForTesting
  static var waitForClosing = !isThisATest;

  new({
    super.key,
    String? path,
    this.customTitle,
    this.pdfPath,
    this.onClosePane,
    this.board = false,
  }) : initialPath = path != null
           ? Future.value(path)
           : FileManager.newFilePath('/'),
       needsNaming = path == null;

  /// Where the note lives, or a fresh untitled path for a new note.
  final Future<String> initialPath;

  /// True for a brand-new note, which gets asked for a name.
  final bool needsNaming;

  /// Shown instead of the file name in the title bar.
  final String? customTitle;

  /// A pdf to bring in as pages once the note has opened.
  final String? pdfPath;

  /// Set when this editor is beside another one: closes it.
  final Future<void> Function()? onClosePane;


  /// A whiteboard: one blank sheet going every way, instead of pages.
  final bool board;

  /// What every note file ends in today: the binary (BSON) note format.
  static const extension = '.sbn2';

  /// What notes from older versions end in: the same note written as JSON
  /// text. They still open, and get saved again with [extension].
  static const extensionOldJson = '.sbn';

  /// Space left between two pages, in page units.
  static const double gapBetweenPages = 16;

  /// Paths the app keeps for itself (such as the quick whiteboard), which
  /// file lists leave out.
  static final _hiddenPaths = [
    RegExp(RegExp.escape(Whiteboard.filePath)),
  ];

  /// Whether [path] is one of the app's own files rather than a note the
  /// user made.
  static bool isReservedPath(String path) =>
      _hiddenPaths.any((pattern) => pattern.hasMatch(path));

  /// Whether this device can turn pdf pages into pictures. Set at start-up;
  /// importing a pdf is only offered when it can.
  static var canRasterPdf = true;

  @override
  State<Editor> createState() => EditorState();
}

class EditorState extends State<Editor> {
  final log = Logger('EditorState');

  /// The open note: its pages and settings. A stand-in until it has loaded.
  late var coreInfo = EditorCoreInfo.placeholder;

  /// Audio recordings synced to strokes. Created once the note has loaded.
  AudioNotes? audioNotes;

  final _canvasGestureDetectorKey = GlobalKey<CanvasGestureDetectorState>();
  final _transformationController = TransformationController();

  /// How far into the note the middle of the screen is, in page units: down
  /// the pages, or across them when they run sideways.
  double get scrollY {
    final view = _transformationController.value;
    final zoom = view.approxScale;
    final shift = view.getTranslation();
    final sideways = CanvasGestureDetector.horizontal;
    final along = sideways ? shift.x : shift.y;

    final detector = _canvasGestureDetectorKey.currentState;
    if (detector == null) {
      log.warning('scrollY: Could not find CanvasGestureDetectorState');
      return along / zoom;
    }
    final box = detector.containerBounds;
    final half = (sideways ? box.maxWidth : box.maxHeight) / 2;
    return (along - half) / zoom + half;
  }

  /// Undo and redo for this note.
  var history = EditorHistory();

  /// Whether to ask for a name: only for new notes, and only if the user
  /// hasn't turned the question off.
  late bool needsNaming = widget.needsNaming && stows.editorPromptRename.value;

  /// The tool picked last time, so a note opens with the same one.
  late Tool _currentTool = _toolFor(stows.lastTool.value);

  /// The shared tool object for [id].
  static Tool _toolFor(ToolId id) => switch (id) {
    .fountainPen => (Pen.currentPen.toolId == id
        ? Pen.currentPen
        : Pen.currentPen = Pen.fountainPen()),
    .ballpointPen => Pen.currentBallpointPen,
    .calligraphyPen => Pen.currentCalligraphyPen,
    .brushPen => Pen.currentBrushPen,
    .shapePen => ShapePen.currentShapePen,
    .highlighter => Highlighter.currentHighlighter,
    .pencil => Pencil.currentPencil,
    .eraser => Eraser(),
    .select => Select.currentSelect,
    .textEditing => Tool.textEditing,
    .laserPointer => LaserPointer.currentLaserPointer,
    .tape => Tape.currentTape,
  };

  /// The tool in use. Picking one also remembers it for next time, and for
  /// going back to after the eraser.
  Tool get currentTool => _currentTool;
  set currentTool(Tool tool) {
    _currentTool = tool;
    if (tool is! Eraser) _lastNonEraserTool = tool;
    stows.lastTool.value = tool.toolId;
  }

  /// Whether the note on disk is behind what's on screen; the save
  /// indicator shows it.
  ValueNotifier<SavingState> savingState = ValueNotifier(SavingState.saved);

  /// Runs the autosave a moment after the last change.
  Timer? _delayedSaveTimer;

  /// Uploads the saved note to the server once it has settled.
  Timer? _watchServerTimer;

  /// How many fingers were on the screen most recently. Two or more means
  /// a pinch, and a stroke started then is thrown away.
  var lastSeenPointerCount = 0;
  Timer? _lastSeenPointerCountTimer;

  /// The typed-text box being edited, if any.
  ValueNotifier<QuillStruct?> quillFocus = ValueNotifier(null);

  /// What the eraser shortcut goes back to: the most recent tool that
  /// wasn't the eraser.
  late Tool _lastNonEraserTool = Pen.currentPen;

  /// The tool to go back to when text editing is turned off.
  Tool _toolBeforeTextEditing = Pen.currentPen;

  /// Whether the pen's side button (or its back end, an
  /// [PointerDeviceKind.inverseStylus], which works the same way here) has
  /// been held at any point in the stroke being drawn.
  var stylusButtonWasPressed = false;

  /// The tool before the stylus button switched to another, see
  /// [onStylusButtonChanged].
  Tool? _toolBeforeStylusButton;

  /// Back to the tool from before the stylus button was held. A lasso
  /// selection made with the button stays, to be moved.
  void _restoreAfterStylusButton() {
    final before = _toolBeforeStylusButton;
    if (before == null) return;
    _toolBeforeStylusButton = null;
    if (currentTool is Select && Select.currentSelect.doneSelecting) return;
    currentTool = before;
  }

  @override
  void initState() {
    EditorSignals.covered.addListener(_onCovered);
    // the tools move between the header and a floating bar with its edge
    stows.floatingToolbarEdge.addListener(_toolbarMoved);
    // the page as it was left, shown at once while the note opens
    widget.initialPath.then((path) {
      final picture = FileManager.getFile('$path.open.png');
      if (mounted &&
          coreInfo.readOnlyReason == .placeholder &&
          !NoteLocks.isProtected(path) &&
          picture.existsSync()) {
        setState(() => _openingPicture = picture);
      }
    });
    DynamicMaterialApp.addFullscreenListener(_setState);
    ScreenColorPicker.source = _pickKey;
    // a selection is shared by all notes: one left from the note before
    // showed (moving) on this one's first page
    Select.currentSelect.unselect();
    stows.toolbarDocked.addListener(_setState);
    stows.dockedToolsBottom.addListener(_setState);
    // the hand button shows whether fingers draw: it changes from the
    // button, and by itself when a stylus touches the page
    stows.editorFingerDrawing.addListener(_setState);

    // no locks at all: open at once, as before locks existed
    if (NoteLocks.surelyNone) _startOnce();
    unawaited(_openUnlessLocked());
    _assignKeybindings();
    // Android can close a backgrounded app without warning: edits still
    // waiting for the autosave delay were lost.
    _lifecycle = AppLifecycleListener(onHide: _saveIfWaiting);
    NoteTabs.paths.addListener(_setState);

    super.initState();
  }

  late final AppLifecycleListener _lifecycle;

  /// Set while the note's lock (or its folder's) is shut: the lock screen
  /// shows instead, and the note isn't read until it opens.
  String? _lockedPath;
  var _started = false;
  var _gatePath = '';

  Future<void> _openUnlessLocked() async {
    _gatePath = await widget.initialPath;
    await NoteLocks.load();
    if (!mounted) return;
    NoteLocks.unlocked.addListener(_checkLock);
    NoteLocks.book.addListener(_checkLock);
    _checkLock();
    if (_lockedPath == null) _startOnce();
  }

  void _startOnce() {
    if (_started) return;
    _started = true;
    _initAsync();
  }

  /// Locks again when the app was away (or the lock was just set).
  void _checkLock() {
    final path = coreInfo.filePath.isNotEmpty ? coreInfo.filePath : _gatePath;
    final shut = NoteLocks.needsUnlock(path) ? path : null;
    if (shut != _lockedPath && mounted) setState(() => _lockedPath = shut);
  }

  void _onUnlocked() {
    setState(() => _lockedPath = null);
    _startOnce();
  }

  void _saveIfWaiting() {
    if (_ocrDirty && !coreInfo.readOnly) {
      _ocrTimer?.cancel();
      _ocrDirty = false;
      unawaited(HandwritingOcr.indexNote(coreInfo.filePath, coreInfo.pages));
    }
    // a save running now: another after it, for what came since
    if (savingState.value != .saved) {
      saveToFile();
    } else {
      _announceQuietWrites();
      if (savingState.value == .saved && _editedThisSession) {
        unawaited(_saveThumbnail());
      }
    }
  }

  /// The default pen size changed to 3, but existing installs have
  /// the old defaults saved.
  void _movePenSizesToThree() {
    if (stows.penSizesAreThree.value) return;
    for (final stow in [
      stows.lastFountainPenOptions,
      stows.lastBallpointPenOptions,
      stows.lastPencilOptions,
      stows.lastShapePenOptions,
    ]) {
      stow.value.size = 3;
      stow.notifyListeners();
    }
    stows.penSizesAreThree.value = true;
  }

  /// The highlighter's default size changed from 3 to 20. Moves the previous
  /// default up, and leaves it alone if the user has chosen another size.
  /// Leaves it alone if the user has chosen another size.
  void _moveFountainPenSizeToTwo() {
    if (stows.fountainSizeIsTwo.value) return;
    final options = stows.lastFountainPenOptions;
    if (options.value.size == 3) {
      options.value.size = 2;
      options.notifyListeners();
    }
    stows.fountainSizeIsTwo.value = true;
  }

  void _moveHighlighterSizeToTwenty() {
    if (stows.highlighterSizeIsTwenty.value) return;
    final options = stows.lastHighlighterOptions;
    if (options.value.size == 3) {
      options.value.size = 20;
      options.notifyListeners();
    }
    stows.highlighterSizeIsTwenty.value = true;
  }

  /// Stabilization by speed can do more without any lag. Moves the previous
  /// default up, and leaves it alone if the user has chosen another amount.
  void _moveBallPenToSpeedSmoothing() {
    if (stows.ballPenSpeedSmoothing.value) return;
    final options = stows.lastBallpointPenOptions;
    if (options.value.streamline == 0.1) {
      options.value.streamline = 0.35;
      options.notifyListeners();
    }
    stows.ballPenSpeedSmoothing.value = true;
  }

  /// The default of 50% stabilization made the ball pen's line trail the pen.
  /// Leaves it alone if the user has chosen another amount.
  void _lowerBallPenStabilization() {
    if (stows.ballPenLagFixed.value) return;
    final options = stows.lastBallpointPenOptions;
    if (options.value.streamline == 0.5) {
      options.value.streamline = 0.1;
      options.notifyListeners();
    }
    stows.ballPenLagFixed.value = true;
  }

  /// The floating bar starts at the top on a tablet now: put back there
  /// once, from wherever it had been moved.
  void _resetFloatingBarOnce() {
    if (stows.floatingBarReset.value) return;
    stows.floatingToolbarEdge.value = -1;
    stows.floatingToolbarAlong.value = 0.5;
    stows.floatingBarReset.value = true;
  }

  void _initAsync() async {
    _resetFloatingBarOnce();
    _movePenSizesToThree();
    _moveFountainPenSizeToTwo();
    _moveHighlighterSizeToTwenty();
    _lowerBallPenStabilization();
    _moveBallPenToSpeedSmoothing();
    final filePath = await widget.initialPath;
    final name = filenameTextEditingController..text = p.basename(filePath);
    // a new note's name starts fully selected, so typing replaces it
    if (needsNaming) {
      name.selection = TextSelection(
        baseOffset: 0,
        extentOffset: name.text.length,
      );
    }

    await _loadCoreInfo(filePath);
    final start = NoteStart.take(filePath);
    if (start != null && mounted) await _applyStart(start);
    if (widget.customTitle == null) NoteTabs.open(coreInfo.filePath);

    if (widget.pdfPath case final pdf?) await importPdfFromFilePath(pdf);
  }

  /// Completes once the page opening this editor has finished sliding in, or
  /// at once if there's no animation. Building every page of a note in the
  /// middle of it made it stutter.
  Future<void> _openAnimationDone() async {
    if (!mounted) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) return;
    final done = Completer<void>();
    void listener(AnimationStatus status) {
      if (status != AnimationStatus.forward && !done.isCompleted) {
        done.complete();
      }
    }

    animation.addStatusListener(listener);
    await done.future.timeout(
      const Duration(milliseconds: 500),
      onTimeout: () {},
    );
    animation.removeStatusListener(listener);
  }

  Future _loadCoreInfo(String filePath) async {
    LagRecorder.doing('open note', lasts: const Duration(seconds: 4));
    final opening = Stopwatch()..start();
    // read the note while the page slides in, then show it
    final loading = LagRecorder.span(
      'open note: start reading',
      () async {
        if (Editor.waitForClosing) await Editor.closing[filePath]?.timeout(
          const Duration(seconds: 10),
          onTimeout: () {},
        );
        return EditorCoreInfo.loadFromFilePath(filePath);
      },
    );
    await _openAnimationDone();
    final loaded = await loading;
    // left before it loaded
    if (!mounted) {
      loaded.dispose();
      return;
    }
    // loaded again (the note changed on the server): still open once
    if (!identical(coreInfo, EditorCoreInfo.placeholder)) {
      Editor.openNotes.remove(coreInfo.filePath);
    }
    coreInfo = loaded;
    Editor.openNotes.add(loaded.filePath);
    unawaited(
      NoteVersions.list(filePath).then(
        (versions) => _lastKeptVersion =
            versions.isEmpty ? DateTime(2000) : versions.first.time,
        onError: (_) => _lastKeptVersion = null,
      ),
    );
    // links to pages and notes were taken out: their boxes go too
    for (final page in coreInfo.pages) {
      page.images.removeWhere(
        (image) => image is SvgEditorImage && image.isRemovedLink,
      );
    }
    // opened from a search result: at the page it was found on, with the
    // words lit up
    if (Editor.openAtPage.remove(filePath) case final page?
        when page >= 0 && page < coreInfo.pages.length) {
      coreInfo.initialPageIndex = page;
      if (Editor.searchOnOpen.remove(filePath) case final query?) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          _showSearchHit(
            SearchHit(
              pageIndex: page,
              source: 'Handwriting',
              snippet: '',
              matchStart: 0,
              matchLength: 0,
            ),
            query,
          );
        });
      }
    }
    if (LagRecorder.enabled) {
      LagRecorder.note('note opened', {
        'ms': opening.elapsedMilliseconds,
        'pages': coreInfo.pages.length,
        'strokes': coreInfo.pages.fold<int>(
          0,
          (sum, p) => sum + p.strokes.length,
        ),
        'images': coreInfo.pages.fold<int>(
          0,
          (sum, p) => sum + p.images.length,
        ),
      });
    }
    if (!mounted) return;
    audioNotes ??= AudioNotes(coreInfo.filePath)
      ..playbackAt.addListener(_followPlayback);
    if (coreInfo.readOnly) {
      log.info('Loaded file as read-only: ${coreInfo.readOnlyReason}');
    }

    final pages = coreInfo.pages;
    for (var i = 0; i < pages.length; i++) {
      listenToQuillChanges(pages[i].quill, i);
    }

    if (coreInfo.isEmpty) {
      // nothing in the file yet: give it its first page
      createPage(-1);
    } else {
      // hook every picture (and pdf background) up to this editor
      for (final page in pages) {
        for (final image in [?page.backgroundImage, ...page.images]) {
          image.onMoveImage = onMoveImage;
          image.onDeleteImage = onDeleteImage;
          image.onMiscChange = _onImageMiscChange;
        }
      }
    }

    // left in text mode last time: put the cursor in the opening page's text
    if (currentTool == Tool.textEditing) {
      final first = coreInfo.initialPageIndex ?? 0;
      assert(first < coreInfo.pages.length);
      _focusTypedText(coreInfo.pages[first].quill);
    }

    final clearBoard =
        coreInfo.filePath == Whiteboard.filePath &&
        stows.autoClearWhiteboardOnExit.value &&
        Whiteboard.needsToAutoClearWhiteboard;
    if (!clearBoard) {
      setState(() {});
    } else {
      // the quick whiteboard starts blank each time when set to: wipe it
      // (undoably) and save the blank board straight away
      clearAllPages();
      await saveToFile();
      Whiteboard.needsToAutoClearWhiteboard = false;
    }

    if (_isBoard && mounted) setState(_setUpBoard);
  }

  void _setState() => setState(() {});

  /// Makes this note's pages into one whiteboard sheet. What was on the pages
  /// goes in its middle, one page under the other, and the board opens where
  /// the writing last ended, or in the middle.
  // ponytail: typed text on old pages stays at the sheet's far corner. Convert
  // it to text boxes if old whiteboards turn out to have any.
  void _setUpBoard() {
    createPage(0);
    final sheet = coreInfo.pages.first;
    if (!sheet.isBoard) {
      const middle = EditorPage.boardSide / 2;
      var y = middle - 400;
      final old = coreInfo.pages.toList();
      final strokes = <Stroke>[];
      final images = <EditorImage>[];
      for (final page in old) {
        final offset = Offset(middle - page.size.width / 2, y);
        if (page.backgroundImage case final background?) {
          background.dstRect = offset & page.size;
          images.add(background);
          page.backgroundImage = null;
        }
        for (final stroke in page.strokes) {
          stroke
            ..shift(offset)
            ..pageIndex = 0
            ..page = sheet;
          strokes.add(stroke);
        }
        for (final image in page.images) {
          if (images.contains(image)) continue;
          image
            ..dstRect = image.dstRect.shift(offset)
            ..pageIndex = 0;
          images.add(image);
        }
        y += page.size.height + 40;
      }
      for (final page in old) {
        page.strokes.clear();
        page.images.clear();
      }
      for (final page in old.skip(1)) {
        page.dispose();
      }
      coreInfo.pages
        ..clear()
        ..add(sheet);
      sheet
        ..size = const Size.square(EditorPage.boardSide)
        ..strokes.addAll(strokes)
        ..images.addAll(images)
        ..backgroundPattern = .none
        ..backgroundColor = BoardPaper.colors['White'];
      sheet.sortStrokes();
      history.markUnsaved();
      autosaveAfterDelay();
    }
    if (!_transformationController.value.isIdentity()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _canvasStackBox;
      if (!mounted || box == null || !box.hasSize) return;
      final last = sheet.strokes.lastOrNull?.centerPoints.lastOrNull;
      final target =
          last ??
          const Offset(EditorPage.boardSide / 2, EditorPage.boardSide / 2);
      _transformationController.value = Matrix4.translationValues(
        box.size.width / 2 - target.dx,
        box.size.height / 2 - target.dy,
        0,
      );
    });
  }

  /// A whiteboard: the one on the home screen, or any note made as one.
  bool get _isBoard =>
      widget.board || (coreInfo.pages.firstOrNull?.isBoard ?? false);

  /// Gets a brand new note going the way it was asked for.
  Future<void> _applyStart(NoteStart start) async {
    createPage(0);
    final page = coreInfo.pages.first;
    if (page.isNotEmpty) return;

    if (start.source case final source?) {
      final photos = await _photosFrom(source);
      if (!mounted) return;
      if (photos.isEmpty) {
        // nothing was chosen, so there's no note to keep
        await Navigator.maybePop(context);
        return;
      }
      for (final (i, photo) in photos.indexed) {
        if (i > 0) insertPageAfter(i - 1);
        final target = coreInfo.pages[i];
        await _pickPhotos(
          [photo],
          (pageIndex: i, center: target.size.center(Offset.zero)),
          false,
        );
        if (!mounted) return;
        _makeLastImageTheBackground(target);
      }
      return;
    }

    setState(() {
      if (start.board) {
        page.size = const Size.square(EditorPage.boardSide);
      } else if (start.size case final size?) {
        page.size = size;
      }
      page
        ..backgroundPattern = start.pattern ?? page.backgroundPattern
        ..backgroundColor = start.color ?? page.backgroundColor
        ..lineHeight = start.lineHeight ?? page.lineHeight;
    });
    history.markUnsaved();
    autosaveAfterDelay();

    final center = page.size.center(Offset.zero);
    if (start.layoutSvg case final svg?) {
      await _pickPhotos(
        [_PhotoInfo(utf8.encode(svg), '.svg')],
        (pageIndex: 0, center: center),
        false,
      );
    }
    if (start.imagePath case final imagePath?) {
      final bytes = await File(imagePath).readAsBytes();
      if (!mounted) return;
      await _pickPhotos(
        [_PhotoInfo(bytes, p.extension(imagePath))],
        (pageIndex: 0, center: center),
        false,
      );
      if (mounted && !start.board) _makeLastImageTheBackground(page);
    }
    if (start.board && mounted) _setUpBoard();
  }

  Future<List<_PhotoInfo>> _photosFrom(NewPageSource source) async {
    switch (source) {
      case .image:
        return _pickPhotosWithFilePicker();
      case .photo:
        final photo = await _capturePhoto();
        return [?photo];
      case .scan:
        return _scanDocument();
      case .import:
        return const [];
    }
  }

  /// Where the pen is writing, on the screen: the board's map fades if it's
  /// in the way.
  final _inkingAt = ValueNotifier<Offset?>(null);

  /// The whiteboard's paper, colour and ready-made layouts, in a card.
  Future<void> _openBoardPaper() => showAppleDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setCard) {
        final sheet = coreInfo.pages.first;
        return Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: 380,
            height: 560,
            child: BoardPanel(
              pattern: sheet.backgroundPattern ?? CanvasBackgroundPattern.none,
              spacing: sheet.lineHeight ?? 40,
              color: sheet.backgroundColor ?? Colors.white,
              setPaper: (paper) {
                _changeBoard(
                  (sheet) => sheet
                    ..backgroundPattern = paper.pattern
                    ..lineHeight = paper.spacing,
                );
                setCard(() {});
              },
              setColor: (color) {
                _changeBoard((sheet) => sheet.backgroundColor = color);
                setCard(() {});
              },
              placeKit: (kit) {
                Navigator.pop(context);
                _pickPhotos([_PhotoInfo(utf8.encode(kit.svg), '.svg')]);
              },
              onClose: () => Navigator.pop(context),
            ),
          ),
        );
      },
    ),
  );

  /// Screen pixels per unit of the board.
  double _boardZoom() {
    final pageBox = coreInfo.pages.firstOrNull?.renderBox;
    if (pageBox == null || !pageBox.attached) return 1;
    return (pageBox.localToGlobal(const Offset(1, 0)) -
            pageBox.localToGlobal(Offset.zero))
        .dx;
  }

  /// Where the board is shown: the canvas, in its own coordinates.
  RenderBox? get _viewport =>
      _screenshotBoundaryKey.currentContext?.findRenderObject() as RenderBox?;

  /// The part of the board on screen, in its own units.
  Rect? _boardVisible() {
    final pageBox = coreInfo.pages.firstOrNull?.renderBox;
    final view = _viewport;
    if (pageBox == null || view == null || !pageBox.attached) return null;
    return Rect.fromPoints(
      pageBox.globalToLocal(view.localToGlobal(Offset.zero)),
      pageBox.globalToLocal(view.localToGlobal(view.size.bottomRight(.zero))),
    );
  }

  /// Moves the board so [point] (on the board) is in the middle.
  void _centerBoardOn(Offset point) {
    final visible = _boardVisible();
    if (visible == null) return;
    final by = (visible.center - point) * _boardZoom();
    final matrix = _transformationController.value.clone();
    final t = matrix.getTranslation();
    _transformationController.value = matrix
      ..setTranslationRaw(t.x + by.dx, t.y + by.dy, t.z);
  }

  /// Zooms the board to [zoom] screen pixels per unit, round the middle.
  void _zoomBoardTo(double zoom) {
    final view = _viewport;
    if (view == null) return;
    final factor = zoom.clamp(0.02, 8.0) / _boardZoom();
    final middle = view.size.center(Offset.zero);
    _transformationController.value = Matrix4.identity()
      ..translateByDouble(middle.dx, middle.dy, 0, 1)
      ..scaleByDouble(factor, factor, 1, 1)
      ..translateByDouble(-middle.dx, -middle.dy, 0, 1)
      ..multiply(_transformationController.value);
  }

  /// Zooms out (or in) to show everything on the board.
  void _fitBoard() {
    final view = _viewport;
    final content = boardContent(coreInfo.pages.first);
    if (view == null || content == null) return;
    final area = content.inflate(40);
    _centerBoardOn(area.center);
    _zoomBoardTo(
      min(view.size.width / area.width, view.size.height / area.height),
    );
  }

  /// Opens another whiteboard in this tab's place, as tabs do.
  Future<void> _openBoard(String path) async {
    if (path == coreInfo.filePath) return;
    // the quick whiteboard has no tabs: the other one opens over it
    if (widget.customTitle != null) {
      await saveToFile();
      if (mounted) await openNote(context, path);
      return;
    }
    if (!NoteTabs.paths.value.contains(path)) {
      NoteTabs.paths.value = [...NoteTabs.paths.value, path];
    }
    await NoteTabActions.switchTo(path, saveToFile);
  }

  /// Renames a whiteboard; the open one as its title does.
  Future<void> _renameBoard(String path) async {
    if (path != coreInfo.filePath) {
      return RenameNoteButton(existingPath: path, unselectNotes: () {})
          .open(context);
    }
    final name = TextEditingController(text: coreInfo.fileName);
    final ok = await showAppleDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename whiteboard'),
        content: TextField(controller: name, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    final newName = name.text.trim();
    name.dispose();
    if (ok != true || newName.isEmpty || !mounted) return;
    filenameTextEditingController.text = newName;
    await _renameWhenNotSaving();
    if (mounted) setState(() {});
  }

  /// Copies a whiteboard and opens the copy.
  Future<void> _duplicateBoard(String path) async {
    if (!await Pro.mayDuplicate(context, [path])) return;
    if (path == coreInfo.filePath) await saveToFile();
    final copies = await duplicateNotes([path]);
    if (copies.isNotEmpty && mounted) await _openBoard(copies.first);
  }

  /// Deletes a whiteboard to the trash, asking first. The open one's tab is
  /// closed first.
  Future<void> _deleteBoard(String path) async {
    final name = path == Whiteboard.filePath
        ? 'Quick whiteboard'
        : path.substring(path.lastIndexOf('/') + 1);
    final ok = await showAppleDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete “$name”?'),
        content: const Text('It goes to the Trash for 30 days.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: EditorUi.destructive),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (path == coreInfo.filePath) {
      await saveToFile();
      if (!mounted) return;
      await NoteTabActions.close(context, path, () async {});
    }
    await moveToTrashWithUndo(overlay, [path]);
  }

  /// The whiteboard's PNG: everything on it, shown whole for a moment and
  /// taken from the screen.
  Future<void> _exportBoardPng(
    BuildContext context, {
    bool share = false,
  }) => ExportProgress.run(context, 'Making PNG…', () async {
    final view = _screenshotBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    final content = boardContent(coreInfo.pages.first);
    if (view == null || content == null) return;
    final before = _transformationController.value.clone();
    _fitBoard();
    // two frames: the ink is drawn again at the new zoom
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    try {
      final pageBox = coreInfo.pages.first.renderBox!;
      final area = content.inflate(20);
      final local = Rect.fromPoints(
        view.globalToLocal(pageBox.localToGlobal(area.topLeft)),
        view.globalToLocal(pageBox.localToGlobal(area.bottomRight)),
      ).intersect(Offset.zero & view.size);
      // ignore: invalid_use_of_protected_member
      final layer = view.layer! as OffsetLayer;
      final image = await layer.toImage(
        local,
        pixelRatio: MediaQuery.devicePixelRatioOf(this.context) * 1.5,
      );
      final png = await image.toByteData(format: .png);
      image.dispose();
      _transformationController.value = before;
      if (png == null || !context.mounted) return;
      final ok = await FileManager.exportFile(
        '${coreInfo.fileName}.png',
        png.buffer.asUint8List(),
        isImage: true,
        share: share,
        context: context,
      );
      if (mounted && !share) _pngSaved(ok);
    } catch (e, st) {
      _transformationController.value = before;
      log.severe('Failed to export the board as PNG', e, st);
    }
  });

  /// Changes the board's paper or color, which isn't in the undo history.
  void _changeBoard(void Function(EditorPage sheet) change) {
    final sheet = coreInfo.pages.firstOrNull;
    if (sheet == null || coreInfo.readOnly) return;
    setState(() => change(sheet));
    history.markUnsaved();
    autosaveAfterDelay();
  }

  /// Ctrl+Z, Ctrl+Y and Ctrl+Shift+Z, kept so they can be unbound again.
  Keybinding? _ctrlZ, _ctrlY, _ctrlShiftZ;

  void _assignKeybindings() {
    Keybinding ctrlWith(List<KeyCode> keys, LogicalKeyboardKey key) =>
        Keybinding([KeyCode.ctrl, ...keys, KeyCode.from(key)], inclusive: true);

    final undoKeys = _ctrlZ = ctrlWith(const [], LogicalKeyboardKey.keyZ);
    final redoKeys = _ctrlY = ctrlWith(const [], LogicalKeyboardKey.keyY);
    final redoKeysToo = _ctrlShiftZ = ctrlWith(
      [KeyCode.shift],
      LogicalKeyboardKey.keyZ,
    );
    Keybinder.bind(undoKeys, () => _unlessTyping(undo));
    Keybinder.bind(redoKeys, () => _unlessTyping(redo));
    Keybinder.bind(redoKeysToo, () => _unlessTyping(redo));
  }

  /// [action], unless a text field (a text box, the note's name) is being
  /// typed in: it has its own undo, and Ctrl+Z there also undid the ink.
  void _unlessTyping(void Function() action) {
    if (_textBox != null) return;
    // the focus is a node inside the field, not the field itself
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused != null &&
        (focused.widget is EditableText ||
            focused.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return;
    }
    // a page's own text keeps its typing history too
    if (coreInfo.pages.any((page) => page.quill.focusNode.hasFocus)) return;
    action();
  }

  void _removeKeybindings() {
    for (final keys in [_ctrlZ, _ctrlY, _ctrlShiftZ]) {
      if (keys != null) Keybinder.remove(keys);
    }
  }

  /// Adds blank pages to the end until page [pageIndex] exists, and makes
  /// sure there is always at least one page. Nothing extra is added after
  /// it: a new page comes from pulling past the last one, or from the
  /// insert-page button.
  void createPage(int pageIndex) {
    final pages = coreInfo.pages;
    while (pages.isEmpty || pages.length <= pageIndex) {
      final blank = EditorPage();
      pages.add(blank);
      listenToQuillChanges(blank.quill, pages.length - 1);
    }
  }

  /// Kept for callers from before: empty pages are never dropped by
  /// themselves in BadNotes, only when the user deletes them.
  void removeExcessPages() {}

  /// Steps back one change. With [historic] given, that change is taken
  /// back instead of the newest one: [redo] and the stray-stroke clean-up
  /// use it this way.
  void undo([Historic? historic]) {
    historic ??= _takeNewestChange();
    if (historic == null) return;

    _undoChange(historic);

    final select = Select.currentSelect;
    // moving or resizing back keeps the selection; anything else ends it
    if (historic is! HistoricMove && historic is! HistoricTransform) {
      select.unselect();
    }
    // pages don't repaint by themselves when ink is taken off them
    for (final page in coreInfo.pages) {
      page.redrawStrokes();
    }
    // a picture's outline has to be measured again: a resize going back
    // isn't just a shift of the old outline
    if (select.singleImage case final image?) {
      select.selectResult.path = _imageOutline(image);
    }

    if (mounted) setState(() {});

    autosaveAfterDelay();
  }

  /// Pops the newest change off the undo list, or null if there is none.
  /// A new change since the last undo switched redo off: the redo list is
  /// emptied then, and redo works again from this point.
  Historic? _takeNewestChange() {
    if (!history.canUndo) return null;
    if (!history.canRedo) {
      history.clearRedo();
      history.canRedo = true;
    }
    return history.undo();
  }

  /// Gives pages from [first] on the page numbers they now sit at.
  void _renumberPagesFrom(int first) {
    final pages = coreInfo.pages;
    for (var i = first; i < pages.length; ++i) {
      pages[i].updatePageIndex(i);
    }
  }

  /// Turns the pages back to how they were before [change], leaving out
  /// the selection, repaint and save steps that [undo] adds.
  void _undoChange(Historic change) {
    final pages = coreInfo.pages;
    switch (change) {
      case HistoricGroup(:final changes):
        // newest part first
        for (final part in changes.reversed) {
          _undoChange(part);
        }

      case HistoricAdd(:final strokes, :final images):
        for (final stroke in strokes) {
          pages[stroke.pageIndex].strokes.remove(stroke);
        }
        for (final image in images) {
          pages[image.pageIndex].images.remove(image);
        }
        removeExcessPages();

      case HistoricDelete(:final strokes, :final images):
        for (final stroke in strokes) {
          createPage(stroke.pageIndex);
          pages[stroke.pageIndex].insertStroke(stroke);
        }
        for (final image in images) {
          createPage(image.pageIndex);
          pages[image.pageIndex].images.add(image);
          image.newImage = true;
        }

      case HistoricReplace(:final added, :final removed):
        for (final stroke in added) {
          pages[stroke.pageIndex].strokes.remove(stroke);
        }
        for (final stroke in removed) {
          createPage(stroke.pageIndex);
          pages[stroke.pageIndex].insertStroke(stroke);
        }

      case HistoricPageOrder(:final before):
        _applyPageOrder(before);

      case HistoricPageDelete(:final page, :final pageIndex, :final onlyPage):
        coreInfo.trash.remove(page);
        // the pages before it have to be there for it to go back in place
        createPage(pageIndex - 1);
        pages.insert(pageIndex, page);
        // The note's only page was deleted, and a blank one took its place:
        // the blank goes again (unless written on), or undoing left two.
        if (onlyPage && pages.length == 2 && pages[1].isEmpty) {
          pages.removeAt(1).dispose();
        }
        _renumberPagesFrom(pageIndex + 1);

      case HistoricPageInsert(:final pageIndex):
        final taken = pages.removeAt(pageIndex);
        // this is a page delete being redone: the page goes to the trash
        if (taken.wasTrashed) coreInfo.trash.add(taken);
        // never no page at all
        createPage(0);
        _renumberPagesFrom(pageIndex);

      case HistoricMove(:final offset, :final pageIndex, :final prevPageIndex):
        final back = Offset(-offset.left, -offset.top);
        final changedPage = pageIndex != prevPageIndex;
        for (final stroke in change.strokes) {
          stroke.shift(back);
          if (changedPage) moveStrokeToPage(stroke, pageIndex, prevPageIndex);
        }
        final select = Select.currentSelect;
        if (select.doneSelecting) {
          final result = select.selectResult;
          result.path = result.path.shift(back);
          if (changedPage) {
            result.pageIndexStart = prevPageIndex;
            result.pageIndex = prevPageIndex;
          }
        }
        for (final image in change.images) {
          final rect = image.dstRect;
          image.dstRect = .fromLTRB(
            rect.left - offset.left,
            rect.top - offset.top,
            rect.right - offset.right,
            rect.bottom - offset.bottom,
          );
          if (changedPage) moveImageToPage(image, pageIndex, prevPageIndex);
        }

      case HistoricTransform():
        final back = change.reverse();
        // the selection turns back with it only if it's what was turned
        final select = Select.currentSelect;
        if (select.doneSelecting &&
            !(back.strokes.every(select.selectResult.strokes.contains) &&
                back.images.every(select.selectResult.images.contains))) {
          select.unselect();
        }
        applyTransform(
          back.strokes,
          back.images,
          back.center,
          back.scale,
          back.angle,
        );

      case HistoricSvgEdit(:final image, :final svgBefore, :final sizeBefore):
        image.replaceSvg(svgBefore, sizeBefore);

      case HistoricReshape(:final strokes, :final before):
        for (final (i, stroke) in strokes.indexed) {
          stroke.reshapeLike(before[i]);
        }

      case HistoricReorder(:final pageIndex):
        final page = pages[pageIndex];
        page.strokes
          ..clear()
          ..addAll(change.strokesBefore);
        page.images
          ..clear()
          ..addAll(change.imagesBefore);

      case HistoricPageRotate(:final pageIndex, :final clockwise):
        _rotatePage(pageIndex, clockwise: !clockwise);

      case HistoricQuillChange(:final pageIndex):
        pages[pageIndex].quill.controller.undo();

      case HistoricQuillReverseChange(:final pageIndex):
        pages[pageIndex].quill.controller.redo();

      case HistoricColorChange(:final colorChanges):
        for (final MapEntry(key: stroke, value: colors)
            in colorChanges.entries) {
          stroke.color = colors.previous;
        }

      case HistoricBackgroundPatternChange(:final pageIndex):
        pages[pageIndex].backgroundPattern = change.change.previous;

      case HistoricPagesPatternChange(:final pageIndexes, :final before):
        for (final (i, pageIndex) in pageIndexes.indexed) {
          if (pageIndex < pages.length) {
            pages[pageIndex].backgroundPattern = before[i];
          }
        }
    }
  }

  /// Applies the newest undone change again.
  void redo() {
    if (!history.canRedo) return;
    undo(history.redo().reverse());
  }

  /// Which page is under [focalPoint] (a point on the screen), if any.
  int? onWhichPageIsFocalPoint(Offset focalPoint) {
    final pages = coreInfo.pages;
    for (var i = 0; i < pages.length; ++i) {
      final page = pages[i];
      final box = page.renderBox;
      if (box == null) continue;
      if ((Offset.zero & page.size).contains(box.globalToLocal(focalPoint))) {
        return i;
      }
    }
    return null;
  }

  /// Where the pointer was at the last draw event; a selection being
  /// dragged moves by the difference.
  Offset previousPosition = .zero;

  /// How far the selection has been dragged in this gesture so far, for
  /// the undo history.
  Offset moveOffset = .zero;

  /// Whether the pointer is over the page without touching it.
  var isHovering = true;

  /// The page the gesture being drawn started on.
  int? dragPageIndex;

  /// What the current pointer is (finger, pen, mouse...) and how hard it
  /// presses, as last reported.
  PointerDeviceKind? currentPointerKind;
  double? currentPressure;

  /// Decides whether a gesture that just started draws (or drags the
  /// selection) rather than scrolling and zooming the view.
  bool isDrawGesture(ScaleStartDetails details) {
    if (coreInfo.readOnly ||
        _readingMode ||
        _placing != null ||
        _stickyColor != null) {
      return false;
    }

    // any picture that was being edited lets go
    CanvasImage.activeListener.notifyListenersPlease();

    _lastSeenPointerCountTimer?.cancel();
    final fingers = details.pointerCount;
    // Still the end of a pinch: the fingers left as a zoom ends start the
    // gesture again one move later, too late for [lastSeenPointerCount] to
    // have caught them, and they mustn't draw either.
    if (lastSeenPointerCount >= 2 || (fingers < 2 && _hadMultiTouch)) {
      return false;
    }
    if (fingers >= 2) {
      // A pinch is starting. Whatever the first finger already drew is a
      // slip: take it back. This is decided by what was recorded, not by
      // [lastSeenPointerCount], which may have been reset by the time the
      // second finger moves (that left a dot under the zoom).
      if (_recordedThisGesture &&
          _drawnWithFinger &&
          stows.editorFingerDrawing.value &&
          (currentTool is Pen || currentTool is Eraser)) {
        _recordedThisGesture = false;
        final slip = history.removeAccidentalStroke();
        if (slip != null) undo(slip);
      }
      lastSeenPointerCount = fingers;
      return false;
    }
    lastSeenPointerCount = fingers;

    dragPageIndex = onWhichPageIsFocalPoint(details.focalPoint);
    if (dragPageIndex == null) return false;

    // typing mode: touches place the cursor, they never draw
    if (currentTool == Tool.textEditing) return false;
    // the selection (or a picture) can always be grabbed
    if (_touchesSelectable(details.focalPoint)) return true;

    final kind = currentPointerKind;
    final draws =
        stows.editorFingerDrawing.value ||
        kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus ||
        // pressure alone isn't enough: some fingers report it and still
        // only want to scroll
        (currentPressure != null && kind != PointerDeviceKind.touch);
    if (!draws) log.fine('Non-stylus found, rejected stroke');
    return draws;
  }

  /// With the lasso tool, a finger on a selection or picture moves it, even
  /// while a finger otherwise scrolls.
  bool _touchesSelectable(Offset focalPoint) {
    if (currentTool is! Select) return false;
    final page = coreInfo.pages[dragPageIndex!];
    final renderBox = page.renderBox;
    if (renderBox == null) return false;
    final position = renderBox.globalToLocal(focalPoint);
    final select = Select.currentSelect;
    if (select.doneSelecting &&
        select.selectResult.pageIndex == dragPageIndex &&
        (select.grabs(position) ||
            select.handleAt(
                  position,
                  _transformationController.value.approxScale,
                ) !=
                null)) {
      return true;
    }
    return _imageAt(page, position) != null;
  }

  /// Whether this stroke or erase is in the undo history, so that a second
  /// finger landing can take back the right thing.
  var _recordedThisGesture = false;

  /// A palm landing while a stylus writes isn't the start of a zoom.
  var _drawnWithFinger = false;

  /// The tools are shared, so a selection made beside this note isn't for it.
  static EditorState? _lastTouched;

  /// The note's canvas, for picking a color off it.
  final _pickKey = GlobalKey();

  /// Any touch in this editor, toolbar included, takes a selection away from
  /// the note beside it, whose toolbar could otherwise act on the wrong note.
  void _becomeActiveEditor() {
    final previous = _lastTouched;
    if (previous == this) return;
    _lastTouched = this;
    ScreenColorPicker.source = _pickKey;
    Select.currentSelect.unselect();
    if (previous != null && previous.mounted) previous.setState(() {});
    setState(() {});
  }

  void _shiftSelection(Select select, Offset offset) {
    for (final stroke in select.movingStrokes) {
      stroke.shift(offset);
    }
    for (final image in select.selectResult.images) {
      image.dstRect = image.dstRect.shift(offset);
    }
    select.selectResult.path = select.selectResult.path.shift(offset);
  }

  /// Keeps the selection under the finger at [focalPoint]. It moves over to
  /// whichever page the finger is on, in either scrolling direction.
  void _dragSelectionTo(Offset focalPoint) {
    final select = Select.currentSelect;
    final pageIndex = dragPageIndex;
    if (pageIndex == null) return;
    final page = coreInfo.pages[pageIndex];
    final renderBox = page.renderBox;
    if (renderBox == null) return;

    var position = renderBox.globalToLocal(focalPoint);
    var moved = position - previousPosition;
    _shiftSelection(select, moved);

    final target = onWhichPageIsFocalPoint(focalPoint);
    final targetBox = target == null ? null : coreInfo.pages[target].renderBox;
    if (target != null && target != pageIndex && targetBox != null) {
      final arrival = targetBox.globalToLocal(focalPoint);
      final jump = arrival - position;
      _shiftSelection(select, jump);
      selectionOffsetPage(select, target - pageIndex);
      dragPageIndex = target;
      position = arrival;
      moved += jump;
      coreInfo.pages[target].redrawStrokes();
    }
    previousPosition = position;
    moveOffset += moved;
    page.redrawStrokes();
  }

  /// Scrolls while a selection is held near the edge of the screen, so it can
  /// reach pages that aren't on screen.
  Timer? _autoScrollTimer;
  Offset _dragFocalPoint = .zero;

  void _autoScrollWhileDragging(Offset focalPoint) {
    _dragFocalPoint = focalPoint;
    _autoScrollTimer ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _autoScrollTick(),
    );
  }

  void _autoScrollTick() {
    final box = _canvasStackBox;
    if (box == null || !mounted) return;
    final horizontal = CanvasGestureDetector.horizontal;
    final local = box.globalToLocal(_dragFocalPoint);
    final along = horizontal ? local.dx : local.dy;
    final length = horizontal ? box.size.width : box.size.height;
    const edge = 70.0, topSpeed = 14.0;
    final double delta;
    if (along < edge) {
      delta = (edge - along) / edge * topSpeed;
    } else if (along > length - edge) {
      delta = -(along - (length - edge)) / edge * topSpeed;
    } else {
      return;
    }

    final matrix = _transformationController.value;
    final translation = matrix.getTranslation();
    final current = horizontal ? translation.x : translation.y;
    final scrollable =
        CanvasGestureDetector.getTopOfPage(
              pageIndex: coreInfo.pages.length,
              pages: coreInfo.pages,
              screenWidth: _canvasWidth,
            ) *
            matrix.approxScale -
        length;
    if (scrollable <= 0) return;
    final next = (current + delta).clamp(-scrollable, 0.0);
    if (next == current) return;
    _transformationController.value = matrix.clone()
      ..setTranslationRaw(
        horizontal ? next : translation.x,
        horizontal ? translation.y : next,
        translation.z,
      );
    _dragSelectionTo(_dragFocalPoint);
  }

  /// Lasso handle being dragged, see [Select.handleAt].
  SelectHandle? _selectHandle;

  /// For a picture's side and corner handles: see [Select.resizedImage].
  Offset _imageAnchor = .zero;
  Rect _imageStartRect = .zero;
  Offset _handleCenter = .zero;

  /// The selection's box when a side or corner started being dragged, as it
  /// is now, and what was in it before, for undo.
  Rect? _boxStart, _boxNow;

  /// The writing on a sticky note before its handle was dragged.
  List<Stroke> _attachedBefore = const [];
  List<Stroke> _boxStrokesBefore = const [];
  List<Rect> _boxImagesBefore = const [];

  /// The corner of a shape being dragged, see [Select.cornerAt], and the
  /// shape as it was before, for undo.
  int? _dragCorner;
  Stroke? _cornerBefore;
  double _handleScale = 1, _handleAngle = 0;

  /// Draw and hold: keeping the pen still snaps the ink to a shape, always
  /// with the shape tool, and if turned on with the ballpoint pen.
  Timer? _drawHoldTimer;
  Offset _drawHoldAnchor = .zero;
  var _drawHoldSnapped = false;

  /// The shape as it snapped, and where: moving the pen on before lifting
  /// it stretches a box, circle or triangle from its far corner (width and
  /// height each on their own), and grows and turns a line around its
  /// middle. Before, the shape stayed as it snapped until the pen lifted.
  Stroke? _heldShape;
  Offset _heldAt = .zero, _heldCenter = .zero;
  static var _toldHowToResize = false;

  void _armDrawHold(Offset position) {
    final tool = currentTool;
    final canSnap =
        (tool is ShapePen && ShapePen.kind == .auto) ||
        // every pen and the highlighter, not just the ball pen
        (tool is Pen && tool is! Tape && stows.penDrawAndHold.value);
    if (!canSnap) return;
    // small hand tremor doesn't count as moving
    final slop = 6 / _transformationController.value.approxScale;
    if ((_drawHoldTimer?.isActive ?? false) &&
        (position - _drawHoldAnchor).distance < slop) {
      return;
    }
    _drawHoldAnchor = position;
    _drawHoldTimer?.cancel();
    _drawHoldTimer = Timer(ShapePen.debounceDuration, _snapHeldStroke);
  }

  /// Scale, magnifier and timer from the toolbar's three dots.
  final _canvasStackKey = GlobalKey();
  Ruler? _ruler;
  int? _rulerEdge;
  var _zoomWindowOn = false;
  Offset _zoomWindowOrigin = .zero;
  int _zoomWindowPage = 0;

  /// True during a stroke in the zoom window, whose gesture details hold
  /// page coordinates rather than screen coordinates.
  var _drawingInZoomWindow = false;
  TimerSetup? _timer;
  StudyStopwatch? _stopwatch;

  /// Counts up, so starting the same timer again starts it afresh.
  var _timerRun = 0;

  /// The width pages are fitted to: less than the screen's in a split view or
  /// next to a vertical toolbar.
  double get _canvasWidth {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final box = _canvasStackBox;
    return box != null && box.hasSize ? box.size.width : screenWidth;
  }

  RenderBox? get _canvasStackBox =>
      _canvasStackKey.currentContext?.findRenderObject() as RenderBox?;

  /// Where a draw gesture at [focalPoint] lands on [page]: follows the ruler's
  /// edge if this stroke started next to it.
  Offset _drawPosition(EditorPage page, Offset focalPoint) {
    if (_drawingInZoomWindow) return focalPoint;
    final box = _canvasStackBox;
    final ruler = _ruler, edge = _rulerEdge;
    if (box == null || ruler == null || edge == null) {
      return page.renderBox!.globalToLocal(focalPoint);
    }
    final onRuler = ruler.project(box.globalToLocal(focalPoint), edge);
    ruler.updateMeasuring(onRuler);
    return page.renderBox!.globalToLocal(box.localToGlobal(onRuler));
  }

  void _toggleZoomWindow() {
    // it shows a share of the page's width, which on a board is far too much
    if (_isBoard) return;
    setState(() {
      if (_zoomWindowOn) {
        _zoomWindowOn = false;
        return;
      }
      // start at the top left of what's on screen
      _zoomWindowPage = currentPageIndex;
      final box = _canvasStackBox;
      final pageBox = coreInfo.pages[_zoomWindowPage].renderBox;
      _zoomWindowOrigin = box == null || pageBox == null
          ? .zero
          : pageBox.globalToLocal(box.localToGlobal(.zero));
      _zoomWindowOn = true;
    });
  }

  Widget _zoomWindowCanvas(int pageIndex, double zoom) {
    final page = coreInfo.pages[pageIndex];
    return InnerCanvas(
      pageIndex: pageIndex,
      redrawPageListenable: page,
      width: page.size.width,
      height: page.size.height,
      showPageIndicator: false,
      showTypedText: false,
      coreInfo: coreInfo,
      currentStroke: Pen.currentStroke?.page == page ? Pen.currentStroke : null,
      currentSelection: () {
        if (currentTool is! Select) return null;
        final selectResult = (currentTool as Select).selectResult;
        return selectResult.pageIndex == pageIndex ? selectResult : null;
      }(),
      currentToolIsSelect: false,
      currentScale: zoom,
    );
  }

  /// Whether this note shows two pages side by side.
  bool get _twoPagesHere =>
      !_isBoard && stows.twoPagesNotes.value.contains(coreInfo.filePath);

  /// Two pages to a row, like a book, staying on the current page.
  void _setTwoPages(bool on) {
    final pageIndex = currentPageIndex;
    final path = coreInfo.filePath;
    stows.twoPagesNotes.value = [
      for (final p in stows.twoPagesNotes.value)
        if (p != path) p,
      if (on) path,
    ];
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CanvasGestureDetector.scrollToPage(
        pageIndex: pageIndex,
        pages: coreInfo.pages,
        screenWidth: _canvasWidth,
        transformationController: _transformationController,
      );
    });
  }

  /// Pages in a row or a column, staying on the current page.
  void _setHorizontalScroll(bool horizontal) {
    final pageIndex = currentPageIndex;
    stows.editorHorizontalScroll.value = horizontal;
    CanvasGestureDetector.scrollToPage(
      pageIndex: pageIndex,
      pages: coreInfo.pages,
      screenWidth: _canvasWidth,
      transformationController: _transformationController,
    );
    setState(() {});
  }

  Timer? _longPressTimer;

  /// The picture, sticky note or shape under [globalPosition] that holding
  /// still there picks, unless the lasso is in use (it has its own menu).
  ({int pageIndex, Stroke? shape, EditorImage? image})? _heldPickable(
    Offset globalPosition,
  ) {
    if (currentTool is Select || currentTool is Eraser) return null;
    final pageIndex = onWhichPageIsFocalPoint(globalPosition);
    if (pageIndex == null) return null;
    final page = coreInfo.pages[pageIndex];
    final renderBox = page.renderBox;
    if (renderBox == null) return null;
    final position = renderBox.globalToLocal(globalPosition);
    final shape = _shapeAt(page, position);
    final image = shape == null ? _imageAt(page, position) : null;
    if (shape == null && image == null) return null;
    return (pageIndex: pageIndex, shape: shape, image: image);
  }

  /// Holding still on a picture, sticky note or shape picks it (a link
  /// opens); elsewhere on the page it offers a link, a comment or zoom right
  /// there. A pen's stroke that had just started is dropped: it was only the
  /// hold.
  Future<void> _onCanvasLongPress(Offset globalPosition) async {
    if (_toolsHidden) {
      final end = await showAppleDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End Go Live?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep going'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('End'),
            ),
          ],
        ),
      );
      if (end == true && mounted) _endLive();
      return;
    }
    if (!mounted ||
        coreInfo.readOnly ||
        _readingMode ||
        _placing != null ||
        _pointersDown != 1 ||
        currentTool is Eraser) {
      return;
    }
    final pageIndex = onWhichPageIsFocalPoint(globalPosition);
    if (pageIndex == null) return;
    final page = coreInfo.pages[pageIndex];
    final renderBox = page.renderBox;
    if (renderBox == null) return;
    final position = renderBox.globalToLocal(globalPosition);
    // pictures have their own long-press menu with the lasso
    if (currentTool is Select && _imageAt(page, position) != null) return;

    _tapDownAt = null;
    Pen.currentStroke = null;
    page.currentStrokeTick.value++;
    HapticFeedback.mediumImpact();

    // held still on a picture, sticky note or shape: picks it (a link opens)
    if (_heldPickable(globalPosition) case final held?) {
      final (:pageIndex, :shape, :image) = held;
      if (image is SvgEditorImage) {
        final bytes = await image.fileBytes();
        if (!mounted) return;
        final pin = bytes == null ? null : pinFromSvg(utf8.decode(bytes));
        if (pin != null) return _openPin(image, pin, editable: true);
      }
      final tool = currentTool;
      setState(() {
        if (tool is! Select) _toolBeforeTapEdit = tool;
        final lastNonEraserTool = _lastNonEraserTool;
        currentTool = Select.currentSelect;
        if (tool is Eraser) _lastNonEraserTool = lastNonEraserTool;
        if (shape != null) {
          _selectShape(shape, pageIndex);
        } else {
          _selectImage(image!, pageIndex);
        }
      });
      return;
    }

    await showAppleMenu(
      context,
      anchor: globalPosition & Size.zero,
      // a small menu at the finger: no grey over the whole page
      barrierColor: Colors.transparent,
      entries: [
        if (NoteClipboard.hasContent) ...[
          AppleMenuItem(
            'Paste here',
            icon: Icons.content_paste,
            onTap: () => _pasteFromNote(pageIndex: pageIndex, at: position),
          ),
          const AppleMenuDivider(),
        ],
        AppleMenuItem(
          'Add link',
          icon: Icons.link,
          onTap: () => _addPin(PinKind.link, pageIndex, position),
        ),
        AppleMenuItem(
          'Add comment',
          icon: Icons.add_comment_outlined,
          onTap: () => _addPin(PinKind.comment, pageIndex, position),
        ),
        AppleMenuItem(
          'Zoom here',
          icon: Icons.zoom_in,
          onTap: () => _openZoomWindowAt(pageIndex, position),
        ),
      ],
    );
  }

  void _openZoomWindowAt(int pageIndex, Offset position) {
    if (_isBoard) return;
    final page = coreInfo.pages[pageIndex];
    setState(() {
      _zoomWindowPage = pageIndex;
      _zoomWindowOrigin = Offset(
        (position.dx - page.size.width * 0.2).clamp(0.0, page.size.width),
        (position.dy - page.size.height * 0.03).clamp(0.0, page.size.height),
      );
      _zoomWindowOn = true;
    });
  }

  Future<void> _addPin(PinKind kind, int pageIndex, Offset position) async {
    final pin = await showPinEditor(context, kind);
    if (pin == null || !mounted) return;
    await _pickPhotos(
      [_PhotoInfo(utf8.encode(pinToSvg(pin)), '.svg')],
      (pageIndex: pageIndex, center: position),
      false,
    );
    if (mounted) setState(() {});
  }

  Future<void> _openPin(
    SvgEditorImage image,
    PagePin pin, {
    required bool editable,
  }) async {
    final action = await showPinDialog(context, pin, editable: editable);
    if (action == null || !mounted) return;
    switch (action) {
      case .delete:
        setState(() {
          coreInfo.pages[image.pageIndex].images.remove(image);
          history.recordChange(
            HistoricDelete(strokes: const [], images: [image]),
          );
        });
        autosaveAfterDelay();
      case .edit:
        final changed = await showPinEditor(context, pin.kind, pin);
        if (changed == null || !mounted) return;
        await _replaceSvg(image, pinToSvg(changed), pinSize(changed));
    }
  }

  /// Swaps [image]'s picture. As its own undo step, which is also what tells
  /// [autosaveAfterDelay] that there's something new to save.
  Future<void> _replaceSvg(SvgEditorImage image, String svg, Size size) async {
    final bytes = await image.fileBytes();
    if (bytes == null || !mounted) return;
    final sizeBefore = image.naturalSize;
    setState(() {
      image.replaceSvg(svg, size);
      if (Select.currentSelect.singleImage == image) {
        Select.currentSelect.selectResult.path = _imageOutline(image);
      }
      history.recordChange(
        HistoricSvgEdit(
          image: image,
          svgBefore: utf8.decode(bytes),
          sizeBefore: sizeBefore,
          svgAfter: svg,
          sizeAfter: size,
        ),
      );
    });
    autosaveAfterDelay();
  }

  /// Typing on the page: where a text box is being made or changed.
  ({int pageIndex, Offset at, SvgEditorImage? image, StickyNoteResult? note})?
  _textBox;

  /// Pictures waiting for a tap that says where they go.
  List<EditorImage>? _placing;

  /// The sticky note tool: a tap on the page adds a note of this color.
  Color? _stickyColor;
  var _stickyStyle = StickyNoteStyle.curl;

  void _toggleStickyTool() => setState(() {
    if (_stickyColor != null) {
      _stickyColor = null;
      return;
    }
    _placing = null;
    if (currentTool == Tool.textEditing) _toggleTextEditing();
    _stickyColor =
        stickyNoteColors[stows.lastStickyNoteColor.value.clamp(
          0,
          stickyNoteColors.length - 1,
        )];
  });

  /// The sticky note tool's bar: the 10 colors, and the note's design.
  Widget _stickyBar() => FloatingToolbar(
    defaultEdge: MediaQuery.sizeOf(context).width < 600
        ? ToolbarEdge.bottom
        : ToolbarEdge.top,
    builder: (context, axis) => Flex(
      direction: axis,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, color) in stickyNoteColors.indexed)
          ColorDot(
            color: color,
            selected: color == _stickyColor,
            onTap: () => setState(() {
              _stickyColor = color;
              stows.lastStickyNoteColor.value = i;
            }),
          ),
        BarDivider(axis: axis),
        Builder(
          builder: (chip) => ToolChip(
            tooltip: 'Design',
            icon: const Icon(Icons.style_outlined),
            onTap: () => showToolPanel(
              chip,
              anchor: rectOf(chip),
              page: PanelPage(
                title: 'Design',
                builder: (context, _) => Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final style in StickyNoteStyle.values)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _stickyStyle = style);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: style == _stickyStyle
                                  ? EditorUi.accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: SvgPicture.string(
                            stickyNoteToSvg(
                              StickyNoteResult('', _stickyColor, style: style),
                            ),
                            width: 64,
                            height: 64,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  /// With the text tool a tap on typed text picks it, as the lasso does
  /// (move, size, delete it); a second tap types in it, see [_onCanvasTap].
  /// A tap on a sticky note edits it. Otherwise a new text box starts right
  /// there, unless the page has older typed text to tap into.
  Future<void> _onTextToolTap(
    EditorPage page,
    int pageIndex,
    Offset position,
  ) async {
    final under = _imageAt(page, position);
    if (under is SvgEditorImage) {
      final bytes = await under.fileBytes();
      if (bytes == null || !mounted) return;
      final svg = utf8.decode(bytes);
      final pin = pinFromSvg(svg);
      if (pin != null) return _openPin(under, pin, editable: true);
      final note = stickyNoteFromSvg(svg);
      if (note != null && note.color == null) {
        // a tap opening the keyboard made text hard to move
        return setState(() {
          _toolBeforeTapEdit = currentTool;
          currentTool = Select.currentSelect;
          _selectImage(under, pageIndex);
        });
      }
      if (note != null) return _editNote(under, note, pageIndex);
    }
    if (!page.quill.controller.document.isEmpty()) return;
    _openTextBox(pageIndex, position);
  }

  void _openTextBox(
    int pageIndex,
    Offset at, {
    SvgEditorImage? image,
    StickyNoteResult? note,
  }) {
    final page = coreInfo.pages[pageIndex];
    final pageBox = page.renderBox, stackBox = _canvasStackBox;
    // where the view goes back to once the box is done, if it was lifted
    _viewBeforeTextBox = null;
    _viewLiftedForTextBox = null;
    if (pageBox != null && stackBox != null) {
      // above where the keyboard is about to come up, gliding there: the
      // page jumped up under the finger
      final y = stackBox.globalToLocal(pageBox.localToGlobal(at)).dy;
      final target = max(stackBox.size.height * 0.2, 90.0);
      if (y > target) {
        final translation = _transformationController.value.getTranslation();
        _viewBeforeTextBox = _transformationController.value.clone();
        final lifted = _viewLiftedForTextBox = _transformationController.value
            .clone()
          ..setTranslationRaw(
            translation.x,
            translation.y - (y - target),
            translation.z,
          );
        CanvasGestureDetector.glideTo(_transformationController, lifted);
      }
    }
    setState(() {
      if (image != null) page.images.remove(image); // retyped in its place
      _textBox = (pageIndex: pageIndex, at: at, image: image, note: note);
    });
  }

  Widget _textBoxOverlay() {
    final box = _textBox!;
    final page = coreInfo.pages[box.pageIndex];
    final image = box.image;
    final natural = image?.naturalSize.width ?? 0;
    final imageScale = image == null || natural == 0
        ? 1.0
        : image.dstRect.width / natural;
    double scale() {
      final pageBox = page.renderBox;
      if (pageBox == null) return 1;
      return (pageBox.localToGlobal(const Offset(1, 0)) -
                  pageBox.localToGlobal(Offset.zero))
              .dx *
          imageScale;
    }

    return TextBoxOverlay(
      inverted: InnerCanvas.invertsInk(
        page,
        coreInfo,
        Theme.brightnessOf(context),
      ),
      repositioned: _transformationController,
      position: () {
        final pageBox = page.renderBox, stackBox = _canvasStackBox;
        if (pageBox == null || stackBox == null) return Offset.zero;
        return stackBox.globalToLocal(pageBox.localToGlobal(box.at));
      },
      scale: scale,
      maxWidth: (page.size.width - box.at.dx) / imageScale,
      text: box.note?.text ?? '',
      format: box.note,
      onDone: (text, format) => _closeTextBox(text.trim(), format),
      liftBy: (dy) {
        final matrix = _transformationController.value.clone();
        final translation = matrix.getTranslation();
        _viewBeforeTextBox ??= _transformationController.value.clone();
        _transformationController.value = _viewLiftedForTextBox = matrix
          ..setTranslationRaw(translation.x, translation.y - dy, translation.z);
      },
    );
  }

  /// The view as it was before a text box lifted the page above the
  /// keyboard, and as the lifting left it.
  Matrix4? _viewBeforeTextBox, _viewLiftedForTextBox;

  Future<void> _closeTextBox(String text, TextFormat format) async {
    final box = _textBox!;
    // The page comes back down: lifted for the keyboard, it stayed up. Not
    // if the view was moved meanwhile: that would yank it away.
    final before = _viewBeforeTextBox, lifted = _viewLiftedForTextBox;
    _viewBeforeTextBox = _viewLiftedForTextBox = null;
    if (before != null && _transformationController.value == lifted) {
      CanvasGestureDetector.glideTo(_transformationController, before);
    }
    final page = coreInfo.pages[box.pageIndex];
    final image = box.image;
    final maxWidth = image == null
        ? page.size.width - box.at.dx
        : (page.size.width - box.at.dx) /
              (image.dstRect.width / image.naturalSize.width);
    final note = format.copyWith(
      text: text,
      color: () => null,
      maxWidth: maxWidth,
    );
    // unpinned, the text tool is put down once a box is done
    if (!stows.pinTextTool.value && currentTool == Tool.textEditing) {
      _toggleTextEditing();
    }
    setState(() {
      _textBox = null;
      if (image == null) return;
      // back from being retyped
      if (text.isEmpty) {
        history.recordChange(
          HistoricDelete(strokes: const [], images: [image]),
        );
      } else {
        page.images.add(image);
      }
    });
    if (image != null) {
      if (text.isEmpty) return autosaveAfterDelay();
      return _replaceSvg(image, stickyNoteToSvg(note), stickyNoteSize(note));
    }
    if (text.isEmpty) return;
    final size = stickyNoteSize(note);
    await _pickPhotos(
      [_PhotoInfo(utf8.encode(stickyNoteToSvg(note)), '.svg')],
      (pageIndex: box.pageIndex, center: box.at + size.center(Offset.zero)),
      false,
    );
    if (mounted) setState(() {});
  }

  /// The stroke of a shape at [position], if any.
  Stroke? _shapeAt(EditorPage page, Offset position) {
    final reach = 14 / _transformationController.value.approxScale;
    for (final stroke in page.strokes.reversed) {
      if (stroke.toolId != .shapePen) continue;
      if (stroke.touchedBy(position, position, reach) ||
          stroke.polylinePath.contains(position)) {
        return stroke;
      }
    }
    return null;
  }

  void _selectShape(Stroke shape, int pageIndex) {
    Select.currentSelect
      ..selectResult = SelectResult(
        pageIndex: pageIndex,
        strokes: [shape],
        images: [],
        path: Path()..addRect(shape.bounds.inflate(6)),
        pageIndexStart: pageIndex,
      )
      ..doneSelecting = true;
  }

  /// The tool to go back to after a picture or shape opened by a tap.
  Tool? _toolBeforeTapEdit;

  /// When ink was last added, to tell a tap from a dot in handwriting.
  DateTime _lastInkTime = DateTime(0);

  /// Whether a tap with [kind] using [tool] leaves a dot: a pen's tap is
  /// writing (the dot of an i, a full stop), and never picks a picture or
  /// shape; holding still does that. A finger writes only with finger
  /// drawing on.
  static bool _writes(Tool tool, PointerDeviceKind kind) =>
      tool is Pen &&
      tool is! ShapePen &&
      (kind != PointerDeviceKind.touch || stows.editorFingerDrawing.value);

  DateTime _lastTapTime = DateTime(0);
  Offset _lastTapPosition = .zero;

  Future<void> _editNoteText(SvgEditorImage image) async {
    final bytes = await image.fileBytes();
    if (bytes == null || !mounted) return;
    final note = stickyNoteFromSvg(utf8.decode(bytes));
    if (note == null) return; // an ordinary SVG picture
    return _editNote(image, note, image.pageIndex);
  }

  /// Text boxes are retyped on the page, sticky notes on a sheet of their color.
  Future<void> _editNote(
    SvgEditorImage image,
    StickyNoteResult note,
    int pageIndex,
  ) async {
    if (note.color == null) {
      Select.currentSelect.unselect();
      return _openTextBox(
        pageIndex,
        image.dstRect.topLeft,
        image: image,
        note: note,
      );
    }
    // typed right on the note, no sheet over the page
    final bytes = await image.fileBytes();
    if (bytes == null || !mounted || _noteTyping != null) return;
    Select.currentSelect.unselect();
    setState(() {
      _noteTyping = (
        image: image,
        note: note,
        pageIndex: pageIndex,
        svgBefore: utf8.decode(bytes),
        sizeBefore: image.naturalSize,
      );
      image.replaceSvg(
        stickyNoteToSvg(note, withText: false),
        stickyNoteSize(note),
      );
    });
  }

  /// A sticky note being typed on, see [NoteTextOverlay], and how it was.
  ({
    SvgEditorImage image,
    StickyNoteResult note,
    int pageIndex,
    String svgBefore,
    Size sizeBefore,
  })?
  _noteTyping;

  Widget _noteTypingOverlay() {
    final typing = _noteTyping!;
    final image = typing.image;
    final page = coreInfo.pages[typing.pageIndex];
    return NoteTextOverlay(
      repositioned: _transformationController,
      position: () {
        final pageBox = page.renderBox, stackBox = _canvasStackBox;
        if (pageBox == null || stackBox == null) return Offset.zero;
        return stackBox.globalToLocal(
          pageBox.localToGlobal(image.dstRect.topLeft),
        );
      },
      scale: () {
        final pageBox = page.renderBox;
        final natural = image.naturalSize.width;
        if (pageBox == null || natural == 0) return 1;
        return (pageBox.localToGlobal(const Offset(1, 0)) -
                    pageBox.localToGlobal(Offset.zero))
                .dx *
            image.dstRect.width /
            natural;
      },
      note: typing.note,
      onChanged: (text) {
        // the paper grows (or shrinks) with the lines typed
        final size = stickyNoteSize(typing.note.copyWith(text: text));
        if (size == image.naturalSize) return;
        setState(
          () => image.replaceSvg(
            stickyNoteToSvg(typing.note.copyWith(text: text), withText: false),
            size,
          ),
        );
      },
      onDone: (text) {
        final changed = typing.note.copyWith(text: text.trim());
        setState(() {
          _noteTyping = null;
          image.replaceSvg(typing.svgBefore, typing.sizeBefore);
        });
        if (changed.text == typing.note.text) return;
        unawaited(
          _replaceSvg(image, stickyNoteToSvg(changed), stickyNoteSize(changed)),
        );
      },
    );
  }

  void _editSelectionText() {
    final image = Select.currentSelect.singleImage;
    if (image is! SvgEditorImage) return;
    unawaited(_editNoteText(image));
  }

  int _pointersDown = 0;

  /// More than one finger has been down since all fingers were last up.
  var _hadMultiTouch = false;
  Offset? _tapDownAt;
  DateTime _tapDownTime = DateTime(0);

  void _onCanvasPointerDown(PointerDownEvent event) {
    if (currentTool is LaserPointer) LaserPointer.noteActivity();
    _pointersDown++;
    if (_pointersDown >= 2) _hadMultiTouch = true;
    _tapDownAt = _pointersDown == 1 ? event.position : null;
    _tapDownTime = DateTime.now();
    _longPressTimer?.cancel();
    if (_pointersDown == 1) {
      _recordedThisGesture = false;
      final position = event.position;
      _longPressTimer = Timer(
        // held on a picture or shape, it's picked sooner than the page menu
        _heldPickable(position) != null
            ? const Duration(milliseconds: 400)
            : const Duration(milliseconds: 600),
        () => _onCanvasLongPress(position),
      );
    }
  }

  void _onCanvasPointerMove(PointerMoveEvent event) {
    final start = _tapDownAt;
    if (start != null && (event.position - start).distance > 12) {
      _tapDownAt = null;
      _longPressTimer?.cancel();
    }
  }

  void _onCanvasPointerUp(PointerUpEvent event) {
    _longPressTimer?.cancel();
    _pointersDown = max(_pointersDown - 1, 0);
    if (_pointersDown == 0) _hadMultiTouch = false;
    final start = _tapDownAt;
    _tapDownAt = null;
    if (start == null ||
        DateTime.now().difference(_tapDownTime).inMilliseconds > 350) {
      return;
    }
    // after the gesture has finished, which ends any stroke the tap started
    final kind = event.kind;
    final position = event.position;
    unawaited(
      Future(() {
        if (mounted) unawaited(_onCanvasTap(position, kind));
      }),
    );
  }

  /// One tap on a picture or shape opens it for editing, whichever tool is in
  /// use. Tapping away goes back to that tool. A stylus using a pen is left
  /// alone: its taps are dots in handwriting.
  Future<void> _onCanvasTap(
    Offset globalPosition,
    PointerDeviceKind kind,
  ) async {
    final tool = currentTool;
    // that tap erased something, and that's all it was for
    if (tool is Eraser && _recordedThisGesture) return;
    final pageIndex = onWhichPageIsFocalPoint(globalPosition);
    if (pageIndex == null) return;
    final page = coreInfo.pages[pageIndex];
    final renderBox = page.renderBox;
    if (renderBox == null) return;
    final position = renderBox.globalToLocal(globalPosition);

    if (_stickyColor case final color? when !coreInfo.readOnly) {
      final note = StickyNoteResult('', color, style: _stickyStyle);
      setState(() => _stickyColor = null);
      unawaited(
        _pickPhotos(
          [_PhotoInfo(utf8.encode(stickyNoteToSvg(note)), '.svg')],
          (pageIndex: pageIndex, center: position),
        ),
      );
      return;
    }

    final placing = _placing;
    if (placing != null) {
      _placing = null;
      setState(() {
        for (final image in placing) {
          image.pageIndex = pageIndex;
          image.pageSize = page.size;
        }
        _putImages(placing, (pageIndex: pageIndex, center: position), true);
      });
      return;
    }

    final readOnly = coreInfo.readOnly || _readingMode;
    if (!readOnly && tool == Tool.textEditing) {
      // so a second tap on text it picked types in it
      _lastTapTime = DateTime.now();
      _lastTapPosition = globalPosition;
      return _onTextToolTap(page, pageIndex, position);
    }

    // a pen writing dots on a link isn't asking to open it
    final writing = _writes(tool, kind);
    final under = _imageAt(page, position);
    if (!writing && under is SvgEditorImage) {
      final bytes = await under.fileBytes();
      if (!mounted) return;
      final pin = bytes == null ? null : pinFromSvg(utf8.decode(bytes));
      if (pin != null) {
        return _openPin(under, pin, editable: !readOnly);
      }
    }
    if (readOnly) return;

    final now = DateTime.now();
    final isDoubleTap =
        now.difference(_lastTapTime).inMilliseconds < 400 &&
        (globalPosition - _lastTapPosition).distance < 30;
    _lastTapTime = isDoubleTap ? DateTime(0) : now;
    _lastTapPosition = globalPosition;
    // a finger's double tap types on a note; a pen's two taps are two dots
    if (isDoubleTap && !writing) {
      final tapped = _imageAt(page, position);
      if (tapped is SvgEditorImage) {
        unawaited(_editNoteText(tapped));
        return;
      }
    }

    if (tool is Tape) {
      // tapping a tape peeks under it instead
      final reach = 12 / _transformationController.value.approxScale;
      if (page.strokes.any(
        (stroke) =>
            stroke.toolId == .tape &&
            stroke.touchedBy(position, position, reach),
      )) {
        return;
      }
    }
    // A pen's tap on a picture or shape is a dot in the writing: holding
    // still picks it, see [_onCanvasLongPress].
    if (writing) return;

    final select = Select.currentSelect;
    if (tool is Select &&
        select.doneSelecting &&
        select.selectResult.pageIndex == pageIndex &&
        (select.grabs(position) ||
            select.handleAt(
                  position,
                  _transformationController.value.approxScale,
                ) !=
                null)) {
      return;
    }

    final shape = _shapeAt(page, position);
    // a finger's tap on a picture or sticky note does nothing: hold it to
    // pick it, or tap twice to type on it. The lasso picks it with a tap.
    final image = shape == null && tool is Select
        ? _imageAt(page, position)
        : null;
    setState(() {
      if (shape != null || image != null) {
        if (tool is! Select) _toolBeforeTapEdit = tool;
        final lastNonEraserTool = _lastNonEraserTool;
        currentTool = select;
        // the eraser's "last tool" stays what it was before the eraser
        if (tool is Eraser) _lastNonEraserTool = lastNonEraserTool;
        if (shape != null) {
          _selectShape(shape, pageIndex);
        } else {
          _selectImage(image!, pageIndex);
        }
      } else if (tool is Select && _toolBeforeTapEdit != null) {
        select.unselect();
        currentTool = _toolBeforeTapEdit!;
        _toolBeforeTapEdit = null;
      }
    });
  }

  Future<void> _showChangeShapeDialog() async {
    final select = Select.currentSelect;
    final kind = await showAppleDialog<ShapeKind>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Change shape'),
        children: [
          for (final kind in ShapeKind.values.where((kind) => kind != .auto))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, kind),
              child: Row(
                spacing: 12,
                children: [Icon(kind.icon), Text(kind.label)],
              ),
            ),
        ],
      ),
    );
    if (kind == null || !mounted || select.selectResult.strokes.length != 1) {
      return;
    }
    final old = select.selectResult.strokes.first;
    final page = coreInfo.pages[select.selectResult.pageIndex];
    final index = page.strokes.indexOf(old);
    if (index < 0) return;
    // in the old one's place in the drawing order
    final changed = ShapePen.changedTo(old, kind)..drawOrder = old.drawOrder;
    setState(() {
      page.strokes[index] = changed;
      _selectShape(changed, select.selectResult.pageIndex);
      history.recordChange(HistoricReplace(removed: [old], added: [changed]));
    });
    autosaveAfterDelay();
  }

  Future<void> _copyToOtherNote() async {
    final select = Select.currentSelect;
    if (!select.doneSelecting) return;
    final images = <({Uint8List bytes, String extension})>[];
    for (final image in select.selectResult.images) {
      final bytes = await image.fileBytes();
      if (bytes != null) images.add((bytes: bytes, extension: image.extension));
    }
    NoteClipboard.strokes = [
      for (final stroke in select.selectResult.strokes) stroke.copy(),
    ];
    NoteClipboard.images = images;
    // a pill offers Paste, here or in any other note (design 16)
    NoteClipboard.offered.value = NoteClipboard.hasContent;
  }

  /// Pastes what was copied, centred on [at] on page [pageIndex] (where the
  /// page was held), or in the middle of the screen.
  Future<void> _pasteFromNote({int? pageIndex, Offset? at}) async {
    if (coreInfo.readOnly || !NoteClipboard.hasContent) return;
    final spot = _visibleSpot();
    pageIndex ??= spot.pageIndex;
    final target = at ?? (pageIndex == spot.pageIndex ? spot.center : null);
    final page = coreInfo.pages[pageIndex];
    final copied = NoteClipboard.strokes;
    final from = copied.isEmpty
        ? null
        : copied
              .map((s) => s.bounds)
              .reduce((a, b) => a.expandToInclude(b))
              .center;
    final move = target == null || from == null ? Offset.zero : target - from;
    final strokes = [
      for (final stroke in copied)
        stroke.copy()
          ..pageIndex = pageIndex
          ..page = page
          ..shift(move),
    ];
    NoteClipboard.offered.value = false;
    if (strokes.isNotEmpty) {
      setState(() {
        strokes.forEach(page.insertStroke);
        history.recordChange(HistoricAdd(strokes: strokes, images: const []));
      });
      page.redrawStrokes();
      autosaveAfterDelay();
    }
    if (NoteClipboard.images.isNotEmpty) {
      await _pickPhotos([
        for (final image in NoteClipboard.images)
          _PhotoInfo(image.bytes, image.extension),
      ], target == null ? null : (pageIndex: pageIndex, center: target));
    }
  }

  void _toggleTape() {
    final tape = Tape.currentTape;
    setState(() => currentTool = currentTool == tape ? Pen.currentPen : tape);
  }

  List<PdfEditorImage> get _pdfPages => [
    for (final page in coreInfo.pages) ...[
      if (page.backgroundImage case final PdfEditorImage pdf) pdf,
      ...page.images.whereType<PdfEditorImage>(),
    ],
  ];

  void _setPdfDarkMode(bool darkMode) {
    setState(() {
      for (final pdf in _pdfPages) pdf.darkMode = darkMode;
    });
    autosaveAfterDelay();
  }

  Future<void> _showJumpToPageDialog() async {
    final total = coreInfo.pages.length;
    var typed = '';
    final page = await showAppleDialog<int>(
      context: context,
      builder: (context) {
        void submit() => Navigator.pop(context, int.tryParse(typed));
        return AlertDialog(
          title: const Text('Jump to page'),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.go,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(hintText: '1 - $total'),
            onChanged: (value) => typed = value,
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.common.cancel),
            ),
            TextButton(onPressed: submit, child: const Text('Go')),
          ],
        );
      },
    );
    if (page == null || !mounted) return;
    CanvasGestureDetector.scrollToPage(
      pageIndex: (page - 1).clamp(0, coreInfo.pages.length - 1),
      pages: coreInfo.pages,
      screenWidth: _canvasWidth,
      transformationController: _transformationController,
      glide: true,
    );
  }

  void _toggleRuler() {
    final size = _canvasStackBox?.size ?? Size.zero;
    setState(() => _ruler = _ruler == null ? Ruler(size.center(.zero)) : null);
  }

  Future<void> _toggleTimer() async {
    final setup = await showTimerDialog(context);
    if (setup == null || !mounted) return;
    if (setup.isStopwatch) {
      setState(() => _stopwatch ??= StudyStopwatch());
    } else {
      _startTimer(setup);
    }
  }

  void _startTimer(TimerSetup setup) => setState(() {
    _timer = setup;
    _timerRun++;
    // a break timer's time isn't focus time
    _stopwatch?.onBreak = setup.isBreak;
  });

  void _closeTimer() => setState(() {
    if (_timer?.isBreak ?? false) _stopwatch?.onBreak = false;
    _timer = null;
  });

  void _onTimerFinished() {
    if (!mounted) return;
    final wasBreak = _timer?.isBreak ?? false;
    _closeTimer();
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    showBanner(
      context,
      wasBreak ? 'Break over' : "Time's up",
      duration: const Duration(seconds: 10),
      actionLabel: wasBreak ? null : 'Break 5 min',
      onAction: () =>
          _startTimer(const TimerSetup(Duration(minutes: 5), isBreak: true)),
    );
  }

  void _snapHeldStroke() {
    final stroke = Pen.currentStroke;
    if (stroke == null || !stroke.isLongEnoughForShape()) return;
    final pageIndex = dragPageIndex;
    // A scribble over ink rubs it out when the pen lifts, even after a
    // pause: snapped, it became a zigzag shape over the writing it meant to
    // erase.
    if (pageIndex != null &&
        pageIndex < coreInfo.pages.length &&
        currentTool is! ShapePen &&
        _scribbledOut(stroke, coreInfo.pages[pageIndex]) != null) {
      return;
    }
    final shape = ShapePen.snapToShape(stroke);
    if (shape == null) return;

    Pen.currentStroke = shape;
    _drawHoldSnapped = true;
    _heldShape = shape.copy();
    _heldAt = _drawHoldAnchor;
    _heldCenter = shape.bounds.center;
    HapticFeedback.mediumImpact();
    // once a run, with a pen (the shape pen snaps on every hold)
    if (!_toldHowToResize && currentTool is! ShapePen) {
      _toldHowToResize = true;
      showBanner(
        context,
        'Shape: move the pen to stretch it',
        duration: const Duration(milliseconds: 1800),
      );
    }
    if (pageIndex != null && pageIndex < coreInfo.pages.length) {
      coreInfo.pages[pageIndex].currentStrokeTick.value++;
    }
    setState(() {});
  }

  /// The snapped shape grown and turned with the pen, see [_heldShape].
  void _resizeHeldShape(Offset position) {
    final held = _heldShape;
    if (held == null) return;
    // a hand's tremor while holding doesn't wobble the shape
    final slop = 6 / _transformationController.value.approxScale;
    if ((position - _heldAt).distance < slop) {
      Pen.currentStroke = held.copy();
      return;
    }
    // A box, circle or triangle stretches from the corner across from the
    // pen: its width and height follow the pen each on their own, like the
    // lasso's handles. Only a line grows and turns around its middle.
    final box = held.bounds;
    final minSide = 3 * held.options.size;
    if (box.width > minSide && box.height > minSide) {
      final corners = [box.topLeft, box.topRight, box.bottomLeft, box.bottomRight];
      Offset farthest(Offset from) => corners.reduce(
        (a, b) => (a - from).distanceSquared >= (b - from).distanceSquared ? a : b,
      );
      final anchor = farthest(_heldAt);
      final moving = farthest(anchor) + (position - _heldAt);
      // never flat: at least a few pen widths each way
      final dx = moving.dx - anchor.dx, dy = moving.dy - anchor.dy;
      final to = Rect.fromPoints(
        anchor,
        Offset(
          anchor.dx + (dx.abs() < minSide ? minSide * (dx < 0 ? -1 : 1) : dx),
          anchor.dy + (dy.abs() < minSide ? minSide * (dy < 0 ? -1 : 1) : dy),
        ),
      );
      final size = held.options.size;
      Pen.currentStroke = held.copy()
        ..mapRect(box, to)
        // the line stays as thick as it was
        ..options.size = size;
      return;
    }
    final from = _heldAt - _heldCenter, to = position - _heldCenter;
    if (from.distance < 1e-3 || to.distance < 1e-3) return;
    final scale = (to.distance / from.distance).clamp(0.2, 5.0);
    var angle = _wrapTurn(to.direction - from.direction);
    // nearly not turned: kept level, so a box stays square to the page
    if (angle.abs() < 8 * pi / 180) angle = 0;
    final size = held.options.size;
    Pen.currentStroke = held.copy()
      ..transform(_heldCenter, scale, angle)
      // the line stays as thick as it was
      ..options.size = size;
  }

  static double _wrapTurn(double angle) => atan2(sin(angle), cos(angle));

  /// What [LagRecorder] calls the tool in use.
  String get _toolForLag => switch (currentTool) {
    final Eraser _ => 'eraser ${Eraser.type.name}',
    final Tool tool => tool.toolId.name,
  };

  void onDrawStart(ScaleStartDetails details) {
    if (currentTool is Pen) _inkingAt.value = details.focalPoint;
    if (!LagRecorder.enabled) return _onDrawStart(details);
    LagRecorder.doing(_toolForLag);
    final page = dragPageIndex == null ? null : coreInfo.pages[dragPageIndex!];
    LagRecorder.pageStrokes = page?.strokes.length ?? 0;
    LagRecorder.noteStrokes = coreInfo.pages.fold(
      0,
      (sum, page) => sum + page.strokes.length,
    );
    LagRecorder.span('draw start', () => _onDrawStart(details));
  }

  void _onDrawStart(ScaleStartDetails details) {
    _drawnWithFinger = currentPointerKind == PointerDeviceKind.touch;
    audioNotes?.onStrokeStarted();
    InkCache.erasing.value = currentTool is Eraser;
    InkCache.penDown = true;
    EditorSignals.penDown();
    final page = coreInfo.pages[dragPageIndex!];
    final box = _canvasStackBox;
    _rulerEdge = currentTool is Pen && box != null && !_drawingInZoomWindow
        ? _ruler?.edgeNear(box.globalToLocal(details.focalPoint))
        : null;
    if (_rulerEdge != null && box != null) {
      _ruler!.startMeasuring(
        _ruler!.project(box.globalToLocal(details.focalPoint), _rulerEdge!),
      );
    }
    final position = _drawPosition(page, details.focalPoint);
    // what the toolbar shows, to only rebuild the editor if it changes
    final hadRedo = history.canRedo;
    final hadSelection = Select.currentSelect.doneSelecting;
    history.canRedo = false;
    _drawHoldTimer?.cancel();
    _drawHoldSnapped = false;
    _heldShape = null;
    _recordedThisGesture = false;

    final tool = currentTool;
    if (tool is Pen) {
      // a new stroke begins
      tool.onDragStart(position, page, dragPageIndex!, currentPressure);
    } else if (tool is Eraser) {
      // erasing starts at the very first touch, not on the first move
      final erased = tool.erase(
        page.strokes,
        position,
        position,
        _transformationController.value.approxScale,
        only: (stroke) => page.isLayerEditable(stroke.layer),
      );
      page.eraserRing = position;
      page.currentStrokeTick.value++;
      if (erased) {
        page.redrawStrokes();
        removeExcessPages();
      }
    } else if (tool is Select) {
      final select = tool;
      final onSelection =
          select.doneSelecting &&
          select.selectResult.pageIndex == dragPageIndex;
      final zoom = _transformationController.value.approxScale;
      final corner = onSelection ? select.cornerAt(position, zoom) : null;
      final handle = onSelection && !select.editingCorners
          ? select.handleAt(position, zoom)
          : null;
      if (corner != null) {
        // moving one corner of a shape; one undo step per drag
        _dragCorner = corner;
        _cornerBefore = select.singleShape!.copy();
      } else if (handle != null) {
        // resize/rotate by dragging a handle; one undo step per drag
        setState(() => _selectionBusy = true);
        _selectHandle = handle;
        final image = select.singleImage;
        // round the middle of what's picked, not of the loose lasso
        _handleCenter = image == null
            ? select.boxCenter
            : select.selectResult.path.getBounds().center;
        _attachedBefore = [for (final stroke in select.attached) stroke.copy()];
        if (image == null && handle != .rotate && handle != .scale) {
          // stretching strokes (and pictures) by a side or corner of the
          // box, which is level here
          _boxStart = select.box;
          _boxNow = _boxStart;
          _boxStrokesBefore = [
            for (final stroke in select.selectResult.strokes) stroke.copy(),
          ];
          _boxImagesBefore = [
            for (final image in select.selectResult.images) image.dstRect,
          ];
        } else if (image != null && handle != .rotate && handle != .scale) {
          final handles = Select.imageHandles(image);
          _imageStartRect = image.dstRect;
          _imageAnchor = handle == .bottom
              ? Select.imageTopCenter(image)
              : handle == .top
              ? Select.imageBottomCenter(image)
              : handles[switch (handle) {
                  .topLeft => SelectHandle.bottomRight,
                  .topRight => SelectHandle.bottomLeft,
                  .bottomRight => SelectHandle.topLeft,
                  .bottomLeft => SelectHandle.topRight,
                  .left => SelectHandle.right,
                  _ => SelectHandle.left,
                }]!;
        }
        _handleScale = 1;
        _handleAngle = 0;
      } else if (!(select.doneSelecting &&
              select.selectResult.pageIndex == dragPageIndex! &&
              select.grabs(position)) &&
          _imageAt(page, position) != null) {
        // touching a picture selects it: then drag to move, corner handle
        // to resize, top handle to rotate (same as a lasso selection)
        _selectImage(_imageAt(page, position)!, dragPageIndex!);
        history.canRedo = true; // selection doesn't affect history
      } else if (select.doneSelecting &&
          select.selectResult.pageIndex == dragPageIndex! &&
          select.grabs(position)) {
        // drag selection in onDrawUpdate; its bar goes while it moves
        setState(() => _selectionBusy = true);
      } else {
        select.onDragStart(position, dragPageIndex!);
        history.canRedo = true; // selection doesn't affect history
      }
    } else if (tool is LaserPointer) {
      tool.onDragStart(position, page, dragPageIndex!);
    }

    // a fresh gesture: nothing dragged yet
    previousPosition = position;
    moveOffset = .zero;

    // any other tool ends a lasso selection
    if (currentTool is! Select) Select.currentSelect.unselect();

    // The stroke being drawn shows on its own layer, see
    // [CurrentStrokePainter]. Rebuilding the editor on every pen down rebuilt
    // every visible page, which showed as a hitch at the start of each stroke.
    page.currentStrokeTick.value++;
    final pen = currentTool is Pen || currentTool is Eraser;
    if (!pen || hadRedo || hadSelection || _rulerEdge != null) setState(() {});
  }

  void onDrawUpdate(ScaleUpdateDetails details) =>
      LagRecorder.span('draw move', () => _onDrawUpdate(details));

  void _onDrawUpdate(ScaleUpdateDetails details) {
    if (_inkingAt.value != null) _inkingAt.value = details.focalPoint;
    audioNotes?.onPointAdded();
    if (dragPageIndex == null) {
      return;
    }
    final page = coreInfo.pages[dragPageIndex!];
    Offset position = _drawPosition(page, details.focalPoint);
    Offset offset = position - previousPosition;

    if (currentTool is Pen) {
      if (!_drawHoldSnapped) {
        (currentTool as Pen).onDragUpdate(position, currentPressure);
        _armDrawHold(position);
        page.currentStrokeTick.value++;
      } else {
        _resizeHeldShape(position);
        page.currentStrokeTick.value++;
      }
    } else if (currentTool is Eraser) {
      final erased = (currentTool as Eraser).erase(
        page.strokes,
        previousPosition,
        position,
        _transformationController.value.approxScale,
        only: (stroke) => page.isLayerEditable(stroke.layer),
      );
      page.eraserRing = position;
      page.currentStrokeTick.value++;
      // the ring is on its own layer: the ink only repaints if it changed
      if (erased) {
        page.redrawStrokes();
        removeExcessPages();
      }
    } else if (currentTool is Select && _dragCorner != null) {
      final select = currentTool as Select;
      final shape = select.singleShape;
      if (shape != null) {
        ShapePen.moveCorner(shape, _dragCorner!, position);
        select.selectResult.path = Path()..addRect(shape.bounds.inflate(6));
        page.redrawStrokes();
      }
    } else if (currentTool is Select &&
        _selectHandle != null &&
        _boxStart != null) {
      final select = currentTool as Select;
      final next = Select.resizedBox(_boxStart!, _selectHandle!, position);
      final from = _boxNow!;
      for (final stroke in select.selectResult.strokes) {
        stroke.mapRect(from, next);
      }
      for (final image in select.selectResult.images) {
        image.dstRect = Rect.fromPoints(
          Stroke.mapPoint(image.dstRect.topLeft, from, next),
          Stroke.mapPoint(image.dstRect.bottomRight, from, next),
        );
      }
      final sx = from.width == 0 ? 1.0 : next.width / from.width;
      final sy = from.height == 0 ? 1.0 : next.height / from.height;
      select.selectResult.path = select.selectResult.path.transform(
        (Matrix4.identity()
              ..translateByDouble(next.left, next.top, 0, 1)
              ..scaleByDouble(sx, sy, 1, 1)
              ..translateByDouble(-from.left, -from.top, 0, 1))
            .storage,
      );
      _boxNow = next;
      page.redrawStrokes();
    } else if (currentTool is Select && _selectHandle != null) {
      final select = currentTool as Select;
      final c = _handleCenter;
      final strokes = select.movingStrokes;
      final images = select.selectResult.images;
      final image = select.singleImage;
      if (image != null &&
          _selectHandle != .rotate &&
          _selectHandle != .scale) {
        final before = image.dstRect;
        image.dstRect = Select.resizedImage(
          image: image,
          handle: _selectHandle!,
          anchor: _imageAnchor,
          startSize: _imageStartRect.size,
          position: position,
        );
        // the writing on a sticky note grows and shrinks with it
        for (final stroke in select.attached) {
          stroke.mapRect(before, image.dstRect);
        }
        select.selectResult.path = _imageOutline(image);
      } else if (_selectHandle == SelectHandle.scale) {
        final d0 = (previousPosition - c).distance;
        final d1 = (position - c).distance;
        if (d0 > 1 && d1 > 1) {
          final f = (d1 / d0).clamp(0.5, 2.0);
          applyTransform(strokes, images, c, f, 0);
          _handleScale *= f;
        }
      } else {
        final a = (position - c).direction - (previousPosition - c).direction;
        applyTransform(strokes, images, c, 1, a);
        _handleAngle += a;
      }
      page.redrawStrokes();
    } else if (currentTool is Select) {
      final select = currentTool as Select;
      if (select.doneSelecting) {
        _dragSelectionTo(details.focalPoint);
        _autoScrollWhileDragging(details.focalPoint);
        return;
      }
      select.onDragUpdate(position);
      page.redrawStrokes();
    } else if (currentTool is LaserPointer) {
      (currentTool as LaserPointer).onDragUpdate(position);
      // only the line being drawn, like a pen: not the whole page on every move
      page.currentStrokeTick.value++;
    }
    previousPosition = position;
    moveOffset += offset;
  }

  /// Whether something can go from page [from] to a different page [to]:
  /// both have to be real pages of this note.
  bool _canMoveBetween(int from, int to) {
    final count = coreInfo.pages.length;
    return from != to && from >= 0 && from < count && to >= 0 && to < count;
  }

  /// Takes [stroke] off page [pageIndexOrig] and puts it on page
  /// [pageIndexDest]. Returns false, and leaves it, if either page doesn't
  /// exist or they are the same page.
  bool moveStrokeToPage(Stroke stroke, int pageIndexOrig, int pageIndexDest) {
    if (!_canMoveBetween(pageIndexOrig, pageIndexDest)) return false;
    final target = coreInfo.pages[pageIndexDest];
    coreInfo.pages[pageIndexOrig].strokes.remove(stroke);
    stroke
      ..pageIndex = pageIndexDest
      ..page = target;
    target.insertStroke(stroke);
    return true;
  }

  /// Like [moveStrokeToPage], for a picture.
  bool moveImageToPage(
    EditorImage image,
    int pageIndexOrig,
    int pageIndexDest,
  ) {
    if (!_canMoveBetween(pageIndexOrig, pageIndexDest)) return false;
    coreInfo.pages[pageIndexOrig].images.remove(image);
    image.pageIndex = pageIndexDest;
    coreInfo.pages[pageIndexDest].images.add(image);
    return true;
  }

  /// Scales/rotates [strokes] and [images] around [center],
  /// and keeps the lasso outline in sync if something is selected.
  void applyTransform(
    List<Stroke> strokes,
    List<EditorImage> images,
    Offset center,
    double scale,
    double angle,
  ) {
    for (final stroke in strokes) {
      stroke.transform(center, scale, angle);
    }
    for (final image in images) {
      final newCenter = Stroke.transformPoint(
        image.dstRect.center,
        center,
        scale,
        angle,
      );
      image.dstRect = Rect.fromCenter(
        center: newCenter,
        width: image.dstRect.width * scale,
        height: image.dstRect.height * scale,
      );
      image.rotation += angle;
    }
    final select = Select.currentSelect;
    if (select.doneSelecting) {
      final m = Matrix4.identity()
        ..translateByDouble(center.dx, center.dy, 0, 1)
        ..rotateZ(angle)
        ..scaleByDouble(scale, scale, 1, 1)
        ..translateByDouble(-center.dx, -center.dy, 0, 1);
      select.selectResult.path = select.selectResult.path.transform(m.storage);
      // The box turns with it, here where every turn goes through: undoing
      // one turned the ink back but left the box at its angle.
      if (select.singleImage == null) select.angle += angle;
    }
  }

  /// Splits each highlighter the lasso picked that the eraser had cut and
  /// that runs out of the lasso: the part inside stays picked, the part
  /// outside stays put. One undo step.
  void _splitCutHighlighters(EditorPage page, Select select) {
    final polygon = select.lassoPolygon;
    final picked = select.selectResult.strokes;
    final removed = <Stroke>[], added = <Stroke>[];
    for (final (i, stroke) in [...picked].indexed) {
      final pieces = Select.splitAtLasso(stroke, polygon);
      if (pieces == null) continue;
      final (inside, outside) = pieces;
      final at = page.strokes.indexOf(stroke);
      if (at < 0) continue;
      // the inside piece after: the outside piece's holes are cleared first
      page.strokes.replaceRange(at, at + 1, [outside, inside]);
      picked[i] = inside;
      removed.add(stroke);
      added.addAll([outside, inside]);
    }
    if (removed.isEmpty) return;
    history.recordChange(HistoricReplace(removed: removed, added: added));
    page.redrawStrokes();
    autosaveAfterDelay();
  }

  /// Resize/rotate the current lasso selection (GoodNotes-style).
  void transformSelection({double scale = 1, double angle = 0}) {
    final select = currentTool as Select;
    if (!select.doneSelecting || select.selectResult.isEmpty) return;
    final center = select.boxCenter;
    final strokes = select.selectResult.strokes;
    final images = select.selectResult.images;
    setState(() {
      applyTransform(strokes, images, center, scale, angle);
      history.recordChange(
        HistoricTransform(
          strokes: strokes,
          images: images,
          center: center,
          scale: scale,
          angle: angle,
        ),
      );
    });
    autosaveAfterDelay();
  }

  /// Carries everything in [select] [pageOffset] pages on (back, if
  /// negative). Nothing happens when either end is off the note.
  void selectionOffsetPage(Select select, int pageOffset) {
    final result = select.selectResult;
    final from = result.pageIndex;
    final to = from + pageOffset;
    final last = coreInfo.pages.length - 1;
    if (from < 0 || from > last || to < 0 || to > last) return;

    final strokes = select.movingStrokes;
    final images = result.images;
    setState(() {
      for (final stroke in strokes) {
        moveStrokeToPage(stroke, from, to);
      }
      for (final image in images) {
        moveImageToPage(image, from, to);
      }
      result.pageIndex += pageOffset;
    });
  }

  void onDrawEnd(ScaleEndDetails details) {
    _inkingAt.value = null;
    if (!LagRecorder.enabled) return _onDrawEnd(details);
    final tool = _toolForLag;
    LagRecorder.span('lift', () => _onDrawEnd(details));
    LagRecorder.doing('after $tool', lasts: const Duration(seconds: 1));
  }

  /// Whether the selection is being moved, turned or resized now.
  var _selectionBusy = false;

  void _onDrawEnd(ScaleEndDetails details) {
    LagRecorder.step('stroke end');
    LagRecorder.note('pen pressure', {
      ...PointerPressureLog.take(),
      'low': _pressureLow.isFinite ? _pressureLow : null,
      'high': _pressureHigh >= 0 ? _pressureHigh : null,
      'none': _pressureNulls,
    });
    _pressureLow = double.infinity;
    _pressureHigh = -1;
    _pressureNulls = 0;
    if (_selectionBusy) setState(() => _selectionBusy = false);
    InkCache.erasing.value = false;
    InkCache.penDown = false;
    EditorSignals.penUp();
    _rulerEdge = null;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (dragPageIndex == null) {
      return;
    }
    final page = coreInfo.pages[dragPageIndex!];
    if (page.eraserRing != null) {
      page.eraserRing = null;
      page.currentStrokeTick.value++;
    }
    bool shouldSave = true;
    _drawHoldTimer?.cancel();
    // what the toolbar and page list show, to only rebuild if it changes
    final pageCount = coreInfo.pages.length;
    final couldUndo = history.canUndo, couldRedo = history.canRedo;
    final tool = currentTool;
    void finish() {
      if (tool is Pen) {
        var newStroke = tool.onDragEnd();
        // a lift with nothing drawn (or nothing left of it) adds nothing
        if (newStroke == null || newStroke.isEmpty) return;

        // Draw shapes: a clean shape the moment the pen lifts, no hold (that's
        // Draw & hold, for the pens). Left as drawn if it isn't one.
        if (tool is ShapePen &&
            ShapePen.kind == .auto &&
            !_drawHoldSnapped &&
            newStroke.isLongEnoughForShape()) {
          final shape = ShapePen.snapToShape(newStroke);
          if (shape != null) {
            newStroke = shape;
            HapticFeedback.lightImpact();
          }
        }

        final tiny =
            newStroke.bounds.deflate(newStroke.options.size / 2).longestSide <
            8 / _transformationController.value.approxScale;
        // a dot on a picture or shape is writing too: holding still picks
        // it instead, see [_onCanvasLongPress]
        if (tiny && currentTool is ShapePen && ShapePen.kind != .auto) {
          shouldSave = false;
          return;
        }

        if (currentTool is Tape) {
          final line = newStroke.centerPoints;
          final reach = 12 / _transformationController.value.approxScale;
          final drawn = newStroke.bounds.deflate(newStroke.options.size / 2);
          if (drawn.longestSide >= reach) {
            newStroke.straightenIfNearlyStraight();
          } else {
            // a tap peeks under the tape, and doesn't leave a tiny strip
            shouldSave = false;
            for (final tape in page.strokes.reversed) {
              if (tape.toolId != .tape) continue;
              if (!tape.touchedBy(line.first, line.first, reach)) continue;
              tape.tapeRevealed = !tape.tapeRevealed;
              page.redrawStrokes();
              break;
            }
            return;
          }
        }

        final erased = _drawHoldSnapped ? null : _scribbledOut(newStroke, page);
        if (erased != null) {
          page.strokes.removeWhere(erased.contains);
          page.redrawStrokes();
          removeExcessPages();
          history.recordChange(HistoricDelete(strokes: erased, images: []));
          return;
        }

        if (stows.circleToLasso.value &&
            !_drawHoldSnapped &&
            currentTool is! ShapePen &&
            currentTool is! Tape &&
            currentTool is! Highlighter &&
            _lassoFromLoop(newStroke, page)) {
          return;
        }

        if (stows.autoStraightenLines.value &&
            currentTool is! ShapePen &&
            currentTool is! Tape &&
            !_drawHoldSnapped &&
            newStroke.isStraightLine()) {
          newStroke.convertToLine();
        }

        createPage(newStroke.pageIndex);
        newStroke.layer = page.activeLayer;
        // after a picture or text box: drawn over it, as writing keeps the
        // order it was done in
        newStroke.onFrontImage = page.drawsOverFrontImages(newStroke);
        // over every picture and text box put on before it, under later ones
        newStroke.afterImage = newStroke.toolId == .tape
            ? -1
            : page.latestFrontOrder(newStroke.layer);
        // kept in the order it was drawn, shapes too
        newStroke.nib2 = true;
        page.insertStroke(newStroke);
        // the finished stroke moves off the current-stroke layer. Nothing else
        // repaints the page for it, so it could vanish until the next repaint.
        page.redrawStrokes();
        audioNotes?.onStrokeAdded(newStroke);
        history.recordChange(HistoricAdd(strokes: [newStroke], images: []));
        _recordedThisGesture = true;
        _lastInkTime = DateTime.now();
      } else if (tool is Eraser) {
        final change = tool.onDragEnd();
        // erasing with the pen's button, or with the one-shot eraser
        // setting on: the tool from before comes back on lift
        final backToTool =
            stylusButtonWasPressed || stows.disableEraserAfterUse.value;
        if (backToTool) {
          stylusButtonWasPressed = false;
          currentTool = _lastNonEraserTool;
        }
        if (change != null) {
          history.recordChange(change);
          _recordedThisGesture = true;
        }
      } else if (tool is Select && _dragCorner != null) {
        final shape = tool.singleShape;
        final before = _cornerBefore;
        _dragCorner = null;
        _cornerBefore = null;
        if (shape != null && before != null) {
          history.recordChange(
            HistoricReplace(removed: [before], added: [shape]),
          );
        }
      } else if (tool is Select &&
          _selectHandle != null &&
          _boxStart != null) {
        final select = tool;
        final start = _boxStart!;
        final strokesBefore = _boxStrokesBefore;
        final imagesBefore = _boxImagesBefore;
        final moved = _boxNow != start;
        _selectHandle = null;
        _boxStart = _boxNow = null;
        _boxStrokesBefore = const [];
        _boxImagesBefore = const [];
        if (!moved) return;
        final page = coreInfo.pages[select.selectResult.pageIndex];
        // Reshaped in place: swapping in copies left changes recorded
        // before this one looking for strokes no longer on the page, so
        // undoing two stretches left both the old and the new strokes.
        final strokes = List.of(select.selectResult.strokes);
        final images = select.selectResult.images;
        history.recordChange(
          HistoricGroup([
            if (strokes.isNotEmpty)
              HistoricReshape(
                strokes: strokes,
                before: strokesBefore,
                after: [for (final stroke in strokes) stroke.copy()],
              ),
            for (final (i, image) in images.indexed)
              HistoricMove(
                pageIndex: select.selectResult.pageIndex,
                prevPageIndex: select.selectResult.pageIndex,
                strokes: const [],
                images: [image],
                offset: Rect.fromLTRB(
                  image.dstRect.left - imagesBefore[i].left,
                  image.dstRect.top - imagesBefore[i].top,
                  image.dstRect.right - imagesBefore[i].right,
                  image.dstRect.bottom - imagesBefore[i].bottom,
                ),
              ),
          ]),
        );
        page.redrawStrokes();
        autosaveAfterDelay();
        return;
      } else if (tool is Select && _selectHandle != null) {
        final select = tool;
        final handle = _selectHandle;
        _selectHandle = null;
        final image = select.singleImage;
        if (image != null && handle != .rotate && handle != .scale) {
          final r = image.dstRect, start = _imageStartRect;
          final move = HistoricMove(
            pageIndex: select.selectResult.pageIndex,
            prevPageIndex: select.selectResult.pageIndex,
            strokes: const [],
            images: [image],
            offset: .fromLTRB(
              r.left - start.left,
              r.top - start.top,
              r.right - start.right,
              r.bottom - start.bottom,
            ),
          );
          final attached = select.attached;
          if (attached.isEmpty) {
            history.recordChange(move);
            return;
          }
          // the note's writing, stretched with it, reshaped in place
          final page = coreInfo.pages[select.selectResult.pageIndex];
          history.recordChange(
            HistoricGroup([
              move,
              HistoricReshape(
                strokes: List.of(attached),
                before: _attachedBefore,
                after: [for (final stroke in attached) stroke.copy()],
              ),
            ]),
          );
          page.redrawStrokes();
          return;
        }
        history.recordChange(
          HistoricTransform(
            strokes: select.movingStrokes,
            images: select.selectResult.images,
            center: _handleCenter,
            scale: _handleScale,
            angle: _handleAngle,
          ),
        );
      } else if (tool is Select) {
        final select = tool;
        final result = select.selectResult;
        if (select.doneSelecting) {
          // a drag of the selection: one undo step for the whole move,
          // which may have crossed onto another page
          final shift = moveOffset;
          if (shift == .zero) return;
          history.recordChange(
            HistoricMove(
              pageIndex: result.pageIndex,
              prevPageIndex: result.pageIndexStart!,
              strokes: select.movingStrokes,
              images: result.images,
              offset: .fromLTRB(shift.dx, shift.dy, shift.dx, shift.dy),
            ),
          );
          result.pageIndexStart = result.pageIndex;
        } else {
          // the lasso was just drawn: pick up what it closes round. Nothing
          // on the page changed, so there's nothing to save
          shouldSave = false;
          select.onDragEnd(
            page.strokes
                .where((stroke) => page.isLayerEditable(stroke.layer))
                .toList(),
            page.images
                .where((image) => page.isLayerEditable(image.layer))
                .toList(),
          );
          _splitCutHighlighters(page, select);

          if (select.selectResult.isEmpty) {
            Select.currentSelect.unselect();
          }
        }
      } else if (tool is LaserPointer) {
        // laser lines fade away by themselves and are never saved
        shouldSave = false;
        final trail = tool.onDragEnd(
          page.redrawStrokes,
          (Stroke faded) => page.laserStrokes.remove(faded),
        );
        if (trail != null) page.laserStrokes.add(trail);
        // the dot goes as soon as the pen lifts
        page.currentStrokeTick.value++;
        page.redrawStrokes();
      }
    }

    if (tool is Pen || tool is Eraser) {
      // Writing doesn't rebuild the editor: that rebuilt every visible page
      // at the end of each stroke. The ink repaints by itself.
      finish();
      page.currentStrokeTick.value++;
      if (coreInfo.pages.length != pageCount ||
          history.canUndo != couldUndo ||
          history.canRedo != couldRedo ||
          currentTool != tool) {
        setState(() {});
      }
    } else {
      setState(finish);
    }

    if (shouldSave) autosaveAfterDelay();
  }

  void onInteractionEnd(ScaleEndDetails details) {
    // once a swipe has settled, the page it's on fills the frame
    if (_live == .wholePage) {
      Timer(const Duration(milliseconds: 400), _fitLivePage);
    }
    // forget the finger count shortly after, so the next gesture starts
    // fresh but the rest of this one still counts as the same gesture
    _lastSeenPointerCountTimer?.cancel();
    _lastSeenPointerCountTimer = Timer(
      const Duration(milliseconds: 10),
      () => lastSeenPointerCount = 0,
    );
  }

  /// Undo, as in other notes apps. With finger drawing on, the first finger
  /// may have left a dot or started a line: that goes first, silently.
  void _onTwoFingerTap() {
    if (Pen.currentStroke != null) {
      final page = Pen.currentStroke!.page;
      Pen.currentStroke = null;
      if (page is EditorPage) page.currentStrokeTick.value++;
    }
    if (_recordedThisGesture &&
        _drawnWithFinger &&
        DateTime.now().difference(_lastInkTime) <
            const Duration(milliseconds: 600)) {
      _recordedThisGesture = false;
      final item = history.removeAccidentalStroke();
      if (item != null) undo(item);
    }
    HapticFeedback.selectionClick();
    undo();
  }

  /// Called for every pointer event on the canvas with what is touching it
  /// and how hard. [isDrawGesture] and the pens read these.
  void updatePointerData(PointerDeviceKind kind, double? pressure) {
    currentPointerKind = kind;
    currentPressure = pressure;
    // for the lag build's report: whether the pen gives any pressure
    if (pressure == null) {
      _pressureNulls++;
    } else {
      _pressureLow = min(_pressureLow, pressure);
      _pressureHigh = max(_pressureHigh, pressure);
    }
  }

  var _pressureLow = double.infinity, _pressureHigh = -1.0;
  var _pressureNulls = 0;

  /// A pen is held just above the screen.
  void onHovering() {
    isHovering = true;
    if (currentTool is LaserPointer) LaserPointer.noteActivity();
  }

  /// The pen moved away from the screen, or touched it.
  void onHoveringEnd() {
    isHovering = false;
  }

  /// The pen's side button went down or up. Held while hovering, it swaps
  /// in the tool picked for it in settings until it is let go; pressed
  /// while writing, it only marks the stroke (see [stylusButtonWasPressed]).
  void onStylusButtonChanged(bool buttonIsPressed) {
    stylusButtonWasPressed |= buttonIsPressed;

    if (!buttonIsPressed && _toolBeforeStylusButton != null) {
      _restoreAfterStylusButton();
      if (mounted) setState(() {});
      return;
    }
    if (!isHovering) return;
    if (buttonIsPressed) {
      // held while hovering: the tool chosen in settings, until released
      final Tool tool = switch (stows.stylusButtonTool.value) {
        1 => Select.currentSelect,
        2 => Highlighter.currentHighlighter,
        _ => Eraser(),
      };
      if (currentTool.toolId != tool.toolId) {
        _toolBeforeStylusButton = currentTool;
        currentTool = tool;
      }
    }

    if (mounted) setState(() {});
  }

  /// A picture was dragged by [offset]: one undo step.
  void onMoveImage(EditorImage image, Rect offset) {
    final page = image.pageIndex;
    history.recordChange(
      HistoricMove(
        pageIndex: page,
        prevPageIndex: page,
        strokes: [],
        images: [image],
        offset: offset,
      ),
    );
    setState(() {}); // the undo button may have just become usable
    autosaveAfterDelay();
  }

  /// A picture's own delete button was used.
  void onDeleteImage(EditorImage image) {
    history.recordChange(HistoricDelete(strokes: [], images: [image]));
    final page = coreInfo.pages[image.pageIndex];
    setState(() => page.images.remove(image));
    autosaveAfterDelay();
  }

  /// Puts typing on page [pageIndex] into the undo history and autosaves
  /// it, and follows which page's text has the cursor.
  void listenToQuillChanges(QuillStruct quill, int pageIndex) {
    quill.changeSubscription?.cancel();
    quill.changeSubscription = quill.controller.changes.listen((event) {
      // Where the page is now: pages deleted, duplicated or put back by an
      // undo before it moved it, and its typing was undone on another page.
      final pageIndex = coreInfo.pages.indexWhere(
        (page) => page.quill == quill,
      );
      if (pageIndex < 0) return; // a deleted page
      // the toolbar's undo/redo only need a rebuild when this flips one
      final buttonsChange = history.canRedo || !history.canUndo;
      _addQuillChangeToHistory(
        quill: quill,
        pageIndex: pageIndex,
        event: event,
      );
      createPage(pageIndex);
      if (buttonsChange) setState(() {});
      autosaveAfterDelay();
    });
    // once: listened to again, a page's focus was told twice or more
    quill.focusNode
      ..removeListener(_onQuillFocusChange)
      ..addListener(_onQuillFocusChange);
  }

  /// Points [quillFocus] at the page whose text now has the cursor.
  void _onQuillFocusChange() {
    QuillStruct? focused;
    for (final page in coreInfo.pages) {
      if (page.quill.focusNode.hasFocus) focused = page.quill;
    }
    if (focused != null) quillFocus.value = focused;
  }

  /// Records one typed-text change for undo.
  void _addQuillChangeToHistory({
    required QuillStruct quill,
    required int pageIndex,
    required flutter_quill.DocChange event,
  }) {
    // the text editor undoing its own change: already in the history
    if (quill.controller.hasRedo) return;

    // One edit can come through the stream more than once. A change that
    // starts from the same text as the newest one replaces it; the old one
    // is only taken off the list here, not undone.
    if (history.canUndo && !history.canRedo) {
      final newest = history.peekUndo();
      final sameEdit =
          newest is HistoricQuillChange &&
          newest.pageIndex == pageIndex &&
          newest.quillChange.before == event.before;
      if (sameEdit) history.undo();
    }

    history.recordChange(
      HistoricQuillChange(pageIndex: pageIndex, quillChange: event),
    );
  }

  /// For a note opened read-only to watch someone else's changes: when the
  /// server has a newer copy, downloads it and opens it again in place.
  void _refreshCurrentNote() async {
    if (coreInfo.readOnlyReason != .watchingServer || !stows.loggedIn) return;

    final notePath = coreInfo.filePath;
    assert(notePath.isNotEmpty, 'Cannot refresh unnamed file');
    final remote = await BadNotesSyncFile.relative(notePath + Editor.extension);

    final newer = await BadNotesSyncInterface.getBestFile(
      remote,
      onLocalFileNotFound: .local,
      onEqualFiles: .local,
      preferCache: false,
    );
    if (newer != .remote) return;

    final downloader = syncer.downloader;
    StreamSubscription<BadNotesSyncFile>? waiting;
    waiting = downloader.transferStream.listen((done) {
      if (done != remote) return;
      waiting?.cancel();
      _loadCoreInfo(notePath)
          .then((_) => coreInfo.readOnlyReason = .watchingServer);
    });

    await downloader.enqueue(syncFile: remote);
    downloader.bringToFront(remote);
  }

  /// Bumped ~1s after the last change so sidebar thumbnails refresh
  /// without redrawing every page while you write.
  final _pagesRevision = ValueNotifier(0);
  Timer? _pagesRevisionTimer;

  void _openPagesOverview() {
    final manager = pageManager(context) as EditorPageManager;
    showPagesOverview(
      context,
      coreInfo: coreInfo,
      currentPageIndex: currentPageIndex,
      goToPage: (pageIndex) => CanvasGestureDetector.scrollToPage(
        pageIndex: pageIndex,
        pages: coreInfo.pages,
        screenWidth: _canvasWidth,
        transformationController: _transformationController,
        glide: true,
      ),
      insertPageAfter: _choosePageAfter,
      duplicatePage: manager.duplicatePage,
      clearPage: manager.clearPage,
      deletePage: manager.deletePage,
      redrawAndSave: manager.redrawAndSave,
      setPageOrder: _setPageOrder,
      restorePage: _restorePage,
      deletePageForever: _deletePageForever,
    );
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  var _pagesPanelOpen = false;

  /// Share & Export's "Choose…": the pages panel is picking pages to export
  /// in this format.
  ({ExportFormat format, bool withPaper})? _exportPick;

  /// The pages panel was opened on its Audio tab (Recordings).
  var _pagesAudio = false;

  bool get _showsPagesView =>
      _pagesPanelOpen && !_readingMode && !_toolsHidden;

  /// Whether the pages open as a sidebar beside the note, which there's room
  /// for on a tablet, instead of in its place.
  bool get _pagesBeside => MediaQuery.sizeOf(context).width >= 700;

  Widget _buildPagesPanel(BuildContext context) {
    // a whiteboard's panel has the whiteboards in place of pages
    if (_isBoard) {
      return BoardsPanel(
        current: coreInfo.filePath,
        quick: Whiteboard.filePath,
        open: _openBoard,
        newBoard: () => const NewDocumentMenu().newWhiteboard(context),
        rename: _renameBoard,
        duplicate: _duplicateBoard,
        delete: _deleteBoard,
        audio: audioNotes == null
            ? null
            : RecordingsPanel(audio: audioNotes!, record: _toggleRecording),
        showAudio: _pagesAudio,
        onClose: () => setState(() => _pagesPanelOpen = false),
      );
    }
    final manager = pageManager(context) as EditorPageManager;
    return PagesPanel(
      coreInfo: coreInfo,
      revision: _pagesRevision,
      currentPage: currentPageIndex,
      goToPage: (pageIndex) {
        CanvasGestureDetector.scrollToPage(
          pageIndex: pageIndex,
          pages: coreInfo.pages,
          screenWidth: _canvasWidth,
          transformationController: _transformationController,
          glide: true,
        );
        // the sidebar stays open beside the note; full screen, it goes
        setState(() {
          if (!_pagesBeside) _pagesPanelOpen = false;
        });
      },
      addPage: coreInfo.readOnly
          ? null
          : () {
              insertPageAfter(coreInfo.pages.length - 1);
              CanvasGestureDetector.scrollToPage(
                pageIndex: coreInfo.pages.length - 1,
                pages: coreInfo.pages,
                screenWidth: _canvasWidth,
                transformationController: _transformationController,
                glide: true,
              );
            },
      audio: audioNotes == null
          ? null
          : RecordingsPanel(audio: audioNotes!, record: _toggleRecording),
      showAudio: _pagesAudio,
      toggleBookmark: (pageIndex) {
        final page = coreInfo.pages[pageIndex];
        setState(() => page.bookmarked = !page.bookmarked);
        history.markUnsaved();
        autosaveAfterDelay();
      },
      copyPages: (pages) => pages.forEach(manager.duplicatePage),
      rotatePages: (pages) => setState(() {
        for (final pageIndex in pages) {
          _rotatePage(pageIndex, clockwise: true);
        }
      }),
      exportPages: _exportPages,
      exportPick: switch (_exportPick?.format) {
        null => null,
        ExportFormat.png => 'PNG',
        _ => 'PDF',
      },
      onExportPickEnd: () => setState(() => _exportPick = null),
      trashPages: (pages) => pages.forEach(manager.deletePage),
      openFullView: _openPagesOverview,
      // beside the note, the Pages button opens and closes it
      onClose: _pagesBeside
          ? null
          : () => setState(() {
              _pagesPanelOpen = false;
              _exportPick = null;
            }),
    );
  }

  /// Set when the note changes, so its handwriting is re-indexed on close.
  var _ocrDirty = false;

  /// Whether this note changed while open, so it needs a new PDF copy.
  var _editedThisSession = false;

  /// Reads the changed pages' handwriting for search once writing stops.
  Timer? _ocrTimer;

  void autosaveAfterDelay() {
    // gone: its last save was made as it closed
    if (!mounted) return;
    _ocrDirty = true;
    _ocrTimer?.cancel();
    // Reading the handwriting for search took the main thread a moment after
    // every 3 s pause, a stutter when writing went on. It waits for a long
    // pause now, or for the note to be left or the app hidden.
    _ocrTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || !_ocrDirty || coreInfo.readOnly) return;
      _ocrDirty = false;
      unawaited(HandwritingOcr.indexNote(coreInfo.filePath, coreInfo.pages));
    });
    _editedThisSession = true;
    _pagesRevisionTimer?.cancel();
    _pagesRevisionTimer = Timer(
      const Duration(seconds: 1),
      () => _pagesRevision.value++,
    );
    if (history.isCurrentStateSaved) return cancelAutosaveAndMarkSaved();

    savingState.value = .waitingToSave;
    _armAutosave();
  }

  /// (Re)starts the autosave countdown with the delay from settings. A
  /// negative delay means autosave is off.
  void _armAutosave() {
    _delayedSaveTimer?.cancel();
    final delay = stows.autosaveDelay.value;
    if (delay < 0) return;
    _delayedSaveTimer = Timer(Duration(milliseconds: delay), _autosaveNow);
  }

  /// The autosave countdown ran out. Mid-stroke it waits another round
  /// instead of saving under the pen.
  void _autosaveNow() {
    if (Pen.currentStroke != null) return _armAutosave();
    // No thumbnail here: drawing it on the main thread made writing stutter
    // after each save. It's made once the note is left or the app is hidden.
    saveToFile(thumbnail: false, quietly: true);
  }

  /// Stops any pending autosave and treats what's on screen as saved.
  void cancelAutosaveAndMarkSaved() {
    _delayedSaveTimer?.cancel();
    savingState.value = .saved;
    history.markLastChangeAsSaved();
  }

  /// Files an autosave wrote [quietly]: the home screen and the uploader
  /// hear of them once the note is left or the app is hidden.
  final _quietWrites = <String>{};

  void _announceQuietWrites() {
    for (final path in _quietWrites) {
      if (FileManager.doesFileExist(path)) FileManager.announceWrite(path);
    }
    _quietWrites.clear();
  }

  /// Saves the note. [quietly] for an autosave while writing: the home
  /// screen isn't told and nothing is uploaded until [_announceQuietWrites].
  Future<void> saveToFile({bool thumbnail = true, bool quietly = false}) async {
    if (coreInfo.readOnlyReason != null) return;
    // One save at a time. Asked for during one, this waits for it and then
    // saves what came after: dropped, a stroke drawn while a save ran was
    // lost when the note closed or the app was hidden right then.
    for (var running = _saving; running != null; running = _saving) {
      await running;
    }
    if (coreInfo.readOnlyReason != null) return;
    if (savingState.value == SavingState.saved) return; // nothing new to write
    final done = Completer<void>();
    _saving = done.future;
    try {
      final saving = _save(thumbnail: thumbnail, quietly: quietly);
      // Never waited on forever: everything after it, the save as the note
      // closes too, would wait with it. Not in tests: their fake clock
      // never lets a closed editor's save finish, and the timer outlived
      // the test.
      await (isThisATest
          ? saving
          : saving.timeout(
              const Duration(minutes: 2),
              onTimeout: () {
                log.severe('Saving took over 2 minutes; letting others save');
                savingState.value = .waitingToSave;
              },
            ));
    } finally {
      _saving = null;
      done.complete();
    }
  }

  /// The save running now, if one is.
  Future<void>? _saving;

  /// [EditorImage.moveFile] for every picture in the note.
  void _moveImageFiles(File? Function(File file) moved) {
    for (final page in coreInfo.pages) {
      for (final image in page.images) {
        image.moveFile(moved);
      }
      page.backgroundImage?.moveFile(moved);
    }
  }

  Future<void> _save({required bool thumbnail, required bool quietly}) async {
    // waiting to save: this save replaces the countdown
    _delayedSaveTimer?.cancel();
    savingState.value = .saving;
    if (history.isCurrentStateSaved) return cancelAutosaveAndMarkSaved();

    final saveWatch = Stopwatch()..start();
    try {
      LagRecorder.step('save: rename');
      await _renameFileNow();
    } catch (e, st) {
      // saved under its old name instead: a rename that threw left every
      // save after it stuck as "saving", and the session's edits unsaved
      log.severe('Failed to rename file: $e', e, st);
    }
    LagRecorder.step('save: pack');

    // after the rename: under the note's new name
    final sbnPath = coreInfo.filePath + Editor.extension;
    final savePoint = history.savePoint;
    // pictures mustn't be dropped from the cache while it's being packed
    final Uint8List noteBytes;
    final OrderedAssetCache assets;
    coreInfo.assetCache.allowRemovingAssets = false;
    try {
      (noteBytes, assets) = await LagRecorder.span('save (pack)', () {
        // A text box being typed again is out of the page till it's done:
        // it's packed as it was, not left out of the note.
        final retyped = _textBox;
        final image = retyped?.image;
        final images = retyped == null
            ? null
            : coreInfo.pages[retyped.pageIndex].images;
        if (image != null) images!.add(image);
        try {
          // the note is read into its save before this returns
          return coreInfo.saveToBinaryAsync(currentPageIndex: currentPageIndex);
        } finally {
          if (image != null) images!.remove(image);
        }
      });
    } catch (e, st) {
      log.severe('Failed to pack file: $e', e, st);
      savingState.value = .waitingToSave;
      if (kDebugMode) rethrow;
      return;
    } finally {
      coreInfo.assetCache.allowRemovingAssets = true;
    }
    LagRecorder.step('save: write');
    try {
      // An asset already saved in its place is left alone. Writing each
      // one back over itself on every save also queued it for upload
      // again and made the home screen reload its list.
      final changed = [
        for (int i = 0; i < assets.length; ++i)
          if (!assets.isFileAt(i, FileManager.getFile('$sbnPath.$i').path)) i,
      ];
      // All read before any is written, and the ones no longer used
      // removed last: with a picture deleted the others move down a
      // number, and one was read from a file being written or removed at
      // the same moment.
      final bytes = await Future.wait([
        for (final i in changed) assets.getBytes(i),
      ]);
      await Future.wait([
        FileManager.writeFile(
          sbnPath,
          noteBytes,
          awaitWrite: true,
          quietly: quietly,
        ),
        for (final (k, i) in changed.indexed)
          () {
            if (quietly) _quietWrites.add('$sbnPath.$i');
            return FileManager.writeFile(
              '$sbnPath.$i',
              bytes[k],
              awaitWrite: true,
              quietly: quietly,
            );
          }(),
      ]);
      await FileManager.removeUnusedAssets(sbnPath, numAssets: assets.length);
      // pictures read from a file that isn't theirs beside the note (a
      // PDF picked from elsewhere, or one whose number changed) are read
      // from the copy just saved
      final savedAt = {
        for (final i in changed)
          if (assets.fileAt(i) case final file?)
            file.path: FileManager.getFile('$sbnPath.$i'),
      };
      if (savedAt.isNotEmpty) _moveImageFiles((file) => savedAt[file.path]);
      if (quietly) {
        _quietWrites.add(sbnPath);
      } else {
        _announceQuietWrites();
      }
      history.markSavedAt(savePoint);
      if (history.isCurrentStateSaved) {
        savingState.value = .saved;
      } else {
        // edited while saving: those changes get their own save
        savingState.value = .waitingToSave;
        autosaveAfterDelay();
      }
    } catch (e, st) {
      log.severe('Failed to save file: $e', e, st);
      savingState.value = .waitingToSave;
      if (kDebugMode) rethrow;
      return;
    }

    LagRecorder.note('saved', {'ms': saveWatch.elapsedMilliseconds});
    if (thumbnail) await _saveThumbnail();
    // a version kept when one is 2 hours old (see NoteVersions): saves
    // while writing keep them, not closing the note
    final now = DateTime.now();
    final last = _lastKeptVersion;
    if (!_isBoard &&
        last != null &&
        now.difference(last) >= const Duration(hours: 2)) {
      _lastKeptVersion = now;
      unawaited(NoteVersions.keep(coreInfo.filePath));
    }
  }

  /// Draws the first page into the note's thumbnail, if it changed since.
  Future<void> _saveThumbnail() async {
    final sbnPath = coreInfo.filePath + Editor.extension;
    // far too big for a thumbnail: a board shows its cover on the home screen
    if (_isBoard) return;
    final page = coreInfo.pages.first;
    // Drawing the thumbnail takes a moment on the main thread. Edits to other
    // pages don't change it, so it's only drawn again when the first page did.
    final signature = _thumbnailSignature(page);
    if (signature == _savedThumbnailSignature &&
        FileManager.doesFileExist('$sbnPath.p')) {
      return;
    }
    _savedThumbnailSignature = signature;
    final previewHeight = page.previewHeight(lineHeight: coreInfo.lineHeight);
    final thumbnailSize = Size(720, 720 * previewHeight / page.size.width);
    final thumbnailWatch = Stopwatch()..start();
    final thumbnail = await EditorExporter.screenshotPage(
      coreInfo: coreInfo,
      pageIndex: 0,
      rasterizeAllStrokes: true,
      targetSize: thumbnailSize,
      cropHeight: previewHeight,
      pixelRatio: 1,
    );
    final drawMs = thumbnailWatch.elapsedMilliseconds;
    final thumbnailPng = await thumbnail.toByteData(format: .png);
    thumbnail.dispose();
    LagRecorder.note('thumbnail', {
      'draw ms': drawMs,
      'png ms': thumbnailWatch.elapsedMilliseconds - drawMs,
    });
    var png = thumbnailPng!.buffer.asUint8List();
    // a picked paper color stays in dark mode, on the home screen too
    if (InnerCanvas.hasChosenColor(page, coreInfo)) {
      png = ThumbnailMarks.markKeepColors(png);
    }
    await FileManager.writeFile(
      // Note that this ends with .sbn2.p
      '$sbnPath.p',
      png,
      awaitWrite: true,
    );
  }

  int? _savedThumbnailSignature;

  /// Changes whenever anything on [page] that shows in the thumbnail does.
  int _thumbnailSignature(EditorPage page) => Object.hash(
    page.size,
    page.backgroundColor ?? coreInfo.backgroundColor,
    page.backgroundPattern ?? coreInfo.backgroundPattern,
    page.lineHeight ?? coreInfo.lineHeight,
    coreInfo.lineThickness,
    page.backgroundImage,
    Object.hashAll([for (final layer in page.layers) layer.visible]),
    Object.hashAll([
      for (final stroke in page.strokes)
        Object.hash(identityHashCode(stroke), stroke.version),
    ]),
    Object.hashAll([
      for (final image in page.images)
        Object.hash(identityHashCode(image), image.dstRect, image.rotation),
    ]),
    page.quill.controller.document.toPlainText(),
  );

  late final _filenameFormKey = GlobalKey<FormState>();

  /// The note's name, as typed in the title bar.
  late final filenameTextEditingController = TextEditingController();

  /// Renames a few seconds after the last keystroke in the name field, not
  /// on every letter.
  Timer? _renameTimer;
  void renameFile([String? _]) {
    _renameTimer?.cancel();
    _renameTimer = Timer(const Duration(seconds: 5), _renameWhenNotSaving);
  }

  /// Gives the note the name in the title field, if it's a valid one and
  /// different. The field then shows the name the file really got, which
  /// can differ (e.g. when that name was already taken).
  /// [_renameFileNow], once no save is running, and with none starting
  /// till it's done: moved under a running save, the save wrote the note
  /// back under its old name, a second copy of it.
  Future<void> _renameWhenNotSaving() async {
    for (var running = _saving; running != null; running = _saving) {
      await running;
    }
    final done = Completer<void>();
    _saving = done.future;
    try {
      await _renameFileNow();
    } catch (e, st) {
      log.severe('Failed to rename file: $e', e, st);
    } finally {
      _saving = null;
      done.complete();
    }
  }

  Future<void> _renameFileNow() async {
    final field = filenameTextEditingController;
    final wanted = field.text.trim();
    if (wanted == coreInfo.fileName) return;

    final valid =
        _filenameFormKey.currentState?.validate() ??
        _validateFilenameTextField(wanted) == null;
    if (valid) {
      final oldPath = coreInfo.filePath;
      final moved = await FileManager.moveFile(
        oldPath + Editor.extension,
        wanted + Editor.extension,
      );
      coreInfo.filePath = moved.substring(
        0,
        moved.lastIndexOf(Editor.extension),
      );
      // its pictures went along: read from their new place
      final from = '${FileManager.getFile(oldPath + Editor.extension).path}.';
      final to =
          '${FileManager.getFile(coreInfo.filePath + Editor.extension).path}.';
      _moveImageFiles(
        (file) => file.path.startsWith(from)
            ? File(to + file.path.substring(from.length))
            : null,
      );
      NoteTabs.rename(oldPath, coreInfo.filePath);
      if (Editor.openNotes.remove(oldPath)) {
        Editor.openNotes.add(coreInfo.filePath);
      }
      // the recordings, OCR and cover went along with the note
      audioNotes?.notePath = coreInfo.filePath;
      needsNaming = false;
    }

    final given = coreInfo.fileName;
    if (given == wanted) return;
    field.value = field.value.copyWith(
      text: given,
      selection: TextSelection.collapsed(offset: given.length),
      composing: TextRange.empty,
    );
  }

  /// The problem with [newName] as a file name, or null if it's fine.
  String? _validateFilenameTextField(String? newName) =>
      newName == null ? null : FileManager.validateFilename(newName);

  /// Whether ink on the page in view shows inverted, as in dark mode.
  bool get _inkInverted {
    if (coreInfo.pages.isEmpty) {
      return stows.editorAutoInvert.value &&
          Theme.brightnessOf(context) == .dark;
    }
    return InnerCanvas.invertsInk(
      coreInfo.pages[currentPageIndex.clamp(0, coreInfo.pages.length - 1)],
      coreInfo,
      Theme.brightnessOf(context),
    );
  }

  void _removeAllTapeOnPage() {
    if (coreInfo.readOnly || coreInfo.pages.isEmpty) return;
    final page =
        coreInfo.pages[currentPageIndex.clamp(0, coreInfo.pages.length - 1)];
    final tape = [
      for (final stroke in page.strokes)
        if (stroke.toolId == .tape) stroke,
    ];
    if (tape.isEmpty) return;
    setState(() {
      for (final stroke in tape) {
        page.strokes.remove(stroke);
      }
      history.recordChange(HistoricDelete(strokes: tape, images: const []));
      page.redrawStrokes();
    });
    autosaveAfterDelay();
  }

  /// The selection's bounds in the canvas stack, or null if nothing is
  /// selected or it's out of sight.
  Rect? _selectionOnScreen() {
    final select = Select.currentSelect;
    final index = select.selectResult.pageIndex;
    if (!select.doneSelecting || index < 0 || index >= coreInfo.pages.length) {
      return null;
    }
    final pageBox = coreInfo.pages[index].renderBox;
    final stackBox = _canvasStackBox;
    if (pageBox == null || stackBox == null || !pageBox.attached) return null;
    // the box with the handles, not the loop drawn round it: a big loop
    // would put the bar far from what's picked
    final box = select.box;
    Offset map(Offset p) => stackBox.globalToLocal(
      pageBox.localToGlobal(Select.turn(p, select.angle)),
    );
    final corners = [
      map(box.topLeft),
      map(box.topRight),
      map(box.bottomLeft),
      map(box.bottomRight),
    ];
    return corners.skip(1).fold<Rect>(
      Rect.fromPoints(corners.first, corners.first),
      (r, p) => r.expandToInclude(Rect.fromPoints(p, p)),
    );
  }

  /// Copies of the selected strokes from before a panel changed their color
  /// or style, for one undo step when it closes.
  List<Stroke>? _styleBefore;

  void _beginStyleEdit() => _styleBefore ??= [
    // in their place in the drawing order, for undo
    for (final stroke in Select.currentSelect.selectResult.strokes)
      stroke.copy()..drawOrder = stroke.drawOrder,
  ];

  void _endStyleEdit() {
    final before = _styleBefore;
    _styleBefore = null;
    if (before == null || !mounted) return;
    final after = Select.currentSelect.selectResult.strokes;
    if (after.length != before.length) return;
    var changed = false;
    for (int i = 0; i < after.length && !changed; i++) {
      changed =
          after[i].color != before[i].color ||
          after[i].options.size != before[i].options.size ||
          after[i].shapeStyle?.toJson().toString() !=
              before[i].shapeStyle?.toJson().toString();
    }
    if (!changed) return;
    setState(() {
      history.recordChange(HistoricReplace(removed: before, added: after));
    });
    autosaveAfterDelay();
  }

  void _redrawSelectionPage() {
    final index = Select.currentSelect.selectResult.pageIndex;
    if (index >= 0 && index < coreInfo.pages.length) {
      coreInfo.pages[index].redrawStrokes();
    }
    setState(() {});
  }

  List<Stroke> get _selectedShapes => [
    for (final stroke in Select.currentSelect.selectResult.strokes)
      if (stroke.toolId == .shapePen) stroke,
  ];

  void _openSelectionColor(Rect anchor) {
    final select = Select.currentSelect;
    final shapes = _selectedShapes;
    final firstFill = shapes.firstOrNull?.shapeStyle?.fill;
    _beginStyleEdit();
    ColorPanel.show(
      context,
      anchor: anchor,
      title: 'Color',
      color: select.getDominantStrokeColor()?.withValues(alpha: 1),
      onChanged: (color) {
        updateColorBar(color);
        for (final stroke in select.selectResult.strokes) {
          stroke.color = stroke.toolId == .highlighter
              ? color.withValues(alpha: stroke.color.a)
              : color;
          final fill = stroke.shapeStyle?.fill;
          if (fill != null) {
            stroke.shapeStyle = stroke.shapeStyle!.copyWith(
              fill: () => color.withValues(alpha: fill.a),
            );
          }
        }
        _redrawSelectionPage();
      },
      fill: shapes.isEmpty
          ? null
          : (
              on: firstFill != null,
              opacity: firstFill?.a ?? stows.shapeFillOpacity.value,
              setOn: (on) {
                for (final shape in shapes) {
                  final style = shape.shapeStyle ?? ShapeStyle.plain;
                  shape.shapeStyle = style.copyWith(
                    fill: () => on
                        ? shape.color.withValues(
                            alpha: stows.shapeFillOpacity.value,
                          )
                        : null,
                  );
                }
                _redrawSelectionPage();
              },
              setOpacity: (opacity) {
                for (final shape in shapes) {
                  final fill = shape.shapeStyle?.fill;
                  if (fill == null) continue;
                  shape.shapeStyle = shape.shapeStyle!.copyWith(
                    fill: () => fill.withValues(alpha: opacity),
                  );
                }
                _redrawSelectionPage();
              },
            ),
    ).whenComplete(_endStyleEdit);
  }

  void _openSelectionStroke(Rect anchor) {
    final shapes = _selectedShapes;
    if (shapes.isEmpty) return;
    _beginStyleEdit();
    showToolPanel(
      context,
      anchor: anchor,
      page: shapeStrokePage(
        style: () => shapes.first.shapeStyle ?? ShapeStyle.plain,
        setStyle: (style) {
          for (final shape in shapes) {
            shape.shapeStyle = style.copyWith(
              fill: () => shape.shapeStyle?.fill,
            );
          }
          _redrawSelectionPage();
        },
        width: () => shapes.first.options.size,
        setWidth: (width) {
          for (final shape in shapes) {
            shape.options.size = width;
            shape.markPolygonNeedsUpdating();
          }
          _redrawSelectionPage();
        },
        minWidth: ShapePen.currentShapePen.sizeMin,
        maxWidth: ShapePen.currentShapePen.sizeMax,
        // the preview in the shape's own colour, not always black
        color: shapes.first.color,
      ),
    ).whenComplete(_endStyleEdit);
  }

  Widget _selectionActionBar() {
    final select = Select.currentSelect;
    final strokes = select.selectResult.strokes;
    final single = strokes.length == 1 && select.selectResult.images.isEmpty
        ? strokes.first
        : null;
    final noteImage = switch (select.singleImage) {
      final SvgEditorImage svg when svg.isStickyNote => svg,
      _ => null,
    };
    final note = noteImage?.note;
    final textImage = switch (select.singleImage) {
      final SvgEditorImage svg when svg.isTextBox => svg,
      _ => null,
    };
    final textNote = textImage?.note;
    return SelectionActionBar(
      screenshot: _screenshotSelection,
      extra: textImage != null && textNote != null
          ? TextFormatBar(
              format: textNote,
              onChanged: (format) {
                final changed = format.copyWith(text: textNote.text);
                _replaceSvg(
                  textImage,
                  stickyNoteToSvg(changed),
                  stickyNoteSize(changed),
                );
              },
            )
          : null,
      onCollapse:
          noteImage != null &&
              note != null &&
              (note.collapsed || select.attached.isEmpty)
          ? () {
              final changed = note.withCollapsed(!note.collapsed);
              _replaceSvg(
                noteImage,
                stickyNoteToSvg(changed),
                stickyNoteSize(changed),
              );
            }
          : null,
      collapsed: note?.collapsed ?? false,
      bounds: _selectionOnScreen,
      repositioned: _transformationController,
      color: textImage != null
          ? null
          : note?.color ??
                select.getDominantStrokeColor()?.withValues(alpha: 1),
      onColor: note != null && note.color != null
          ? (anchor) => _openNoteColor(anchor, noteImage!, note)
          : _openSelectionColor,
      onStroke: _selectedShapes.isEmpty ? null : _openSelectionStroke,
      onEditShape: select.singleShape == null
          ? null
          : () {
              select.editingCorners = !select.editingCorners;
              _redrawSelectionPage();
            },
      editingShape: select.editingCorners,
      onResize: noteImage != null || textImage != null
          ? null
          : _openSelectionResize,
      cut: () async {
        await _copyToOtherNote();
        if (mounted) _deleteSelection();
      },
      copy: _copyToOtherNote,
      duplicate: _duplicateSelection,
      delete: _deleteSelection,
      front: () => _reorderSelection(true),
      back: () => _reorderSelection(false),
      moreEntries: () => [
        AppleMenuItem(
          'Duplicate',
          icon: Icons.library_add_outlined,
          onTap: _duplicateSelection,
        ),
        AppleMenuItem(
          'Paste',
          icon: Icons.content_paste,
          enabled: NoteClipboard.hasContent,
          onTap: _pasteFromNote,
        ),
        const AppleMenuDivider(),
        AppleMenuItem(
          'Take Screenshot',
          icon: Icons.photo_camera_outlined,
          onTap: () => setState(() => _screenshotOn = true),
        ),
        const AppleMenuDivider(),
        AppleMenuItem(
          'Edit Text',
          icon: Icons.text_fields,
          onTap: _editSelectionText,
        ),
        if (single?.toolId == .shapePen)
          AppleMenuItem(
            'Change Shape',
            icon: Icons.category_outlined,
            onTap: _showChangeShapeDialog,
          ),
        AppleMenuItem(
          'Copy as Text',
          icon: Icons.content_copy,
          onTap: _copySelectionAsText,
        ),
        AppleMenuItem(
          'Convert to Text',
          icon: Icons.text_snippet_outlined,
          onTap: _convertSelectionToText,
        ),
        if (audioNotes != null)
          AppleMenuItem(
            'Play Audio from Here',
            icon: Icons.play_circle_outline,
            onTap: _playFromSelection,
          ),
        const AppleMenuDivider(),
        AppleMenuItem(
          'Delete',
          icon: Icons.delete_outline,
          destructive: true,
          onTap: _deleteSelection,
        ),
      ],
    );
  }

  void _openNoteColor(
    Rect anchor,
    SvgEditorImage image,
    StickyNoteResult note,
  ) {
    var current = note;
    ColorPanel.show(
      context,
      anchor: anchor,
      title: 'Change Color',
      color: note.color,
      presets: stickyNoteColors,
      onChanged: (color) {
        current = current.copyWith(color: () => color);
        _replaceSvg(image, stickyNoteToSvg(current), stickyNoteSize(current));
      },
    );
  }

  void _openSelectionResize(Rect anchor) {
    var percent = 100.0;
    showToolPanel(
      context,
      anchor: anchor,
      page: PanelPage(
        title: 'Resize',
        width: 300,
        builder: (context, setPanelState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PanelGroup(
              children: [
                PanelSliderRow(
                  title: 'Size',
                  value: percent,
                  min: 25,
                  max: 300,
                  valueText: '${percent.round()}%',
                  onChanged: (v) => setPanelState(() => percent = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PanelGroup(
              children: [
                PanelNavRow(
                  title: 'Resize',
                  chevron: false,
                  onTap: () {
                    Navigator.pop(context);
                    if (percent.round() != 100) {
                      transformSelection(scale: percent / 100);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// What [scribble] rubs out, if it's a scribble over ink with a pen that
  /// scribbles to erase ([Stows.penScribbleToErase]): null if nothing.
  ///
  /// A zigzag on empty paper stays as ink, and so does handwriting that
  /// only crosses a bit of other ink. A shape counts as covering its
  /// inside: a hand rubs a square out from inside it, not along its sides,
  /// and only the sides counting, shapes were never erased.
  List<Stroke>? _scribbledOut(Stroke scribble, EditorPage page) {
    final on = switch (scribble.toolId) {
      .ballpointPen ||
      .brushPen ||
      .calligraphyPen ||
      .pencil => stows.penScribbleToErase.value,
      .fountainPen => stows.fountainScribbleToErase.value,
      _ => false,
    };
    if (!on || !scribble.isScribble) return null;
    final everything = stows.scribbleErasesAll.value;
    final area = scribble.bounds;
    // a shape rubbed out from inside: the scribble covers a good part of
    // it, and a good part of the scribble lies in it (a word written in a
    // big box doesn't cover it)
    bool rubbedInside(Stroke shape) {
      if (!everything || shape.toolId != .shapePen || !shape.isClosedShape) {
        return false;
      }
      final box = shape.bounds;
      final common = area.intersect(box);
      if (common.isEmpty ||
          common.width * common.height < 0.4 * box.width * box.height) {
        return false;
      }
      final line = scribble.centerPoints;
      // (a hand rubbing a shape out goes past its sides too)
      final inside = line.where(shape.hasInside).length;
      return inside >= line.length * 0.35;
    }

    final rubbed = <Stroke>[];
    final erased = page.strokes.where((stroke) {
      if (!page.isLayerEditable(stroke.layer)) return false;
      if (!everything &&
          (stroke.toolId == .shapePen || stroke.toolId == .highlighter)) {
        return false;
      }
      if (rubbedInside(stroke)) {
        rubbed.add(stroke);
        return true;
      }
      return scribble.drawnOver(stroke);
    }).toList();
    if (erased.isEmpty) return null;
    final share = scribble.shareOver(
      erased,
      alsoOver: rubbed.isEmpty
          ? null
          : (p) => rubbed.any((shape) => shape.hasInside(p)),
    );
    if (share < 0.3) return null;
    return erased;
  }

  /// Selects what a pen loop was drawn around, see [Stows.circleToLasso].
  /// Returns whether it did, and so the loop isn't kept as ink.
  bool _lassoFromLoop(Stroke loop, EditorPage page) {
    final points = loop.centerPoints;
    if (points.length < 12) return false;
    var length = 0.0;
    for (int i = 1; i < points.length; i++) {
      length += (points[i] - points[i - 1]).distance;
    }
    if (length < 150) return false;
    if ((points.first - points.last).distance > max(30.0, length * 0.12)) {
      return false;
    }
    final path = Path()..addPolygon(points, true);
    final bounds = path.getBounds();
    bool inside(Offset p) => bounds.contains(p) && path.contains(p);
    // wholly inside, or with [Stows.lassoPartly] mostly: a word with its
    // last letter sticking out was left out before
    final share = stows.lassoPartly.value ? 0.7 : 1.0;
    bool circled(Stroke stroke) {
      final line = stroke.centerPoints;
      if (line.isEmpty || !bounds.overlaps(stroke.bounds)) return false;
      final within = line.where(inside).length;
      return within >= line.length * share;
    }

    final strokes = [
      for (final stroke in page.strokes)
        if (page.isLayerEditable(stroke.layer) && circled(stroke)) stroke,
    ];
    final images = [
      for (final image in page.images)
        if (inside(image.dstRect.center)) image,
    ];
    if (strokes.isEmpty && images.isEmpty) return false;
    // A loop round something much smaller than itself is a letter O or a
    // 0 written round a dot, not a lasso: the "O" went, and the dot was
    // selected.
    var circledArea = images.isEmpty
        ? strokes.first.bounds
        : images.first.dstRect;
    for (final stroke in strokes) {
      circledArea = circledArea.expandToInclude(stroke.bounds);
    }
    for (final image in images) {
      circledArea = circledArea.expandToInclude(image.dstRect);
    }
    if (circledArea.longestSide < 0.3 * bounds.shortestSide) return false;
    showBanner(
      context,
      strokes.length + images.length == 1
          ? 'Selected 1 item'
          : 'Selected ${strokes.length + images.length} items',
      actionLabel: 'Keep as ink',
      onAction: () => _keepLoopAsInk(loop, page),
      duration: const Duration(seconds: 5),
    );
    setState(() {
      if (currentTool is! Select) _toolBeforeTapEdit = currentTool;
      currentTool = Select.currentSelect;
      Select.currentSelect
        ..selectResult = SelectResult(
          pageIndex: loop.pageIndex,
          strokes: strokes,
          images: images,
          path: path,
          pageIndexStart: loop.pageIndex,
        )
        ..doneSelecting = true;
      page.redrawStrokes();
    });
    return true;
  }

  /// The loop that selected ([_lassoFromLoop]) put back on the page as the
  /// ink it was meant to be, and nothing selected.
  void _keepLoopAsInk(Stroke loop, EditorPage page) {
    if (!mounted) return;
    setState(() {
      Select.currentSelect.unselect();
      if (currentTool is Select && _toolBeforeTapEdit != null) {
        currentTool = _toolBeforeTapEdit!;
        _toolBeforeTapEdit = null;
      }
      loop
        ..layer = page.activeLayer
        ..nib2 = true
        ..onFrontImage = page.liesOnFrontImage(loop)
        ..afterImage = page.liesOnFrontImage(loop)
            ? page.latestFrontOrder(page.activeLayer)
            : -1;
      page.insertStroke(loop);
      page.redrawStrokes();
      history.recordChange(HistoricAdd(strokes: [loop], images: []));
    });
    autosaveAfterDelay();
  }

  /// Copies what's selected onto the same page, the ink a little up and to
  /// the right so the copy can be seen, and selects the copy.
  void _duplicateSelection() {
    final select = currentTool as Select;
    if (!select.doneSelecting) return;

    setState(() {
      final result = select.selectResult;
      final page = coreInfo.pages[result.pageIndex];
      const nudge = Offset(25, -25);

      final strokeCopies = [
        for (final stroke in result.strokes) stroke.copy()..shift(nudge),
      ];
      // pictures are copied where they are
      final imageCopies = [
        for (final image in result.images)
          image.copy()
            ..id = coreInfo.nextImageId++
            ..inFront = image.inFront
            ..layer = image.layer,
      ];

      page.strokes.addAll(strokeCopies);
      page.images.addAll(imageCopies);
      select.selectResult = result.copyWith(
        strokes: strokeCopies,
        images: imageCopies,
        path: result.path.shift(nudge),
      );

      history.recordChange(
        HistoricAdd(strokes: strokeCopies, images: imageCopies),
      );
      autosaveAfterDelay();
    });
  }

  /// Takes what's selected off its page, as one undo step.
  void _deleteSelection() {
    final select = currentTool as Select;
    if (!select.doneSelecting) return;

    setState(() {
      final page = coreInfo.pages[select.selectResult.pageIndex];
      // the writing on a selected sticky note goes with it
      final strokes = select.movingStrokes;
      final images = select.selectResult.images;
      strokes.forEach(page.strokes.remove);
      images.forEach(page.images.remove);
      select.unselect();

      history.recordChange(HistoricDelete(strokes: strokes, images: images));
      autosaveAfterDelay();
    });
  }

  /// Switches to [tool] from the toolbar. Picking the eraser while it is
  /// already on switches back to the tool from before it.
  void _setTool(Tool tool) {
    _toolBeforeTapEdit = null;
    final picked = tool is Eraser && currentTool is Eraser
        ? _lastNonEraserTool
        : tool;
    currentTool = picked;

    // remember which highlighter, pencil or pen is the one in use; the
    // other pens and the shape and tape tools keep their own
    switch (picked) {
      case Highlighter():
        Highlighter.currentHighlighter = picked;
      case Pencil():
        Pencil.currentPencil = picked;
      case ShapePen() || Tape():
        break;
      case Pen()
          when picked != Pen.currentBallpointPen &&
              picked != Pen.currentCalligraphyPen &&
              picked != Pen.currentBrushPen:
        Pen.currentPen = picked;
      default:
        break;
    }

    if (mounted) setState(() {});
  }

  /// Gives the current tool [color], or recolours the selected strokes.
  void _setColor(Color color) {
    setState(() {
      updateColorBar(color);

      final tool = currentTool;
      switch (tool) {
        case Highlighter():
          tool.color = color.withAlpha(stows.highlighterAlpha.value);
        case Pencil():
          tool.color = color.withAlpha(stows.pencilAlpha.value);
        case Pen():
          tool.color = color;
        case LaserPointer():
          tool.color = color;
        case Select(doneSelecting: true):
          _recolorSelection(tool, color);
        default:
          break;
      }
    });
  }

  /// Gives every selected stroke [color], as one undo step. Highlighter
  /// strokes keep how see-through they were.
  void _recolorSelection(Select select, Color color) {
    final strokes = select.selectResult.strokes;
    final changes = <Stroke, Change<Color>>{};
    for (final stroke in strokes) {
      final next = stroke.toolId == .highlighter
          ? color.withValues(alpha: stroke.color.a)
          : color;
      changes[stroke] = Change(previous: stroke.color, current: next);
      stroke.color = next;
    }
    history.recordChange(
      HistoricColorChange(
        pageIndex: strokes.first.pageIndex,
        colorChanges: changes,
      ),
    );
    autosaveAfterDelay();
  }

  /// Puts [color] in the recent-colours row. The row keeps two lists of
  /// the same colours: one in the order they were used (to know which is
  /// oldest) and one in the order they are shown, so a colour already
  /// there doesn't jump around.
  void updateColorBar(Color color) {
    if (stows.recentColorsDontSavePresets.value &&
        PresetColors.contains(color)) {
      return;
    }

    final byTime = stows.recentColorsChronological;
    final byPlace = stows.recentColorsPositioned;
    final key = color.toARGB32().toString();

    // older versions only kept the shown order: start the time order from it
    if (byTime.value.length != byPlace.value.length) {
      log.info(
        'MIGRATING recentColors: ${byTime.value.length} vs ${byPlace.value.length}',
      );
      byTime.value = List.of(byPlace.value);
    }

    // pinned colours have their own place already
    if (stows.pinnedColors.value.contains(key)) return;

    if (byPlace.value.contains(key)) {
      // used again: it becomes the newest, but stays where it is shown
      byTime.value
        ..remove(key)
        ..add(key);
      byTime.notifyListeners();
      return;
    }

    if (byPlace.value.length < stows.recentColorsLength.value) {
      // room left: newest in time, first in the row
      byTime.value.add(key);
      byPlace.value.insert(0, key);
    } else {
      // full: it takes the place of the colour used longest ago
      final oldest = byTime.value.removeAt(0);
      byTime.value.add(key);
      byPlace.value[byPlace.value.indexOf(oldest)] = key;
    }
    byTime.notifyListeners();
    byPlace.notifyListeners();
  }

  /// A picture's own setting changed (e.g. it was moved in front of the
  /// ink): repaint and save.
  void _onImageMiscChange() {
    if (mounted) setState(() {});
    autosaveAfterDelay();
  }

  /// Takes a photo with the device's camera app, then the user taps where it
  /// goes on the page.
  Future<void> _takePhoto() async {
    if (coreInfo.readOnly) return;
    final photo = await _capturePhoto();
    if (photo != null)
      unawaited(RecentImages.add(photo.bytes, photo.extension));
    if (photo != null && mounted) await _pickPhotos([photo]);
  }

  /// The device's document scanner, which finds the page's corners and
  /// straightens it. Comes with Google Play services.
  Future<List<_PhotoInfo>> _scanDocument() async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: 30,
        isGalleryImport: true,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      return [
        for (final path in result.images ?? const <String>[])
          _PhotoInfo(await File(path).readAsBytes(), '.jpg'),
      ];
    } on PlatformException catch (e) {
      final cancelled = e.message?.toLowerCase().contains('cancel') ?? false;
      if (!cancelled && mounted) {
        showBanner(context, 'Could not open the scanner: ${e.message}');
      }
      return const [];
    } finally {
      unawaited(scanner.close());
    }
  }

  Future<_PhotoInfo?> _capturePhoto() async {
    final XFile? photo;
    try {
      photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 90,
      );
    } on PlatformException catch (e) {
      if (mounted) {
        showBanner(context, 'Could not open the camera: ${e.message}');
      }
      return null;
    }
    if (photo == null) return null;
    final bytes = await photo.readAsBytes();
    final extension = p.extension(photo.path);
    return _PhotoInfo(bytes, extension.isEmpty ? '.jpg' : extension);
  }

  /// A picture that fills the page and stays in place, under the writing.
  Future<void> _pickPageBackground() async {
    final spot = _visibleSpot();
    final added = await _pickPhotos(null, spot);
    if (added == 0 || !mounted) return;
    _makeLastImageTheBackground(coreInfo.pages[spot.pageIndex]);
  }

  void _makeLastImageTheBackground(EditorPage page) {
    if (page.images.isEmpty) return;
    final image = page.images.last;
    _imageToSelect = null;
    Select.currentSelect.unselect();
    setState(() {
      if (page.backgroundImage != null) page.images.add(page.backgroundImage!);
      page.images.remove(image);
      page.backgroundImage = image;
    });
    autosaveAfterDelay();
  }

  static Path _imageOutline(EditorImage image) =>
      Path()..addPolygon(Select.imageCorners(image), true);

  void _selectImage(EditorImage image, int pageIndex) {
    Select.currentSelect
      ..selectResult = SelectResult(
        pageIndex: pageIndex,
        strokes: [],
        images: [image],
        path: _imageOutline(image),
        pageIndexStart: pageIndex,
      )
      ..doneSelecting = true
      ..attached = _writingOn(image, pageIndex);
  }

  /// The strokes written on [image], if it's a sticky note: all of each
  /// stroke is on it.
  List<Stroke> _writingOn(EditorImage image, int pageIndex) {
    if (image is! SvgEditorImage || !image.isStickyNote) return const [];
    final area = image.dstRect.inflate(2);
    final page = coreInfo.pages[pageIndex];
    return [
      for (final stroke in page.strokes)
        if (stroke.toolId != .tape &&
            stroke.centerPoints.isNotEmpty &&
            stroke.centerPoints.every(area.contains))
          stroke,
    ];
  }

  /// A just added picture, to select once it has loaded and has a size.
  EditorImage? _imageToSelect;

  /// The page in the middle of the screen, and the point on it. New pictures
  /// and notes go here, in view, rather than at the top of a page.
  _Spot _visibleSpot() {
    final box = _canvasStackBox;
    if (box != null) {
      final middle = box.localToGlobal(box.size.center(.zero));
      final pageIndex = onWhichPageIsFocalPoint(middle);
      final pageBox = pageIndex == null
          ? null
          : coreInfo.pages[pageIndex].renderBox;
      if (pageIndex != null && pageBox != null) {
        return (pageIndex: pageIndex, center: pageBox.globalToLocal(middle));
      }
    }
    // the middle of the screen is between two pages
    final pageIndex = currentPageIndex;
    return (
      pageIndex: pageIndex,
      center: coreInfo.pages[pageIndex].size.center(.zero),
    );
  }

  /// Centers [image] on [center] once it has a size, and selects it if it's
  /// [_imageToSelect].
  void _placeWhenLoaded(EditorImage image, Offset center) {
    void onChange() {
      if (image.dstRect.isEmpty) return;
      image.removeListener(onChange);
      final page = coreInfo.pages[image.pageIndex].size;
      final size = image.dstRect.size;
      image.dstRect =
          Offset(
            (center.dx - size.width / 2).clamp(
              0.0,
              max(page.width - size.width, 0.0),
            ),
            (center.dy - size.height / 2).clamp(
              0.0,
              max(page.height - size.height, 0.0),
            ),
          ) &
          size;
      // not now: the size can be set while the page is building
      unawaited(
        Future(() {
          if (!mounted || _imageToSelect != image) return;
          _imageToSelect = null;
          if (currentTool is! Select) return;
          setState(() => _selectImage(image, image.pageIndex));
        }),
      );
    }

    image.addListener(onChange);
  }

  /// The topmost picture under [position] on [page], if any.
  static EditorImage? _imageAt(EditorPage page, Offset position) {
    for (final image in page.images.reversed) {
      if (!page.isLayerEditable(image.layer)) continue;
      // a turned picture is tested where it shows: in its own turned box
      final local = Stroke.transformPoint(
        position,
        image.dstRect.center,
        1,
        -image.rotation,
      );
      if (image.dstRect.inflate(8).contains(local)) return image;
    }
    return null;
  }

  /// Adds pictures centered on [at]. Without it the user taps where they go.
  Future<int> _pickPhotos([
    List<_PhotoInfo>? photoInfos,
    _Spot? at,
    bool selectAfter = true,
  ]) async {
    if (coreInfo.readOnly) return 0;

    final pageIndex = (at ?? _visibleSpot()).pageIndex;

    if (photoInfos == null) {
      photoInfos = await _pickPhotosWithFilePicker();
      for (final photo in photoInfos) {
        unawaited(RecentImages.add(photo.bytes, photo.extension));
      }
    }
    if (photoInfos.isEmpty) return 0;

    final pageSize = coreInfo.pages[pageIndex].size;
    // Some Android pickers let a pdf through. It isn't a picture: those are
    // skipped, and the user is pointed to importing a pdf instead.
    var skippedPdf = false;
    final images = <EditorImage>[];
    for (final photo in photoInfos) {
      final type = photo.extension.toLowerCase();
      if (type == '.pdf') {
        skippedPdf = true;
        continue;
      }
      images.add(
        type == '.svg'
            ? SvgEditorImage(
                id: coreInfo.nextImageId++,
                svgString: utf8.decode(photo.bytes),
                svgFile: null,
                pageIndex: pageIndex,
                pageSize: pageSize,
                onMoveImage: onMoveImage,
                onDeleteImage: onDeleteImage,
                onMiscChange: _onImageMiscChange,
                onLoad: _setState,
                assetCache: coreInfo.assetCache,
              )
            : PngEditorImage(
                id: coreInfo.nextImageId++,
                extension: photo.extension,
                imageProvider: MemoryImage(photo.bytes),
                pageIndex: pageIndex,
                pageSize: pageSize,
                onMoveImage: onMoveImage,
                onDeleteImage: onDeleteImage,
                onMiscChange: _onImageMiscChange,
                onLoad: _setState,
                assetCache: coreInfo.assetCache,
              ),
      );
    }

    if (images.isNotEmpty) {
      // placed where asked, or held under the finger until a tap places it
      if (at != null) {
        _putImages(images, at, selectAfter);
      } else {
        setState(() => _placing = images);
      }
    }

    if (skippedPdf && mounted) {
      await showAppleDialog(
        context: context,
        builder: (context) => AdaptiveAlertDialog(
          title: Text(t.editor.photoPdfError.title),
          content: Text(t.editor.photoPdfError.message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.common.done),
            ),
          ],
        ),
      );
    }

    return images.length;
  }

  void _putImages(List<EditorImage> images, _Spot at, bool selectAfter) {
    if (selectAfter) {
      // use the Select tool so that the user can move the new image
      if (currentTool is! Select) _toolBeforeTapEdit = currentTool;
      currentTool = Select.currentSelect;
      _imageToSelect = images.length == 1 ? images.first : null;
    }
    for (final (i, image) in images.indexed) {
      _placeWhenLoaded(image, at.center + Offset(24, 24) * i.toDouble());
    }
    history.recordChange(HistoricAdd(strokes: const [], images: images));
    createPage(at.pageIndex);
    final page = coreInfo.pages[at.pageIndex];
    page.putImagesInFront(images, layer: page.activeLayer);
    autosaveAfterDelay();
  }

  /// Eraser bar "Clear page": removes all ink and images (undoable).
  Future<void> _clearCurrentPage() async {
    if (coreInfo.readOnly || coreInfo.pages.isEmpty) return;
    final page = coreInfo.pages[currentPageIndex];
    if (page.strokes.isEmpty && page.images.isEmpty) return;
    final ok = await showAppleDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear this page?'),
        content: const Text(
          'All writing and images on it are removed. You can undo this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final strokes = List.of(page.strokes);
    final images = List.of(page.images);
    setState(() {
      page.strokes.clear();
      page.images.clear();
      history.recordChange(HistoricDelete(strokes: strokes, images: images));
    });
    autosaveAfterDelay();
  }

  /// Turns typing mode on (cursor in the page in view) or off (back to
  /// the tool from before).
  void _toggleTextEditing() => setState(() {
    if (currentTool != Tool.textEditing) {
      _toolBeforeTextEditing = currentTool;
      currentTool = Tool.textEditing;
      _focusTypedText(coreInfo.pages[currentPageIndex].quill);
      return;
    }
    currentTool = _toolBeforeTextEditing;
    for (final page in coreInfo.pages) {
      // drop any highlighted text but leave the cursor where it was, and
      // put the keyboard away
      final text = page.quill.controller;
      text.moveCursorToPosition(text.selection.extentOffset);
      page.quill.focusNode.unfocus();
    }
  });

  /// A page's own typed text gets the cursor only if it has some. Otherwise
  /// the cursor would sit in the corner, instead of where the user taps.
  void _focusTypedText(QuillStruct quill) {
    quillFocus.value = quill;
    if (!quill.controller.document.isEmpty()) quill.focusNode.requestFocus();
  }

  void _reorderSelection(bool toFront) {
    final select = currentTool;
    if (select is! Select ||
        !select.doneSelecting ||
        select.selectResult.isEmpty) {
      return;
    }
    final pageIndex = select.selectResult.pageIndex;
    final page = coreInfo.pages[pageIndex];
    final strokesBefore = page.strokes.toList();
    final imagesBefore = page.images.toList();
    setState(() {
      page.reorder(
        select.selectResult.strokes,
        select.selectResult.images,
        toFront: toFront,
      );
      // pictures go over or under the writing too
      for (final image in select.selectResult.images) {
        image.inFront = toFront;
        if (toFront) {
          image.order = max(
            DateTime.now().microsecondsSinceEpoch,
            page.latestFrontOrder(image.layer) + 1,
          );
        }
      }
      // and writing over or under the pictures
      for (final stroke in select.selectResult.strokes) {
        stroke.onFrontImage = toFront;
        stroke.afterImage = toFront ? page.latestFrontOrder(stroke.layer) : -1;
      }
      history.recordChange(
        HistoricReorder(
          pageIndex: pageIndex,
          strokesBefore: strokesBefore,
          imagesBefore: imagesBefore,
          strokesAfter: page.strokes.toList(),
          imagesAfter: page.images.toList(),
        ),
      );
    });
    page.redrawStrokes();
    autosaveAfterDelay();
  }

  /// Just the paper, full screen: fingers and pens only scroll and zoom.
  var _readingMode = false;

  void _toggleReadingMode() {
    FocusManager.instance.primaryFocus?.unfocus();
    Select.currentSelect.unselect();
    setState(() {
      _readingMode = !_readingMode;
      _screenshotOn = false;
    });
    DynamicMaterialApp.setFullscreen(_readingMode, updateSystem: true);
  }



  /// The header across the top (design M_Editor): back, pages, the note's
  /// name or the open notes' tabs, then finger drawing, undo, redo, add
  /// page, share and More. Hidden in full screen unless the tools are kept.
  Widget? _header(BuildContext context) {
    if (_toolsHidden ||
        (DynamicMaterialApp.isFullscreen &&
            !stows.editorToolbarShowInFullscreen.value)) {
      return null;
    }
    final ui = EditorUi.of(context);
    final colors = BadNotesColors.of(context);
    final Widget name = widget.customTitle != null
        ? Text(widget.customTitle!, maxLines: 1, overflow: TextOverflow.ellipsis)
        : Form(
            key: _filenameFormKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: IntrinsicWidth(
              child: TextFormField(
                cursorColor: colors.accent,
                style: BnType.body.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                controller: filenameTextEditingController,
                onChanged: renameFile,
                onFieldSubmitted: (_) => _renameWhenNotSaving(),
                // a finger's tap outside doesn't unfocus a field on Android:
                // the caret stayed on the name while writing on the page
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                autofocus: needsNaming,
                validator: _validateFilenameTextField,
              ),
            ),
          );
    // the main note's: not a note beside it, nor a page with its own title
    final mainNote = widget.onClosePane == null && widget.customTitle == null;
    final phone = MediaQuery.sizeOf(context).width < 600;
    final Widget title = mainNote
        // switching notes would lose a text box being typed
        ? IgnorePointer(
            ignoring: _textBox != null,
            child: phone
                ? NoteTitlePill(
                    path: coreInfo.filePath,
                    name: name,
                    beforeSwitching: saveToFile,
                  )
                // a tablet: the open notes as tabs right in the bar
                : NoteTabsBar(beforeSwitching: saveToFile, activeTitle: name),
          )
        : Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(BnRadius.chip),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(widthFactor: 1, child: name),
          );
    final leading = IconTheme.merge(
      data: IconThemeData(color: ui.icon, size: 20),
      child: widget.onClosePane != null
          ? BnIconButton(
              icon: BnIcons.close,
              tooltip: 'Close this side',
              onPressed: widget.onClosePane,
            )
          // leaving would lose a text box being typed
          : IgnorePointer(
              ignoring: _textBox != null,
              child: SaveIndicator(
                savingState: savingState,
                triggerSave: saveToFile,
              ),
            ),
    );
    final timers = _timer == null && _stopwatch == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              if (_timer != null)
                CountdownChip(
                  key: ValueKey(_timerRun),
                  setup: _timer!,
                  onFinished: _onTimerFinished,
                  onClose: _closeTimer,
                ),
              if (_stopwatch != null)
                StopwatchChip(
                  stopwatch: _stopwatch!,
                  onClose: () => setState(() => _stopwatch = null),
                ),
            ],
          );
    // A tablet: two rows, the open notes' tabs on top, then the buttons
    // either side of the tools (docked) or the page (floating).
    if (mainNote && !phone) {
      final docked = stows.toolbarDocked.value && _showsTools;
      final tabs = DecoratedBox(
        // a shade darker than before, so the white open tab stands out of
        // the strip as a browser's does
        decoration: BoxDecoration(color: colors.sunken),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Row(
            spacing: 8,
            children: [
              leading,
              Expanded(child: title),
            ],
          ),
        ),
      );
      final controls = DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(bottom: BorderSide(color: colors.hairline)),
        ),
        child: ValueListenableBuilder(
          valueListenable: history.changes,
          builder: (context, _, _) => _toolbar(
            context,
            ToolbarPart.header,
            title: docked
                ? _dockedToolRow(context, bottom: false)
                : _toolsInHeader(context)
                ? _headerTools(context)
                : ListenableBuilder(
                    listenable: _transformationController,
                    builder: (context, _) => Text(
                      _isBoard
                          ? ''
                          : 'Page ${currentPageIndex + 1} of '
                                '${coreInfo.pages.length}',
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                  ),
            centerTitle: true,
            undoPill: docked ? _undoRedo(context, floating: false) : null,
            timerChip: timers,
          ),
        ),
      );
      return ColoredBox(
        color: ui.desk,
        child: SafeArea(
          bottom: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [tabs, controls]),
        ),
      );
    }
    final bar = DecoratedBox(
      decoration: BoxDecoration(
        // with tabs (a tablet), a light grey the open tab stands out from
        color: mainNote && !phone ? colors.sunkenSoft : colors.surface,
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: ValueListenableBuilder(
        valueListenable: history.changes,
        builder: (context, _, _) => _toolbar(
          context,
          ToolbarPart.header,
          leading: leading,
          title: title,
          timerChip: timers,
        ),
      ),
    );
    return ColoredBox(
      color: ui.desk,
      child: SafeArea(bottom: false, child: bar),
    );
  }

  /// The tools fixed in a row under the header (or along the bottom), when
  /// the toolbar style is Docked: the tools, then the chosen tool's sizes
  /// and colors, scrolling if they don't fit.
  Widget _dockedTools(BuildContext context, {required bool bottom}) {
    final colors = BadNotesColors.of(context);
    final side = BorderSide(color: colors.hairline);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: bottom ? Border(top: side) : Border(bottom: side),
      ),
      child: SafeArea(
        top: false,
        bottom: bottom,
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              // balances the undo/redo pill, so the tools sit in the middle
              const SizedBox(width: 96),
              Expanded(
                child: Center(
                  child: _dockedToolRow(context, bottom: bottom),
                ),
              ),
              _undoRedo(context, floating: false),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _toolbarMoved() {
    if (mounted) setState(() {});
  }

  /// Where the header's tools are, for the sub-bar to hang under them.
  final _headerToolsLink = LayerLink();

  /// The tools in the header, with a grip to pull them out: let go on the
  /// left, right or bottom of the screen and they float there; a floating
  /// bar let go at the top comes back into the header.
  Widget _headerTools(BuildContext context) {
    final grip = Draggable<Object>(
      axis: null,
      // a light stand-in while dragged: a second live toolbar would bind
      // the shortcuts twice
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: BnToolDock(
            vertical: false,
            children: [
              const BnDragHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Tools',
                  style: BnType.body.copyWith(
                    color: BadNotesColors.of(context).text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: const Opacity(opacity: 0.3, child: BnDragHandle()),
      onDragEnd: (details) {
        final size = MediaQuery.sizeOf(context);
        final at = details.offset;
        final edge = at.dx < size.width * 0.25
            ? ToolbarEdge.left
            : at.dx > size.width * 0.75
            ? ToolbarEdge.right
            : at.dy > size.height * 0.35
            ? ToolbarEdge.bottom
            : null;
        // let go near the top: it stays in the header
        if (edge == null) return;
        HapticFeedback.selectionClick();
        stows.floatingToolbarAlong.value = 0.5;
        stows.floatingToolbarEdge.value = edge.index;
      },
      child: const Tooltip(
        message: 'Drag out to move the tools',
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: BnDragHandle(),
        ),
      ),
    );
    return CompositedTransformTarget(
      link: _headerToolsLink,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [grip, _toolbar(context, ToolbarPart.dock)],
        ),
      ),
    );
  }

  /// Whether the floating style's tools sit in the header's middle, where
  /// "Page 1 of 2" was: on a wide tablet (landscape) with the bar at the
  /// top. The tool's sizes and colors then float just under the header.
  bool _toolsInHeader(BuildContext context) =>
      !stows.toolbarDocked.value &&
      _showsTools &&
      _headerHasTools(context) &&
      MediaQuery.sizeOf(context).width >= 1000 &&
      const {-1, 0}.contains(stows.floatingToolbarEdge.value);

  /// Whether the header (two rows, a tablet's) holds the docked tools.
  bool _headerHasTools(BuildContext context) =>
      widget.onClosePane == null &&
      widget.customTitle == null &&
      MediaQuery.sizeOf(context).width >= 600;

  /// The docked tools and the chosen tool's sizes and colors, scrolling if
  /// they don't fit: under the header on a phone, in its middle on a tablet.
  Widget _dockedToolRow(BuildContext context, {required bool bottom}) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toolbar(context, ToolbarPart.dock),
            if (ToolFloatingBar.hasBar(currentTool)) ...[
              const BnBarDivider(height: 22),
              ToolSubBar(
                currentTool: currentTool,
                setTool: _setTool,
                setColor: _setColor,
                invert: _inkInverted,
                clearPage: _clearCurrentPage,
                removeAllTape: _removeAllTapeOnPage,
                framed: false,
                writingTools: false,
                opensUp: bottom,
              ),
            ],
          ],
        ),
      );

  /// Undo and redo in one pill: floating at the top right, or at the end of
  /// the docked tools.
  Widget _undoRedo(BuildContext context, {required bool floating}) {
    final colors = BadNotesColors.of(context);
    return ValueListenableBuilder(
      valueListenable: history.changes,
      builder: (context, _, _) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: floating ? colors.surface : colors.sunken,
          borderRadius: BorderRadius.circular(floating ? 16 : 12),
          boxShadow: floating ? BnShadows.floating : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BnIconButton(
              icon: BnIcons.undo,
              tooltip: 'Undo',
              color: colors.text2,
              onPressed: history.canUndo ? undo : null,
            ),
            BnIconButton(
              icon: BnIcons.redo,
              tooltip: 'Redo',
              color: colors.text2,
              onPressed: history.canRedo ? redo : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Whether the docked tools show now: when the floating bar would.
  bool get _showsTools =>
      !_readingMode &&
      !_toolsHidden &&
      !coreInfo.readOnly &&
      _textBox == null &&
      _placing == null &&
      _stickyColor == null;

  /// The editor's tools: in one bar, or as the header or the tool dock.
  Toolbar _toolbar(
    BuildContext context,
    ToolbarPart part, {
    Widget? leading,
    Widget? title,
    Axis dockAxis = Axis.horizontal,
    Widget? timerChip,
    Widget? undoPill,
    bool centerTitle = false,
  }) =>Toolbar(
      part: part,
      headerLeading: leading,
      headerTitle: title,
      headerUndo: undoPill,
      centerTitle: centerTitle,
      dockAxis: dockAxis,
      fingerDrawing: stows.editorFingerDrawing.value,
      timerChip: timerChip,
      readOnly: coreInfo.readOnly,
      textBoxOpen: _textBox != null,
      inkInverted: coreInfo.pages.isEmpty
          ? null
          : InnerCanvas.invertsInk(
              coreInfo.pages[currentPageIndex.clamp(
                0,
                coreInfo.pages.length - 1,
              )],
              coreInfo,
              Theme.brightnessOf(context),
            ),
      setTool: _setTool,
      currentTool: currentTool,
      transformSelection: transformSelection,
      duplicateSelection: _duplicateSelection,
      deleteSelection: _deleteSelection,
      setColor: _setColor,
      quillFocus: quillFocus,
      textEditing: currentTool == Tool.textEditing,
      toggleTextEditing: _toggleTextEditing,
      undo: undo,
      isUndoPossible: history.canUndo,
      redo: redo,
      isRedoPossible: history.canRedo,
      toggleFingerDrawing: () {
        final fingersDraw = stows.editorFingerDrawing;
        fingersDraw.value = !fingersDraw.value;
        lastSeenPointerCount = 0;
        if (!fingersDraw.value) {
          _canvasGestureDetectorKey.currentState
              ?.unlockSingleFingerPan();
        }
      },
      pickPhoto: (anchor) => showToolPanel(
        context,
        anchor: anchor,
        page: imagesPage(
          fromFiles: () => _pickPhotos(),
          camera: _takePhoto,
          asBackground: _pickPageBackground,
          insertRecent: (file) async {
            final bytes = await file.readAsBytes();
            final name = file.path.toLowerCase();
            final ext = name.substring(name.lastIndexOf('.'));
            unawaited(RecentImages.add(bytes, ext));
            await _pickPhotos([_PhotoInfo(bytes, ext)]);
          },
        ),
      ),
      addStickyNote: (_) => _toggleStickyTool(),
      stickyNoteActive: _stickyColor != null,
      addSticker: (anchor) => showToolPanel(
        context,
        anchor: anchor,
        page: stickersPage(pick: _placeSticker),
      ),
      addTextBox: () {
        if (currentTool != Tool.textEditing) _toggleTextEditing();
      },
      timerActive: _timer != null || _stopwatch != null,
      toggleTimer: _toggleTimer,
      magnifierOn: _zoomWindowOn,
      toggleMagnifier: _toggleZoomWindow,
      horizontalScroll: CanvasGestureDetector.horizontal,
      setHorizontalScroll: _setHorizontalScroll,
      setTwoPages: _isBoard || MediaQuery.sizeOf(context).width < 900
          ? null
          : _setTwoPages,
      twoPagesOn: _twoPagesHere,
      rulerOn: _ruler != null,
      toggleRuler: _toggleRuler,
      toggleTape: _toggleTape,
      hasPdf: _pdfPages.isNotEmpty,
      pdfDarkMode: _pdfPages.firstOrNull?.darkMode ?? false,
      setPdfDarkMode: _setPdfDarkMode,
      jumpToPage: _showJumpToPageDialog,
      pasteFromNote: _pasteFromNote,
      copyToOtherNote: _copyToOtherNote,
      changeShape: _showChangeShapeDialog,
      audioNotes: audioNotes,
      toggleRecording: _toggleRecording,
      clearPage: _clearCurrentPage,
      reorderSelection: _reorderSelection,
      editSelectionText: _editSelectionText,
      takeScreenshot: () => setState(() => _screenshotOn = true),
      rotatePage: _rotateCurrentPage,
      trashPage: _trashCurrentPage,
      deleteSpecificItems: _deleteSpecificItems,
      showLayers: _showLayers,
      startTapeQuiz: _startTapeQuiz,
      openShareMenu: _openShareMenu,
      addBoardKit: _addBoardKit,
      takePhoto: _takePhoto,
      splitOn: _splitAxis != null,
      openSplit: _openSplit,
      // the pages panel, on its Audio tab, beside the note
      showRecordings: () => setState(() {
        _pagesPanelOpen = true;
        _pagesAudio = true;
      }),
      playFromSelection: _playFromSelection,
      convertSelectionToText: _convertSelectionToText,
      paste: paste,
      exportAsSba: exportAsSba,
      pagesOpen: _pagesPanelOpen,
      togglePages: () => setState(() {
        _pagesPanelOpen = !_pagesPanelOpen;
        _pagesAudio = false;
      }),
      board: _isBoard
          ? (
              paper: _openBoardPaper,
              rename: () => _renameBoard(coreInfo.filePath),
              duplicate: () => _duplicateBoard(coreInfo.filePath),
              fit: _fitBoard,
              delete: () => _deleteBoard(coreInfo.filePath),
            )
          : null,
      openSearch: () => _scaffoldKey.currentState?.openEndDrawer(),
      toggleReadingMode: _toggleReadingMode,
      addPage: _isBoard
          ? (_) => const NewDocumentMenu().newWhiteboard(context)
          : (_) async {
              final currentPageIndex = this.currentPageIndex;
              final added = await _choosePageAfter(currentPageIndex);
              if (added == null || !mounted) return;
              CanvasGestureDetector.scrollToPage(
                pageIndex: added,
                pages: coreInfo.pages,
                screenWidth: _canvasWidth,
                transformationController: _transformationController,
                glide: true,
              );
            },
      pageBookmarked:
          coreInfo.pages.getOrNull(currentPageIndex)?.bookmarked ??
          false,
      toggleBookmark: _isBoard
          ? null
          : () => setState(() {
              final page = coreInfo.pages[currentPageIndex];
              page.bookmarked = !page.bookmarked;
              history.markUnsaved();
              autosaveAfterDelay();
            }),
      duplicatePage: _isBoard
          ? null
          : () => (pageManager(context) as EditorPageManager)
                .duplicatePage(currentPageIndex),
      openNoteSettings: _openNoteSettings,
      openVersionHistory: coreInfo.readOnly ? null : _openVersionHistory,
      saveAsTemplate: coreInfo.readOnly || _isBoard
          ? null
          : () => showSaveTemplateSheet(
              context,
              note: coreInfo,
              pageIndex: currentPageIndex,
            ),
      openTags: widget.customTitle != null
          ? null
          : () => showTagsSheet(context, coreInfo.filePath),
      pageNumber: currentPageIndex + 1,
      pageCount: coreInfo.pages.length,
      // a whole board is far too big to put in one file
      exportAsPdf: _isBoard ? null : exportAsPdf,
      exportAsPng: _isBoard ? _exportBoardPng : exportAsPng,
    );


  void _applyPageOrder(List<EditorPage> order) {
    coreInfo.pages
      ..clear()
      ..addAll(order);
    for (final (i, page) in coreInfo.pages.indexed) {
      page.updatePageIndex(i);
      listenToQuillChanges(page.quill, i);
    }
  }

  /// Puts the pages in a new order, which can be undone.
  void _setPageOrder(List<EditorPage> order) {
    if (coreInfo.readOnly) return;
    final before = coreInfo.pages.toList();
    setState(() {
      _applyPageOrder(order);
      history.recordChange(HistoricPageOrder(before: before, after: order));
    });
    autosaveAfterDelay();
  }

  /// Puts a page from the note's trash back, at the end.
  void _restorePage(EditorPage page) {
    if (coreInfo.readOnly) return;
    setState(() {
      coreInfo.trash.remove(page);
      page.wasTrashed = false;
      coreInfo.pages.add(page);
      final index = coreInfo.pages.length - 1;
      page.updatePageIndex(index);
      listenToQuillChanges(page.quill, index);
      history.recordChange(HistoricPageInsert(pageIndex: index, page: page));
    });
    autosaveAfterDelay();
  }

  /// Removes a page from the note's trash for good.
  void _deletePageForever(EditorPage page) {
    if (coreInfo.readOnly) return;
    setState(() => coreInfo.trash.remove(page));
    history.markUnsaved();
    autosaveAfterDelay();
  }

  Timer? _searchHighlightTimer;

  /// Goes to a search result. In a pdf the words themselves light up. Typed text
  /// and handwriting don't know where their words are, so the page does.
  Future<void> _showSearchHit(SearchHit hit, String query) async {
    if (hit.pageIndex >= coreInfo.pages.length) return;
    final page = coreInfo.pages[hit.pageIndex];
    CanvasGestureDetector.scrollToPage(
      pageIndex: hit.pageIndex,
      pages: coreInfo.pages,
      screenWidth: _canvasWidth,
      transformationController: _transformationController,
    );
    final words = <Rect>[];
    if (hit.bounds case final line?) {
      words.add(line);
    } else if (hit.source == 'Handwriting') {
      words.addAll(
        HandwritingOcr.readPages(
          coreInfo.filePath,
        ).getOrNull(hit.pageIndex)?.find(query) ?? const [],
      );
    }
    if (hit.source == 'PDF') {
      final whole = Offset.zero & page.size;
      try {
        if (page.backgroundImage case final PdfEditorImage pdf) {
          words.addAll(await pdf.findText(query, whole));
        }
        for (final pdf in page.images.whereType<PdfEditorImage>()) {
          words.addAll(await pdf.findText(query, pdf.dstRect));
        }
      } catch (e) {
        log.warning('Could not find the text on the page', e);
      }
    }
    if (!mounted) return;
    page.searchHighlights = words.isEmpty ? [Offset.zero & page.size] : words;
    page.redrawStrokes();
    if (words.isNotEmpty) _scrollToSpot(hit.pageIndex, words.first.center.dy);
    _searchHighlightTimer?.cancel();
    _searchHighlightTimer = Timer(const Duration(seconds: 5), () {
      page.searchHighlights = const [];
      if (mounted) page.redrawStrokes();
    });
  }

  TapeQuiz<Stroke>? _quiz;
  var _quizRevealed = false;

  Stroke? get _quizTape => _quiz?.current;

  void _coverAllTape() {
    for (final page in coreInfo.pages) {
      var changed = false;
      for (final stroke in page.strokes) {
        if (stroke.toolId == .tape && stroke.tapeRevealed) {
          stroke.tapeRevealed = false;
          changed = true;
        }
      }
      if (changed) page.redrawStrokes();
    }
  }

  /// Every tape on every page in reading order, one at a time, like flashcards.
  void _startTapeQuiz() {
    final tapes = [
      for (final page in coreInfo.pages)
        ...page.strokes.where((stroke) => stroke.toolId == .tape).toList()
          ..sort((a, b) => a.bounds.top.compareTo(b.bounds.top)),
    ];
    if (tapes.isEmpty) {
      showBanner(
        context,
        'Cover something with tape first, then quiz yourself',
      );
      return;
    }
    _coverAllTape();
    setState(() {
      _quiz = TapeQuiz(tapes);
      _quizRevealed = false;
    });
    _scrollToSpot(tapes.first.pageIndex, tapes.first.bounds.center.dy);
  }

  /// Brings height [y] of a page into the upper part of the view.
  void _scrollToSpot(int pageIndex, double y) {
    final width = _canvasWidth;
    CanvasGestureDetector.scrollToPage(
      pageIndex: pageIndex,
      pages: coreInfo.pages,
      screenWidth: width,
      transformationController: _transformationController,
    );
    final box = _canvasStackBox;
    if (CanvasGestureDetector.horizontal || box == null) return;
    final page = coreInfo.pages[pageIndex];
    final fit = min(page.size.width, width) / page.size.width;
    final scale = _transformationController.value.approxScale;
    final top = CanvasGestureDetector.getTopOfPage(
      pageIndex: pageIndex,
      pages: coreInfo.pages,
      screenWidth: width,
    );
    final position = (top + y * fit) * scale;
    final translation = _transformationController.value.getTranslation();
    _transformationController.value = _transformationController.value.clone()
      ..setTranslationRaw(
        translation.x,
        min(box.size.height * 0.4 - position, 0.0),
        translation.z,
      );
  }

  void _revealQuizTape() {
    final tape = _quizTape;
    if (tape == null) return;
    tape.tapeRevealed = true;
    coreInfo.pages[tape.pageIndex].redrawStrokes();
    setState(() => _quizRevealed = true);
  }

  void _answerQuiz(bool knewIt) {
    final quiz = _quiz, tape = _quizTape;
    if (quiz == null || tape == null) return;
    tape.tapeRevealed = false;
    coreInfo.pages[tape.pageIndex].redrawStrokes();
    quiz.answer(knewIt: knewIt);
    final next = quiz.current;
    if (next == null) {
      final days = RevisionPlan.quizDone(
        coreInfo.filePath,
        quiz.firstTry,
        quiz.total,
      );
      showBanner(
        context,
        '${quiz.firstTry} of ${quiz.total} known at the first try. '
        'Revise again in $days ${days == 1 ? 'day' : 'days'}',
      );
      return _endQuiz();
    }
    setState(() => _quizRevealed = false);
    _scrollToSpot(next.pageIndex, next.bounds.center.dy);
  }

  void _endQuiz() {
    _coverAllTape();
    setState(() => _quiz = null);
  }

  Future<void> _addBoardKit() async {
    if (coreInfo.readOnly) return;
    final kit = await showBoardKitPicker(context);
    if (kit == null || !mounted) return;
    await _pickPhotos([_PhotoInfo(utf8.encode(kit.svg), '.svg')]);
    if (mounted) setState(() {});
  }

  /// Saves a change to the layers, which isn't in the undo history.
  void _layersChanged(EditorPage page) {
    Select.currentSelect.unselect();
    setState(() {});
    page.redrawStrokes();
    history.markUnsaved();
    autosaveAfterDelay();
  }

  Future<void> _showLayers() async {
    if (coreInfo.readOnly || coreInfo.pages.isEmpty) return;
    final page = coreInfo.pages[currentPageIndex];
    await showLayersSheet(
      context,
      page: page,
      pageNumber: _isBoard ? null : currentPageIndex + 1,
      onChanged: () => _layersChanged(page),
      deleteLayer: (layer) async {
        final hasContent =
            page.strokes.any((stroke) => stroke.layer == layer.id) ||
            page.images.any((image) => image.layer == layer.id);
        if (hasContent) {
          final ok = await showAppleDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Delete ${layer.name}?'),
              content: const Text(
                'Everything on this layer goes with it. Undo brings it back.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (ok != true || !mounted) return;
        }
        final removed = page.removeLayer(layer.id);
        if (hasContent) {
          history.recordChange(
            HistoricDelete(strokes: removed.strokes, images: removed.images),
          );
        }
        _layersChanged(page);
      },
    );
  }

  /// Side by side or one above the other, or null when not split.
  late Axis? _splitAxis = _isMainEditor ? NoteTabs.ownView?.axis : null;

  /// Whether the second view is left of or above this note.
  late var _splitPaneFirst =
      _isMainEditor && (NoteTabs.ownView?.paneFirst ?? false);

  bool get _isMainEditor =>
      widget.onClosePane == null && widget.customTitle == null;

  /// Where a tab being dragged over the canvas would open.
  final _tabDropSide = ValueNotifier<AxisDirection?>(null);
  final _tabDropKey = GlobalKey();

  AxisDirection? _dropSideAt(Offset globalPosition) {
    final box = _tabDropKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return splitSideAt(box.globalToLocal(globalPosition), box.size);
  }

  /// Opens the note of a tab dropped on the canvas, on the side it landed.
  Future<void> _openTabInSplit(String path, Offset globalPosition) async {
    final side = _dropSideAt(globalPosition);
    if (side == null) return;
    final axis = axisDirectionToAxis(side);
    final paneFirst = side == .left || side == .up;
    if (path == coreInfo.filePath) {
      return _setSplit(axis, paneFirst: paneFirst);
    }
    if (_splitAxis != null) _setSplit(null);
    await NoteTabs.openBeside(NoteSplit(path, axis, paneFirst: paneFirst));
  }

  void _setSplit(Axis? axis, {bool? paneFirst}) {
    setState(() {
      _splitAxis = axis;
      _splitPaneFirst = paneFirst ?? _splitPaneFirst;
    });
    if (_isMainEditor) {
      NoteTabs.ownView = axis == null
          ? null
          : (axis: axis, paneFirst: _splitPaneFirst);
    }
  }

  Future<void> _openSplit() async {
    if (_isBoard) {
      showBanner(context, 'A whiteboard has no pages to split');
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: .min,
          children: [
            ListTile(
              leading: const Icon(Icons.vertical_split_outlined),
              title: const Text('Side by side'),
              subtitle: const Text('Another view of this note'),
              onTap: () => Navigator.pop(context, 'horizontal'),
            ),
            ListTile(
              leading: const Icon(Icons.horizontal_split_outlined),
              title: const Text('Top and bottom'),
              subtitle: const Text('Another view of this note'),
              onTap: () => Navigator.pop(context, 'vertical'),
            ),
            if (_isMainEditor)
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Another note'),
                subtitle: const Text(
                  'Next to this one, to read and write on both. '
                  'Or hold a tab and drag it here',
                ),
                onTap: () => Navigator.pop(context, 'note'),
              ),
            if (_splitAxis != null)
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Close split view'),
                onTap: () => Navigator.pop(context, 'close'),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'horizontal':
        _setSplit(.horizontal);
      case 'vertical':
        _setSplit(.vertical);
      case 'note':
        await _splitWithOtherNote();
      case 'close':
        _setSplit(null);
    }
  }

  Future<void> _splitWithOtherNote() async {
    final files = await FileManager.getAllFiles();
    files
      ..remove(coreInfo.filePath)
      ..sort();
    if (!mounted) return;
    final path = await showAppleDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Open next to this note'),
        children: [
          SizedBox(
            width: double.maxFinite,
            height: 360,
            child: files.isEmpty
                ? const Center(child: Text('No other notes yet'))
                : ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(p.basename(files[i])),
                      subtitle: Text(p.dirname(files[i])),
                      onTap: () => Navigator.pop(context, files[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
    if (path == null) return;
    final axis = _splitAxis ?? Axis.horizontal;
    if (_splitAxis != null) _setSplit(null);
    await NoteTabs.openBeside(NoteSplit(path, axis));
  }

  final _screenshotBoundaryKey = GlobalKey();

  /// Where the screenshot frame starts, on the screen.
  Rect? _screenshotStart;

  /// A screenshot of what the lasso picked (design 15): cut to the lasso's
  /// own shape or as a rectangle, with the paper or ink only, in a small
  /// card by the selection. The selection is let go of first, so its
  /// outline isn't in the picture.
  Future<void> _screenshotSelection() async {
    final select = Select.currentSelect;
    final index = select.selectResult.pageIndex;
    if (index < 0 || index >= coreInfo.pages.length) return;
    final page = coreInfo.pages[index];
    final pageBox = page.renderBox;
    final boundary =
        _screenshotBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (pageBox == null || !pageBox.attached || boundary == null) return;
    final lasso = select.selectResult.path.shift(Offset.zero);
    final bounds = lasso.getBounds().inflate(10);
    final near = Rect.fromPoints(
      pageBox.localToGlobal(bounds.topLeft),
      pageBox.localToGlobal(bounds.bottomRight),
    );
    final ratio = min(
      MediaQuery.devicePixelRatioOf(context) * 2,
      3000 / max(near.longestSide, 1),
    );
    setState(select.unselect);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    // the page as it shows, around the selection
    ui.Image? paper;
    try {
      final local = Rect.fromPoints(
        boundary.globalToLocal(near.topLeft),
        boundary.globalToLocal(near.bottomRight),
      );
      // ignore: invalid_use_of_protected_member
      final layer = boundary.layer! as OffsetLayer;
      paper = await layer.toImage(local, pixelRatio: ratio);
    } catch (_) {
      paper = null;
    }
    final k = near.width * ratio / bounds.width; // pixels per page unit
    final size = Size(bounds.width * k, bounds.height * k);

    // the same without the paper: the page's own layer, drawn for a frame
    // with no paper colour or lines. Pictures, sticky notes, typed text
    // and ink all come, in their order on the page.
    ui.Image? noPaper;
    final pageLayer = _repaintBoundaryIn(pageBox);
    if (pageLayer != null) {
      InnerCanvas.hidePaper.value = true;
      try {
        await WidgetsBinding.instance.endOfFrame;
        if (pageLayer.attached) {
          // ignore: invalid_use_of_protected_member
          final layer = pageLayer.layer! as OffsetLayer;
          noPaper = await layer.toImage(bounds, pixelRatio: k);
        }
      } catch (_) {
        noPaper = null;
      } finally {
        InnerCanvas.hidePaper.value = false;
      }
    }
    if (!mounted) {
      paper?.dispose();
      noPaper?.dispose();
      return;
    }

    Future<Uint8List?> make(LassoShotLook look) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      if (look.lassoShape) {
        canvas.clipPath(
          lasso
              .shift(-bounds.topLeft)
              .transform(Matrix4.diagonal3Values(k, k, 1).storage),
        );
      }
      final picture = look.withPaper ? paper : noPaper ?? paper;
      if (picture != null) {
        canvas.drawImageRect(
          picture,
          Offset.zero &
              Size(picture.width.toDouble(), picture.height.toDouble()),
          Offset.zero & size,
          Paint()..filterQuality = FilterQuality.high,
        );
      }
      final image = await recorder.endRecording().toImage(
        max(1, size.width.round()),
        max(1, size.height.round()),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return bytes?.buffer.asUint8List();
    }

    await showLassoShot(
      context,
      near: near,
      fileName:
          '${coreInfo.fileName}_${DateTime.now().millisecondsSinceEpoch}.png',
      make: make,
    );
    paper?.dispose();
    noPaper?.dispose();
  }

  /// The first repaint boundary in [box]: a page's own layer.
  static RenderRepaintBoundary? _repaintBoundaryIn(RenderObject box) {
    if (box is RenderRepaintBoundary) return box;
    RenderRepaintBoundary? found;
    box.visitChildren((child) => found ??= _repaintBoundaryIn(child));
    return found;
  }

  var _screenshotOn = false;

  /// Turns a page and everything on it by a quarter. Typed text stays upright
  /// and wraps again to the new width.
  void _rotatePage(int pageIndex, {required bool clockwise}) {
    final page = coreInfo.pages[pageIndex];
    final angle = clockwise ? pi / 2 : -pi / 2;
    Select.currentSelect.unselect();
    applyTransform(
      page.strokes,
      page.images,
      EditorPage.rotationPivot(page.size, clockwise: clockwise),
      1,
      angle,
    );
    page.backgroundImage?.rotation += angle;
    page.size = page.size.flipped;
    for (final stroke in page.strokes) stroke.page = page;
    for (final image in page.images) image.pageSize = page.size;
    page.redrawStrokes();
  }

  void _rotateCurrentPage(bool clockwise) {
    if (coreInfo.readOnly || coreInfo.pages.isEmpty || _isBoard) return;
    final pageIndex = currentPageIndex;
    setState(() {
      _rotatePage(pageIndex, clockwise: clockwise);
      history.recordChange(
        HistoricPageRotate(pageIndex: pageIndex, clockwise: clockwise),
      );
    });
    autosaveAfterDelay();
  }

  /// There's no trash bin to restore from later: undo brings the page back
  /// until the note is closed.
  Future<void> _trashCurrentPage() async {
    if (coreInfo.readOnly || coreInfo.pages.isEmpty || _isBoard) return;
    final pageIndex = currentPageIndex;
    final ok = await showAppleDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move this page to trash?'),
        content: const Text('You can put it back from Pages, under Trash.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move to trash'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    (pageManager(context) as EditorPageManager).deletePage(pageIndex);
  }

  /// Lets the user pick kinds of content to remove from the current page.
  Future<void> _deleteSpecificItems() async {
    if (coreInfo.readOnly || coreInfo.pages.isEmpty) return;
    final page = coreInfo.pages[currentPageIndex];
    const inkKinds = {
      'Pen': {
        ToolId.fountainPen,
        ToolId.ballpointPen,
        ToolId.calligraphyPen,
        ToolId.brushPen,
      },
      'Pencil': {ToolId.pencil},
      'Highlighter': {ToolId.highlighter},
      'Shapes': {ToolId.shapePen},
      'Tape': {ToolId.tape},
    };
    const imagesKind = 'Images & stickers', textKind = 'Typed text';
    final hasText = !page.quill.controller.document.isEmpty();
    final kinds = [
      for (final MapEntry(:key, :value) in inkKinds.entries)
        if (page.strokes.any((s) => value.contains(s.toolId))) key,
      if (page.images.isNotEmpty) imagesKind,
      if (hasText) textKind,
    ];
    if (kinds.isEmpty) {
      showBanner(context, 'This page is empty');
      return;
    }

    final chosen = <String>{};
    final ok = await showAppleDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete specific items'),
          content: Column(
            mainAxisSize: .min,
            children: [
              for (final kind in kinds)
                CheckboxListTile(
                  title: Text(kind),
                  contentPadding: EdgeInsets.zero,
                  value: chosen.contains(kind),
                  onChanged: (on) => setDialogState(
                    () => on! ? chosen.add(kind) : chosen.remove(kind),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: chosen.isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    final tools = {for (final kind in chosen) ...?inkKinds[kind]};
    final strokes = page.strokes
        .where((s) => tools.contains(s.toolId))
        .toList();
    final images = chosen.contains(imagesKind)
        ? page.images.toList()
        : <EditorImage>[];
    setState(() {
      page.strokes.removeWhere(strokes.contains);
      page.images.removeWhere(images.contains);
      if (strokes.isNotEmpty || images.isNotEmpty) {
        history.recordChange(HistoricDelete(strokes: strokes, images: images));
      }
    });
    // records its own undo step through the page's quill listener
    if (chosen.contains(textKind)) page.quill.controller.clear();
    autosaveAfterDelay();
  }

  /// The note's handwriting gets read again in the new languages for search.
  Future<bool> _chooseHandwritingLanguages() async {
    final changed = await showHandwritingLanguages(context);
    if (changed) _ocrDirty = true;
    return changed;
  }

  /// Each page's text: typed and pdf text at once, then again with
  /// handwriting recognized if the note changed since last time.
  Stream<List<OcrPage>> _searchTexts() async* {
    final pdfTexts = <String>[];
    for (final page in coreInfo.pages) {
      final pdfs = [
        ?page.backgroundImage,
        ...page.images,
      ].whereType<PdfEditorImage>();
      final texts = <String>[];
      for (final pdf in pdfs) {
        try {
          texts.add(await pdf.loadText());
        } catch (e) {
          log.warning('Could not read pdf text', e);
        }
      }
      pdfTexts.add(texts.join(' '));
    }

    List<OcrPage> all() {
      final handwriting = HandwritingOcr.readPages(coreInfo.filePath);
      return [
        for (final (i, page) in coreInfo.pages.indexed)
          OcrPage(
            key: '',
            lines: handwriting.getOrNull(i)?.lines ?? const [],
            typed: page.quill.controller.document.toPlainText(),
            pdf: pdfTexts.getOrNull(i) ?? '',
          ),
      ];
    }

    yield all();
    if (_ocrDirty && !coreInfo.readOnly) {
      _ocrDirty = false;
      await HandwritingOcr.indexNote(coreInfo.filePath, coreInfo.pages);
      yield all();
    }
  }

  /// Record (the toolbar's button, or the Audio tab): stops the recording
  /// going, or asks what to record (sound on or off; the microphone, the
  /// device's sound, or both) and starts one.
  Future<void> _toggleRecording() async {
    final audio = audioNotes;
    if (audio == null || coreInfo.readOnly) return;
    void tell(String msg) {
      if (!mounted) return;
      showBanner(context, msg);
    }

    try {
      if (audio.isRecording) {
        await audio.stopRecording();
        if (mounted) setState(() {});
        return tell('Recording saved: Pages, then the Audio tab');
      }
      final choice = await showRecordingOptions(context);
      if (choice == null || !mounted) return;
      final problem = await audio.startRecording(
        audio: choice.audio,
        mic: choice.mic,
        device: choice.device,
      );
      if (mounted) setState(() {});
      if (problem != null) return tell(problem);
    } catch (e) {
      log.warning('Recording failed', e);
      return tell('Could not record: $e');
    }
    // another app (e.g. a screen recorder) can hold the mic and leave us
    // with silence; say so instead of saving an empty recording
    await Future.delayed(const Duration(seconds: 3));
    if (await audio.isSilent()) {
      tell(
        'No sound from the microphone. Another app (like a screen '
        'recorder) may be using it.',
      );
    }
  }

  /// Whether the ink is following a recording being played, see
  /// [AudioNotes.playbackAt].
  var _inkFollowsAudio = false;

  /// Shows the ink written during the recording being played up to where
  /// the voice is, and all of it again once it's over.
  void _followPlayback() {
    final audio = audioNotes;
    final at = audio?.playbackAt.value;
    if (audio == null || at == null) {
      if (!_inkFollowsAudio) return;
      _inkFollowsAudio = false;
      for (final page in coreInfo.pages) {
        if (page.replayPartial.isNotEmpty || page.replayGhosts.isNotEmpty) {
          page
            ..replayPartial = const []
            ..replayGhosts = const [];
          page.currentStrokeTick.value++;
        }
        if (page.replayShown == null) continue;
        page.replayShown = null;
        page.redrawStrokes();
      }
      return;
    }
    _inkFollowsAudio = true;
    // the free version plays the voice over the notes as they are
    final mode = Pro.has ? stows.playbackMode.value : 'static';
    for (final page in coreInfo.pages) {
      if (mode == 'static') {
        // the notes as they are; only the voice plays
        if (page.replayPartial.isNotEmpty || page.replayGhosts.isNotEmpty) {
          page
            ..replayPartial = const []
            ..replayGhosts = const [];
          page.currentStrokeTick.value++;
        }
        if (page.replayShown != null) {
          page.replayShown = null;
          page.redrawStrokes();
        }
        continue;
      }
      // Real-time reveal, and Spotlight on top of it: what's being written
      // now grows along its line, at the speed it was written, on the top
      // layer, and what's written stays
      final writing = audio.writingAt(page.strokes, at);
      final shown = audio.shownAt(page.strokes, at);
      // Spotlight: what isn't written yet shows faded, so the whole page
      // can be followed (as GoodNotes does)
      final ghosts = mode == 'spotlight' && shown.length < page.strokes.length
          ? [
              for (final stroke in page.strokes)
                if (!shown.contains(stroke)) stroke,
            ]
          : const <Stroke>[];
      if (writing.isNotEmpty ||
          page.replayPartial.isNotEmpty ||
          ghosts.length != page.replayGhosts.length) {
        page
          ..replayPartial = [
            for (final (stroke, part) in writing) ?_partOf(stroke, part),
          ]
          ..replayGhosts = ghosts;
        page.currentStrokeTick.value++;
      }
      final before = page.replayShown;
      if (before != null && before.length == shown.length) continue;
      page.replayShown = shown.length == page.strokes.length ? null : shown;
      if (before == null && page.replayShown == null) continue;
      page.redrawStrokes();
    }
  }

  /// The first [part] of [stroke], as the pen had drawn it; null when there's
  /// nothing to show yet. Shapes and tape show whole once begun.
  static Stroke? _partOf(Stroke stroke, double part) {
    if (stroke.runtimeType != Stroke ||
        stroke.toolId == .shapePen ||
        stroke.toolId == .tape) {
      return stroke;
    }
    return stroke.firstPart(part);
  }

  Future<void> _playFromSelection() async {
    final audio = audioNotes;
    final select = currentTool;
    if (audio == null || select is! Select || !select.doneSelecting) return;
    final found = await audio.playFrom(select.selectResult.strokes);
    if (!found && mounted) {
      showBanner(context, 'These strokes were not written during a recording');
    }
  }

  /// Reads the selected handwriting and copies it, straight away.
  Future<void> _copySelectionAsText() async {
    final select = currentTool;
    if (select is! Select || !select.doneSelecting) return;
    final strokes = select.selectResult.strokes.toList();
    if (strokes.isEmpty) return;
    showBanner(context, 'Reading…');
    try {
      final readings = await HandwritingOcr.recognize(strokes);
      final text = readings.values.firstWhere(
        (t) => t.trim().isNotEmpty,
        orElse: () => '',
      );
      if (!mounted) return;
      if (text.isEmpty) {
        showBanner(context, 'No text recognized');
        return;
      }
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) showBanner(context, 'Copied: $text');
    } catch (e) {
      if (mounted) {
        showBanner(
          context,
          'Recognition failed. Connect to the internet once to download the handwriting model.',
        );
      }
    }
  }

  /// Recognizes the selected handwriting and offers to copy it or
  /// replace the handwriting with a typed text box.
  Future<void> _convertSelectionToText() async {
    final select = currentTool;
    if (select is! Select || !select.doneSelecting) return;
    final strokes = select.selectResult.strokes.toList();
    if (strokes.isEmpty) return;

    Map<String, String> readings;
    try {
      if (mounted) showBanner(context, 'Recognizing…');
      readings = await HandwritingOcr.recognize(strokes);
    } catch (e) {
      if (mounted)
        showBanner(
          context,
          'Recognition failed. Connect to the internet once to download the handwriting model.',
        );
      return;
    }
    if (!mounted) return;
    readings.removeWhere((_, text) => text.trim().isEmpty);
    if (readings.isEmpty) {
      if (mounted) showBanner(context, 'No text recognized');
      return;
    }

    var shownLanguage = readings.keys.first;
    final controller = TextEditingController(text: readings[shownLanguage]);
    final action = await showAppleDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Recognized text'),
          content: Column(
            mainAxisSize: .min,
            spacing: 8,
            children: [
              if (readings.length > 1)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final language in readings.keys)
                      ChoiceChip(
                        label: Text(HandwritingOcr.languages[language]!),
                        selected: language == shownLanguage,
                        onSelected: (_) => setDialogState(() {
                          shownLanguage = language;
                          controller.text = readings[language]!;
                        }),
                      ),
                  ],
                ),
              TextField(controller: controller, maxLines: 8, minLines: 2),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'languages'),
              child: const Text('Languages'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'copy'),
              child: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'replace'),
              child: const Text('Replace with text'),
            ),
          ],
        ),
      ),
    );
    if (action == 'languages' && mounted) {
      controller.dispose();
      if (await _chooseHandwritingLanguages()) {
        return _convertSelectionToText();
      }
      return;
    }
    final text = controller.text;
    controller.dispose();
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) showBanner(context, 'Copied');
    } else if (action == 'replace' && mounted) {
      final page = coreInfo.pages[select.selectResult.pageIndex];
      // the text goes where the handwriting was
      final spot = (
        pageIndex: select.selectResult.pageIndex,
        center: select.selectResult.path.getBounds().center,
      );
      setState(() {
        for (final s in strokes) {
          page.strokes.remove(s);
        }
        select.unselect();
        history.recordChange(HistoricDelete(strokes: strokes, images: []));
      });
      await _pickPhotos([
        _PhotoInfo(
          utf8.encode(stickyNoteToSvg(StickyNoteResult(text, null))),
          '.svg',
        ),
      ], spot);
      if (mounted) setState(() {});
    }
  }

  /// Adds a text box or sticky note to the current page as an SVG image.
  Future<void> _placeSticker(StickerArt sticker) async {
    if (coreInfo.readOnly) return;
    await _pickPhotos([_PhotoInfo(utf8.encode(sticker.svg), '.svg')]);
    if (mounted) setState(() {});
  }

  /// Picture types the photo picker offers: what the image decoder can
  /// read, plus svg.
  static const _pickableImageTypes = [
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff', 'tga', 'ico',
    'psd', 'exr', 'pvrtc', 'svg',
  ];

  /// Lets the user choose pictures from their files and reads them in.
  /// Files without an extension are left out.
  Future<List<_PhotoInfo>> _pickPhotosWithFilePicker() async {
    final chosen = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _pickableImageTypes,
    );
    if (chosen.isEmpty) return const [];

    Future<_PhotoInfo?> read(PlatformFile file) async {
      final type = p.extension(file.path ?? file.name);
      if (type.isEmpty) return null;
      return _PhotoInfo(await file.readAsBytes(), type);
    }

    final photos = await Future.wait(chosen.map(read));
    return photos.nonNulls.toList();
  }

  /// Asks for a pdf file and adds its pages to the note. False if nothing
  /// was added (cancelled, read-only, or pdfs can't be shown here).
  Future<bool> importPdf() async {
    if (coreInfo.readOnly || !Editor.canRasterPdf) return false;

    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked == null) return false;
    return importPdfFromFilePath(picked.path!);
  }

  /// Adds every page of the pdf at [path] as a page of the note, each with
  /// the pdf page as its background. They go before the note's last page,
  /// which is expected to be blank.
  Future<bool> importPdfFromFilePath(String path) async {
    final document = await coreInfo.assetCache.pdfDocumentCache.load(path);
    final pages = coreInfo.pages;

    final blankLast = pages.removeLast();
    assert(blankLast.isEmpty);

    for (final pdfPage in document.pages) {
      assert(pdfPage.pageNumber >= 1, 'pdfrx page numbers start at 1');
      // every page gets the standard width, so pens look the same size on
      // all of them; the height keeps the pdf page's shape
      const width = EditorPage.defaultWidth;
      final size = Size(width, width * pdfPage.height / pdfPage.width);
      final page = EditorPage(
        size: size,
        backgroundImage: PdfEditorImage(
          id: coreInfo.nextImageId++,
          pdfBytes: null,
          pdfFile: File(path),
          pdfPage: pdfPage.pageNumber - 1,
          pageIndex: pages.length,
          pageSize: size,
          naturalSize: pdfPage.size,
          onMoveImage: onMoveImage,
          onDeleteImage: onDeleteImage,
          onMiscChange: _onImageMiscChange,
          onLoad: _setState,
          assetCache: coreInfo.assetCache,
        ),
      );
      pages.add(page);
      // One undo step per page for now. A single step for the whole pdf
      // would be nicer; it needs a grouped page insert.
      history.recordChange(
        HistoricPageInsert(pageIndex: pages.length - 1, page: page),
      );
    }

    pages.add(blankLast);
    if (mounted) setState(() {});
    autosaveAfterDelay();
    return true;
  }

  /// Clipboard picture formats that can be pasted, with the extension each
  /// is saved under when the clipboard gives no file name.
  static const _pastableImages = <SimpleFileFormat, String>{
    Formats.jpeg: '.jpeg',
    Formats.png: '.png',
    Formats.gif: '.gif',
    Formats.tiff: '.tiff',
    Formats.bmp: '.bmp',
    Formats.ico: '.ico',
    Formats.svg: '.svg',
    Formats.webp: '.webp',
  };

  /// Pastes the pictures on the system clipboard into the note.
  Future paste() async {
    final clipboard = await SystemClipboard.instance?.read();
    if (clipboard == null) return;

    final photos = <_PhotoInfo>[];
    final pending = <ReadProgress>[];
    for (final MapEntry(key: format, value: fallbackType)
        in _pastableImages.entries) {
      if (!clipboard.canProvide(format)) continue;
      final progress = clipboard.getFile(format, (file) async {
        final collected = BytesBuilder(copy: false);
        await for (final chunk in file.getStream()) {
          collected.add(chunk);
        }
        final bytes = collected.takeBytes();
        if (bytes.isEmpty) {
          log.warning('Pasted empty file: $file ($fallbackType)');
          return;
        }
        final name = file.fileName;
        final type = name == null
            ? fallbackType
            : name.substring(name.lastIndexOf('.'));
        photos.add(_PhotoInfo(bytes, type));
      });
      if (progress != null) pending.add(progress);
    }

    // the clipboard hands files over in the background: wait for all
    while (pending.isNotEmpty) {
      pending.removeWhere((progress) => progress.fraction.value == 1);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    await _pickPhotos(photos);
  }

  /// Saves the whole note as a pdf wherever the user chooses.
  Future exportAsPdf(BuildContext context) =>
      ExportProgress.run(context, 'Making PDF…', () async {
        final document = await EditorExporter.generatePdf(
          coreInfo,
          context,
          (done, total) => ExportProgress.pages('Making PDF…', done, total),
        );
        ExportProgress.step('Finishing the PDF…');
        final bytes = await document.save();
        if (!context.mounted) return;
        await FileManager.exportFile(
          '${coreInfo.fileName}.pdf',
          bytes,
          context: context,
        );
      });

  /// The PDF of one page, or of the whole note. Null if there's nothing on it.
  Future<Uint8List?> _pdfBytes(BuildContext context, {int? onlyPage}) =>
      _pdfBytesOf(
        context,
        onlyPage == null ? coreInfo.pages : [coreInfo.pages[onlyPage]],
      );

  Future<Uint8List?> _pdfBytesOf(
    BuildContext context,
    List<EditorPage> pages,
  ) async {
    if (pages.every((page) => page.isEmpty)) {
      showBanner(context, 'Nothing to send yet');
      return null;
    }
    return ExportProgress.run(context, 'Making PDF…', () async {
      final pdf = await EditorExporter.generatePdf(
        coreInfo.copyWith(pages: pages),
        context,
        (done, total) => ExportProgress.pages('Making PDF…', done, total),
      );
      ExportProgress.step('Finishing the PDF…');
      return pdf.save();
    });
  }

  /// Exports the picked pages: as PNGs (one, or a zip) or a PDF, in the
  /// format and with the paper Share & Export's "Choose…" asked for; a PDF
  /// with the paper from the pages panel's own Export.
  Future<void> _exportPages(List<int> descending) async {
    final ascending = descending.reversed.toList();
    final pick = _exportPick;
    InnerCanvas.exportWithoutPaper = !(pick?.withPaper ?? true);
    try {
      if (pick?.format == ExportFormat.png) {
        if (ascending.length == 1) {
          await exportAsPng(context, pageIndex: ascending.single, share: true);
        } else {
          await _exportPagesAsPngZip(context, only: ascending);
        }
        return;
      }
      final bytes = await _pdfBytesOf(context, [
        for (final i in ascending) coreInfo.pages[i],
      ]);
      if (bytes == null || !mounted) return;
      final name = ascending.length == 1
          ? '${coreInfo.fileName}_page_${ascending.single + 1}.pdf'
          : '${coreInfo.fileName}_${ascending.length}_pages.pdf';
      await FileManager.exportFile(name, bytes, context: context);
    } catch (e, st) {
      log.severe('Failed to export pages', e, st);
      if (mounted) showBanner(context, 'Could not export these pages');
    } finally {
      InnerCanvas.exportWithoutPaper = false;
    }
  }

  Future<void> _exportThisPageAsPdf(BuildContext context) async {
    final pageIndex = currentPageIndex;
    try {
      final bytes = await _pdfBytes(context, onlyPage: pageIndex);
      if (bytes == null || !context.mounted) return;
      await FileManager.exportFile(
        '${coreInfo.fileName}_page_${pageIndex + 1}.pdf',
        bytes,
        context: context,
      );
    } catch (e, st) {
      log.severe('Failed to export the page', e, st);
      if (context.mounted) showBanner(context, 'Could not export this page');
    }
  }

  Future<void> _print(BuildContext context, {int? onlyPage}) async {
    try {
      final bytes = await _pdfBytes(context, onlyPage: onlyPage);
      if (bytes == null) return;
      await Printing.layoutPdf(
        name: coreInfo.fileName,
        onLayout: (_) async => bytes,
      );
    } catch (e, st) {
      log.severe('Failed to print', e, st);
      if (context.mounted) showBanner(context, 'Could not print');
    }
  }

  /// Exporting, printing and presenting, all from one place.
  /// Share and Export: this page or all of them, printing, and presenting.
  /// Share and Export (design 10): a format, which pages, the paper or
  /// not, then Print, Save or Share; presenting below.
  void _openShareMenu(Rect anchor) => showShareExportCard(
    context,
    anchor: anchor,
    pageCount: coreInfo.pages.length,
    // a whole board is far too big for one PDF page or a printer
    formats: _isBoard
        ? const {ExportFormat.png, ExportFormat.badNotes}
        : const {ExportFormat.pdf, ExportFormat.png, ExportFormat.badNotes},
    allowThisPage: !_isBoard,
    canPrint: !_isBoard,
    presentModes: _isBoard
        ? const {PresentMode.everythingLive, PresentMode.inkOnly}
        : const {
            PresentMode.everythingLive,
            PresentMode.inkOnly,
            PresentMode.fullPageFocus,
          },
    onChoosePages: _isBoard
        ? null
        : (format, withPaper) => setState(() {
            _exportPick = (format: format, withPaper: withPaper);
            _pagesPanelOpen = true;
            _pagesAudio = false;
          }),
    onExport: (format, pages, withPaper, action) =>
        _export(format, pages, withPaper, action),
    onPresent: (mode) => _startLive(switch (mode) {
      PresentMode.everythingLive => LiveMode.everything,
      PresentMode.inkOnly => LiveMode.inkOnly,
      PresentMode.fullPageFocus => LiveMode.wholePage,
    }),
  );

  Future<void> _export(
    ExportFormat format,
    ExportPages pages,
    bool withPaper,
    ExportAction action,
  ) async {
    // "Choose…" opened the pages panel: its selection exports from there
    if (pages == ExportPages.chosen) return;
    final one = pages == ExportPages.thisPage && !_isBoard;
    InnerCanvas.exportWithoutPaper = !withPaper;
    try {
      if (action == ExportAction.print && !_isBoard) {
        return await _print(context, onlyPage: one ? currentPageIndex : null);
      }
      switch (format) {
        case ExportFormat.badNotes:
          await exportAsSba(context);
        case ExportFormat.png:
          // Share opens the share sheet; Save puts it in the gallery
          final share = action == ExportAction.share;
          if (_isBoard) {
            await _exportBoardPng(context, share: share);
          } else if (one) {
            await exportAsPng(context, share: share);
          } else {
            await _exportPagesAsPngZip(context);
          }
        case ExportFormat.pdf:
          if (one) {
            await _exportThisPageAsPdf(context);
          } else {
            await exportAsPdf(context);
          }
      }
    } finally {
      InnerCanvas.exportWithoutPaper = false;
    }
  }

  /// How the screen is being presented, if it is.
  LiveMode? _live;

  bool get _toolsHidden => _live?.hidesTools ?? false;

  Future<void> _openCasting() async {
    var opened = false;
    try {
      opened =
          await const MethodChannel('badnotes/screen')
              .invokeMethod<bool>('openCasting') ??
          false;
    } on PlatformException catch (e, st) {
      log.warning('Could not open screen casting', e, st);
    } on MissingPluginException catch (e, st) {
      log.warning('Could not open screen casting', e, st);
    }
    if (!opened && mounted) {
      showBanner(
        context,
        'Use screen casting in your device\'s quick settings',
      );
    }
  }

  /// Presents the screen in [mode].
  Future<void> _startLive(LiveMode mode) async {
    // the screen stays just as it is: all it takes is casting it
    if (!mode.hidesTools) return _openCasting();
    FocusManager.instance.primaryFocus?.unfocus();
    Select.currentSelect.unselect();
    setState(() {
      _live = mode;
      _screenshotOn = false;
    });
    DynamicMaterialApp.setFullscreen(true, updateSystem: true);
    showBanner(context, 'Hold on the page or go back to end');
    if (mode == .wholePage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitLivePage());
    }
  }

  void _fitLivePage() {
    final box = _canvasStackBox;
    if (!mounted || _live != .wholePage || box == null || !box.hasSize) return;
    final view = CanvasGestureDetector.fitPage(
      pageIndex: currentPageIndex,
      pages: coreInfo.pages,
      viewport: box.size,
    );
    _canvasGestureDetectorKey.currentState?.holdZoom(view.approxScale);
    _transformationController.value = view;
  }

  void _endLive() {
    final hid = _toolsHidden, held = _live == .wholePage;
    setState(() => _live = null);
    if (hid) DynamicMaterialApp.setFullscreen(false, updateSystem: true);
    if (held) _canvasGestureDetectorKey.currentState?.holdZoom(null);
  }

  /// Saves the note with all its pictures in one archive (.sba) file.
  Future exportAsSba(BuildContext context) =>
      ExportProgress.run(context, 'Packing the note…', () async {
        final archive = await coreInfo.saveToSba(
          currentPageIndex: currentPageIndex,
        );
        if (!context.mounted) return;
        await FileManager.exportFile(
          '${coreInfo.fileName}.sba',
          Uint8List.fromList(archive),
          context: context,
        );
      });

  /// Saves one page (the one in view, unless [pageIndex] says) as a png.
  ///
  /// The page is drawn afresh rather than copied off the screen, so the
  /// selection box, the text cursor and other overlays stay out and the
  /// paper colour is right. Its longest side is kept to 3000 pixels at
  /// most, so huge pages don't run out of memory.
  Future exportAsPng(
    BuildContext context, {
    int? pageIndex,
    bool share = false,
  }) => ExportProgress.run(context, 'Making PNG…', () async {
    final index = pageIndex ?? currentPageIndex;
    try {
      final png = await _pagePng(index);
      if (!context.mounted) return;
      final ok = await FileManager.exportFile(
        '${coreInfo.fileName}_page_${index + 1}.png',
        png,
        isImage: true,
        share: share,
        context: context,
      );
      if (mounted && !share) _pngSaved(ok);
    } catch (e, st) {
      log.severe('Failed to export PNG', e, st);
      if (mounted) showBanner(this.context, 'Could not make the PNG');
    }
  });

  /// Page [index] drawn afresh as a png, its longest side 3000 px at most.
  Future<Uint8List> _pagePng(int index) async {
    final longest = coreInfo.pages[index].size.longestSide;
    final picture = await EditorExporter.screenshotPage(
      coreInfo: coreInfo,
      pageIndex: index,
      rasterizeAllStrokes: true,
      pixelRatio: min(1.0, 3000.0 / longest),
    );
    try {
      final png = await picture.toByteData(format: .png);
      return png!.buffer.asUint8List();
    } finally {
      picture.dispose();
    }
  }

  /// Every page as a png, together in one zip, to save or share.
  Future<void> _exportPagesAsPngZip(BuildContext context, {List<int>? only}) =>
      ExportProgress.run(context, 'Making PNGs…', () async {
        final indices =
            only ?? [for (var i = 0; i < coreInfo.pages.length; i++) i];
        final total = indices.length;
        final zip = Archive();
        try {
          for (final (n, i) in indices.indexed) {
            ExportProgress.pages('Making PNGs…', n, total);
            final png = await _pagePng(i);
            if (!mounted) return;
            zip.addFile(
              ArchiveFile('${coreInfo.fileName}_page_${i + 1}.png', png.length, png),
            );
          }
          ExportProgress.step('Zipping $total pages…');
          final bytes = Uint8List.fromList(ZipEncoder().encode(zip));
          if (!context.mounted) return;
          await FileManager.exportFile(
            only == null
                ? '${coreInfo.fileName} (PNG).zip'
                : '${coreInfo.fileName} ($total pages, PNG).zip',
            bytes,
            context: context,
          );
        } catch (e, st) {
          log.severe('Failed to export the pages as PNGs', e, st);
          if (mounted) showBanner(this.context, 'Could not make the PNGs');
        }
      });

  /// Says where a PNG went: it was saved without a word before, and with
  /// photos access refused nothing happened at all.
  void _pngSaved(bool ok) {
    // on a computer it went where the save dialog said
    if (!Platform.isAndroid && !Platform.isIOS) return;
    showBanner(
      context,
      ok ? 'Saved to Photos' : 'Allow photos access to save the PNG',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_lockedPath case final locked?) {
      return LockScreen(
        path: locked,
        onUnlocked: _onUnlocked,
        onClose: widget.onClosePane ?? () => Navigator.of(context).maybePop(),
      );
    }
    // the pages' layout follows this note's two-pages setting
    CanvasGestureDetector.twoPages = _twoPagesHere;
    final colorScheme = ColorScheme.of(context);
    final platform = Theme.of(context).platform;
    final readOnly = coreInfo.readOnly;
    // pulling past either end adds a page, except where pages can't change
    final fixedPages = readOnly || _readingMode || _isBoard;
    final Widget canvas = CanvasGestureDetector(
      key: _canvasGestureDetectorKey,
      filePath: coreInfo.filePath,
      pages: coreInfo.pages,
      initialPageIndex: coreInfo.initialPageIndex,
      transformationController: _transformationController,
      board: _isBoard,
      pageBuilder: pageBuilder,
      // a cheap stand-in for a page while it scrolls into view
      placeholderPageBuilder: (context, pageIndex) => Canvas(
        path: coreInfo.filePath,
        page: coreInfo.pages[pageIndex],
        pageIndex: 0,
        textEditing: false,
        coreInfo: EditorCoreInfo.placeholder,
        currentStroke: null,
        currentSelection: null,
        placeholder: true,
        setAsBackground: null,
        currentTool: currentTool,
        currentScale: double.minPositive,
      ),
      // drawing
      isDrawGesture: isDrawGesture,
      onDrawStart: onDrawStart,
      onDrawUpdate: onDrawUpdate,
      onDrawEnd: onDrawEnd,
      onInteractionEnd: onInteractionEnd,
      updatePointerData: updatePointerData,
      onHovering: onHovering,
      onHoveringEnd: onHoveringEnd,
      onStylusButtonChanged: onStylusButtonChanged,
      isTextEditing: () => currentTool == Tool.textEditing,
      // undo and redo, by button and by two- and three-finger taps
      undo: undo,
      redo: redo,
      onTwoFingerTap: readOnly ? null : _onTwoFingerTap,
      onThreeFingerTap: readOnly ? null : redo,
      // scrolling
      scrollWithFinger: readOnly || _readingMode,
      onPullPastLastPage: fixedPages ? null : addPageAtEnd,
      onPullPastFirstPage: fixedPages ? null : addPageAtStart,
    );

    final readonlyBanner = ReadOnlyBanner(
      coreInfo.readOnlyReason,
      action: coreInfo.readOnlyReason == .versionTooNew
          ? showVersionTooNewDialog
          : null,
    );

    final header = _header(context);

    final boardSheet = _isBoard ? coreInfo.pages.firstOrNull : null;
    final boardColor = boardSheet?.backgroundColor ?? Colors.white;
    final mainCanvas = Stack(
      key: _canvasStackKey,
      fit: StackFit.expand,
      children: [
        Listener(
          onPointerDown: _onCanvasPointerDown,
          onPointerMove: _onCanvasPointerMove,
          onPointerUp: _onCanvasPointerUp,
          onPointerCancel: (_) {
            _longPressTimer?.cancel();
            _pointersDown = max(_pointersDown - 1, 0);
            if (_pointersDown == 0) _hadMultiTouch = false;
            _tapDownAt = null;
          },
          child: _withFrozenView(RepaintBoundary(
            key: _screenshotBoundaryKey,
            child: boardSheet == null
                ? canvas
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: BoardPaperPainter(
                          pattern:
                              boardSheet.backgroundPattern ??
                              CanvasBackgroundPattern.none,
                          spacing: boardSheet.lineHeight ?? 40,
                          color: boardColor,
                          invert:
                              stows.editorAutoInvert.value &&
                              Theme.of(context).brightness == .dark,
                          transformation: _transformationController,
                        ),
                      ),
                      canvas,
                    ],
                  ),
          )),
        ),
        if (_ruler != null && !_readingMode)
          Positioned.fill(child: RulerOverlay(ruler: _ruler!)),
        if (!_isBoard && !_toolsHidden)
          Positioned.fill(
            child: PageSlider(
              pages: coreInfo.pages,
              transformationController: _transformationController,
              onTap: _showJumpToPageDialog,
            ),
          ),
        if (_zoomWindowOn && !_readingMode)
          Positioned.fill(
            child: ZoomWindow(
              pages: coreInfo.pages,
              initialPageIndex: _zoomWindowPage,
              initialOrigin: _zoomWindowOrigin,
              transformationController: _transformationController,
              canvasBuilder: _zoomWindowCanvas,
              canDraw: (kind) =>
                  stows.editorFingerDrawing.value ||
                  kind == PointerDeviceKind.stylus ||
                  kind == PointerDeviceKind.invertedStylus,
              updatePointerData: updatePointerData,
              onDrawStart: (pageIndex, point) {
                _drawingInZoomWindow = true;
                dragPageIndex = pageIndex;
                onDrawStart(ScaleStartDetails(focalPoint: point));
              },
              onDrawUpdate: (point) =>
                  onDrawUpdate(ScaleUpdateDetails(focalPoint: point)),
              onDrawEnd: () {
                onDrawEnd(ScaleEndDetails());
                _drawingInZoomWindow = false;
              },
              onClose: _toggleZoomWindow,
            ),
          ),
        if (!_isBoard && !_toolsHidden)
          Positioned(
            right: CanvasGestureDetector.horizontal
                ? 8
                : 36, // clear of the slider
            bottom: _readingMode
                ? 72 // clear of the exit button
                : (CanvasGestureDetector.horizontal ? 36 : 8),
            child: IgnorePointer(
              child: ListenableBuilder(
                listenable: _transformationController,
                // "12 of 24 · 100%", quiet in the corner
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 14,
                  ),
                  child: Text(
                    '${currentPageIndex + 1} of ${coreInfo.pages.length} · '
                    '${(_transformationController.value.getMaxScaleOnAxis() * 100).round()}%',
                    style: BnType.caption.copyWith(
                      color: BadNotesColors.of(context).muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // comes and goes with a fade, looking like the other bars
        AnimatedSwitcher(
          duration: BnMotion.fast,
          transitionBuilder: (child, animation) => bnPopIn(
            context,
            animation,
            child,
            alignment: Alignment.bottomCenter,
          ),
          child:
              !(_placing != null ||
                  _stickyColor != null ||
                  (currentTool == Tool.textEditing &&
                      _textBox == null &&
                      !_readingMode &&
                      !coreInfo.readOnly))
              ? const SizedBox.shrink()
              : Align(
                  key: const ValueKey('hint'),
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24,
                      left: 16,
                      right: 16,
                    ),
                    child: Material(
                      color: EditorUi.of(context).bar,
                      elevation: 4,
                      shadowColor: Colors.black38,
                      borderRadius: BorderRadius.circular(EditorUi.barRadius),
                      child: Row(
                        mainAxisSize: .min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Icon(
                              Icons.info_outline,
                              size: 18,
                              color: EditorUi.of(context).iconDim,
                            ),
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              child: Text(
                                _stickyColor != null
                                    ? 'Tap to add a sticky note.'
                                    : _placing != null
                                    ? 'Tap where you want it.'
                                    : 'Tap to add a text box.',
                                style: BnType.body.copyWith(
                                  color: EditorUi.of(context).text,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cancel',
                            visualDensity: VisualDensity.compact,
                            color: EditorUi.of(context).iconDim,
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() {
                              _placing = null;
                              _stickyColor = null;
                              if (currentTool == Tool.textEditing) {
                                _toggleTextEditing();
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        if (!_readingMode &&
            !_toolsHidden &&
            !coreInfo.readOnly &&
            _textBox == null &&
            (_placing == null || _stickyColor != null)) ...[
          if (currentTool is Select &&
              Select.currentSelect.doneSelecting &&
              !Select.currentSelect.selectResult.isEmpty)
            // out of the way while the selection is moved, turned or
            // resized; back where it now is once the finger lifts
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _selectionBusy,
                // fades in as the lasso closes: it popped up all at once
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : BnMotion.fast,
                  curve: BnMotion.curve,
                  builder: (context, shown, child) =>
                      Opacity(opacity: shown, child: child),
                  child: AnimatedOpacity(
                    opacity: _selectionBusy ? 0 : 1,
                    duration: BnMotion.fast,
                    curve: BnMotion.curve,
                    child: _selectionActionBar(),
                  ),
                ),
              ),
            ),
          if (_stickyColor != null)
            Positioned.fill(child: _stickyBar())
          else if (!stows.toolbarDocked.value) ...[
            // undo and redo float at the top right, clear of the tools
            Positioned(
              top: 14,
              right: 16,
              child: _undoRedo(context, floating: true),
            ),
            if (_toolsInHeader(context))
              // the tools are in the header: only their sizes and colors
              // float, just under it
              if (ToolFloatingBar.hasBar(currentTool))
                // hung under the tools wherever they are, so the two stay
                // lined up (the pages panel beside the note, a turn)
                Positioned(
                  top: 0,
                  left: 0,
                  child: CompositedTransformFollower(
                    link: _headerToolsLink,
                    showWhenUnlinked: false,
                    targetAnchor: Alignment.bottomCenter,
                    followerAnchor: Alignment.topCenter,
                    offset: const Offset(0, 22),
                    child: ToolSubBar(
                      currentTool: currentTool,
                      setTool: _setTool,
                      setColor: _setColor,
                      invert: _inkInverted,
                      clearPage: _clearCurrentPage,
                      removeAllTape: _removeAllTapeOnPage,
                      writingTools: false,
                      opensUp: false,
                    ),
                  ),
                )
              else
                const SizedBox.shrink()
            else
              Positioned.fill(
                child: ToolFloatingBar(
                  currentTool: currentTool,
                  setTool: _setTool,
                  setColor: _setColor,
                  invert: _inkInverted,
                  clearPage: _clearCurrentPage,
                  removeAllTape: _removeAllTapeOnPage,
                  dock: (axis) =>
                      _toolbar(context, ToolbarPart.dock, dockAxis: axis),
                ),
              ),
          ],
        ],
        if (_textBox != null && !_readingMode)
          Positioned.fill(child: _textBoxOverlay()),
        if (_noteTyping != null && !_readingMode)
          Positioned.fill(child: _noteTypingOverlay()),
        if (_readingMode)
          Positioned.fill(
            child: ReadingTools(
              pages: coreInfo.pages,
              transformationController: _transformationController,
              isTouching: () => _pointersDown > 0,
            ),
          ),
        // the board's map, bottom right
        if (boardSheet != null && !_readingMode && !_toolsHidden)
          Positioned(
            right: 12,
            bottom: 12,
            child: BoardMap(
              page: boardSheet,
              repositioned: _transformationController,
              visible: _boardVisible,
              // as a notebook's zoom: 100% is how the board opened
              zoom: () => _transformationController.value.approxScale,
              centerOn: _centerBoardOn,
              zoomTo: (scale) => _zoomBoardTo(
                _boardZoom() *
                    scale /
                    _transformationController.value.approxScale,
              ),
              fit: _fitBoard,
              writingAt: _inkingAt,
            ),
          ),
        if (_quiz case final quiz?)
          Positioned(
            left: 8,
            right: 8,
            bottom: 12,
            child: Center(
              child: TapeQuizBar(
                done: quiz.done,
                total: quiz.total,
                revealed: _quizRevealed,
                onReveal: _revealQuizTape,
                onAnswer: _answerQuiz,
                onClose: _endQuiz,
              ),
            ),
          ),
        // palm rejection's test: touches it ignored, as grey dots for 2 s
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder(
              valueListenable: PalmRejection.ignoredTouches,
              builder: (context, points, _) {
                if (points.isEmpty) return const SizedBox.shrink();
                final box = context.findRenderObject() as RenderBox?;
                if (box == null || !box.hasSize) return const SizedBox.shrink();
                return Stack(
                  children: [
                    for (final p in points)
                      Positioned(
                        left: box.globalToLocal(p).dx - 7,
                        top: box.globalToLocal(p).dy - 7,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        // opening: the page as it was left, until the note is read
        if (_openingPicture case final picture?
            when coreInfo.readOnlyReason == .placeholder)
          Positioned.fill(
            child: IgnorePointer(
              child: Image.file(
                picture,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                gaplessPlayback: true,
              ),
            ),
          ),
        // after a copy: Paste, here or in another note (design 16)
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: PastePill(
              enabled: !coreInfo.readOnly && !_readingMode,
              onPaste: _pasteFromNote,
            ),
          ),
        ),
        // recording: stop and the time, at the top right under undo
        if (audioNotes != null)
          Positioned(
            top: stows.toolbarDocked.value ? 14 : 70,
            right: 16,
            child: RecordingPill(
              audio: audioNotes!,
              onStop: _toggleRecording,
            ),
          ),
        if (_screenshotOn)
          Positioned.fill(
            child: ScreenshotOverlay(
              boundaryKey: _screenshotBoundaryKey,
              fileName:
                  '${coreInfo.fileName}_${DateTime.now().millisecondsSinceEpoch}.png',
              initialGlobal: _screenshotStart,
              onPin: (png) async {
                await QuickBoard.load();
                await QuickBoard.addPhoto(png);
              },
              onClose: () => setState(() {
                _screenshotOn = false;
                _screenshotStart = null;
              }),
            ),
          ),
      ],
    );

    final splitAxis = _splitAxis;
    final Widget splitOrCanvas = splitAxis == null || _readingMode
        ? mainCanvas
        : NoteSplitView(
            axis: splitAxis,
            main: mainCanvas,
            paneFirst: _splitPaneFirst,
            title: 'This note',
            pages: coreInfo.pages,
            canvasBuilder: _zoomWindowCanvas,
            updatePointerData: updatePointerData,
            onDrawStart: coreInfo.readOnly
                ? null
                : (pageIndex, point) {
                    _drawingInZoomWindow = true;
                    dragPageIndex = pageIndex;
                    onDrawStart(ScaleStartDetails(focalPoint: point));
                  },
            onDrawUpdate: (point) =>
                onDrawUpdate(ScaleUpdateDetails(focalPoint: point)),
            onDrawEnd: () {
              onDrawEnd(ScaleEndDetails());
              _drawingInZoomWindow = false;
            },
            onSwitch: () => _setSplit(splitAxis, paneFirst: !_splitPaneFirst),
            onFlip: () =>
                _setSplit(splitAxis == .horizontal ? .vertical : .horizontal),
            onClose: () => _setSplit(null),
          );
    final canvasArea = DragTarget<String>(
      onWillAcceptWithDetails: (_) => _isMainEditor,
      onMove: (details) => _tabDropSide.value = _dropSideAt(details.offset),
      onLeave: (_) => _tabDropSide.value = null,
      onAcceptWithDetails: (details) {
        _tabDropSide.value = null;
        _openTabInSplit(details.data, details.offset);
      },
      builder: (context, _, _) => Stack(
        key: _tabDropKey,
        fit: StackFit.expand,
        children: [
          splitOrCanvas,
          ValueListenableBuilder(
            valueListenable: _tabDropSide,
            builder: (context, side, _) => side == null
                ? const SizedBox.shrink()
                : IgnorePointer(
                    child: Align(
                      alignment: switch (side) {
                        .left => Alignment.centerLeft,
                        .right => Alignment.centerRight,
                        .up => Alignment.topCenter,
                        .down => Alignment.bottomCenter,
                      },
                      child: FractionallySizedBox(
                        widthFactor: axisDirectionToAxis(side) == .horizontal
                            ? 0.5
                            : 1,
                        heightFactor: axisDirectionToAxis(side) == .vertical
                            ? 0.5
                            : 1,
                        child: ColoredBox(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                          child: Center(
                            child: Text(
                              'Open here',
                              style: TextTheme.of(context).titleMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );

    final docked = stows.toolbarDocked.value && _showsTools;
    final dockedBottom =
        docked &&
        stows.dockedToolsBottom.value &&
        MediaQuery.sizeOf(context).width < 600;
    final Widget body = Column(
      children: [
        ?header,
        // a tablet has the docked tools in the header's middle
        if (docked &&
            !dockedBottom &&
            !(header != null && _headerHasTools(context)))
          _dockedTools(context, bottom: false),
        // what the color picker picks from
        Expanded(
          child: RepaintBoundary(key: _pickKey, child: canvasArea),
        ),
        if (dockedBottom) _dockedTools(context, bottom: true),
        readonlyBanner,
      ],
    );

    return ValueListenableBuilder(
      valueListenable: savingState,
      // leaving waits for the note to be saved
      builder: (context, state, child) => PopScope(
        canPop: state == .saved,
        onPopInvokedWithResult: (didPop, _) =>
            _onLeave(context, state, didPop),
        child: child!,
      ),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _becomeActiveEditor(),
        child: PopScope(
          // back leaves reading mode before it leaves the note
          canPop: !_readingMode && !_toolsHidden,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_toolsHidden) {
              _endLive();
            } else if (_readingMode) {
              _toggleReadingMode();
            }
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: EditorUi.of(context).desk,
            // opens from its button: a swipe from the edge would stop the pen
            endDrawerEnableOpenDragGesture: false,
            endDrawer: NoteSearchPanel(
              texts: _searchTexts,
              pages: coreInfo.pages,
              chooseLanguages: _chooseHandwritingLanguages,
              showHit: _showSearchHit,
            ),
            // The pages view takes the place of the note and its toolbar. The note
            // stays built underneath, only hidden, so it keeps its zoom and scroll
            // and isn't painted while the pages are.
            body: Stack(
              fit: StackFit.expand,
              children: [
                Row(
                  children: [
                    // on a tablet, the pages open as a sidebar on the left
                    if (_showsPagesView && _pagesBeside) ...[
                      SizedBox(
                        width: 300,
                        child: KeyedSubtree(
                          key: ValueKey('pages-panel-$_pagesAudio'),
                          child: _buildPagesPanel(context),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                    ],
                    Expanded(
                      child: Offstage(
                        key: const ValueKey('editor-body'),
                        offstage: _showsPagesView && !_pagesBeside,
                        child: body,
                      ),
                    ),
                  ],
                ),
                if (_showsPagesView && !_pagesBeside)
                  KeyedSubtree(
                    key: ValueKey('pages-panel-$_pagesAudio'),
                    child: _buildPagesPanel(context),
                  ),
              ],
            ),
            floatingActionButton: _readingMode
                ? FloatingActionButton.small(
                    // two editors side by side mustn't share a hero
                    heroTag: null,
                    tooltip: 'Exit reading mode',
                    onPressed: _toggleReadingMode,
                    child: const Icon(Icons.close_fullscreen),
                  )
                : _toolsHidden
                ? null
                : (DynamicMaterialApp.isFullscreen &&
                      !stows.editorToolbarShowInFullscreen.value)
                ? FloatingActionButton(
                    heroTag: null,
                    shape: platform.isCupertino ? const CircleBorder() : null,
                    onPressed: () {
                      DynamicMaterialApp.setFullscreen(
                        false,
                        updateSystem: true,
                      );
                    },
                    child: const Icon(Icons.fullscreen_exit),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void snackBarNeedsToSaveBeforeExiting() {
    if (!mounted) return;
    showBanner(context, t.editor.needsToSaveBeforeExiting);
  }

  void _openNoteSettings() =>
      showApplePopover(
    context,
    width: 440,
    builder: (context) => bottomSheet(context),
  );

  /// Gives the current page [template]'s paper (its writing isn't copied).
  void _usePaperOf(MyTemplate template) {
    if (coreInfo.readOnly || coreInfo.pages.isEmpty) return;
    final page = coreInfo.pages[currentPageIndex];
    final paper = template.paper;
    setState(() {
      page
        ..backgroundPattern = paper.pattern
        ..lineHeight = paper.lineHeight
        ..backgroundColor = paper.color;
    });
    history.markUnsaved();
    autosaveAfterDelay();
  }

  /// Back was pressed while the note was in [state]. Unsaved changes are
  /// saved first and the note is then left by itself, without a second
  /// press; during a save the user is asked to wait.
  void _onLeave(BuildContext context, SavingState state, bool didPop) {
    LagRecorder.step('leave pressed');
    LagRecorder.doing('leaving note', lasts: const Duration(seconds: 3));
    LagRecorder.note('leave pressed', {'saving': state.name});
    switch (state) {
      case .saved:
        break;
      case .saving:
        assert(!didPop);
        snackBarNeedsToSaveBeforeExiting();
      case .waitingToSave:
        assert(!didPop);
        // no thumbnail yet: drawing it first held up leaving by up to half
        // a second; it's made once the home screen shows
        final navigator = Navigator.of(context);
        saveToFile(thumbnail: false).then((_) {
          // only while the note is still on top: pressed again meanwhile,
          // back had already left it, and this popped the page under it
          if (mounted &&
              savingState.value == .saved &&
              (ModalRoute.of(this.context)?.isCurrent ?? false)) {
            navigator.maybePop();
          }
        });
    }
  }

  /// The page-settings sheet (paper, lines, pictures, watching the server)
  /// for the page in view.
  Widget bottomSheet(BuildContext context) {
    final invert =
        stows.editorAutoInvert.value && Theme.brightnessOf(context) == .dark;
    final pageIndex = currentPageIndex;

    void saveUnlessReadOnly(void Function() change) => setState(() {
      if (coreInfo.readOnly) return;
      change();
      autosaveAfterDelay();
    });

    return EditorBottomSheet(
      // my templates, as small as the papers: picking one gives this page
      // its paper
      mine: coreInfo.readOnly || _isBoard
          ? null
          : MyTemplatesRail(
              selected: null,
              tileWidth: 66,
              onPick: (template) {
                if (template == null) return;
                _usePaperOf(template);
                Navigator.pop(context);
              },
            ),
      invert: invert,
      coreInfo: coreInfo,
      currentPageIndex: pageIndex,
      setBackgroundPattern: (pattern, {required allPages}) =>
          saveUnlessReadOnly(
            () => _setBackgroundPattern(pattern, pageIndex, allPages),
          ),
      setLineHeight: (lineHeight) => saveUnlessReadOnly(() {
        coreInfo.lineHeight = lineHeight;
        // a page with its own spacing (from one of my templates) didn't
        // move with the slider, while the papers in the sheet did
        coreInfo.pages.getOrNull(pageIndex)?.lineHeight = null;
        stows.lastLineHeight.value = lineHeight;
      }),
      setLineThickness: (lineThickness) => saveUnlessReadOnly(() {
        coreInfo.lineThickness = lineThickness;
        stows.lastLineThickness.value = lineThickness;
      }),
      removeBackgroundImage: () => setState(() {
        if (coreInfo.readOnly) return;
        // the background becomes an ordinary picture on the page
        final page = coreInfo.pages[pageIndex];
        final background = page.backgroundImage;
        if (background == null) return;
        page.images.add(background);
        page.backgroundImage = null;
        autosaveAfterDelay();
      }),
      redrawImage: _setState,
      clearPage: () => clearPage(pageIndex),
      clearAllPages: clearAllPages,
      redrawAndSave: () => saveUnlessReadOnly(() {}),
      pickPhotos: _pickPhotos,
      importPdf: importPdf,
      canRasterPdf: Editor.canRasterPdf,
      getIsWatchingServer: () => _watchServerTimer?.isActive ?? false,
      setIsWatchingServer: _watchServer,
    );
  }

  /// Gives page [pageIndex] the lines/grid [pattern], or with [allPages]
  /// every page (except board sheets) and the note's default for new ones.
  /// One undo step either way.
  void _setBackgroundPattern(
    CanvasBackgroundPattern pattern,
    int pageIndex,
    bool allPages,
  ) {
    stows.lastBackgroundPattern.value = pattern;
    // the next new notebook starts on this paper too
    final last = PaperKind.all
        .where((kind) => kind.name == stows.lastPaperName.value)
        .firstOrNull;
    if (last?.pattern != pattern) {
      final papers = PaperKind.all.where((kind) => kind.pattern == pattern);
      if (papers.firstOrNull case final paper?) {
        stows.lastPaperName.value = paper.name;
      }
    }
    final pages = coreInfo.pages;
    if (!allPages) {
      final page = pages[pageIndex];
      final previous = page.backgroundPattern ?? coreInfo.backgroundPattern;
      page.backgroundPattern = pattern;
      history.recordChange(
        HistoricBackgroundPatternChange(
          pageIndex: pageIndex,
          change: Change(previous: previous, current: pattern),
        ),
      );
      return;
    }
    final indexes = [
      for (final (i, page) in pages.indexed)
        if (!page.isBoard) i,
    ];
    history.recordChange(
      HistoricPagesPatternChange(
        pageIndexes: indexes,
        before: [for (final i in indexes) pages[i].backgroundPattern],
        after: [for (final _ in indexes) pattern],
      ),
    );
    for (final i in indexes) {
      pages[i].backgroundPattern = pattern;
    }
    coreInfo.backgroundPattern = pattern;
  }

  /// Starts or stops checking the server every few seconds for a newer copy
  /// of this note. While watching, the note is read-only.
  void _watchServer(bool watch) {
    if (!watch) {
      _watchServerTimer?.cancel();
      _watchServerTimer = null;
      if (coreInfo.readOnlyReason != .watchingServer) return;
      coreInfo.readOnlyReason = null;
      if (mounted) setState(() {});
      return;
    }
    _watchServerTimer ??= Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshCurrentNote(),
    );
    if (coreInfo.readOnlyReason == .watchingServer) return;
    assert(coreInfo.readOnlyReason == null);
    coreInfo.readOnlyReason = .watchingServer;
    if (mounted) setState(() {});
  }

  /// Builds page [pageIndex] of the note.
  Widget pageBuilder(BuildContext context, int pageIndex) {
    final page = coreInfo.pages[pageIndex];
    final stroke = Pen.currentStroke;
    final tool = currentTool;
    final selection = tool is Select && tool.selectResult.pageIndex == pageIndex
        ? tool.selectResult
        : null;
    return Canvas(
      path: coreInfo.filePath,
      page: page,
      pageIndex: pageIndex,
      textEditing: !_readingMode && tool == Tool.textEditing,
      coreInfo: coreInfo,
      currentStroke: stroke?.page == page ? stroke : null,
      currentSelection: selection,
      setAsBackground: (image) => _setAsBackground(page, image),
      // a selection tool would let pictures be picked up
      currentTool: _readingMode ? Pen.currentPen : tool,
      currentScale: _transformationController.value.approxScale,
    );
  }

  /// Makes [image] the background of [page]. A background it already had
  /// goes back to being an ordinary picture.
  void _setAsBackground(EditorPage page, EditorImage image) {
    final previous = page.backgroundImage;
    if (previous != null) page.images.add(previous);
    page.images.remove(image);
    page.backgroundImage = image;
    // whatever picture was being edited lets go
    CanvasImage.activeListener.notifyListenersPlease();
    autosaveAfterDelay();
    setState(() {});
  }

  /// The pages list: reorder, duplicate, clear and delete pages.
  Widget pageManager(BuildContext context) {
    void unlessReadOnly(void Function() change) => setState(() {
      if (coreInfo.readOnly) return;
      change();
      autosaveAfterDelay();
    });

    return EditorPageManager(
      coreInfo: coreInfo,
      currentPageIndex: currentPageIndex,
      redrawAndSave: () => unlessReadOnly(() {}),
      insertPageAfter: _choosePageAfter,
      duplicatePage: (pageIndex) => unlessReadOnly(() => _duplicatePage(pageIndex)),
      clearPage: clearPage,
      deletePage: (pageIndex) => unlessReadOnly(() => _deletePage(pageIndex)),
      transformationController: _transformationController,
    );
  }

  /// Puts a copy of page [pageIndex] (ink, pictures, text, background and
  /// lines) right after it, as one undo step.
  void _duplicatePage(int pageIndex) {
    final page = coreInfo.pages[pageIndex];
    final at = pageIndex + 1;
    final text = flutter_quill.Document.fromDelta(
      page.quill.controller.document.toDelta(),
    );
    final copy = page.copyWith(
      strokes: [
        for (final stroke in page.strokes) stroke.copy()..pageIndex += 1,
      ],
      images: [
        for (final image in page.images)
          image.copy()
            ..pageIndex += 1
            ..layer = image.layer,
      ],
      quill: QuillStruct(
        controller: flutter_quill.QuillController(
          document: text,
          selection: const TextSelection.collapsed(offset: 0),
        ),
        focusNode: FocusNode(debugLabel: 'Quill Focus Node'),
      ),
      backgroundImage: page.backgroundImage?.copy()?..pageIndex += 1,
    )..backgroundPattern = page.backgroundPattern;
    coreInfo.pages.insert(at, copy);
    listenToQuillChanges(copy.quill, at);
    // the pages after it moved down one: undo found their ink by the old
    // numbers, and did nothing or acted on the wrong page
    _renumberPagesFrom(at + 1);
    Select.currentSelect.unselect();
    history.recordChange(HistoricPageInsert(pageIndex: at, page: copy));
  }

  /// Takes page [pageIndex] out, as one undo step. A page with anything on
  /// it goes to the trash; an empty one is simply dropped.
  void _deletePage(int pageIndex) {
    final onlyPage = coreInfo.pages.length == 1;
    final page = coreInfo.pages.removeAt(pageIndex);
    page.wasTrashed = page.isNotEmpty;
    if (page.wasTrashed) coreInfo.trash.add(page);
    createPage(pageIndex - 1);
    _renumberPagesFrom(pageIndex);
    // a selection on a page after it would now point at another page
    Select.currentSelect.unselect();
    history.recordChange(
      HistoricPageDelete(pageIndex: pageIndex, page: page, onlyPage: onlyPage),
    );
  }

  EditorPage? _pageBeside(int pageIndex) =>
      coreInfo.pages.getOrNull(pageIndex) ?? coreInfo.pages.firstOrNull;

  /// Asks where the page goes and what it should look like, then adds it.
  /// Completes with its index, or null if none was added.
  Future<int?> _choosePageAfter(
    int pageIndex, {
    PagePosition position = PagePosition.after,
  }) async {
    if (coreInfo.readOnly || _isBoard) return null;
    final choice = await showNewPageSheet(
      context,
      current: _pageBeside(pageIndex),
      noteLineHeight: coreInfo.lineHeight,
      noteLineThickness: coreInfo.lineThickness,
      noteColor: coreInfo.backgroundColor,
      position: position,
      note: coreInfo,
      pageIndex: pageIndex,
    );
    if (choice == null || !mounted) return null;
    if (choice.source == .import) {
      await importPdf();
      return null;
    }

    final photos = switch (choice.source) {
      final source? => await _photosFrom(source),
      null => const <_PhotoInfo>[],
    };
    if (choice.source != null && photos.isEmpty) return null;
    if (!mounted) return null;

    final after = switch (choice.position) {
      .before => pageIndex - 1,
      .after => pageIndex,
      .last => coreInfo.pages.length - 1,
    };
    // one of my templates: its page, with what's on it
    if (choice.mine case final mine? when photos.isEmpty) {
      final page = await MyTemplates.loadPage(mine, into: coreInfo);
      if (!mounted) return null;
      for (final image in [?page.backgroundImage, ...page.images]) {
        image
          ..onMoveImage = onMoveImage
          ..onDeleteImage = onDeleteImage
          ..onMiscChange = _onImageMiscChange;
      }
      insertPageAfter(after, null, page);
      return after + 1;
    }
    if (photos.isEmpty) {
      insertPageAfter(after, choice.template);
      return after + 1;
    }
    // a scan can have many pages, each gets its own
    for (final (i, photo) in photos.indexed) {
      insertPageAfter(after + i, choice.template);
      final page = coreInfo.pages[after + i + 1];
      await _pickPhotos(
        [photo],
        (pageIndex: after + i + 1, center: page.size.center(Offset.zero)),
        false,
      );
      if (!mounted) return null;
      _makeLastImageTheBackground(page);
    }
    return after + 1;
  }

  /// Whether a page was added at the very end.
  /// Pulled past the last page: a page like it, without asking (the Add
  /// page button still offers every template).
  Future<bool> addPageAtEnd() async {
    if (coreInfo.readOnly || coreInfo.pages.isEmpty) return false;
    final last = coreInfo.pages.length - 1;
    insertPageAfter(last, PageTemplate.sameAs(coreInfo.pages[last]));
    return true;
  }

  /// Pulled past the first page: a page like it before it, without asking.
  Future<bool> addPageAtStart() async {
    if (coreInfo.readOnly || coreInfo.pages.isEmpty) return false;
    Select.currentSelect.unselect();
    insertPageAfter(-1, PageTemplate.sameAs(coreInfo.pages.first));
    return true;
  }

  /// Adds a page after [pageIndex]: of [template]'s look, or [ready] (one
  /// of my templates, with what's on it).
  void insertPageAfter(
    int pageIndex, [
    PageTemplate? template,
    EditorPage? ready,
  ]) => setState(() {
    if (coreInfo.readOnly) return;
    final look = template ?? PageTemplate.sameAs(_pageBeside(pageIndex));
    final page =
        ready ??
        (EditorPage(size: look.size)
          ..backgroundPattern = look.pattern
          ..lineHeight = look.lineHeight
          ..backgroundColor = look.color);
    coreInfo.pages.insert(pageIndex + 1, page);
    // the pages after it moved along: undoing ink finds its page by index
    for (int i = pageIndex + 1; i < coreInfo.pages.length; i++) {
      coreInfo.pages[i].updatePageIndex(i);
      listenToQuillChanges(coreInfo.pages[i].quill, i);
    }
    // a selection on a page after it would now point at another page
    Select.currentSelect.unselect();
    history.recordChange(
      HistoricPageInsert(pageIndex: pageIndex + 1, page: page),
    );
    autosaveAfterDelay();
  });

  /// Wipes the ink and pictures off page [pageIndex], as one undo step.
  void clearPage(int pageIndex) {
    if (coreInfo.readOnly) return;
    final page = coreInfo.pages[pageIndex];
    setState(() {
      final strokes = List.of(page.strokes);
      final images = List.of(page.images);
      page.strokes.clear();
      page.images.clear();
      removeExcessPages();
      history.recordChange(HistoricDelete(strokes: strokes, images: images));
      autosaveAfterDelay();
    });
  }

  /// Wipes every page, as one undo step. The pages themselves stay.
  void clearAllPages() {
    if (coreInfo.readOnly) return;
    setState(() {
      final strokes = <Stroke>[], images = <EditorImage>[];
      for (final page in coreInfo.pages) {
        strokes.addAll(page.strokes);
        images.addAll(page.images);
        page.strokes.clear();
        page.images.clear();
      }
      removeExcessPages();
      history.recordChange(HistoricDelete(strokes: strokes, images: images));
    });
    autosaveAfterDelay();
  }

  /// The note was written by a newer version of the app and opened
  /// read-only. Explains why, and lets the user edit it anyway.
  Future<void> showVersionTooNewDialog() async {
    final allowEditing = await showAppleDialog<bool>(
      context: context,
      builder: (context) => AdaptiveAlertDialog(
        title: Text(t.editor.versionTooNew.title),
        content: Text(t.editor.versionTooNew.subtitle),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.editor.versionTooNew.allowEditing),
          ),
        ],
      ),
    );
    if (!mounted || allowEditing != true) return;
    if (coreInfo.readOnlyReason != .versionTooNew) return;
    coreInfo.readOnlyReason = null;
    setState(() {});
  }

  /// The page found last time, used when the view can't be measured.
  late int _lastCurrentPageIndex = coreInfo.initialPageIndex ?? 0;

  /// The page in the middle of the screen.
  int get currentPageIndex {
    if (!mounted) return _lastCurrentPageIndex;
    return _lastCurrentPageIndex = getPageIndexFromScrollPosition(
      scrollY: -scrollY,
      screenWidth: _canvasWidth,
      pages: coreInfo.pages,
    );
  }

  /// The page that [scrollY] (a distance from the top of the first page)
  /// falls on: the first page whose bottom edge is further on. Past the
  /// end, that's the last page.
  @visibleForTesting
  static int getPageIndexFromScrollPosition({
    required double scrollY,
    required double screenWidth,
    required List<EditorPage> pages,
  }) {
    final last = pages.length - 1;
    for (var i = 0; i < last + 1; i++) {
      // where page i ends is where page i + 1 starts
      final end = CanvasGestureDetector.getTopOfPage(
        pageIndex: i + 1,
        pages: pages,
        screenWidth: screenWidth,
      );
      if (scrollY < end) return i;
    }
    return last;
  }

  /// When this note's newest version was kept, read as it opens (none yet:
  /// long ago, so the first save keeps one).
  DateTime? _lastKeptVersion;

  /// Earlier versions of this note: look, restore, or open one as a copy.
  Future<void> _openVersionHistory() => showVersionHistory(
    context,
    notePath: coreInfo.filePath,
    beforeRestore: () async {
      await saveToFile();
      cancelAutosaveAndMarkSaved();
    },
    // the restored note is read again: this editor goes, a fresh one opens
    afterRestore: () {
      if (!mounted) return;
      final path = coreInfo.filePath;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => TabbedEditor(path: path)),
      );
    },
    openCopy: _openBoard,
  );

  /// The note as it was left, shown while it opens (see [deactivate]).
  File? _openingPicture;

  /// A still picture of the pages while a popover is open over the note
  /// ([EditorSignals.covered]). The pages under it took the GPU most of a
  /// frame to draw, so a popover's scrolling stuttered.
  ui.Image? _frozenView;

  void _onCovered() {
    if (!mounted) return;
    if (EditorSignals.covered.value > 0) {
      if (_frozenView != null || EditorSignals.drawing.value) return;
      final box = _screenshotBoundaryKey.currentContext?.findRenderObject();
      if (box is! RenderRepaintBoundary || !box.hasSize || !box.attached) {
        return;
      }
      try {
        final picture = box.toImageSync(
          pixelRatio: MediaQuery.devicePixelRatioOf(context),
        );
        setState(() => _frozenView = picture);
      } catch (e) {
        log.fine('No still picture under the popover: $e');
      }
    } else if (_frozenView case final old?) {
      setState(() => _frozenView = null);
      // after the live pages have been drawn again
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  /// [live] (the pages), or while a popover is open the still picture of
  /// them on top, the pages kept but not drawn.
  Widget _withFrozenView(Widget live) {
    final frozen = _frozenView;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: frozen != null, child: live),
        if (frozen != null)
          IgnorePointer(
            child: RawImage(image: frozen, fit: BoxFit.fill),
          ),
      ],
    );
  }

  /// Keeps a picture of the screen as the note is left, for next time: a
  /// note opens with it showing at once instead of a blank page.
  @override
  void deactivate() {
    // right after a stroke the GPU is still busy with it: no picture then
    // (leaving at that moment was when the app hung)
    final justDrew =
        EditorSignals.drawing.value ||
        DateTime.now().difference(EditorSignals.lastLift) <
            const Duration(seconds: 1);
    // nor while the app is going away: drawing then raced the screen's end
    final shown =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (!justDrew &&
        shown &&
        coreInfo.readOnlyReason != .placeholder &&
        coreInfo.filePath.isNotEmpty &&
        !NoteLocks.isProtected(coreInfo.filePath) &&
        !_isBoard) {
      try {
        final boundary =
            _screenshotBoundaryKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        // ignore: invalid_use_of_protected_member
        final layer = boundary?.layer;
        if (boundary != null && boundary.attached && layer is OffsetLayer) {
          LagRecorder.step('leave: picture of the note');
          final image = layer.toImageSync(
            Offset.zero & boundary.size,
            pixelRatio: 1,
          );
          LagRecorder.step('leave: picture taken');
          final file = FileManager.getFile('${coreInfo.filePath}.open.png');
          unawaited(() async {
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            if (png != null) {
              await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
            }
          }());
        }
      } catch (e) {
        log.fine('No picture kept for opening next time: $e');
      }
    }
    super.deactivate();
  }

  @override
  void dispose() {
    LagRecorder.step('editor dispose');
    EditorSignals.covered.removeListener(_onCovered);
    NoteLocks.unlocked.removeListener(_checkLock);
    NoteLocks.book.removeListener(_checkLock);
    _frozenView?.dispose();
    _frozenView = null;
    stows.floatingToolbarEdge.removeListener(_toolbarMoved);
    _lifecycle.dispose();
    NoteTabs.paths.removeListener(_setState);
    stows.toolbarDocked.removeListener(_setState);
    stows.dockedToolsBottom.removeListener(_setState);
    stows.editorFingerDrawing.removeListener(_setState);
    _pagesRevisionTimer?.cancel();
    _pagesRevision.dispose();
    audioNotes?.playbackAt.removeListener(_followPlayback);
    audioNotes?.dispose();
    _ocrTimer?.cancel();
    if (_ocrDirty && !coreInfo.readOnly) {
      unawaited(HandwritingOcr.indexNote(coreInfo.filePath, coreInfo.pages));
    }
    // a note opened again before this one finished saving waits for it
    final path = coreInfo.filePath;
    if (!identical(coreInfo, EditorCoreInfo.placeholder)) {
      Editor.openNotes.remove(path);
    }
    final closing = _cleanUpAsync();
    if (path.isNotEmpty) {
      Editor.closing[path] = closing;
      closing.whenComplete(() {
        if (Editor.closing[path] == closing) Editor.closing.remove(path);
      });
    }
    unawaited(closing);

    DynamicMaterialApp.removeFullscreenListener(_setState);

    for (final timer in [
      _delayedSaveTimer,
      _watchServerTimer,
      _lastSeenPointerCountTimer,
      _longPressTimer,
      _drawHoldTimer,
      _autoScrollTimer,
    ]) {
      timer?.cancel();
    }

    _removeKeybindings();

    // Pen settings are changed inside their stored objects, which the
    // stored values can't see: tell each one so it gets written out.
    for (final options in [
      stows.lastFountainPenOptions,
      stows.lastBallpointPenOptions,
      stows.lastCalligraphyPenOptions,
      stows.lastBrushPenOptions,
      stows.lastHighlighterOptions,
      stows.lastPencilOptions,
      stows.lastShapePenOptions,
    ]) {
      options.notifyListeners();
    }

    _tabDropSide.dispose();
    _searchHighlightTimer?.cancel();
    if (_lastTouched == this) _lastTouched = null;

    super.dispose();
    LagRecorder.step('editor disposed');
  }

  /// What's left to do once the editor has gone: a rename still waiting
  /// is done now, then the last save, then the thumbnail.
  Future<void> _cleanUpAsync() async {
    // left while a text box was being typed again: it stays as it was
    if (_textBox case (:final pageIndex, :final image?, at: _, note: _)) {
      coreInfo.pages[pageIndex].images.add(image);
      _textBox = null;
    }
    try {
      final rename = _renameTimer;
      if (rename != null && rename.isActive) {
        rename.cancel();
        // failing, the last save still comes, under the old name
        await _renameWhenNotSaving();
        filenameTextEditingController.dispose();
      }
      LagRecorder.step('leave: last save');
      await saveToFile(thumbnail: false);
      LagRecorder.step('leave: saved');
      _announceQuietWrites();
      // autosaves leave the thumbnail for now (a test's editor is gone
      // with its fake clock before the thumbnail could be drawn). It's
      // drawn once the home screen has come in: drawing it takes the main
      // thread a quarter to half a second, and made that stutter.
      if (_editedThisSession && !coreInfo.readOnly && !isThisATest) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        LagRecorder.step('leave: thumbnail');
        await _saveThumbnail();
        LagRecorder.step('leave: thumbnail done');
      }
      if (_editedThisSession &&
          !coreInfo.readOnly &&
          coreInfo.filePath.isNotEmpty) {
        PdfCopies.noteChanged(coreInfo.filePath);
      }
    } finally {
      // closed before its note had loaded: the placeholder every editor
      // shares isn't this one's to dispose
      if (!identical(coreInfo, EditorCoreInfo.placeholder)) coreInfo.dispose();
    }
  }
}
