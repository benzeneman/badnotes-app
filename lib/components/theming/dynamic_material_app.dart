import 'dart:io';

import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/i18n/extensions/redirecting_localization_delegate.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaru/yaru.dart';

/// The root app widget. It follows the theme and font settings and owns
/// the app-wide fullscreen flag.
class DynamicMaterialApp extends StatefulHookWidget {
  const new({super.key, required this.title, required this.router});

  final String title;
  final GoRouter router;

  /// On Windows the app draws its own title bar.
  static final useYaruTitlebar = Platform.isWindows;

  static final _fullscreen = ValueNotifier<bool>(false);

  /// Whether the app is currently fullscreen (immersive on mobile).
  static bool get isFullscreen => _fullscreen.value;

  /// Records the fullscreen [value]. With [updateSystem], also asks the
  /// window (desktop) or the system bars (mobile) to follow; leave it false
  /// when the change came from the system in the first place.
  static void setFullscreen(bool value, {required bool updateSystem}) {
    _fullscreen.value = value;
    if (updateSystem) _applyToSystem(value);
  }

  static void _applyToSystem(bool fullscreen) {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    if (isDesktop) {
      windowManager.setFullScreen(fullscreen);
      return;
    }
    SystemChrome.setEnabledSystemUIMode(
      fullscreen ? SystemUiMode.immersive : SystemUiMode.edgeToEdge,
    );
  }

  static void addFullscreenListener(void Function() listener) =>
      _fullscreen.addListener(listener);

  static void removeFullscreenListener(void Function() listener) =>
      _fullscreen.removeListener(listener);

  @override
  State<DynamicMaterialApp> createState() => DynamicMaterialAppState();
}

/// Keeps [DynamicMaterialApp.isFullscreen] in step with the window and the
/// system bars, and rebuilds the app when the theme settings change.
class DynamicMaterialAppState extends State<DynamicMaterialApp>
    with WindowListener {
  /// Themes are costly to build and never change, so each one is made the
  /// first time it is needed and then kept.
  static final _plain = _ThemePair(readable: false);
  static final _readable = _ThemePair(readable: true);

  @override
  void initState() {
    windowManager.addListener(this);
    SystemChrome.setSystemUIChangeCallback(_systemBarsChanged);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    SystemChrome.setSystemUIChangeCallback(null);
    super.dispose();
  }

  @override
  void onWindowEnterFullScreen() => _followSystem(true);

  @override
  void onWindowLeaveFullScreen() => _followSystem(false);

  Future<void> _systemBarsChanged(bool barsShowing) async =>
      _followSystem(!barsShowing);

  void _followSystem(bool fullscreen) =>
      DynamicMaterialApp.setFullscreen(fullscreen, updateSystem: false);

  @override
  Widget build(BuildContext context) {
    final mode = useValueListenable(stows.appTheme);
    final themes = useValueListenable(stows.hyperlegibleFont)
        ? _readable
        : _plain;
    return ExplicitlyThemedApp(
      title: widget.title,
      router: widget.router,
      themeMode: mode,
      theme: themes.light,
      darkTheme: themes.dark,
    );
  }
}

class _ThemePair {
  new({required this.readable});

  final bool readable;
  late final light = BadNotesTheme.create(.light, readable: readable);
  late final dark = BadNotesTheme.create(.dark, readable: readable);
}

/// The Windows title bar (app icon and name) above the app's pages.
class _WindowsFrame extends StatelessWidget {
  const new({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final heading = Row(
      children: [
        SizedBox.square(
          dimension: 16,
          child: SvgPicture.asset('assets/icon/icon.svg'),
        ),
        const SizedBox(width: 8),
        const Text('BadNotes'),
      ],
    );
    return Scaffold(
      appBar: YaruWindowTitleBar(
        title: heading,
        centerTitle: false,
        buttonPadding: const EdgeInsets.only(bottom: 1),
      ),
      body: child,
    );
  }
}

/// The [MaterialApp] itself, with the themes handed in from outside so
/// tests can build the real app with any theme.
///
/// High-contrast themes that are not given are made from [theme] and
/// [darkTheme].
@visibleForTesting
class ExplicitlyThemedApp extends StatelessWidget {
  @protected
  const new({
    super.key,
    required this.title,
    required this.router,
    required this.themeMode,
    required this.theme,
    required this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
  });

  final String title;
  final GoRouter router;
  final ThemeMode themeMode;
  final ThemeData theme;
  final ThemeData? darkTheme, highContrastTheme, highContrastDarkTheme;

  /// One key for the app's whole life, so its state survives rebuilds.
  static final _materialAppKey = GlobalKey<State<MaterialApp>>();

  static const _localizations = <LocalizationsDelegate<Object?>>[
    RedirectingLocalizationDelegate<CupertinoLocalizations>(
      GlobalCupertinoLocalizations.delegate,
    ),
    RedirectingLocalizationDelegate<MaterialLocalizations>(
      GlobalMaterialLocalizations.delegate,
    ),
    RedirectingLocalizationDelegate<WidgetsLocalizations>(
      GlobalWidgetsLocalizations.delegate,
    ),
    RedirectingLocalizationDelegate<FlutterQuillLocalizations>(
      FlutterQuillLocalizations.delegate,
    ),
  ];

  static ThemeData? _sharper(ThemeData? base) =>
      base?.copyWith(colorScheme: base.colorScheme._sharper());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      key: _materialAppKey,
      title: title,
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: _localizations,
      themeMode: themeMode,
      theme: theme,
      darkTheme: darkTheme,
      highContrastTheme: highContrastTheme ?? _sharper(theme),
      highContrastDarkTheme: highContrastDarkTheme ?? _sharper(darkTheme),
      debugShowCheckedModeBanner: false,
      builder: DynamicMaterialApp.useYaruTitlebar
          ? (context, child) => _WindowsFrame(child: child)
          : null,
    );
  }
}

extension on ColorScheme {
  /// The same hue on a pure white or black surface at full contrast.
  ColorScheme _sharper() => ColorScheme.fromSeed(
    brightness: brightness,
    seedColor: primary,
    surface: brightness == .light ? Colors.white : Colors.black,
    contrastLevel: 1,
  );
}
