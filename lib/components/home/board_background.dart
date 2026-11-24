import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// What the quick notes board is drawn on (design 7).
enum BoardPattern {
  none('None'),
  dots('Dots'),
  grid('Grid'),
  cork('Cork'),
  photo('Photo');

  const BoardPattern(this.label);

  final String label;

  static BoardPattern get current => BoardPattern.values.firstWhere(
    (p) => p.name == stows.boardPattern.value,
    orElse: () => BoardPattern.dots,
  );
}

/// The board's colours to pick from.
const boardColors = <Color>[
  Color(0xFFF3EEE4),
  Color(0xFFFFFFFF),
  Color(0xFFE9F1FB),
  Color(0xFFE2F3EC),
  Color(0xFFEEEAFC),
  Color(0xFFFDE7E1),
  Color(0xFF2B2B30),
];

/// The board's background, filling its space: a colour with a pattern, or
/// the user's photo faded a little so notes stay easy to read.
class BoardBackground extends StatelessWidget {
  const BoardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    // drawn once, not again for each frame of a zoom or a moved note
    return RepaintBoundary(child: _build());
  }

  Widget _build() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        stows.boardPattern,
        stows.boardColor,
        stows.boardPhotoFade,
        QuickBoard.backgroundChanged,
      ]),
      builder: (context, _) {
        final pattern = BoardPattern.current;
        final color = Color(stows.boardColor.value);
        if (pattern == BoardPattern.photo &&
            FileManager.doesFileExist(QuickBoard.backgroundFile)) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image(
                key: ValueKey(QuickBoard.backgroundChanged.value),
                image: ResizeImage(
                  FileImage(FileManager.getFile(QuickBoard.backgroundFile)),
                  width: 1600,
                  allowUpscaling: false,
                ),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, _, _) => ColoredBox(color: color),
              ),
              ColoredBox(
                color: Colors.white.withValues(
                  alpha: stows.boardPhotoFade.value.clamp(0.0, 0.9),
                ),
              ),
            ],
          );
        }
        return CustomPaint(
          painter: _PatternPainter(pattern, color),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter(this.pattern, this.color);

  final BoardPattern pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final base = pattern == BoardPattern.cork ? const Color(0xFFC9A57A) : color;
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final dark = base.computeLuminance() < 0.3;
    final mark = Paint()
      ..color = dark
          ? Colors.white.withValues(alpha: 0.12)
          : Color.lerp(base, Colors.black, 0.12)!;
    switch (pattern) {
      case BoardPattern.dots:
        // one draw call for every dot: thousands of circles were slow
        final dots = <double>[];
        for (var y = 9.0; y < size.height; y += 18) {
          for (var x = 9.0; x < size.width; x += 18) {
            dots
              ..add(x)
              ..add(y);
          }
        }
        canvas.drawRawPoints(
          PointMode.points,
          Float32List.fromList(dots),
          mark
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      case BoardPattern.grid:
        mark.strokeWidth = 1;
        for (var x = 0.0; x < size.width; x += 22) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), mark);
        }
        for (var y = 0.0; y < size.height; y += 22) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), mark);
        }
      case BoardPattern.cork:
        // a speckle that looks the same each time, in three sizes of
        // speck, each drawn in one call
        var seed = 7;
        double next() {
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          return seed / 0x7fffffff;
        }

        final specks = [<double>[], <double>[], <double>[]];
        for (var y = 0.0; y < size.height; y += 6) {
          for (var x = 0.0; x < size.width; x += 6) {
            if (next() < 0.45) {
              final px = x + next() * 5, py = y + next() * 5;
              specks[(next() * 3).floor().clamp(0, 2)]
                ..add(px)
                ..add(py);
            }
          }
        }
        for (final (i, points) in specks.indexed) {
          canvas.drawRawPoints(
            PointMode.points,
            Float32List.fromList(points),
            Paint()
              ..color = const Color(0xFFB48D60)
              ..strokeWidth = 2 * (0.75 + i * 0.3)
              ..strokeCap = StrokeCap.round,
          );
        }
      case BoardPattern.none:
      case BoardPattern.photo:
        break;
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.pattern != pattern || old.color != color;
}

/// The board background panel (design 7), next to [anchor].
Future<void> showBoardBackground(BuildContext anchor) => showBnPopover<void>(
  anchor: anchor,
  width: 360,
  builder: (context) => const _BackgroundPanel(),
);

class _BackgroundPanel extends StatefulWidget {
  const _BackgroundPanel();

  @override
  State<_BackgroundPanel> createState() => _BackgroundPanelState();
}

class _BackgroundPanelState extends State<_BackgroundPanel> {
  var _busy = false;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _busy = true);
    final ok = await QuickBoard.setBackgroundPhoto(await picked.readAsBytes());
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) stows.boardPattern.value = BoardPattern.photo.name;
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Text(
      title,
      style: BnType.caption.copyWith(
        color: BadNotesColors.of(context).muted,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final pattern = BoardPattern.current;
    final color = Color(stows.boardColor.value);
    final hasPhoto = FileManager.doesFileExist(QuickBoard.backgroundFile);

    Widget tile(BoardPattern p) {
      final selected = p == pattern;
      return GestureDetector(
        onTap: () {
          if (p == BoardPattern.photo && !hasPhoto) {
            _pickPhoto();
            return;
          }
          setState(() => stows.boardPattern.value = p.name);
        },
        child: Semantics(
          button: true,
          selected: selected,
          label: '${p.label} background',
          child: Column(
            children: [
              AnimatedContainer(
                duration: BnMotion.fast,
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(
                    color: selected ? colors.accent : colors.hairline,
                    width: selected ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: switch (p) {
                  BoardPattern.none => Icon(
                    BnIcons.close,
                    size: 18,
                    color: colors.faint,
                  ),
                  BoardPattern.photo when hasPhoto => Image(
                    image: ResizeImage(
                      FileImage(FileManager.getFile(QuickBoard.backgroundFile)),
                      width: 160,
                    ),
                    fit: BoxFit.cover,
                  ),
                  BoardPattern.photo => Icon(
                    BnIcons.photo,
                    size: 18,
                    color: colors.muted,
                  ),
                  _ => CustomPaint(painter: _PatternPainter(p, color)),
                },
              ),
              const SizedBox(height: 5),
              Text(
                p.label,
                style: BnType.micro.copyWith(
                  color: selected ? colors.accentStrong : colors.text2,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Board background',
          style: BnType.section.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        _section('Pattern'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (final p in BoardPattern.values) tile(p)],
        ),
        if (pattern != BoardPattern.photo) ...[
          _section('Colour'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in boardColors)
                BnColorDot(
                  color: c,
                  size: 26,
                  selected: c.toARGB32() == color.toARGB32(),
                  onTap: () =>
                      setState(() => stows.boardColor.value = c.toARGB32()),
                ),
            ],
          ),
        ],
        _section('Your photo'),
        Row(
          children: [
            Expanded(
              child: Text(
                hasPhoto
                    ? 'Fills the board, cropped to fit'
                    : 'Put a photo of your own behind the notes',
                style: BnType.caption.copyWith(color: colors.muted),
              ),
            ),
            const SizedBox(width: 10),
            BnButton(
              label: hasPhoto ? 'Change' : 'Choose',
              height: 34,
              onPressed: _busy ? null : _pickPhoto,
            ),
          ],
        ),
        if (pattern == BoardPattern.photo) ...[
          const SizedBox(height: 10),
          BnSlider(
            label: 'Fade photo',
            valueLabel: '${(stows.boardPhotoFade.value * 100).round()}%',
            value: stows.boardPhotoFade.value.clamp(0.0, 0.9),
            max: 0.9,
            onChanged: (v) => setState(() => stows.boardPhotoFade.value = v),
          ),
          const SizedBox(height: 4),
          Text(
            'A little fade keeps the notes easy to read on a busy photo.',
            style: BnType.micro.copyWith(color: colors.faint),
          ),
        ],
        const SizedBox(height: 14),
        Divider(height: 1, color: colors.divider),
        const SizedBox(height: 12),
        BnButton(
          label: 'Remove background',
          kind: BnButtonKind.destructive,
          expand: true,
          onPressed: () => setState(() {
            stows.boardPattern.value = BoardPattern.none.name;
            stows.boardColor.value = colors.surface.toARGB32();
          }),
        ),
      ],
    );
  }
}
