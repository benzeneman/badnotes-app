import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:badnotes/components/editor/sticker_art.dart';
import 'package:badnotes/components/editor_ui/editor_ui_colors.dart';
import 'package:badnotes/components/editor_ui/tool_panel.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/recent_images.dart';

/// Pictures: the ones put in lately in a grid, the camera at the top, and
/// "Insert from…" for any other.
PanelPage imagesPage({
  required VoidCallback fromFiles,
  required VoidCallback camera,
  required VoidCallback asBackground,
  required ValueChanged<File> insertRecent,
}) {
  final recent = RecentImages.list();
  return PanelPage(
    title: 'Images',
    width: 380,
    trailing: (context) => IconButton(
      tooltip: 'Camera',
      icon: Icon(Icons.photo_camera_outlined, color: EditorUi.of(context).icon),
      onPressed: () {
        Navigator.pop(context);
        camera();
      },
    ),
    builder: (context, _) {
      final ui = EditorUi.of(context);
      final ratio = MediaQuery.devicePixelRatioOf(context);
      void run(VoidCallback action) {
        Navigator.pop(context);
        action();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FutureBuilder(
            future: recent,
            builder: (context, snapshot) {
              final files = snapshot.data ?? const <File>[];
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(height: 120);
              }
              if (files.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Text(
                    'Pictures you put in notes show up here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ui.label),
                  ),
                );
              }
              return GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final file in files)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.pop(context);
                        insertRecent(file);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        // decoded at the size it's shown, not the photo's
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                          cacheWidth: (88 * ratio).round(),
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => ColoredBox(color: ui.card),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: ui.card,
                  foregroundColor: ui.text,
                ),
                onPressed: () => run(fromFiles),
                child: const Text('Insert from…'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: ui.label),
                onPressed: () => run(asBackground),
                child: const Text('As page background'),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// The stickers, the ones used lately first. Small pictures, drawn at the
/// size they're shown.
PanelPage stickersPage({required ValueChanged<StickerArt> pick}) => PanelPage(
  title: 'Stickers',
  width: 360,
  builder: (context, _) {
    final recent = [
      for (final name in stows.recentStickers.value)
        ...stickers.where((s) => s.name == name),
    ];
    Widget grid(List<StickerArt> list) => Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final sticker in list)
          Tooltip(
            message: sticker.name,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                stows.recentStickers.value = [
                  sticker.name,
                  for (final name in stows.recentStickers.value)
                    if (name != sticker.name) name,
                ].take(12).toList();
                Navigator.pop(context);
                pick(sticker);
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SvgPicture.string(sticker.svg, width: 60, height: 60),
              ),
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recent.isNotEmpty) ...[
          const PanelSection('Recents'),
          grid(recent),
        ],
        const PanelSection('All Stickers'),
        grid(stickers),
      ],
    );
  },
);
