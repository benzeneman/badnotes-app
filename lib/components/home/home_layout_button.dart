import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:stow_codecs/stow_codecs.dart';

/// The view button: a "Sort & view" popover (design N11) with the page's
/// own choices, grid or list, and the cover size.
class ViewOptionsButton extends HookWidget {
  const ViewOptionsButton({
    super.key,
    this.leading = const [],
    this.trailing = const [],
    this.sort = const [],
  });

  /// Above the rest, e.g. "Select All".
  final List<AppleMenuEntry> leading;

  /// Under a "Sort by" title.
  final List<AppleMenuEntry> sort;

  /// After [sort], above the view choices.
  final List<AppleMenuEntry> trailing;

  @override
  Widget build(BuildContext context) {
    final layout = useValueListenable(stows.homeLayout);
    final isList = layout == .list;
    return BnIconButton(
      tooltip: 'View options',
      icon: isList ? BnIcons.list : BnIcons.grid,
      onPressed: () => showViewOptions(
        context,
        anchor: rectOf(context),
        leading: leading,
        sort: sort,
        trailing: trailing,
      ),
    );
  }
}

/// Opens the "Sort & view" popover by [anchor].
Future<void> showViewOptions(
  BuildContext context, {
  required Rect anchor,
  List<AppleMenuEntry> leading = const [],
  List<AppleMenuEntry> sort = const [],
  List<AppleMenuEntry> trailing = const [],
}) => showAnchoredPanel<void>(
  context,
  anchor: anchor,
  width: 270,
  builder: (context) =>
      _ViewOptions(leading: leading, sort: sort, trailing: trailing),
);

class _ViewOptions extends StatelessWidget {
  const new({
    required this.leading,
    required this.sort,
    required this.trailing,
  });

  final List<AppleMenuEntry> leading, sort, trailing;

  Widget _entries(BuildContext context, List<AppleMenuEntry> entries) {
    final colors = BadNotesColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in entries)
          switch (entry) {
            AppleMenuDivider() => Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              color: colors.divider,
            ),
            final AppleMenuItem item => _OptionRow(item: item),
          },
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final heading = BnType.caption.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.muted,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading.isNotEmpty) ...[
            _entries(context, leading),
            Container(
              height: 1.5,
              margin: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              color: colors.divider,
            ),
          ],
          if (sort.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Text('Sort by', style: heading),
            ),
            _entries(context, sort),
          ],
          if (trailing.isNotEmpty) _entries(context, trailing),
          if (sort.isNotEmpty || trailing.isNotEmpty)
            Container(
              height: 1.5,
              margin: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              color: colors.divider,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Text('View', style: heading),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ValueListenableBuilder(
              valueListenable: stows.homeLayout,
              builder: (context, layout, _) => _PillSegmented<bool>(
                values: const [false, true],
                labels: const ['Grid', 'List'],
                selected: layout == .list,
                onChanged: (list) =>
                    stows.homeLayout.value = list ? .list : .simpleGrid,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
            child: Text('Cover size', style: heading),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: ValueListenableBuilder(
              valueListenable: stows.homeCoverSize,
              builder: (context, size, _) => _PillSegmented<int>(
                values: const [0, 1, 2],
                labels: const ['S', 'M', 'L'],
                selected: size,
                onChanged: (size) => stows.homeCoverSize.value = size,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A 42 px row of the popover; chosen rows end with a tick.
class _OptionRow extends StatelessWidget {
  const new({required this.item});

  final AppleMenuItem item;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final color = !item.enabled
        ? colors.disabled
        : item.destructive
        ? colors.danger
        : colors.text;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        hoverColor: colors.rowHover,
        onTap: !item.enabled
            ? null
            : item.children != null
            ? () => showAppleMenu(
                context,
                anchor: rectOf(context),
                entries: item.children!,
              )
            : () {
                Navigator.pop(context);
                item.onTap?.call();
              },
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (item.icon != null && !item.checked)
                Icon(item.icon, size: 16, color: colors.text2),
              if (item.checked) ...[
                if (item.icon != null)
                  Icon(item.icon, size: 14, color: colors.muted),
                const BnCheckBadge(),
              ],
              if (item.children != null)
                Icon(BnIcons.forward, size: 15, color: colors.faint),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round track with the chosen value as a white pill.
class _PillSegmented<T> extends StatelessWidget {
  const new({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: colors.sunkenSoft,
        shape: const StadiumBorder(),
      ),
      child: Row(
        spacing: 4,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: values[i] == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(values[i]),
                  child: AnimatedContainer(
                    duration: BnMotion.fast,
                    curve: BnMotion.curve,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: values[i] == selected
                          ? colors.surface
                          : colors.sunkenSoft,
                      shape: const StadiumBorder(),
                      shadows: values[i] == selected
                          ? BnShadows.card
                          : const [],
                    ),
                    child: Text(
                      labels[i],
                      style: BnType.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: values[i] == selected
                            ? colors.accentStrong
                            : colors.text2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Older installs have one of the first two saved, which are both the grid now.
enum HomeLayout {
  masonryGrid,
  simpleGrid,
  list;

  static const codec = EnumCodec(values);
}
