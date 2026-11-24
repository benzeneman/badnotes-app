import 'dart:math' as math;

import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:flutter/material.dart';

/// A folder drawn as a tab, a back panel with up to two small covers
/// peeking out, and a lighter front panel with the name and count. Plain
/// boxes only (no images), in its own [RepaintBoundary].
class BnFolderTile extends StatelessWidget {
  const new({
    super.key,
    required this.name,
    required this.count,
    this.color = BnFolderColor.lavender,
    this.icon,
    this.peeks = const [],
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.height = 104,
  });

  final String name;

  /// e.g. "12 items".
  final String count;
  final BnFolderColor color;
  final BnFolderIcon? icon;

  /// The colours of up to two covers that peek out of the folder.
  final List<Color> peeks;
  final VoidCallback? onTap, onLongPress;

  /// Picked in multi-select: an accent ring.
  final bool selected;
  final double height;

  static const _peekAngles = [-7.0, 5.0];
  static const _peekLefts = [26.0, 64.0];

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final peeks = this.peeks.take(2).toList();
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: name,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: BnMotion.fast,
            curve: BnMotion.curve,
            height: height,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              boxShadow: selected
                  ? [
                      BoxShadow(color: colors.desk, spreadRadius: 2),
                      BoxShadow(color: colors.accent, spreadRadius: 4),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: 64,
                  height: 20,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.back,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  top: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.back,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                for (int i = 0; i < peeks.length; i++)
                  Positioned(
                    left: peeks.length == 1 ? 40 : _peekLefts[i],
                    top: 18,
                    width: 36,
                    height: 48,
                    child: Transform.rotate(
                      angle:
                          (peeks.length == 1 ? -4 : _peekAngles[i]) *
                          math.pi /
                          180,
                      // The shadow on even corners of its own: the GPU
                      // draws that directly, but blurred the cover's uneven
                      // corners through a layer of its own, for every peek
                      // on every frame the desk scrolled.
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: peeks[i],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              bottomLeft: Radius.circular(2),
                              topRight: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 56,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    decoration: BoxDecoration(
                      color: color.front,
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      border: const Border(
                        top: BorderSide(color: Color(0xB3FFFFFF)),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 10,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            right: icon == null ? 0 : 30,
                          ),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BnType.body.copyWith(
                              color: BnColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          count,
                          maxLines: 1,
                          style: BnType.caption.copyWith(color: BnColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                if (icon != null)
                  Positioned(
                    right: 12,
                    bottom: 56 - 12 - 28,
                    width: 28,
                    height: 28,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0xA6FFFFFF),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Center(
                        child: BnPathIcon(
                          icon!.path,
                          size: 16,
                          color: color.ink,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The dashed "New folder" tile at the end of the folders row.
class BnNewFolderTile extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 104,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: const _DashedBorderPainter(Color(0xFFCFCEC8)),
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(BnIcons.add, size: 18, color: colors.muted),
              const SizedBox(height: 6),
              Text(
                label,
                style: BnType.caption.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          const Radius.circular(14),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

/// A notebook cover's frame: radius 4 12 12 4 with a darker 10 px spine,
/// the cover shadow, and the label inside at the bottom left.
class BnCoverFrame extends StatelessWidget {
  const new({
    super.key,
    required this.child,
    this.label,
    this.dark = false,
    this.favorite = false,
    this.outlined = false,
    this.selected = false,
    this.selecting = false,
    this.spine = true,
  });

  /// The cover's art or first page.
  final Widget child;

  /// Written on the cover; null for none.
  final String? label;

  /// The art is dark: the label is light.
  final bool dark;
  final bool favorite;

  /// A white cover on the light desk needs a hairline edge.
  final bool outlined;

  /// Picked in multi-select: a ring and a check.
  final bool selected;

  /// Multi-select is on: an empty circle shows where the check goes.
  final bool selecting;

  /// Off for a page preview with no cover.
  final bool spine;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: BnMotion.fast,
        curve: BnMotion.curve,
        decoration: BoxDecoration(
          // Even corners for the soft shadow: the GPU draws those directly,
          // but blurred the cover's uneven corners afresh on every frame.
          // The selection ring keeps the cover's shape.
          borderRadius: selected
              ? BnRadius.cover
              : const BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            if (selected) ...[
              BoxShadow(color: colors.desk, spreadRadius: 2),
              BoxShadow(color: colors.accent, spreadRadius: 4),
            ],
            ...BnShadows.cover,
          ],
        ),
        child: ClipRRect(
          borderRadius: BnRadius.cover,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (spine)
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 10,
                  child: ColoredBox(color: Color(0x14000000)),
                ),
              if (outlined)
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BnRadius.cover,
                    border: Border.all(color: colors.hairline),
                  ),
                ),
              if (label != null)
                Positioned(
                  left: 18,
                  right: 10,
                  bottom: 12,
                  child: Text(
                    label!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BnType.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: dark
                          ? const Color(0xCCFFFFFF)
                          : const Color(0xBF1C1C1E),
                    ),
                  ),
                ),
              if (favorite && !selecting)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: dark ? const Color(0xFFF2C94C) : BnColors.accent,
                  ),
                ),
              if (selecting || selected)
                Positioned(
                  right: 8,
                  top: 8,
                  child: AnimatedContainer(
                    duration: BnMotion.fast,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.accent
                          : Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : colors.faint,
                        width: selected ? 2 : 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            BnIcons.check,
                            size: 13,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A notebook on the desk: the cover (3:4) and under it the title and a
/// meta line.
class BnNotebookTile extends StatelessWidget {
  const new({
    super.key,
    required this.cover,
    required this.title,
    this.meta,
    this.onTap,
    this.onLongPress,
  });

  /// Usually a [BnCoverFrame].
  final Widget cover;
  final String title;

  /// e.g. "Today".
  final String? meta;
  final VoidCallback? onTap, onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 3 / 4, child: cover),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BnType.body.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (meta != null)
            Text(
              meta!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BnType.caption.copyWith(color: colors.muted),
            ),
        ],
      ),
    );
  }
}
