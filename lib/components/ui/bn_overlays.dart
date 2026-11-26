import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_controls.dart';
import 'package:badnotes/components/ui/bn_surfaces.dart';
import 'package:badnotes/components/ui/editor_signals.dart';
import 'package:flutter/material.dart';

/// Keeps [child] (a popup, dialog or sheet) above the on-screen keyboard:
/// pads it by the keyboard's height. Android changes that height on every
/// frame while the keyboard slides, so the popup moves up with it. Without
/// this, a popup's text field stayed under the keyboard.
class BnAboveKeyboard extends StatelessWidget {
  const BnAboveKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    // counted once: what's inside sees no keyboard left to avoid
    child: MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: child,
    ),
  );
}

/// Whether [context] is wide enough for tablet layouts (side sheets).
bool bnIsWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 700;

/// Fades in and grows from 0.96, from [alignment]. Nothing bouncy, and
/// nothing at all with "reduce motion".
Widget bnPopIn(
  BuildContext context,
  Animation<double> animation,
  Widget child, {
  Alignment alignment = Alignment.center,
}) {
  if (MediaQuery.disableAnimationsOf(context)) return child;
  final curved = CurvedAnimation(
    parent: animation,
    curve: BnMotion.curve,
    reverseCurve: Curves.easeInCubic,
  );
  return FadeTransition(
    opacity: curved,
    child: ScaleTransition(
      alignment: alignment,
      scale: Tween(begin: BnMotion.popoverStartScale, end: 1.0).animate(curved),
      child: child,
    ),
  );
}

/// A bar at the bottom of the screen that slides down a little and fades
/// out while it isn't [visible], and back while it is: the dock and the
/// selection bar trade places this way. It stays laid out, so nothing
/// around it jumps, but takes no taps or focus while hidden. Instant with
/// "reduce motion".
class BnSlideFade extends StatelessWidget {
  const new({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : BnMotion.normal;
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeFocus(
        excluding: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.6),
          duration: duration,
          curve: BnMotion.curve,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: duration,
            curve: BnMotion.curve,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Opens [builder]'s content as a popover anchored to [anchor]'s widget:
/// under it if there is room, otherwise above, kept on screen. Tapping
/// outside closes it.
Future<T?> showBnPopover<T>({
  required BuildContext anchor,
  required WidgetBuilder builder,
  double width = 320,
  double gap = 8,
  bool preferAbove = false,
}) {
  final box = anchor.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(anchor).overlay!.context.findRenderObject()! as RenderBox;
  final rect = Rect.fromPoints(
    box.localToGlobal(Offset.zero, ancestor: overlay),
    box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
  );
  EditorSignals.covered.value++;
  return showGeneralDialog<T>(
    context: anchor,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(anchor).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: BnMotion.normal,
    pageBuilder: (context, _, _) => BnAboveKeyboard(
      child: CustomSingleChildLayout(
        delegate: _PopoverLayout(rect, gap, preferAbove, width),
        child: BnPopover(
          width: width,
          child: Builder(builder: builder),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final size = MediaQuery.sizeOf(context);
      final above = preferAbove || rect.center.dy > size.height / 2;
      return bnPopIn(
        context,
        animation,
        child,
        alignment: Alignment(
          (rect.center.dx / size.width) * 2 - 1,
          above
              ? (rect.top / size.height) * 2 - 1
              : (rect.bottom / size.height) * 2 - 1,
        ),
      );
    },
  ).whenComplete(() => EditorSignals.covered.value--);
}

class _PopoverLayout extends SingleChildLayoutDelegate {
  new(this.anchor, this.gap, this.preferAbove, this.width);

  final Rect anchor;
  final double gap, width;
  final bool preferAbove;

  static const _margin = 12.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final below = constraints.maxHeight - anchor.bottom - gap - _margin;
    final above = anchor.top - gap - _margin;
    final room = preferAbove || above > below ? above : below;
    return BoxConstraints(
      maxWidth: (constraints.maxWidth - 2 * _margin).clamp(0, width),
      maxHeight: room.clamp(120, constraints.maxHeight - 2 * _margin),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size child) {
    final below = size.height - anchor.bottom - gap - _margin;
    final above = anchor.top - gap - _margin;
    final goAbove =
        (preferAbove && above >= child.height) ||
        (below < child.height && above > below);
    final x = (anchor.center.dx - child.width / 2).clamp(
      _margin,
      size.width - child.width - _margin,
    );
    final y = goAbove ? anchor.top - gap - child.height : anchor.bottom + gap;
    return Offset(x, y.clamp(_margin, size.height - child.height - _margin));
  }

  @override
  bool shouldRelayout(_PopoverLayout old) =>
      old.anchor != anchor || old.gap != gap || old.width != width;
}

/// One button of a [showBnDialog].
class BnDialogAction<T> {
  const new(
    this.label, {
    this.value,
    this.primary = false,
    this.destructive = false,
  });

  final String label;

  /// What the dialog returns when this is pressed.
  final T? value;
  final bool primary, destructive;
}

/// A dialog in the popover style over the scrim: a title, optional
/// [message] or [content], and buttons at the bottom right.
Future<T?> showBnDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  List<BnDialogAction<T>> actions = const [],
  double width = 400,
  bool barrierDismissible = true,
}) {
  final colors = BadNotesColors.of(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: colors.scrim,
    transitionDuration: BnMotion.normal,
    pageBuilder: (context, _, _) => BnAboveKeyboard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BnPopover(
            width: width,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: BnType.title.copyWith(
                    color: BadNotesColors.of(context).text,
                  ),
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      message,
                      style: BnType.body.copyWith(
                        color: BadNotesColors.of(context).muted,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ),
                if (content != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: content,
                  ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final action in actions)
                          BnButton(
                            label: action.label,
                            kind: action.primary
                                ? action.destructive
                                      ? BnButtonKind.destructive
                                      : BnButtonKind.primary
                                : action.destructive
                                ? BnButtonKind.destructive
                                : BnButtonKind.secondary,
                            onPressed: () =>
                                Navigator.of(context).pop(action.value),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) =>
        bnPopIn(context, animation, child),
  );
}

/// A sheet: from the right on a tablet, from the bottom on a phone.
Future<T?> showBnSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double width = 380,
}) {
  final colors = BadNotesColors.of(context);
  if (!bnIsWide(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => BnAboveKeyboard(child: Builder(builder: builder)),
    );
  }
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: colors.scrim,
    transitionDuration: BnMotion.normal,
    pageBuilder: (context, _, _) => BnAboveKeyboard(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SafeArea(
            child: BnPopover(
              width: width,
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: double.infinity,
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: BnMotion.curve,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
