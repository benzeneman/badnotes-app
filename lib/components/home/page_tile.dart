import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/locks.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';

/// A page of a note, small: the note's first page as its thumbnail, others
/// as lined paper with their number. Tapping opens the note at that page.
class PageTile extends StatelessWidget {
  const new({
    super.key,
    required this.path,
    required this.page,
    required this.label,
    this.bookmark = false,
  });

  final String path;

  /// From 0.
  final int page;
  final String label;

  /// A ribbon at the top right, for a bookmarked page.
  final bool bookmark;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final thumbnail = FileManager.getFile('$path${Editor.extension}.p');
    // no picture of a locked note's page
    final locked = NoteLocks.isProtected(path);
    final first = !locked && page == 0 && thumbnail.existsSync();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Editor.openAtPage[path] = page;
        openNote(context, path);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: colors.hairline),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (first)
                    Image(
                      image: ResizeImage(
                        FileImage(thumbnail),
                        width: 300,
                        allowUpscaling: false,
                      ),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  else ...[
                    const CustomPaint(painter: _Lines()),
                    Center(
                      child: locked
                          ? const Icon(
                              Icons.lock_outline,
                              color: Color(0x661C1C1E),
                            )
                          : Text(
                              '${page + 1}',
                              style: BnType.display.copyWith(
                                color: const Color(0x331C1C1E),
                              ),
                            ),
                    ),
                  ],
                  if (bookmark)
                    Positioned(
                      right: 10,
                      top: 0,
                      child: CustomPaint(
                        size: const Size(13, 20),
                        painter: _Ribbon(colors.accent),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BnType.caption.copyWith(
              color: bookmark ? colors.text : colors.muted,
              fontWeight: bookmark ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// "Physics · p.12".
  static String short(String path, int page) =>
      '${noteName(path)} · p.${page + 1}';
}

class _Lines extends CustomPainter {
  const _Lines();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE3E8F3);
    for (double y = 14; y < size.height; y += 11) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_Lines old) => false;
}

class _Ribbon extends CustomPainter {
  const _Ribbon(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width / 2, size.height * 0.72)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_Ribbon old) => old.color != color;
}
