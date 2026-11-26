import 'dart:async';
import 'dart:io';

import 'package:badnotes/components/editor_ui/bar_color_row.dart';
import 'package:badnotes/components/home/home_layout_button.dart';
import 'package:badnotes/components/home/sort_button.dart';
import 'package:badnotes/components/navbar/responsive_navbar.dart';
import 'package:badnotes/data/codecs/base64_codec.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/quota.dart';
import 'package:badnotes/data/tools/highlighter.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:sbn/canvas_background_pattern.dart';
import 'package:sbn/tool_id.dart';
import 'package:stow/stow.dart';
import 'package:stow_codecs/stow_codecs.dart';
import 'package:stow_plain/stow_plain.dart';
import 'package:stow_secure/stow_secure.dart';

/// Set once by [Stows.markAsOnMainIsolate]. Settings made before that (or
/// on a background isolate) only hold their defaults and never touch disk.
var _isOnMainIsolate = false;

/// Whether a setting made now should stay in memory only.
bool get _volatile => !_isOnMainIsolate;

/// A plainly stored setting whose type needs no codec.
PlainStow<T> _plain<T>(String key, T defaultValue) =>
    PlainStow<T>(key, defaultValue, volatile: _volatile);

/// A saved pen's stroke options, stored as JSON under [key].
PlainStow<StrokeOptions> _strokeOptions(String key, StrokeOptions fallback) =>
    PlainStow.json(
      key,
      fallback,
      fromJson: (json) => StrokeOptions.fromJson(json as Map<String, dynamic>),
      volatile: _volatile,
    );

/// The app's settings, every one of them, in one place.
final stows = Stows();

/// Every setting BadNotes keeps between launches.
///
/// The string given to each stow is the key it is saved under on the device:
/// those keys (and their defaults and codecs) must never change, or people's
/// settings would quietly reset after an update.
class Stows {
  new() {
    // Shrinking the number of recent colours drops the oldest ones.
    recentColorsLength.addListener(() {
      while (recentColorsLength.value < recentColorsPositioned.value.length) {
        final oldest = recentColorsChronological.value.removeAt(0);
        recentColorsPositioned.value.remove(oldest);
      }
    });
  }

  /// Lets settings read and write the disk. Call it before [runApp].
  static void markAsOnMainIsolate() {
    _isOnMainIsolate = true;
  }

  @pragma('vm:platform-const')
  static final isDesktop =
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  final log = Logger('Stows');

  // ---------------------------------------------------------------------
  // Where notes live, and the signed-in account
  // ---------------------------------------------------------------------

  /// A folder the user picked for their notes, or null for the default one.
  final customDataDir = PlainStow<String?>(
    'customDataDir',
    null,
    volatile: _volatile,
  );

  final username = SecureStow('username', '', volatile: _volatile);

  /// Which cloud the notes go to.
  final syncProvider = PlainStow(
    'syncProvider',
    SyncProvider.googleDrive,
    codec: const EnumCodec(SyncProvider.values),
    volatile: _volatile,
  );

  /// For OneDrive, its refresh token. For Google Drive just `google`: the
  /// Google Sign-In plugin looks after those tokens itself.
  final ncPassword = SecureStow('ncPassword', '', volatile: _volatile);

  /// The passphrase notes are encrypted with before they leave the device.
  final encPassword = SecureStow('encPassword', '', volatile: _volatile);

  final key = SecureStow('key', '', volatile: _volatile);
  final iv = SecureStow('iv', '', volatile: _volatile);

  /// True once there is an account and both secrets. Only meaningful after
  /// those three settings have been read.
  bool get loggedIn =>
      username.value.isNotEmpty &&
      ncPassword.value.isNotEmpty &&
      encPassword.value.isNotEmpty;

  /// The BadNotes Pro licence the server signed for this account, or ''.
  final proLicence = SecureStow('proLicence', '', volatile: _volatile);

  /// When the licence server was last asked, in ms since the epoch.
  final proCheckedMs = _plain('proCheckedMs', 0);

  /// A paid Play purchase the server hasn't recorded yet, as JSON, or ''.
  final proWaiting = _plain('proWaiting', '');

  /// Developer builds only: Pro unlocked on this device without buying.
  final proDevUnlock = _plain('proDevUnlock', false);

  /// The account picture.
  final pfp = PlainStow<Uint8List?>(
    'pfp',
    null,
    codec: const Base64StowCodec(),
    volatile: _volatile,
  );

  // ---------------------------------------------------------------------
  // Syncing
  // ---------------------------------------------------------------------

  /// What the cloud folder looked like last time (its index and change
  /// token), so the next sync only fetches what's new.
  final cloudSyncState = _plain('cloudSyncState', '');

  /// Set when Google or Microsoft turned our sign-in down: syncing waits
  /// until the user signs in again.
  final syncNeedsLogin = _plain('syncNeedsLogin', false);

  /// When the cloud was last reached, in ms since the epoch.
  final lastSyncedMs = _plain('lastSyncedMs', 0);

  /// A JSON map from each local file to the modified time (ms) it had when
  /// it last went up or came down. A newer time means unsynced edits.
  final fileSyncLastSynced = _plain('fileSyncLastSynced', '{}');

  /// Keep a PDF copy of each changed note in Google Drive, to read and share
  /// from there.
  final drivePdfCopies = _plain('drivePdfCopies', true);

  /// Back the whole library up to Google Drive every week.
  final autoDriveBackup = _plain('autoDriveBackup', true);

  /// When that backup last ran, in ms since the epoch.
  final lastDriveBackup = _plain('lastDriveBackup', 0);

  /// When an automatic backup was last started, whether or not it finished.
  final lastDriveBackupTry = _plain('lastDriveBackupTry', 0);

  /// Hold syncing back while on mobile data.
  final syncOnlyOnWifi = _plain('syncOnlyOnWifi', false);

  /// Send note thumbnails over mobile data as well (normally left for Wi-Fi).
  final syncPreviewsOnMobileData = _plain('syncPreviewsOnMobileData', true);

  final syncInBackground = _plain('syncInBackground', true);

  /// Files the user deleted here, so the cloud copy goes too.
  final fileSyncAlreadyDeleted = _plain('fileSyncAlreadyDeleted', <String>{});

  /// Files whose cloud copy is known to be broken.
  final fileSyncCorruptFiles = _plain('fileSyncCorruptFiles', <String>{});

  /// Cloud files older than this are replaced by the local copy. The
  /// default catches uploads from before 0.18.4, which could be empty.
  final fileSyncResyncEverythingDate = PlainStow(
    'fileSyncResyncEverythingDate',
    DateTime.parse('2023-12-10T10:06:31.000Z'),
    codec: const DateTimeCodec(),
    volatile: _volatile,
  );

  /// The storage quota as last fetched, shown while offline.
  final lastStorageQuota = PlainStow<Quota?>(
    'lastStorageQuota',
    null,
    codec: const QuotaCodec(),
    volatile: _volatile,
  );

  // ---------------------------------------------------------------------
  // Look of the app
  // ---------------------------------------------------------------------

  final appTheme = PlainStow(
    'appTheme',
    ThemeMode.system,
    codec: const EnumCodec(ThemeMode.values),
    volatile: _volatile,
  );

  /// Which platform's look the app takes. Android starts with the iPad-style
  /// layout; the rest start with their own. Changeable in the settings.
  final platform = PlainStow(
    'platform',
    defaultTargetPlatform == .android
        ? TargetPlatform.iOS
        : defaultTargetPlatform,
    codec: const EnumCodec(TargetPlatform.values),
    volatile: _volatile,
  );

  final layoutSize = PlainStow(
    'layoutSize',
    LayoutSize.auto,
    codec: LayoutSize.codec,
    volatile: _volatile,
  );

  /// The app's accent colour; null follows the system's.
  final accentColor = PlainStow<Color?>(
    'accentColor',
    null,
    codec: const ColorCodec(),
    volatile: _volatile,
  );

  final hyperlegibleFont = _plain('hyperlegibleFont', false);

  final locale = _plain('locale', '');

  // ---------------------------------------------------------------------
  // The editor in general
  // ---------------------------------------------------------------------

  final editorToolbarAlignment = PlainStow(
    'editorToolbarAlignment',
    AxisDirection.up,
    codec: const EnumCodec(AxisDirection.values),
    volatile: _volatile,
  );
  final editorToolbarShowInFullscreen = _plain(
    'editorToolbarShowInFullscreen',
    true,
  );
  final editorFingerDrawing = _plain('editorFingerDrawing', true);
  final editorAutoInvert = _plain('editorAutoInvert', true);
  final preferGreyscale = _plain('preferGreyscale', false);
  final editorPromptRename = _plain('editorPromptRename', isDesktop);
  final autosaveDelay = _plain('autosaveDelay', 10000);
  final shapeRecognitionDelay = _plain('shapeRecognitionDelay', 500);
  final autoStraightenLines = _plain('autoStraightenLines', false);
  final printPageIndicators = _plain('printPageIndicators', false);

  /// Photos are kept at full size: shrinking one re-encodes it as PNG, which
  /// loses its colour profile.
  final maxImageSize = _plain<double>('maxImageSize', 8192);

  final autoClearWhiteboardOnExit = _plain('autoClearWhiteboardOnExit', false);
  final disableEraserAfterUse = _plain('disableEraserAfterUse', false);
  final hideFingerDrawingToggle = _plain('hideFingerDrawingToggle', false);

  /// Turns finger drawing off by itself once a stylus shows up, since few
  /// people think to do it themselves.
  final autoDisableFingerDrawingWhenStylusDetected = _plain(
    'autoDisableFingerDrawingWhenStylusDetected',
    true,
  );

  final editorHorizontalScroll = _plain('editorHorizontalScroll', false);

  /// Keep earlier versions of each note (see NoteVersions).
  final keepVersions = _plain('keepVersions', false);

  /// Notes laid out as two facing pages, by path.
  final twoPagesNotes = _plain('twoPagesNotes', <String>[]);

  /// Handwriting recognition languages, comma separated codes.
  final handwritingLanguages = _plain('handwritingLanguages', 'en,hi');

  // ---------------------------------------------------------------------
  // New pages
  // ---------------------------------------------------------------------

  static const defaultLineHeight = 40;
  static const defaultLineThickness = 3;

  final lastBackgroundPattern = PlainStow(
    'lastBackgroundPattern',
    CanvasBackgroundPattern.none,
    codec: const EnumCodec(CanvasBackgroundPattern.values),
    volatile: _volatile,
  );
  final lastLineHeight = _plain('lastLineHeight', defaultLineHeight);

  /// The paper ([PaperKind.name]) and page colour ([PageTemplate.colors])
  /// the last notebook was made with: the next one starts with them.
  final lastPaperName = _plain('lastPaperName', 'Dot grid');
  final lastPageColorName = _plain('lastPageColorName', 'White');
  final lastLineThickness = _plain('lastLineThickness', defaultLineThickness);

  final lastZoomLock = _plain('lastZoomLock', false),
      lastSingleFingerPanLock = _plain('lastSingleFingerPanLock', false),
      lastAxisAlignedPanLock = _plain('lastAxisAlignedPanLock', false);

  // ---------------------------------------------------------------------
  // Tool bar
  // ---------------------------------------------------------------------

  final lastTool = PlainStow(
    'lastTool',
    ToolId.fountainPen,
    codec: ToolId.codec,
    volatile: _volatile,
  );

  /// Tools pinned below the header rather than in the floating bar.
  final toolbarDocked = _plain('toolbarDocked', false);

  /// On a phone, docked tools sit at the bottom instead of below the header.
  final dockedToolsBottom = _plain('dockedToolsBottom', false);

  /// The user's order of tool ids; empty means the built-in order.
  final toolbarOrder = _plain('toolbarOrder', <String>[]);

  /// Tool ids moved from the dock into "More tools".
  final toolbarHidden = _plain('toolbarHidden', <String>[]);

  /// Smaller buttons in the tool dock.
  final toolbarCompact = _plain('toolbarCompact', false);

  /// Fade the tool dock out while a stroke is drawn.
  final toolbarAutoHide = _plain('toolbarAutoHide', false);

  /// The floating bar's centre along its edge, from 0 to 1.
  final floatingToolbarAlong = _plain('floatingToolbarAlong', 0.5);

  /// The edge the floating bar sits on: 0 top, 1 left, 2 right, 3 bottom.
  /// -1 means the top on a tablet and the bottom on a phone.
  final floatingToolbarEdge = _plain('floatingToolbarEdge', -1);

  /// Set once the floating bar has been sent back to its default place on
  /// installs that had moved it.
  final floatingBarReset = _plain('floatingBarReset', false);

  /// What holding the stylus's side button does: 0 erase, 1 lasso,
  /// 2 highlight.
  final stylusButtonTool = _plain('stylusButtonTool', 0);

  // ---------------------------------------------------------------------
  // Colours
  // ---------------------------------------------------------------------

  final recentColorsChronological = _plain(
    'recentColorsChronological',
    <String>[],
  );
  final recentColorsPositioned = _plain('recentColorsPositioned', <String>[]);
  final pinnedColors = _plain('pinnedColors', <String>[]);
  final recentColorsDontSavePresets = _plain('dontSavePresetColors', false);
  final recentColorsLength = _plain('recentColorsLength', 5);

  /// The colours of each tool in the floating bar, in order, as
  /// "tool:argb". A bare "tool:" records that the tool's row was filled once.
  final barColors = _plain('barColors', <String>[]);

  final lastFountainPenColor = _plain(
        'lastFountainPenColor',
        Colors.black.toARGB32(),
      ),
      lastBrushPenColor = _plain('lastBrushPenColor', Colors.black.toARGB32()),
      lastBallpointPenColor = _plain(
        'lastBallpointPenColor',
        Colors.black.toARGB32(),
      ),
      lastHighlighterColor = _plain(
        'lastHighlighterColor',
        BarColors.lightYellow.withAlpha(Highlighter.alpha).toARGB32(),
      ),
      lastPencilColor = _plain('lastPencilColor', Colors.black.toARGB32()),
      lastShapePenColor = _plain('lastShapePenColor', Colors.black.toARGB32());

  // ---------------------------------------------------------------------
  // Pens
  // ---------------------------------------------------------------------

  final lastFountainPenOptions = _strokeOptions(
        'lastFountainPenProperties',
        Pen.fountainPenOptions,
      ),
      lastBrushPenOptions = _strokeOptions(
        'lastBrushPenProperties',
        Pen.brushPenOptions,
      ),
      lastCalligraphyPenOptions = _strokeOptions(
        'lastCalligraphyPenProperties',
        Pen.calligraphyPenOptions,
      ),
      lastBallpointPenOptions = _strokeOptions(
        'lastBallpointPenProperties',
        Pen.ballpointPenOptions,
      ),
      lastHighlighterOptions = _strokeOptions(
        'lastHighlighterProperties',
        Pen.highlighterOptions,
      ),
      lastPencilOptions = _strokeOptions(
        'lastPencilProperties',
        Pen.pencilOptions,
      ),
      lastShapePenOptions = _strokeOptions(
        'lastShapePenProperties',
        Pen.shapePenOptions,
      );

  final fountainPenPressure = _plain('fountainPenPressure', true);

  /// How strongly a fountain pen responds to pressure, 0 to 1.
  final fountainPressureAmount = _plain('fountainPressureAmount', 0.4);

  /// The pen sizes in the toolbar's size slots (see `Pen.sizeSlots`).
  final penSizeSlots = _plain('penSizeSlots', <String>[]);

  /// The line style each pen has in each size slot, as "toolId:slot:line".
  final penSlotLines = _plain('penSlotLines', <String>[]);

  /// The user's saved pens (see `PenPreset`).
  final penPresets = _plain('penPresets', <String>[]);

  /// Every pen's stylus pressure goes through this curve: light, normal,
  /// firm or custom (see `PressureCurve`). Light unless chosen otherwise.
  final pressureCurve = _plain('pressureCurve', 'light');

  /// The custom curve's one point, 0 to 1 each: how hard the pen presses
  /// (x) and how thick that comes out (y).
  final pressureCurveX = _plain('pressureCurveX', 0.5);
  final pressureCurveY = _plain('pressureCurveY', 0.5);

  /// Pressure under this (0 to 0.2) draws nothing.
  final pressureThreshold = _plain('pressureThreshold', 0.0);

  final penReduceLatency = _plain('penReduceLatency', true);
  final penDrawAndHold = _plain('penDrawAndHold', false);

  /// Scribbling over ink with the fountain pen erases it.
  final fountainScribbleToErase = _plain('fountainScribbleToErase', false);

  /// The same for the ballpoint, brush, calligraphy pen and pencil.
  final penScribbleToErase = _plain('penScribbleToErase', false);

  /// How opaque new pencil strokes are.
  final pencilAlpha = _plain('pencilAlpha', 255);

  // ---------------------------------------------------------------------
  // Highlighter
  // ---------------------------------------------------------------------

  final highlighterAlpha = _plain('highlighterAlpha', Highlighter.alpha);
  final highlighterStraight = _plain('highlighterStraight', false);

  /// Highlights stay horizontal or vertical.
  final highlighterAxisLock = _plain('highlighterAxisLock', false);

  // ---------------------------------------------------------------------
  // Shapes, tape, laser, stickers, text
  // ---------------------------------------------------------------------

  final shapeKind = _plain('shapeKind', 'rectangle');

  /// The style new shapes get (see `ShapePen.defaultStyle`).
  final shapeFill = _plain('shapeFill', false);
  final shapeFillOpacity = _plain('shapeFillOpacity', 0.15);
  final shapeLine = _plain('shapeLine', 1);
  final shapeRounded = _plain('shapeRounded', true);
  final shapeArrowStart = _plain('shapeArrowStart', 0);
  final shapeArrowEnd = _plain('shapeArrowEnd', 0);

  final tapeColor = _plain('tapeColor', 0xFFFFB74D);
  final tapePattern = _plain('tapePattern', 'stripes');

  /// Doodles the user drew for tape (see `TapePattern.parseDoodle`).
  final tapeDoodles = _plain('tapeDoodles', <String>[]);

  /// The doodle custom tape uses at the moment.
  final tapeDoodle = _plain('tapeDoodle', '');

  /// Lay tape in a straight line from where the pen touched down.
  final tapeStraight = _plain('tapeStraight', false);

  /// When the tape quizzes come round again (see `RevisionPlan`).
  final revisionPlan = _plain('revisionPlan', <String>[]);

  final laserColor = _plain('laserColor', Colors.red.toARGB32());
  final laserDot = _plain('laserDot', false);

  /// A soft glow around the laser's trail.
  final laserGlow = _plain('laserGlow', true);
  final laserHoldMillis = _plain('laserHoldMillis', 300);

  /// The stickers used lately, most recent first.
  final recentStickers = _plain('recentStickers', <String>[]);

  /// The index of the sticky-note colour chosen last.
  final lastStickyNoteColor = _plain('lastStickyNoteColor', 0);

  /// Stay on the text tool after finishing a text box.
  final pinTextTool = _plain('pinTextTool', false);

  // ---------------------------------------------------------------------
  // Eraser and lasso
  // ---------------------------------------------------------------------

  /// The eraser's kind as an `EraserType` index; 0 (precise) by default.
  final eraserType = _plain('eraserType', 0);

  /// The eraser's radius, in screen pixels.
  final eraserRadius = _plain('eraserRadius', 28.0);

  /// The kinds of ink the eraser touches, by `EraserFilter` name.
  final eraserFilter = _plain('eraserFilter', <String>[
    'pen',
    'pencil',
    'highlighter',
    'tape',
  ]);

  /// A scribble also erases shapes and highlights.
  final scribbleErasesAll = _plain('scribbleErasesAll', false);

  /// A loop drawn round ink with a pen selects that ink.
  final circleToLasso = _plain('circleToLasso', false);

  /// Such a loop also picks ink that is mostly (70%) inside it.
  final lassoPartly = _plain('lassoPartly', false);

  /// The kinds of thing the lasso picks up, by `Select.groupOf` name.
  final lassoFilter = _plain('lassoFilter', <String>[
    'handwriting',
    'images',
    'shapes',
    'arrows',
    'textBoxes',
    'tape',
    'stickyNotes',
  ]);

  // ---------------------------------------------------------------------
  // Palm rejection
  // ---------------------------------------------------------------------

  /// Ignore touches while the stylus is close.
  final palmRejection = _plain('palmRejection', true);

  /// For how long after the stylus lifts touches are still ignored, in ms.
  final palmAfterLiftMs = _plain('palmAfterLiftMs', 400);

  /// The user is left-handed, so the palm rests left of the pen.
  final leftHanded = _plain('leftHanded', false);

  /// Ignore big (palm-sized) touches even with no stylus around.
  final palmIgnoreBigTouches = _plain('palmIgnoreBigTouches', false);

  /// Let two fingers zoom and scroll while the stylus is close.
  final palmTwoFingersZoom = _plain('palmTwoFingersZoom', true);

  // ---------------------------------------------------------------------
  // Recording and playback
  // ---------------------------------------------------------------------

  /// Whether new recordings take sound at all, and from the microphone, the
  /// device's own audio, or both.
  final recordAudio = _plain('recordAudio', true);
  final recordMic = _plain('recordMic', true);
  final recordDevice = _plain('recordDevice', false);

  /// How ink plays back alongside a recording: "reveal" writes it again in
  /// time with the voice, "spotlight" dims everything but what's being
  /// talked about, "static" leaves it alone.
  final playbackMode = _plain('playbackMode', 'reveal');

  // ---------------------------------------------------------------------
  // Quick notes board
  // ---------------------------------------------------------------------

  /// The board's backdrop: "none", "dots", "grid", "cork" or "photo".
  final boardPattern = _plain('boardPattern', 'dots');
  /// ARGB; 0 (the default) is transparent, no fill behind the pattern.
  final boardColor = _plain('boardColor', 0x00000000);

  /// How much a photo backdrop is faded.
  final boardPhotoFade = _plain('boardPhotoFade', 0.3);

  // ---------------------------------------------------------------------
  // Home screen
  // ---------------------------------------------------------------------

  final homeLayout = PlainStow(
    'homeLayout',
    HomeLayout.simpleGrid,
    codec: HomeLayout.codec,
    volatile: _volatile,
  );
  final browseSortMetric = PlainStow(
    'browseSortMetric',
    SortMetric.nameAToZ,
    codec: SortMetric.codec,
    volatile: _volatile,
  );

  /// Notes opened lately, newest first.
  final recentFiles = _plain('recentFiles', <String>[]);
  final favoriteNotes = _plain('favoriteNotes', <String>[]);

  /// Notebook cover size on the home screen: 0 small, 1 medium, 2 large.
  final homeCoverSize = _plain('homeCoverSize', 1);

  /// Up to 8 recent searches across all notes, newest first.
  final recentSearches = _plain('recentSearches', <String>[]);

  /// The feature tour has been shown (or skipped on an install that already
  /// had notes when it updated), so it doesn't open on its own again.
  final tourSeen = _plain('tourSeen', false);

  // ---------------------------------------------------------------------
  // Focus timer
  // ---------------------------------------------------------------------

  /// Focus and break lengths, in minutes.
  final timerFocusMinutes = _plain('timerFocusMinutes', 25);
  final timerBreakMinutes = _plain('timerBreakMinutes', 5);

  /// Begin the break as soon as a focus session finishes.
  final timerAutoBreak = _plain('timerAutoBreak', false);

  /// Seconds focused on the day [timerTotalDay] (yyyy-mm-dd).
  final timerTotalSeconds = _plain('timerTotalSeconds', 0);
  final timerTotalDay = _plain('timerTotalDay', '');

  // ---------------------------------------------------------------------
  // Updates
  // ---------------------------------------------------------------------

  final shouldCheckForUpdates = _plain(
    'shouldCheckForUpdates',
    FlavorConfig.shouldCheckForUpdatesByDefault && !Platform.isLinux,
  );
  final shouldAlwaysAlertForUpdates = _plain(
    'shouldAlwaysAlertForUpdates',
    kDebugMode,
  );

  // ---------------------------------------------------------------------
  // One-off upgrades of older installs. Each defaults to true because a
  // fresh install already starts with the new values.
  // ---------------------------------------------------------------------

  /// The ballpoint's stabilisation has been turned down.
  final ballPenLagFixed = _plain('ballPenLagFixed', true);

  /// The ballpoint uses the speed-aware stabilisation.
  final ballPenSpeedSmoothing = _plain('ballPenSpeedSmoothing', true);

  /// The fountain pen has its finer default size.
  final fountainSizeIsTwo = _plain('fountainSizeIsTwo', true);

  /// Pen sizes have moved to the default of 3.
  final penSizesAreThree = _plain('penSizesAreThree', true);

  /// The highlighter has its default size of 20.
  final highlighterSizeIsTwenty = _plain('highlighterSizeIsTwenty', true);
}

/// A view of another [Stow] through a two-way conversion. It stores nothing
/// of its own: reads and writes go straight to [parent].
class TransformedStow<T_in, T_out> extends Stow<dynamic, T_out, dynamic> {
  new(this.parent, this.transform, this.reverseTransform)
    : super(parent.key, transform(parent.defaultValue), volatile: true) {
    parent.addListener(notifyListeners);
  }

  final Stow<dynamic, T_in, dynamic> parent;
  final T_out Function(T_in) transform;
  final T_in Function(T_out) reverseTransform;

  @override
  T_out get value => transform(parent.value);

  @override
  set value(T_out value) => parent.value = reverseTransform(value);

  @override
  Future<dynamic> protectedRead() async => null;

  @override
  Future<void> protectedWrite(dynamic value) async {}

  @override
  void dispose() {
    parent.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  String toString() =>
      'TransformedPref<$T_in, $T_out>(from ${parent.key}, $value)';
}

/// The clouds notes can sync to.
enum SyncProvider { googleDrive, oneDrive }
