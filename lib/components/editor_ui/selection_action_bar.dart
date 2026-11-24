import 'package:flutter/material.dart';
import 'package:badnotes/components/editor_ui/editor_ui_colors.dart';
import 'package:badnotes/components/editor_ui/tool_chips.dart';
import 'package:badnotes/components/theming/apple_ui.dart';

/// The dark bar under a selection: its color, stroke settings and shape
/// corners, then cut, copy, duplicate, delete and a menu of the rest.
/// Follows the selection as the page moves.
class SelectionActionBar extends StatelessWidget {
  const SelectionActionBar({
    super.key,
    required this.bounds,
    required this.repositioned,
    required this.color,
    required this.onColor,
    required this.onStroke,
    required this.onEditShape,
    required this.editingShape,
    required this.onResize,
    this.extra,
    this.onCollapse,
    this.collapsed = false,
    required this.cut,
    required this.copy,
    required this.duplicate,
    required this.delete,
    required this.front,
    required this.back,
    required this.moreEntries,
    this.screenshot,
  });

  /// A picture of what's picked, to save, share or pin (design 12).
  final VoidCallback? screenshot;

  /// Where the selection is, in this widget's coordinates.
  final Rect? Function() bounds;
  final Listenable repositioned;

  final Color? color;
  final ValueChanged<Rect> onColor;

  /// Null without shapes selected.
  final ValueChanged<Rect>? onStroke;

  /// Null unless one drawn shape is selected.
  final VoidCallback? onEditShape;
  final bool editingShape;
  /// Null where resizing is done by the handles only.
  final ValueChanged<Rect>? onResize;

  /// More buttons at the start, such as a text box's format.
  final Widget? extra;

  /// Folds a sticky note down, or opens it, if given.
  final VoidCallback? onCollapse;
  final bool collapsed;
  final VoidCallback cut, copy, duplicate, delete, front, back;

  /// The ⋯ menu under its Cut / Front / Back row.
  final List<AppleMenuEntry> Function() moreEntries;

  Widget _button(
    String tooltip,
    IconData icon,
    void Function(Rect anchor) onTap, {
    bool selected = false,
    Color? color,
  }) => Builder(
    builder: (context) => ToolChip(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      selected: selected,
      onTap: () => onTap(rectOf(context)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bar = Material(
      color: EditorUi.of(context).bar,
      elevation: 4,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(EditorUi.barRadius),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null)
                Builder(
                  builder: (context) => ColorDot(
                    color: color!,
                    selected: true,
                    showChevron: true,
                    size: 20,
                    onTap: () => onColor(rectOf(context)),
                  ),
                ),
              if (onStroke != null)
                _button('Stroke settings', Icons.line_weight, onStroke!),
              if (onEditShape != null)
                _button(
                  'Edit shape',
                  Icons.polyline_outlined,
                  (_) => onEditShape!(),
                  selected: editingShape,
                ),
              ?extra,
              if (onCollapse != null)
                _button(
                  collapsed ? 'Expand' : 'Collapse',
                  collapsed ? Icons.open_in_full : Icons.close_fullscreen,
                  (_) => onCollapse!(),
                ),
              if (onResize != null) _button('Resize', Icons.crop_free, onResize!),
              const BarDivider(axis: Axis.horizontal),
              _button('Cut', Icons.content_cut, (_) => cut()),
              _button('Copy', Icons.copy_outlined, (_) => copy()),
              _button('Duplicate', Icons.library_add_outlined, (_) => duplicate()),
              if (screenshot != null)
                _button(
                  'Screenshot',
                  Icons.center_focus_strong_outlined,
                  (_) => screenshot!(),
                ),
              _button(
                'Delete',
                Icons.delete_outline,
                (_) => delete(),
                color: EditorUi.destructive,
              ),
              _button(
                'More',
                Icons.more_horiz,
                (anchor) => showSelectionMenu(
                  context,
                  anchor: anchor,
                  top: [
                    (icon: Icons.content_cut, label: 'Cut', onTap: cut),
                    (icon: Icons.flip_to_front, label: 'Front', onTap: front),
                    (icon: Icons.flip_to_back, label: 'Back', onTap: back),
                  ],
                  entries: moreEntries(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return ListenableBuilder(
      listenable: repositioned,
      builder: (context, child) {
        final rect = bounds();
        if (rect == null) return const SizedBox.shrink();
        return CustomSingleChildLayout(
          delegate: _UnderRect(rect),
          child: child,
        );
      },
      child: bar,
    );
  }
}

/// Puts the bar under [rect], clear of the rotate handle, or above it when
/// there's no room below. Always on screen.
class _UnderRect extends SingleChildLayoutDelegate {
  _UnderRect(this.rect);

  final Rect rect;

  /// Room for the rotate handle under the selection's box (45 px down, 8 px
  /// round), and 12 px more.
  static const _gap = 66.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest).deflate(const EdgeInsets.all(8));

  @override
  Offset getPositionForChild(Size size, Size child) {
    var top = rect.bottom + _gap;
    if (top + child.height > size.height - 8) {
      top = rect.top - child.height - 12;
      // no room above either: at the bottom, over the selection
      if (top < 64) top = size.height - child.height - 24;
    }
    final left = rect.center.dx - child.width / 2;
    return Offset(
      left.clamp(8.0, size.width - child.width - 8).toDouble(),
      top.clamp(8.0, size.height - child.height - 8).toDouble(),
    );
  }

  @override
  bool shouldRelayout(_UnderRect oldDelegate) => oldDelegate.rect != rect;
}

/// The ⋯ menu of a selection: a row of [top] actions, then [entries], in a
/// dark grey card next to [anchor].
Future<void> showSelectionMenu(
  BuildContext context, {
  required Rect anchor,
  required List<({IconData icon, String label, VoidCallback onTap})> top,
  required List<AppleMenuEntry> entries,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Close',
  barrierColor: Colors.transparent,
  transitionDuration: const Duration(milliseconds: 120),
  pageBuilder: (context, animation, _) {
    void run(VoidCallback? onTap) {
      Navigator.pop(context);
      onTap?.call();
    }

    final menu = Material(
      color: EditorUi.of(context).menu,
      elevation: 6,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(EditorUi.cardRadius + 4),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (final action in top)
                  Expanded(
                    child: InkWell(
                      onTap: () => run(action.onTap),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Icon(action.icon, color: EditorUi.of(context).icon, size: 20),
                            const SizedBox(height: 3),
                            Text(
                              action.label,
                              style: TextStyle(
                                color: EditorUi.of(context).text,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Divider(height: 1, color: EditorUi.of(context).cardDivider),
            for (final entry in entries)
              if (entry is AppleMenuItem)
                InkWell(
                  onTap: entry.enabled ? () => run(entry.onTap) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          entry.icon,
                          size: 19,
                          color: !entry.enabled
                              ? EditorUi.of(context).iconDim
                              : entry.destructive
                              ? EditorUi.destructive
                              : EditorUi.of(context).icon,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.label,
                          style: TextStyle(
                            fontSize: 15,
                            color: !entry.enabled
                                ? EditorUi.of(context).iconDim
                                : entry.destructive
                                ? EditorUi.destructive
                                : EditorUi.of(context).text,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Divider(height: 1, color: EditorUi.of(context).cardDivider),
          ],
        ),
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: CustomSingleChildLayout(
        delegate: _NextTo(anchor),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
          child: menu,
        ),
      ),
    );
  },
);

/// Under [anchor], or above it without room, always on screen.
class _NextTo extends SingleChildLayoutDelegate {
  _NextTo(this.anchor);

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest).deflate(const EdgeInsets.all(8));

  @override
  Offset getPositionForChild(Size size, Size child) {
    var top = anchor.bottom + 6;
    if (top + child.height > size.height - 8) top = anchor.top - child.height - 6;
    return Offset(
      (anchor.center.dx - child.width / 2)
          .clamp(8.0, size.width - child.width - 8)
          .toDouble(),
      top.clamp(8.0, size.height - child.height - 8).toDouble(),
    );
  }

  @override
  bool shouldRelayout(_NextTo oldDelegate) => oldDelegate.anchor != anchor;
}
