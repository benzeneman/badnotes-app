import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:flutter/material.dart';

/// The editor's colors, from the "Minimal" design (design/DESIGN.md §2): a
/// white header and white floating bars on a warm light desk, with one
/// violet accent. Dark mode keeps the same structure in near-black greys.
///
/// Colors that are the same in both are static; the rest come from
/// [EditorUi.of].
final class EditorUi {
  const EditorUi._({
    required this.brightness,
    required this.tabStrip,
    required this.topBar,
    required this.topBarIcon,
    required this.topBarSelected,
    required this.topBarSelectedIcon,
    required this.desk,
    required this.bar,
    required this.panel,
    required this.card,
    required this.cardDivider,
    required this.chosenChip,
    required this.icon,
    required this.iconDim,
    required this.text,
    required this.label,
    required this.menu,
    required this.hairline,
    required this.previewBg,
    required this.accentTint,
    required this.accentStrong,
    required this.handle,
  });

  /// The colors for [context]'s light or dark theme.
  static EditorUi of(BuildContext context) =>
      Theme.brightnessOf(context) == Brightness.dark ? dark : light;

  static const dark = EditorUi._(
    brightness: Brightness.dark,
    tabStrip: BnColors.deskDark,
    topBar: BnColors.surfaceDark,
    topBarIcon: BnColors.text2Dark,
    topBarSelected: BnColors.accentTintDark,
    topBarSelectedIcon: BnColors.accentStrongDark,
    desk: BnColors.deskDark,
    bar: BnColors.surfaceDark,
    panel: BnColors.surfaceDark,
    card: BnColors.previewBgDark,
    cardDivider: BnColors.dividerDark,
    chosenChip: BnColors.sunkenDark,
    icon: BnColors.text2Dark,
    iconDim: BnColors.mutedDark,
    text: BnColors.textDark,
    label: BnColors.mutedDark,
    // flat and nearly opaque: no blur over the canvas
    menu: Color(0xF21C1C1F),
    hairline: BnColors.hairlineDark,
    previewBg: BnColors.previewBgDark,
    accentTint: BnColors.accentTintDark,
    accentStrong: BnColors.accentStrongDark,
    handle: BnColors.handleDark,
  );

  static const light = EditorUi._(
    brightness: Brightness.light,
    tabStrip: BnColors.desk,
    topBar: BnColors.surface,
    topBarIcon: BnColors.text2,
    topBarSelected: BnColors.accentTint,
    topBarSelectedIcon: BnColors.accentStrong,
    desk: BnColors.desk,
    bar: BnColors.surface,
    panel: BnColors.surface,
    card: BnColors.previewBg,
    cardDivider: BnColors.divider,
    chosenChip: BnColors.sunkenSoft,
    icon: BnColors.text2,
    iconDim: BnColors.faint,
    text: BnColors.text,
    label: BnColors.muted,
    menu: Color(0xF5FFFFFF),
    hairline: BnColors.hairline,
    previewBg: BnColors.previewBg,
    accentTint: BnColors.accentTint,
    accentStrong: BnColors.accentStrong,
    handle: BnColors.handle,
  );

  final Brightness brightness;
  final Color tabStrip, topBar, topBarIcon, topBarSelected, topBarSelectedIcon;

  /// Around the pages.
  final Color desk;

  /// Floating tool bars and the undo pill.
  final Color bar;

  /// Panels, and the cards inside them.
  final Color panel, card, cardDivider;

  /// A chosen size or option, in grey.
  final Color chosenChip;
  final Color icon, iconDim, text, label;

  /// The ⋯ menu of a selection: a flat, nearly opaque colour (no blur over
  /// the canvas).
  final Color menu;

  /// 1 px borders of bars and panels.
  final Color hairline;

  /// The well a preview sits in, inside a panel.
  final Color previewBg;

  /// A chosen tool, chip or row: [accentTint] behind, [accentStrong] on it.
  final Color accentTint, accentStrong;

  /// The toolbar's drag handle dots.
  final Color handle;

  /// The chosen pen's chip.
  static const chosenTool = BnColors.accent;
  static const accent = BnColors.accent;
  static const switchOn = BnColors.accent;
  static const destructive = BnColors.danger;
  static const selection = BnColors.accent;

  static const barRadius = BnRadius.dock;
  static const panelRadius = BnRadius.popover;
  static const cardRadius = BnRadius.card;
  static const subBarRadius = BnRadius.card;
}
