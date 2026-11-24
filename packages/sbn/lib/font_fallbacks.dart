import 'package:flutter/material.dart';

/// Font families tried, in order, for interface text when the main font is
/// missing. Covers common Linux, Android, Apple and Windows system fonts.
const badnotesSansSerifFontFallbacks = [
  'Adwaita Sans',
  'Inter',
  'Noto Sans',
  'Roboto',
  'Cantarell',
  'system-ui',
  'Atkinson Hyperlegible Next',
  'AtkinsonHyperlegibleNext',
  'Atkinson Hyperlegible',
  'AtkinsonHyperlegible',
  'sans-serif',
  'Ubuntu',
  'packages/yaru/Ubuntu',
  'CupertinoSystemDisplay',
  'CupertinoSystemText',
  '.AppleSystemUIFont',
  '.SF Pro Display',
  '.SF Pro Text',
  '.SF UI Display',
  '.SF UI Text',
  'Segoe UI',
];

/// Font families tried, in order, for fixed-width text such as code and logs.
const badnotesMonoFontFallbacks = [
  'Fira Mono',
  'ui-monospace',
  'Cascadia Code',
  'Source Code Pro',
  'Menlo',
  'Consolas',
  'DejaVu Sans Mono',
  'monospace',
];

/// Font families tried, in order, for typed text inside notes: the bundled
/// handwriting faces, then handwriting-style system fonts, and finally the
/// ordinary sans-serif list.
const badnotesHandwritingFontFallbacks = [
  'Neucha',
  'Dekko',
  'Segoe Print',
  'Bradley Hand',
  'Chilanka',
  'TSCu_Comic',
  'Coming Soon',
  'casual',
  'cursive',
  'handwriting',
  ...badnotesSansSerifFontFallbacks,
];

extension TextThemeExtension on TextTheme {
  /// A copy of this theme where every one of the fifteen text styles uses
  /// [fontFamily] and [fontFamilyFallback]. Styles that are null stay null.
  TextTheme withFont({
    required String? fontFamily,
    List<String>? fontFamilyFallback,
  }) {
    TextStyle? apply(TextStyle? style) => style?.copyWith(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
    );

    return copyWith(
      displayLarge: apply(displayLarge),
      displayMedium: apply(displayMedium),
      displaySmall: apply(displaySmall),
      headlineLarge: apply(headlineLarge),
      headlineMedium: apply(headlineMedium),
      headlineSmall: apply(headlineSmall),
      titleLarge: apply(titleLarge),
      titleMedium: apply(titleMedium),
      titleSmall: apply(titleSmall),
      bodyLarge: apply(bodyLarge),
      bodyMedium: apply(bodyMedium),
      bodySmall: apply(bodySmall),
      labelLarge: apply(labelLarge),
      labelMedium: apply(labelMedium),
      labelSmall: apply(labelSmall),
    );
  }
}
