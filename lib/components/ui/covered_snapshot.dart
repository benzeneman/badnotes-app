import 'package:flutter/widgets.dart';

/// Shows [child] as a still picture while another route (a dialog, a
/// popover, a sheet) sits on top of this one.
///
/// Impeller keeps no raster cache, so without this the whole screen under a
/// dialog was drawn again on every frame the dialog moved or scrolled: on a
/// 2560x1600 tablet that alone took 20-40 ms a frame. A change under the
/// dialog still shows, as the picture is taken again when [child] repaints.
class CoveredSnapshot extends StatefulWidget {
  const CoveredSnapshot({super.key, required this.child});

  final Widget child;

  @override
  State<CoveredSnapshot> createState() => _CoveredSnapshotState();
}

class _CoveredSnapshotState extends State<CoveredSnapshot> {
  final _controller = SnapshotController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.allowSnapshotting = !(ModalRoute.isCurrentOf(context) ?? true);
  }

  @override
  void dispose() {
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
