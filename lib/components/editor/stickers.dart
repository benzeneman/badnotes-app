import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:badnotes/components/editor/sticker_art.dart';

/// Opens a bottom sheet with every sticker in a grid and completes with the
/// one the user tapped, or null if the sheet was dismissed.
Future<StickerArt?> showStickerPicker(BuildContext context) =>
    showModalBottomSheet<StickerArt>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: _buildStickerSheet,
    );

/// The sheet takes 60% of the screen height and scrolls if the grid is
/// longer than that.
Widget _buildStickerSheet(BuildContext context) {
  final sheetHeight = MediaQuery.sizeOf(context).height * 0.6;
  return SafeArea(
    child: SizedBox(
      height: sheetHeight,
      child: GridView.extent(
        maxCrossAxisExtent: 84,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final sticker in stickers) _stickerTile(context, sticker),
        ],
      ),
    ),
  );
}

/// One sticker, named in its tooltip; tapping it closes the sheet with it.
Widget _stickerTile(BuildContext sheetContext, StickerArt sticker) => Tooltip(
  message: sticker.name,
  child: InkWell(
    onTap: () => Navigator.pop(sheetContext, sticker),
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: SvgPicture.string(sticker.svg),
    ),
  ),
);
