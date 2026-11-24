import 'dart:async';

import 'package:flutter/widgets.dart';

/// Shows [child] as a still picture while another route (a dialog, a
/// popover, a sheet) sits on top of this one.
///
/// Impeller keeps no raster cache, so without this the whole screen under a
/// dialog was drawn again on every frame the dialog moved or scrolled: on a
/// 2560x1600 tablet that alone took 20-40 ms a frame. The picture is taken
/// once, when the route above opens; changes under it show once it is gone.
class CoveredSnapshot extends StatefulWidget {
  const CoveredSnapshot({super.key, required this.child});

  final Widget child;

  /// How long the picture stays after the route above starts to close: its
  /// closing animation (200 ms) runs over the picture, not the live screen.
  static const _release = Duration(milliseconds: 260);

  @override
  State<CoveredSnapshot> createState() => _CoveredSnapshotState();
}

class _CoveredSnapshotState extends State<CoveredSnapshot> {
  final _controller = SnapshotController();
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final covered = !(ModalRoute.isCurrentOf(context) ?? true);
    if (covered) {
      _timer?.cancel();
      _timer = null;
      _controller.allowSnapshotting = true;
    } else if (_controller.allowSnapshotting && _timer == null) {
      // This route is current again from the first frame of the closing
      // animation above it; letting go of the picture right then drew the
      // whole live screen under every frame of the close.
      _timer = Timer(CoveredSnapshot._release, () {
        _timer = null;
        // covered again meanwhile: the timer was cancelled
        _controller.allowSnapshotting = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SnapshotWidget(
    controller: _controller,
    mode: SnapshotMode.permissive,
    child: widget.child,
  );
}
