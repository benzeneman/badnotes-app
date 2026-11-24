// BadNotes "Minimal" design tokens.
// Source of truth: design/DESIGN.md §2. Wire these into the theme
// (BadNotesColors ThemeExtension + EditorUi) instead of using them directly
// in widgets, so light/dark switching keeps working.
import 'package:flutter/material.dart';

abstract final class BnColors {
  // Light
  static const desk = Color(0xFFF6F6F4);
  static const surface = Color(0xFFFFFFFF);
  static const sunken = Color(0xFFEDEDEA);
  static const sunkenSoft = Color(0xFFF2F2EF);
  static const previewBg = Color(0xFFF6F6F4);
  static const hairline = Color(0xFFE7E6E1);
  static const divider = Color(0xFFEFEEEA);
  static const rowHover = Color(0xFFF4F4F1);
  static const text = Color(0xFF1C1C1E);
  static const text2 = Color(0xFF3A3A3F);
  static const muted = Color(0xFF6B6B70);
  static const faint = Color(0xFF8A8A90);
  static const handle = Color(0xFFA4A4AA);
  static const disabled = Color(0xFFB4B4B8);
  static const toggleOff = Color(0xFFE2E1DC);

  static const accent = Color(0xFF6E56CF);
  static const accentStrong = Color(0xFF5A43B8);
  static const accentTint = Color(0xFFF0EDFC);
  static const accentTintBorder = Color(0xFFE0D9FA);
  static const accentSoft = Color(0xFFE9E4FB);
  static const highlightText = Color(0xFF4B3A9E);

  static const danger = Color(0xFFD93A2B);
  static const success = Color(0xFF2A7660);
  static const successTint = Color(0xFFE2F3EC);
  static const scrim = Color(0x47141416); // rgba(20,20,22,.28)

  // Dark (derived)
  static const deskDark = Color(0xFF111113);
  static const surfaceDark = Color(0xFF1C1C1F);
  static const sunkenDark = Color(0xFF26262A);
  static const hairlineDark = Color(0xFF2E2E32);
  static const dividerDark = Color(0xFF2A2A2E);
  static const textDark = Color(0xFFEDEDEF);
  static const text2Dark = Color(0xFFC7C7CC);
  static const mutedDark = Color(0xFF8E8E93);
  static const accentDark = Color(0xFF8B7CF0);
  static const accentStrongDark = Color(0xFFB9ADF7);
  static const accentTintDark = Color(0xFF2A2440);
  static const dangerDark = Color(0xFFFF6B5E);
  static const scrimDark = Color(0x80000000);

  // Cover pastels
  static const lavender = Color(0xFFE8E1FB);
  static const blush = Color(0xFFFBE3DA);
  static const mint = Color(0xFFDCEFE9);
  static const sand = Color(0xFFF7ECCF);
  static const sky = Color(0xFFDCE8FB);
  static const rose = Color(0xFFF8DDE6);
  static const charcoal = Color(0xFF2B2B30);

  // Quick notes
  static const noteButter = Color(0xFFFFF4CC);
  static const notePeach = Color(0xFFFDE7E1);
  static const noteSky = Color(0xFFE9F1FB);
  static const noteLilac = Color(0xFFEEEAFC);
  static const noteMint = Color(0xFFE2F3EC);

  // Default ink presets
  static const inkBlack = Color(0xFF1C1C1E);
  static const inkBlue = Color(0xFF2B4ACB);
  static const inkRed = Color(0xFFE03131);
  static const inkGreen = Color(0xFF2F9E77);
}

/// Folder colours: back panel + tab, front panel, icon ink.
enum BnFolderColor {
  lavender(Color(0xFFCFC2F5), Color(0xFFE6DEFB), Color(0xFF5A43B8)),
  peach(Color(0xFFF2C2B1), Color(0xFFFBE3DA), Color(0xFFA9502F)),
  mint(Color(0xFFB5DDD0), Color(0xFFDCEFE9), Color(0xFF2A7660)),
  sand(Color(0xFFEBD69F), Color(0xFFF7ECCF), Color(0xFF7E611A)),
  sky(Color(0xFFB9D3F2), Color(0xFFE3EDFB), Color(0xFF2B5C9E)),
  rose(Color(0xFFEFC1D0), Color(0xFFF8DDE6), Color(0xFF9E3E5E));

  const BnFolderColor(this.back, this.front, this.ink);
  final Color back, front, ink;
}

abstract final class BnRadius {
  static const chip = 8.0;
  static const control = 10.0; // inputs, buttons, segmented track
  static const tool = 12.0;
  static const card = 14.0; // cards, sub-bar
  static const dock = 16.0; // editor tool dock
  static const popover = 18.0; // popovers, sheets, dialogs
  static const pill = 999.0; // home dock
  static const cover = BorderRadius.only(
    topLeft: Radius.circular(4), bottomLeft: Radius.circular(4),
    topRight: Radius.circular(12), bottomRight: Radius.circular(12),
  );
}

abstract final class BnShadows {
  static const card = [BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1))];
  static const floating = [BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, 10))];
  static const popover = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1F000000), blurRadius: 48, offset: Offset(0, 18)),
  ];
  static const cover = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
  ];
}

abstract final class BnType {
  static const family = 'Inter';
  static const display = TextStyle(fontFamily: family, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.8, height: 1.15);
  static const title = TextStyle(fontFamily: family, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2);
  static const section = TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontFamily: family, fontSize: 13, fontWeight: FontWeight.w500);
  static const bodyLarge = TextStyle(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w500);
  static const caption = TextStyle(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w400);
  static const micro = TextStyle(fontFamily: family, fontSize: 11, fontWeight: FontWeight.w500);
}

abstract final class BnMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 200);
  static const curve = Curves.easeOutCubic;
  static const popoverStartScale = 0.96;
}

abstract final class BnSpace {
  static const marginLandscape = 40.0;
  static const marginPortrait = 28.0;
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 24.0, xxl = 32.0;
  static const iconStroke = 1.8;
}
