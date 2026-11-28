import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:sbn/font_fallbacks.dart';

/// The colors the design uses beyond what a [ColorScheme] holds: every token
/// of the "Minimal" design (design/DESIGN.md §2), for light and dark.
class BadNotesColors extends ThemeExtension<BadNotesColors> {
  const BadNotesColors({
    required this.desk,
    required this.surface,
    required this.sunken,
    required this.sunkenSoft,
    required this.previewBg,
    required this.hairline,
    required this.divider,
    required this.rowHover,
    required this.text,
    required this.text2,
    required this.muted,
    required this.faint,
    required this.handle,
    required this.disabled,
    required this.toggleOff,
    required this.accent,
    required this.accentStrong,
    required this.accentTint,
    required this.accentTintBorder,
    required this.accentSoft,
    required this.highlightText,
    required this.danger,
    required this.success,
    required this.successTint,
    required this.scrim,
    required this.editorHeader,
    required this.editorHeaderTab,
    required this.folder,
    required this.folderTab,
    required this.pageShadow,
  });

  /// The app and editor background.
  final Color desk;

  /// Cards, bars, popovers.
  final Color surface;

  /// Search field, segmented track.
  final Color sunken;

  /// Small pressed or chosen backgrounds, previews.
  final Color sunkenSoft;

  /// The well a preview sits in, inside a popover.
  final Color previewBg;

  /// 1 px borders.
  final Color hairline;

  /// Lines between rows inside a card.
  final Color divider;
  final Color rowHover;

  final Color text, text2, muted, faint, handle, disabled, toggleOff;

  final Color accent, accentStrong, accentTint, accentTintBorder, accentSoft;

  /// Text on [accentSoft], e.g. a search match.
  final Color highlightText;

  final Color danger, success, successTint, scrim;

  final Color editorHeader, editorHeaderTab;

  /// The default folder colours (lavender).
  final Color folder, folderTab;
  final Color pageShadow;

  // The names older widgets use.
  Color get secondaryText => muted;
  Color get segmentTrack => sunken;

  static const light = BadNotesColors(
    desk: BnColors.desk,
    surface: BnColors.surface,
    sunken: BnColors.sunken,
    sunkenSoft: BnColors.sunkenSoft,
    previewBg: BnColors.previewBg,
    hairline: BnColors.hairline,
    divider: BnColors.divider,
    rowHover: BnColors.rowHover,
    text: BnColors.text,
    text2: BnColors.text2,
    muted: BnColors.muted,
    faint: BnColors.faint,
    handle: BnColors.handle,
    disabled: BnColors.disabled,
    toggleOff: BnColors.toggleOff,
    accent: BnColors.accent,
    accentStrong: BnColors.accentStrong,
    accentTint: BnColors.accentTint,
    accentTintBorder: BnColors.accentTintBorder,
    accentSoft: BnColors.accentSoft,
    highlightText: BnColors.highlightText,
    danger: BnColors.danger,
    success: BnColors.success,
    successTint: BnColors.successTint,
    scrim: BnColors.scrim,
    editorHeader: BnColors.surface,
    editorHeaderTab: BnColors.sunkenSoft,
    folder: Color(0xFFE6DEFB),
    folderTab: Color(0xFFCFC2F5),
    pageShadow: Color(0x14000000),
  );

  static const dark = BadNotesColors(
    desk: BnColors.deskDark,
    surface: BnColors.surfaceDark,
    sunken: BnColors.sunkenDark,
    sunkenSoft: BnColors.sunkenSoftDark,
    previewBg: BnColors.previewBgDark,
    hairline: BnColors.hairlineDark,
    divider: BnColors.dividerDark,
    rowHover: BnColors.rowHoverDark,
    text: BnColors.textDark,
    text2: BnColors.text2Dark,
    muted: BnColors.mutedDark,
    faint: BnColors.faintDark,
    handle: BnColors.handleDark,
    disabled: BnColors.disabledDark,
    toggleOff: BnColors.toggleOffDark,
    accent: BnColors.accentDark,
    accentStrong: BnColors.accentStrongDark,
    accentTint: BnColors.accentTintDark,
    accentTintBorder: BnColors.accentTintBorderDark,
    accentSoft: BnColors.accentSoftDark,
    highlightText: BnColors.highlightTextDark,
    danger: BnColors.dangerDark,
    success: BnColors.successDark,
    successTint: BnColors.successTintDark,
    scrim: BnColors.scrimDark,
    editorHeader: BnColors.surfaceDark,
    editorHeaderTab: BnColors.sunkenDark,
    // pastel folders are artwork: the same in dark mode
    folder: Color(0xFFE6DEFB),
    folderTab: Color(0xFFCFC2F5),
    pageShadow: Color(0x66000000),
  );

  static BadNotesColors of(BuildContext context) =>
      Theme.of(context).extension<BadNotesColors>() ?? light;

  @override
  BadNotesColors copyWith() => this;

  /// Themes switch at once (the app has no theme animation; see
  /// ThemeReveal), so there is nothing in between to blend.
  @override
  BadNotesColors lerp(covariant BadNotesColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

abstract class BadNotesTheme {
  /// The one accent color, for what's chosen or can be acted on. Everything
  /// else is white and warm neutral greys.
  static const badNotesBlue = BnColors.accent;
  static const fontFamily = BnType.family;

  /// The font of the "readable font" setting.
  static const readableFontFamily = 'AtkinsonHyperlegibleNext';

  static Color accent(Brightness brightness) =>
      brightness == .light ? BnColors.accent : BnColors.accentDark;

  /// The app's theme; with [readable], Atkinson Hyperlegible instead of Inter.
  static ThemeData create(Brightness brightness, {bool readable = false}) {
    final light = brightness == .light;
    final fontFamily = readable ? readableFontFamily : BadNotesTheme.fontFamily;
    final accent = BadNotesTheme.accent(brightness);
    final colors = light ? BadNotesColors.light : BadNotesColors.dark;
    final background = colors.desk;
    final surface = colors.surface;
    final ink = colors.text;

    final colorScheme =
        ColorScheme.fromSeed(
          brightness: brightness,
          seedColor: accent,
          dynamicSchemeVariant: .fidelity,
        ).copyWith(
          primary: accent,
          onPrimary: Colors.white,
          secondary: accent,
          surface: surface,
          surfaceTint: Colors.transparent,
          surfaceContainerLowest: surface,
          surfaceContainerLow: background,
          surfaceContainer: surface,
          surfaceContainerHigh: surface,
          surfaceContainerHighest: colors.segmentTrack,
          onSurface: ink,
          onSurfaceVariant: colors.secondaryText,
          outline: colors.secondaryText,
          outlineVariant: colors.hairline,
        );

    final title = TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: badnotesSansSerifFontFallbacks,
      color: ink,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );
    const controlShape = RoundedRectangleBorder(
      borderRadius: .all(.circular(BnRadius.control)),
    );
    const buttonSize = Size(0, 40);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 18);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      // the same on every device: Android, in look and in text rendering
      platform: TargetPlatform.android,
      fontFamily: fontFamily,
      fontFamilyFallback: badnotesSansSerifFontFallbacks,
      textTheme: _textTheme(fontFamily, ink, colors.muted),
      extensions: [colors],
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      cardColor: surface,
      dividerColor: colors.divider,
      // Taps darken slightly instead of a ripple, which is also lighter to draw.
      splashFactory: NoSplash.splashFactory,
      highlightColor: ink.withValues(alpha: 0.06),
      hoverColor: colors.rowHover,
      focusColor: ink.withValues(alpha: 0.06),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: QuietPageTransitionsBuilder(),
          TargetPlatform.iOS: QuietPageTransitionsBuilder(),
          TargetPlatform.linux: QuietPageTransitionsBuilder(),
          TargetPlatform.macOS: QuietPageTransitionsBuilder(),
          TargetPlatform.windows: QuietPageTransitionsBuilder(),
          TargetPlatform.fuchsia: QuietPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: title,
        iconTheme: IconThemeData(color: colors.text2, size: 20),
      ),
      iconTheme: IconThemeData(color: colors.text2, size: 20),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const .all(.circular(BnRadius.card)),
          side: BorderSide(color: colors.hairline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: colors.scrim,
        elevation: 16,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: const .all(.circular(BnRadius.popover)),
          side: BorderSide(color: colors.hairline),
        ),
        titleTextStyle: title,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: badnotesSansSerifFontFallbacks,
          color: colors.text2,
          fontSize: 13,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        modalBarrierColor: colors.scrim,
        showDragHandle: true,
        dragHandleColor: colors.handle,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BnRadius.popover),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: const .all(.circular(BnRadius.card)),
          side: BorderSide(color: colors.hairline),
        ),
        menuPadding: const EdgeInsets.all(6),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: badnotesSansSerifFontFallbacks,
          color: ink,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(12),
          shadowColor: const WidgetStatePropertyAll(Colors.black26),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: const .all(.circular(BnRadius.card)),
              side: BorderSide(color: colors.hairline),
            ),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: light ? BnColors.text : colors.sunken,
        actionTextColor: light ? BnColors.accentTintBorder : colors.accent,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: .all(.circular(BnRadius.tool)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.text2,
        textColor: ink,
        selectedColor: colors.accentStrong,
        selectedTileColor: colors.accentTint,
        minTileHeight: 40,
        shape: controlShape,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: buttonSize,
          padding: buttonPadding,
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: badnotesSansSerifFontFallbacks,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          shape: controlShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: buttonSize,
          padding: buttonPadding,
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: badnotesSansSerifFontFallbacks,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: ink,
          minimumSize: buttonSize,
          padding: buttonPadding,
          side: BorderSide(color: colors.hairline),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: badnotesSansSerifFontFallbacks,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          shape: controlShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accentStrong,
          minimumSize: buttonSize,
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: badnotesSansSerifFontFallbacks,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          shape: controlShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.text2,
          shape: const RoundedRectangleBorder(
            borderRadius: .all(.circular(BnRadius.tool)),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: .all(.circular(BnRadius.card)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: badnotesSansSerifFontFallbacks,
          color: colors.faint,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: const .all(.circular(BnRadius.control)),
          borderSide: BorderSide(color: colors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const .all(.circular(BnRadius.control)),
          borderSide: BorderSide(color: colors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const .all(.circular(BnRadius.control)),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: colors.accentSoft,
        selectionHandleColor: accent,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: accent,
        inactiveTrackColor: colors.hairline,
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 10,
          elevation: 2,
          pressedElevation: 3,
        ),
        overlayShape: SliderComponentShape.noOverlay,
        showValueIndicator: ShowValueIndicator.onDrag,
        valueIndicatorColor: ink,
        // ignore: deprecated_member_use
        year2023: true,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accent : colors.toggleOff,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbIcon: const WidgetStatePropertyAll(null),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : surface,
        ),
        side: BorderSide(color: colors.faint, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: .all(.circular(5))),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accent : colors.faint,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: colors.accentTint,
        disabledColor: colors.sunkenSoft,
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? colors.accentTintBorder
                : colors.hairline,
          ),
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: badnotesSansSerifFontFallbacks,
          color: colors.text2,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: badnotesSansSerifFontFallbacks,
          color: colors.accentStrong,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: colors.accentStrong,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        shape: const RoundedRectangleBorder(
          borderRadius: .all(.circular(BnRadius.chip)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? surface : colors.sunken,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? ink : colors.text2,
          ),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(controlShape),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: fontFamily,
              fontFamilyFallback: badnotesSansSerifFontFallbacks,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: colors.muted,
        indicatorColor: accent,
        dividerColor: colors.divider,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: light ? BnColors.text : colors.sunken,
          borderRadius: const .all(.circular(BnRadius.chip)),
        ),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: badnotesSansSerifFontFallbacks,
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: colors.hairline,
        // ignore: deprecated_member_use
        year2023: false,
        stopIndicatorColor: Colors.transparent,
      ),
      cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
        applyThemeToAll: true,
      ),
    );
  }

  static TextTheme _textTheme(String fontFamily, Color ink, Color secondary) {
    TextStyle style(
      double size,
      FontWeight weight,
      Color color, [
      double? height,
      double letterSpacing = 0,
    ]) => TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: badnotesSansSerifFontFallbacks,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
    return TextTheme(
      // display: page titles ("Recent")
      displaySmall: style(28, .w600, ink, 1.15, -0.8),
      headlineMedium: style(26, .w600, ink, 1.2, -0.6),
      headlineSmall: style(22, .w600, ink, 1.2, -0.4),
      // title: dialog & sheet titles
      titleLarge: style(17, .w600, ink, 1.3, -0.2),
      // section: section headers, popover titles
      titleMedium: style(15, .w600, ink, 1.3),
      titleSmall: style(13, .w600, ink, 1.3),
      bodyLarge: style(14, .w500, ink, 1.4),
      bodyMedium: style(13, .w500, ink, 1.4),
      // caption: meta lines
      bodySmall: style(12, .w400, secondary, 1.35),
      labelLarge: style(13, .w500, ink),
      labelMedium: style(12, .w500, ink),
      // micro: cover labels, tiny badges
      labelSmall: style(11, .w500, secondary),
    );
  }
}

/// A short fade with a small rise. Only opacity and position change, and
/// while it runs the page is a still picture: a fade of the live page (a
/// note's pages, say) drew it all again offscreen on every frame.
class QuietPageTransitionsBuilder extends PageTransitionsBuilder {
  const QuietPageTransitionsBuilder();

  @override
  Duration get transitionDuration => BnMotion.normal;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: BnMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(curved),
        child: _StillWhileMoving(
          animation: animation,
          enabled: route.allowSnapshotting,
          child: child,
        ),
      ),
    );
  }
}

/// [child] as a picture while [animation] runs, live again once it stops.
/// A platform view inside is drawn live instead (permissive mode).
class _StillWhileMoving extends StatefulWidget {
  const new({
    required this.animation,
    required this.enabled,
    required this.child,
  });

  final Animation<double> animation;
  final bool enabled;
  final Widget child;

  @override
  State<_StillWhileMoving> createState() => _StillWhileMovingState();
}

class _StillWhileMovingState extends State<_StillWhileMoving> {
  final _controller = SnapshotController();

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_status);
    _status(widget.animation.status);
  }

  @override
  void didUpdateWidget(_StillWhileMoving oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation == widget.animation) return;
    oldWidget.animation.removeStatusListener(_status);
    widget.animation.addStatusListener(_status);
    _status(widget.animation.status);
  }

  void _status(AnimationStatus status) => _controller.allowSnapshotting =
      !kIsWeb && widget.enabled && status.isAnimating;

  @override
  void dispose() {
    widget.animation.removeStatusListener(_status);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SnapshotWidget(
    controller: _controller,
    mode: SnapshotMode.permissive,
    autoresize: true,
    child: widget.child,
  );
}

extension BadNotesThemePlatform on TargetPlatform {
  bool get isCupertino => switch (this) {
    .iOS => true,
    .macOS => true,
    _ => false,
  };

  bool get isMaterialNative => switch (this) {
    .android => true,
    .fuchsia => true,
    _ => false,
  };
}
