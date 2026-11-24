import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';

/// Shrinks slightly under the finger.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: _pressed ? const Duration(milliseconds: 100) : BnMotion.normal,
        curve: BnMotion.curve,
        child: widget.child,
      ),
    );
  }
}

/// A home page's top, as a sliver: the shared header, then the page's big
/// title with [leading] before it and [actions] at the right, and [below].
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.below,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;

  /// The row of controls under the title.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final margin = HomeChrome.margin(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        margin,
        MediaQuery.paddingOf(context).top + 26,
        margin,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HomeHeader(),
            const SizedBox(height: 30),
            HomeTitle(
              title: title,
              leading: leading,
              trailing: actions.isEmpty
                  ? null
                  : Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
            if (below != null) ...[const SizedBox(height: 16), below!],
          ],
        ),
      ),
    );
  }
}

/// A row of choices with a pill that slides to the chosen one.
class SlidingSegments<T> extends StatelessWidget {
  const SlidingSegments({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.width = 84,
  });

  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final colorScheme = ColorScheme.of(context);
    final keys = segments.keys.toList();
    final index = keys.indexOf(selected);
    return Container(
      height: 32,
      width: width * keys.length + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.segmentTrack,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            left: width * index,
            top: 0,
            bottom: 0,
            width: width,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(7),
                boxShadow: const [
                  BoxShadow(color: Color(0x1F000000), blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
          Row(
            children: [
              for (final key in keys)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(key),
                  child: SizedBox(
                    width: width,
                    child: Center(
                      child: Text(
                        segments[key]!,
                        style: TextTheme.of(context).labelLarge?.copyWith(
                          fontSize: 13,
                          fontWeight: key == selected ? .w600 : .w400,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A flat blue folder, drawn so it stays crisp at any size without an asset.
class FolderShape extends StatelessWidget {
  const FolderShape({super.key, this.badge});

  /// Goes in the top left corner of the front of the folder.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return AspectRatio(
      aspectRatio: 1.3,
      child: CustomPaint(
        painter: _FolderPainter(colors.folder, colors.folderTab),
        child: badge == null
            ? null
            : Column(
                crossAxisAlignment: .start,
                children: [
                  const Spacer(flex: 32),
                  Expanded(
                    flex: 68,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                      ),
                      child: Align(alignment: .topLeft, child: badge),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FolderPainter extends CustomPainter {
  const _FolderPainter(this.front, this.back);

  final Color front, back;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = w * 0.05;
    final backPath = Path()
      ..moveTo(0, h * 0.14 + r)
      ..quadraticBezierTo(0, h * 0.14, r, h * 0.14)
      ..lineTo(w * 0.34, h * 0.14)
      ..lineTo(w * 0.44, h * 0.26)
      ..lineTo(w - r, h * 0.26)
      ..quadraticBezierTo(w, h * 0.26, w, h * 0.26 + r)
      ..lineTo(w, h * 0.5)
      ..lineTo(0, h * 0.5)
      ..close();
    canvas.drawPath(backPath, Paint()..color = back);
    canvas.drawRRect(
      RRect.fromLTRBR(0, h * 0.32, w, h * 0.96, Radius.circular(r)),
      Paint()..color = front,
    );
  }

  @override
  bool shouldRepaint(_FolderPainter old) =>
      front != old.front || back != old.back;
}

/// The dashed "New" page at the start of the documents.
class DashedRect extends StatelessWidget {
  const DashedRect({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedPainter(ColorScheme.of(context).primary),
    child: child,
  );
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    const dash = 5.0, gap = 4.0, r = 6.0;
    void along(Offset from, Offset to) {
      final length = (to - from).distance;
      final unit = (to - from) / length;
      for (var d = 0.0; d < length; d += dash + gap) {
        final end = d + dash < length ? d + dash : length;
        canvas.drawLine(from + unit * d, from + unit * end, paint);
      }
    }

    final w = size.width, h = size.height;
    along(const Offset(r, 0), Offset(w - r, 0));
    along(Offset(w, r), Offset(w, h - r));
    along(Offset(r, h), Offset(w - r, h));
    along(const Offset(0, r), Offset(0, h - r));
    final corner = paint..style = .stroke;
    for (final (rect, start) in [
      (Rect.fromLTWH(0, 0, r * 2, r * 2), 3.14159),
      (Rect.fromLTWH(w - r * 2, 0, r * 2, r * 2), -1.5708),
      (Rect.fromLTWH(w - r * 2, h - r * 2, r * 2, r * 2), 0.0),
      (Rect.fromLTWH(0, h - r * 2, r * 2, r * 2), 1.5708),
    ]) {
      canvas.drawArc(rect, start, 1.5708, false, corner);
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => color != old.color;
}
