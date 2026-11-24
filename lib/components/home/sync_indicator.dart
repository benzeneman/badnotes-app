import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/data/prefs.dart';

/// A dark corner over a note or folder that hasn't reached the cloud yet,
/// with an upload arrow that turns while it's going up. Nothing once synced,
/// or when not signed in to a cloud.
class SyncBadge extends HookWidget {
  const SyncBadge({
    super.key,
    required this.path,
    this.folder = false,
    this.size = 36,
  });

  /// The note, without its extension, or the folder.
  final String path;
  final bool folder;
  final double size;

  @override
  Widget build(BuildContext context) {
    useListenable(stows.username);
    useListenable(SyncStatus.failedUploads);
    useStream(syncer.uploader.queueStream);
    final spin = useAnimationController(duration: const Duration(seconds: 3));

    final unsynced = SyncStatus.isUnsynced(path, folder: folder);
    // turns while waiting in the queue, still while waiting to retry
    final failed = SyncStatus.failedUploads.value.any(
      (p) => folder ? p.startsWith('$path/') : p.startsWith('$path.'),
    );
    final moving = unsynced && !failed;
    useEffect(() {
      if (moving) {
        spin.repeat();
      } else {
        spin.stop();
      }
      return null;
    }, [moving]);

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: unsynced
            ? Semantics(
                key: const ValueKey(true),
                label: 'Not synced',
                child: CustomPaint(
                  size: Size.square(size),
                  painter: _CornerPainter(spin),
                ),
              )
            : SizedBox.square(key: const ValueKey(false), dimension: size),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.spin) : super(repaint: spin);

  final Animation<double> spin;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(s, 0)
        ..lineTo(0, s)
        ..close(),
      Paint()..color = const Color(0xE63A3A3F),
    );

    final center = Offset(s * 0.3, s * 0.3);
    final r = s * 0.16;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.1, s * 0.04)
      ..strokeCap = StrokeCap.round;

    // a dashed ring
    const dashes = 8;
    const step = math.pi * 2 / dashes;
    final rect = Rect.fromCircle(center: center, radius: r);
    final turn = spin.value * math.pi * 2;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, turn + i * step, step * 0.55, false, white);
    }

    // an arrow going up
    final top = center.translate(0, -r * 0.55);
    canvas.drawLine(center.translate(0, r * 0.55), top, white);
    canvas.drawLine(top, top.translate(-r * 0.4, r * 0.4), white);
    canvas.drawLine(top, top.translate(r * 0.4, r * 0.4), white);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.spin != spin;
}
