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
/// It is taken again whenever [refresh] notifies: what a popover on top
/// changes (a note's colour, the layout) shows while it's chosen.
class CoveredSnapshot extends StatefulWidget {
  const CoveredSnapshot({super.key, required this.child, this.refresh});

  final Widget child;
  final Listenable? refresh;

  @override
  State<CoveredSnapshot> createState() => _CoveredSnapshotState();
}

class _CoveredSnapshotState extends State<CoveredSnapshot> {
  final _controller = SnapshotController();
  ColorScheme? _scheme;
  Timer? _live;
  var _still = false;

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_controller.clear);
  }

  @override
  void didUpdateWidget(CoveredSnapshot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refresh == widget.refresh) return;
    oldWidget.refresh?.removeListener(_controller.clear);
    widget.refresh?.addListener(_controller.clear);
  }

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
    _still = _live == null && !(ModalRoute.isCurrentOf(context) ?? true);
    if (!_still) {
      _controller.allowSnapshotting = false;
      return;
    }
    // a frame later: the frame a dialog opens on already builds and draws
    // it, taking the picture then as well made that frame stutter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _still) _controller.allowSnapshotting = true;
    });
  }

  @override
  void dispose() {
    _live?.cancel();
    widget.refresh?.removeListener(_controller.clear);
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
