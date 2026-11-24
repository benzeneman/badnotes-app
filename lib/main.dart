import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:badnotes/components/editor/handwriting_ocr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_to_regexp/path_to_regexp.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart';
import 'package:badnotes/data/lag_recorder.dart';
import 'package:badnotes/components/theming/dynamic_material_app.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/data/backup.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/data/tools/stroke_properties.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/components/editor/note_tabs.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:badnotes/pages/home/home.dart';
import 'package:badnotes/pages/logs.dart';
import 'package:badnotes/pages/user/login.dart';
import 'package:window_manager/window_manager.dart';
import 'package:worker_manager/worker_manager.dart';
import 'package:workmanager/workmanager.dart';
import 'package:yaru/yaru.dart';

/// Entry point. Store builds pass their flavor through `--dart-define`
/// (FLAVOR, APP_STORE, UPDATE_CHECK), which is read before anything else.
Future<void> main(List<String> args) async {
  FlavorConfig.setupFromEnvironment();
  await appRunner(args);
}

/// How many background isolates the worker pool gets. A debug build keeps
/// just one so hot reload stays quick.
int get _workerIsolates => kDebugMode ? 1 : 2;

/// The fonts bundled with the app, each shipping its own OFL text.
const _bundledFontLicenses = [
  'assets/google_fonts/Inter/OFL.txt',
  'assets/google_fonts/Atkinson_Hyperlegible_Next/OFL.txt',
  'assets/google_fonts/Dekko/OFL.txt',
  'assets/google_fonts/Fira_Mono/OFL.txt',
  'assets/google_fonts/Neucha/OFL.txt',
];

/// Brings the whole app up: logging, storage and plugins first, then the
/// widget tree, then the jobs that run once the first frame is on its way.
Future<void> appRunner(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  _configureLogging(args);
  StrokeOptionsExtension.setDefaults();
  Stows.markAsOnMainIsolate();

  await _prepareServices();

  setLocale();
  stows.locale.addListener(setLocale);
  stows.customDataDir.addListener(FileManager.migrateDataDir);
  pdfrxFlutterInitialize();

  LicenseRegistry.addLicense(_extraLicenses);
  _limitImageCache();

  runApp(LagRecorder.wrap(TranslationProvider(child: const App())));
  _afterLaunch();
}

/// Sets how chatty the root logger is, keeps every record for the logs page,
/// and in release builds routes uncaught errors into the log too.
void _configureLogging(List<String> args) {
  final options = (ArgParser()..addFlag('verbose', abbr: 'v', negatable: false))
      .parse(args);
  final wantDetail = kDebugMode || options.flag('verbose');
  Logger.root.level = wantDetail ? Level.INFO : Level.WARNING;

  Logger.root.onRecord.listen((record) {
    logsHistory.add(record);
    // ignore: avoid_print
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
  });

  // Hooking the error handlers while debugging gets in the way of hot
  // reload, so only release and profile builds do it.
  if (kDebugMode) return;

  final crashLog = Logger('ErrorLogger');
  FlutterError.onError = (details) {
    crashLog.severe(
      details.exceptionAsString(),
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    crashLog.severe(error, stackTrace);
    return true; // dealt with: nothing more to print
  };
}

/// Everything the first frame depends on, started together and awaited as
/// one batch.
Future<void> _prepareServices() {
  final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  return Future.wait([
    stows.customDataDir.waitUntilRead().then((_) => FileManager.init()),
    if (isDesktop) windowManager.ensureInitialized(),
    workerManager.init(isolatesCount: _workerIsolates),
    if (DynamicMaterialApp.useYaruTitlebar)
      YaruWindowTitleBar.ensureInitialized(),
    stows.locale.waitUntilRead(),
    Printing.info().then((info) => Editor.canRasterPdf = info.canRaster),
  ]);
}

/// Licenses Flutter can't find on its own: the bundled fonts.
Stream<LicenseEntry> _extraLicenses() async* {
  for (final asset in _bundledFontLicenses) {
    final text = await rootBundle.loadString(asset);
    yield LicenseEntryWithLineBreaks(const ['google_fonts'], text);
  }
}

/// Decoded images are kept around for reuse; a tight cap keeps low-memory
/// phones comfortable.
void _limitImageCache() {
  final cache = PaintingBinding.instance.imageCache;
  cache.maximumSizeBytes = 48 << 20;
  cache.maximumSize = 200;
}

/// Jobs kicked off right after [runApp]: the lag recorder, syncing, and the
/// late handwriting scan for search.
void _afterLaunch() {
  LagRecorder.location = App.location;
  LagRecorder.start();
  startSyncAfterLoaded();
  setupBackgroundSync();

  // Reading handwriting needs ML Kit, which only phones have; wait until
  // start-up has calmed down before catching up on unread notes.
  if (Platform.isAndroid || Platform.isIOS) {
    Future.delayed(const Duration(seconds: 8), HandwritingOcr.backfill);
  }
}

/// Fetches and pushes notes once the account prefs are loaded. When nobody
/// is signed in it waits, re-running itself when the account details change.
void startSyncAfterLoaded() async {
  // one after the other, in this order
  for (final readPref in <Future<void> Function()>[
    stows.username.waitUntilRead,
    stows.encPassword.waitUntilRead,
    stows.syncProvider.waitUntilRead,
    stows.cloudSyncState.waitUntilRead,
    stows.syncOnlyOnWifi.waitUntilRead,
    stows.syncPreviewsOnMobileData.waitUntilRead,
    stows.fileSyncLastSynced.waitUntilRead,
  ]) {
    await readPref();
  }

  final accountPrefs = [stows.username, stows.encPassword];
  for (final pref in accountPrefs) {
    pref.removeListener(startSyncAfterLoaded);
  }
  if (!stows.loggedIn) {
    for (final pref in accountPrefs) {
      pref.addListener(startSyncAfterLoaded);
    }
    return;
  }

  // a short pause so the remaining prefs can finish loading
  await Future.delayed(const Duration(milliseconds: 100));
  _syncBothWays();

  // The weekly Drive backup waits a minute so it doesn't compete with start-up.
  await stows.autoDriveBackup.waitUntilRead();
  await stows.lastDriveBackup.waitUntilRead();
  Timer(const Duration(minutes: 1), Backup.autoBackupIfDue);

  // Getting Wi-Fi back is a good moment to catch up.
  _wifiWatch ??= Connectivity().onConnectivityChanged.listen((links) {
    if (stows.loggedIn && links.contains(ConnectivityResult.wifi)) {
      _syncBothWays();
    }
  });

  // Returning to the app may mean other devices changed something meanwhile.
  _returnWatch ??= AppLifecycleListener(
    onResume: () {
      if (stows.loggedIn) _syncBothWays();
    },
  );
}

void _syncBothWays() {
  syncer.downloader.refresh();
  syncer.uploader.refresh();
}

StreamSubscription<List<ConnectivityResult>>? _wifiWatch;
AppLifecycleListener? _returnWatch;

/// Uses the language picked in settings when it is one the app ships,
/// otherwise follows the device.
void setLocale() {
  final chosen = stows.locale.value;
  final shipped =
      chosen.isNotEmpty && AppLocaleUtils.supportedLocalesRaw.contains(chosen);
  if (shipped) {
    LocaleSettings.setLocaleRaw(chosen);
  } else {
    LocaleSettings.useDeviceLocale();
  }
}

/// Registers the occasional sync job with the OS on phones, if the user
/// allows background syncing. Runs again by itself once that pref is read.
void setupBackgroundSync() {
  if (!(Platform.isAndroid || Platform.isIOS)) return;

  final allowed = stows.syncInBackground;
  if (!allowed.loaded) {
    allowed.addListener(setupBackgroundSync);
    return;
  }
  allowed.removeListener(setupBackgroundSync);
  if (!allowed.value) return;

  final scheduler = Workmanager()..initialize(doBackgroundSync);
  const taskName = 'background-sync';
  const every = Duration(hours: 12);
  final conditions = Constraints(
    networkType: NetworkType.unmetered,
    requiresBatteryNotLow: true,
    requiresCharging: false,
    requiresDeviceIdle: true,
    requiresStorageNotLow: true,
  );

  if (Platform.isAndroid) {
    scheduler.registerPeriodicTask(
      taskName,
      taskName,
      frequency: every,
      initialDelay: every,
      constraints: conditions,
    );
  } else if (Platform.isIOS) {
    scheduler.registerOneOffTask(
      taskName,
      taskName,
      initialDelay: every,
      constraints: conditions,
    );
  }
}

/// The background job itself. It runs without the UI, so it sets up only what
/// syncing needs and stops after a handful of downloads to spare data and
/// battery.
@pragma('vm:entry-point')
void doBackgroundSync() {
  Workmanager().executeTask((_, _) async {
    FlavorConfig.setupFromEnvironment();
    StrokeOptionsExtension.setDefaults();
    Editor.canRasterPdf = false;

    await Future.wait([
      FileManager.init(),
      workerManager.init(isolatesCount: _workerIsolates),
      stows.syncProvider.waitUntilRead(),
      stows.cloudSyncState.waitUntilRead(),
    ]);

    return _downloadAFew(limit: 10);
  });
}

/// Completes once [limit] transfers have happened or nothing is left to
/// fetch; the result says whether anything was transferred at all.
Future<bool> _downloadAFew({required int limit}) {
  final finished = Completer<bool>();
  var count = 0;
  late final StreamSubscription<BadNotesSyncFile> watch;
  watch = syncer.downloader.transferStream.listen((_) {
    count++;
    final enough = count >= limit;
    final nothingLeft = syncer.downloader.numPending <= 0;
    if (!enough && !nothingLeft && !finished.isCompleted) return;
    watch.cancel();
    if (!finished.isCompleted) finished.complete(count > 0);
  });
  return finished.future;
}

/// The root widget: owns the router and opens files shared to the app.
class const App({super.key}) extends StatefulWidget {
  static final log = Logger('App');

  /// The page shown at launch: the Documents tab.
  static String initialLocation = pathToFunction(RoutePaths.home)({
    'subpage': HomePage.browseSubpage,
  });

  /// The current path, e.g. '/home/recent', or '' before the router exists.
  static String location() {
    try {
      final current = _navigation.routerDelegate.currentConfiguration;
      // A page pushed on top (like the editor) only shows up as the last
      // match, not in the overall uri.
      final top = current.matches.isNotEmpty ? current.matches.last : null;
      return top is ImperativeRouteMatch
          ? top.matches.uri.path
          : current.uri.path;
    } catch (_) {
      return '';
    }
  }

  static final _navigation = GoRouter(
    initialLocation: initialLocation,
    observers: [if (LagRecorder.enabled) LagRecorder.observer],
    routes: <GoRoute>[
      GoRoute(path: '/', redirect: (_, _) => initialLocation),
      GoRoute(path: RoutePaths.home, builder: _homeFor),
      GoRoute(path: RoutePaths.edit, builder: _editorFor),
      GoRoute(path: RoutePaths.login, builder: (_, _) => const NcLoginPage()),
      GoRoute(path: '/profile', redirect: (_, _) => RoutePaths.login),
      GoRoute(path: RoutePaths.logs, builder: (_, _) => const LogsPage()),
    ],
  );

  static Widget _homeFor(BuildContext context, GoRouterState state) {
    return HomePage(
      subpage: state.pathParameters['subpage'] ?? HomePage.recentSubpage,
      path: state.uri.queryParameters['path'],
    );
  }

  static Widget _editorFor(BuildContext context, GoRouterState state) {
    final query = state.uri.queryParameters;
    return TabbedEditor(path: query['path'], pdfPath: query['pdfPath']);
  }

  /// Note formats the app opens directly.
  static const _noteExtensions = {'.sbn', '.sbn2', '.sba'};

  /// Opens a file handed over by the OS: notes are imported and opened, PDFs
  /// become a new note when this device can draw PDF pages.
  static void openFile(SharedFile file) async {
    final source = file.value;
    if (source == null || file.type != SharedMediaType.FILE) return;
    log.info('Opening file: (${file.type}) $source');

    final ext = p.extension(source).isEmpty ? '.sbn2' : p.extension(source);

    if (_noteExtensions.contains(ext)) {
      final imported = await FileManager.importFile(
        source,
        null,
        extension: ext,
      );
      if (imported == null) return;
      // give the copy a moment to land on disk
      await Future.delayed(const Duration(milliseconds: 100));
      _navigation.push(RoutePaths.editFilePath(imported));
      return;
    }

    if (ext == '.pdf' && Editor.canRasterPdf) {
      final notePath = await FileManager.suffixFilePathToMakeItUnique(
        '/${p.basenameWithoutExtension(source)}',
      );
      _navigation.push(RoutePaths.editImportPdf(notePath, source));
      return;
    }

    log.warning('openFile: Unsupported file type: $ext');
  }

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  StreamSubscription<List<SharedFile>>? _sharedWhileOpen;

  @override
  void initState() {
    _listenForSharedFiles();
    super.initState();
  }

  /// Phones can hand files to the app: catch both the one that launched it
  /// and any shared while it is already running.
  void _listenForSharedFiles() {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    final sharing = FlutterSharingIntent.instance;
    sharing.getInitialSharing().then(_openAll);
    _sharedWhileOpen = sharing.getMediaStream().listen(_openAll);
  }

  void _openAll(List<SharedFile> files) => files.forEach(App.openFile);

  @override
  Widget build(BuildContext context) =>
      DynamicMaterialApp(title: 'BadNotes', router: App._navigation);

  @override
  void dispose() {
    _sharedWhileOpen?.cancel();
    super.dispose();
  }
}
