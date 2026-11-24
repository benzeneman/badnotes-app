import 'package:badnotes/components/home/note_facts.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:flutter/material.dart';

/// The whiteboards, newest first, with the quick one ([quick]) at the top.
List<String> boardPaths(Map<String, NoteFacts> facts, String quick) {
  final boards = [
    for (final MapEntry(key: path, value: f) in facts.entries)
      if (f.board && path != quick) path,
  ]..sort(
      (a, b) => FileManager.lastModified(b + _extension)
          .compareTo(FileManager.lastModified(a + _extension)),
    );
  return [quick, ...boards];
}

const _extension = '.sbn2';

/// A whiteboard's card: its picture if one was saved, else dotted paper.
class BoardThumb extends StatelessWidget {
  const BoardThumb({super.key, required this.path, this.ringed = false});

  final String path;

  /// The board that's open.
  final bool ringed;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final thumbnail = FileManager.getFile('$path$_extension.p');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: ringed ? colors.accentStrong : colors.hairline,
          width: ringed ? 2.5 : 1,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.card)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(BnRadius.card - 1),
        ),
        child: CustomPaint(
          painter: BoardDots(colors.hairline),
          child: thumbnail.existsSync()
              ? Image(
                  image: ResizeImage(
                    FileImage(thumbnail),
                    width: 640,
                    allowUpscaling: false,
                  ),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Dotted paper, as on a whiteboard's card.
class BoardDots extends CustomPainter {
  const BoardDots(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double y = 12; y < size.height; y += 16) {
      for (double x = 12; x < size.width; x += 16) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(BoardDots old) => old.color != color;
}

/// A whiteboard's side panel, in place of a notebook's pages: the
/// whiteboards (tap one to open it, ⋯ to rename, copy or delete it) and the
/// recordings.
class BoardsPanel extends StatefulWidget {
  const BoardsPanel({
    super.key,
    required this.current,
    required this.quick,
    required this.open,
    required this.newBoard,
    required this.rename,
    required this.duplicate,
    required this.delete,
    this.audio,
    this.showAudio = false,
    this.onClose,
  });

  /// Opens on the Audio tab, as Recordings in the Insert menu does.
  final bool showAudio;

  /// The board that's open, and the quick whiteboard's path.
  final String current, quick;
  final ValueChanged<String> open;
  final VoidCallback? newBoard;
  final ValueChanged<String> rename, duplicate, delete;

  /// What's in the Audio tab, when the board can have recordings.
  final Widget? audio;
  final VoidCallback? onClose;

  @override
  State<BoardsPanel> createState() => _BoardsPanelState();
}

class _BoardsPanelState extends State<BoardsPanel> {
  late var _audio = widget.showAudio && widget.audio != null;

  @override
  void initState() {
    super.initState();
    NoteFactsCache.scan();
  }

  String _name(String path) => path == widget.quick
      ? 'Quick whiteboard'
      : path.substring(path.lastIndexOf('/') + 1);

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Material(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            right: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Whiteboards',
                      style: BnType.title.copyWith(color: colors.text),
                    ),
                  ),
                  if (widget.onClose != null)
                    BnIconButton(
                      icon: Icons.close,
                      size: 32,
                      iconSize: 18,
                      tooltip: 'Close',
                      color: colors.text2,
                      onPressed: widget.onClose!,
                    ),
                ],
              ),
            ),
          ),
          if (widget.audio != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: BnSegmented<bool>(
                height: 34,
                segments: const [
                  BnSegment(false, 'Boards'),
                  BnSegment(true, 'Audio'),
                ],
                selected: _audio,
                onChanged: (audio) => setState(() => _audio = audio),
              ),
            ),
          Expanded(
            child: _audio && widget.audio != null
                ? widget.audio!
                : ValueListenableBuilder(
                    valueListenable: NoteFactsCache.facts,
                    builder: (context, facts, _) =>
                        _boards(boardPaths(facts, widget.quick)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _boards(List<String> paths) {
    final colors = BadNotesColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        if (widget.newBoard != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: OutlinedButton.icon(
              onPressed: widget.newBoard,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New whiteboard'),
            ),
          ),
        for (final path in paths)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.open(path),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 120,
                    child: BoardThumb(
                      path: path,
                      ringed: path == widget.current,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _name(path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BnType.body.copyWith(
                            color: colors.text,
                            fontWeight: path == widget.current
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                      ),
                      // the quick whiteboard is cleared from its own menu
                      if (path != widget.quick)
                        Builder(
                          builder: (context) => BnIconButton(
                            icon: Icons.more_horiz,
                            size: 32,
                            iconSize: 18,
                            tooltip: 'Whiteboard options',
                            color: colors.text2,
                            onPressed: () => showAppleMenu(
                              context,
                              anchor: rectOf(context),
                              entries: [
                                AppleMenuItem(
                                  'Rename',
                                  icon: Icons.drive_file_rename_outline,
                                  onTap: () => widget.rename(path),
                                ),
                                AppleMenuItem(
                                  'Duplicate',
                                  icon: Icons.copy_outlined,
                                  onTap: () => widget.duplicate(path),
                                ),
                                AppleMenuItem(
                                  'Delete',
                                  icon: Icons.delete_outline,
                                  destructive: true,
                                  onTap: () => widget.delete(path),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
