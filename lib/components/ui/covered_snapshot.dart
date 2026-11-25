import 'dart:async';

import 'package:flutter/material.dart';

/// Shows [child] as a still picture while another route (a dialog, a
/// popover, a sheet) sits on top of this one.
///
/// Impeller keeps no raster cache, so without this the whole screen under a
/// dialog was drawn again on every frame the dialog moved or scrolled: on a
/// 2560x1600 tablet that alone took 20-40 ms a frame. The picture isn't
/// taken again when [child] repaints, so while the theme changes (light and
/// dark from the profile popover) it is drawn live, to change with the rest.
class CoveredSnapshot extends StatefulWidget {
  const CoveredSnapshot({super.key, required this.child});

  final Widget child;

  @override
  State<CoveredSnapshot> createState() => _CoveredSnapshotState();
}

class _CoveredSnapshotState extends State<CoveredSnapshot> {
  final _controller = SnapshotController();
  ColorScheme? _scheme;
  Timer? _live;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // every step of the theme's animation is a new scheme
    final scheme = Theme.of(context).colorScheme;
    final changed = _scheme != null && _scheme != scheme;
    _scheme = scheme;
    if (changed) {
      // drawn live through the theme's animation, then still again
      _live?.cancel();
      _live = Timer(const Duration(milliseconds: 600), () {
        _live = null;
        if (mounted) _update();
      });
    }
    _update();
  }

  void _update() {
    _controller.allowSnapshotting =
        _live == null && !(ModalRoute.isCurrentOf(context) ?? true);
  }

  @override
  void dispose() {
    _live?.cancel();
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
