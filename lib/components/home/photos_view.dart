import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/home/quick_board_view.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// A picture inside a note: its asset file and the note.
class NotePhoto {
  const new(this.file, this.note, this.modified);

  /// e.g. `/College/Physics.sbn2.3`.
  final String file;

  /// e.g. `/College/Physics`.
  final String note;
  final DateTime modified;
}

/// The pictures inside notes (design §7.5): asset files whose first bytes
/// are a PNG, JPEG or WebP, found off the UI thread and kept until a note
/// changes.
abstract final class NotePhotos {
  static final photos = ValueNotifier<List<NotePhoto>>(const []);
  static Future<void>? _scanning;
  static StreamSubscription<FileOperation>? _changes;
  static var _stale = true;

  static Future<void> scan() {
    _changes ??= FileManager.fileWriteStream.stream.listen((event) {
      if (event.isNoteAsset) _stale = true;
    });
    if (!_stale) return Future.value();
    return _scanning ??= _scan().whenComplete(() => _scanning = null);
  }

  static Future<void> _scan() async {
    _stale = false;
    final root = FileManager.documentsDirectory;
    final extension = Editor.extension;
    photos.value = await Isolate.run(() {
      final out = <NotePhoto>[];
      final asset = RegExp(r'\.sbn2\.\d+$');
      bool isPicture(List<int> head) =>
          (head.length >= 4 &&
              head[0] == 0x89 &&
              head[1] == 0x50 &&
              head[2] == 0x4E &&
              head[3] == 0x47) ||
          (head.length >= 3 &&
              head[0] == 0xFF &&
              head[1] == 0xD8 &&
              head[2] == 0xFF) ||
          (head.length >= 12 &&
              String.fromCharCodes(head.sublist(0, 4)) == 'RIFF' &&
              String.fromCharCodes(head.sublist(8, 12)) == 'WEBP');
      final dir = Directory(root);
      if (!dir.existsSync()) return out;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final path = entity.path.substring(root.length);
        if (path.split('/').any((part) => part.startsWith('.'))) continue;
        if (!asset.hasMatch(path)) continue;
        try {
          final raf = entity.openSync();
          final head = raf.readSync(12);
          raf.closeSync();
          if (!isPicture(head)) continue;
        } on FileSystemException {
          continue;
        }
        final note = path.substring(0, path.lastIndexOf(extension));
        out.add(NotePhoto(path, note, entity.lastModifiedSync()));
      }
      out.sort((a, b) => b.modified.compareTo(a.modified));
      return out;
    });
  }
}

/// The desk's Photos filter (design N23): pictures from notes and the
/// board, in a masonry grid.
class PhotosGrid extends HookWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      NotePhotos.scan();
      QuickBoard.load();
      return null;
    }, const []);
    final notePhotos = useValueListenable(NotePhotos.photos);
    final board = [
      for (final item in useValueListenable(QuickBoard.items))
        if (item.isPhoto) item,
    ];
    final colors = BadNotesColors.of(context);
    final count = notePhotos.length + board.length;
    if (count == 0) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Text(
            'Pictures you put in notes, or pin to your board, show here.',
            textAlign: TextAlign.center,
            style: BnType.body.copyWith(color: colors.muted),
          ),
        ),
      );
    }
    final columns = (MediaQuery.sizeOf(context).width / 300).floor().clamp(
      2,
      5,
    );
    return SliverMasonryGrid.count(
      crossAxisCount: columns,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childCount: count,
      itemBuilder: (context, i) {
        if (i < board.length) {
          final item = board[i];
          return _PhotoCard(
            file: item.photo!,
            title: 'Pinned photo',
            meta: '${homeShortDate(item.createdAt)} · on your board',
            onTap: () => showQuickPhoto(context, item),
          );
        }
        final photo = notePhotos[i - board.length];
        final folder = noteFolder(photo.note);
        return _PhotoCard(
          file: photo.file,
          title: noteName(photo.note),
          meta: folder == '/'
              ? homeShortDate(photo.modified)
              : '${folder.substring(1, folder.length - 1)} folder',
          onTap: () => openNote(context, photo.note),
        );
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.file,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  final String file, title, meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: BnCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image(
                image: ResizeImage(
                  FileImage(FileManager.getFile(file)),
                  width: 600,
                  allowUpscaling: false,
                ),
                fit: BoxFit.fitWidth,
                gaplessPlayback: true,
                errorBuilder: (context, _, _) => SizedBox(
                  height: 120,
                  child: ColoredBox(color: colors.sunkenSoft),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BnType.body.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      meta,
                      maxLines: 1,
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
