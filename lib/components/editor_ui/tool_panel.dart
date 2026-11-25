import 'dart:math' as math;

import 'package:badnotes/components/ui/bn_tool_panels.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A page of a [ToolPanel]: its title and what's in it.
class PanelPage {
  const new({
    required this.title,
    required this.builder,
    this.width = 300,
    this.leading,
    this.trailing,
    this.caption,
  });

  /// Buttons at the left and right of the title, such as the camera.
  final WidgetBuilder? leading, trailing;

  final String title;

  /// A short line under the title, in muted 12.
  final String? caption;

  /// Builds the page; [StateSetter] rebuilds it after a change.
  final StatefulWidgetBuilder builder;
  final double width;
}

/// Opens [page] as a popover: next to [anchor] on a tablet, or from the
/// bottom on a phone. Pages can open further pages with [ToolPanel.push].
Future<void> showToolPanel(
  BuildContext context, {
  required Rect anchor,
  required PanelPage page,
  bool freezeEditor = false,
  bool keepFocus = false,
}) {
  HapticFeedback.selectionClick();
  final screen = MediaQuery.sizeOf(context);
  final colors = BadNotesColors.of(context);
  // [freezeEditor]: the editor shows a still picture of its pages while this
  // is open, so a scroll here doesn't draw every live page under it again
  // each frame. Off for panels whose changes show live on the page.
  if (freezeEditor) EditorSignals.covered.value++;
  void done() {
    if (freezeEditor) EditorSignals.covered.value--;
  }

  if (screen.width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      barrierColor: colors.scrim,
      isScrollControlled: true,
      showDragHandle: true,
      // [keepFocus]: typing stays where it was, so the keyboard doesn't go
      // down and come back up (the whole editor laid out twice) around it
      requestFocus: keepFocus ? false : null,
      constraints: BoxConstraints(maxHeight: screen.height * 0.75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BnRadius.popover),
        ),
      ),
      builder: (context) => BnAboveKeyboard(
        child: RepaintBoundary(child: ToolPanel(first: page, sheet: true)),
      ),
    ).whenComplete(done);
  }
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: BnMotion.normal,
    requestFocus: keepFocus ? false : null,
    pageBuilder: (context, animation, _) =>
        _Placed(anchor: anchor, animation: animation, page: page),
  ).whenComplete(done);
}

/// Places the panel above or under its button (or beside it, at the side
/// of the screen), on screen.
class _Placed extends StatelessWidget {
  const new({
    required this.anchor,
    required this.animation,
    required this.page,
  });

  final Rect anchor;
  final Animation<double> animation;
  final PanelPage page;

  /// Between the panel and its button.
  static const _gap = 14.0;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // the keyboard (the colour panel's hex code) counts as screen it can't use
    final insets = MediaQuery.paddingOf(context);
    final padding = insets.copyWith(
      bottom: math.max(insets.bottom, MediaQuery.viewInsetsOf(context).bottom),
    );
    const margin = 8.0;
    final width = page.width.clamp(0.0, screen.width - 2 * margin);
    // a button at a side of the screen opens its panel beside it
    final side =
        anchor.height > anchor.width * 1.6 ||
        (anchor.left < 80 || anchor.right > screen.width - 80) &&
            anchor.top > 120;
    double left, top;
    final minTop = padding.top + margin;
    final maxBottom = screen.height - padding.bottom - margin;
    // a button low on the screen opens its panel above it
    final roomBelow = maxBottom - anchor.bottom - _gap;
    final roomAbove = anchor.top - _gap - minTop;
    var above = !side && roomBelow < 320 && roomAbove > roomBelow;
    if (side) {
      left = anchor.center.dx < screen.width / 2
          ? anchor.right + _gap
          : anchor.left - width - _gap;
      top = (anchor.top - 40).clamp(minTop, math.max(minTop, maxBottom - 320));
    } else {
      left = (anchor.center.dx - width / 2).clamp(
        margin,
        screen.width - width - margin,
      );
      top = anchor.bottom + _gap;
      // no room either side of a big anchor (or the keyboard is up): over
      // it from the top of the screen, all of it on screen, not cut short
      if (math.max(roomAbove, roomBelow) < 240) {
        above = false;
        top = minTop;
      }
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final curved = CurvedAnimation(
      parent: animation,
      curve: BnMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    // grows out of its button
    final origin = Alignment(
      ((anchor.center.dx - left) / width * 2 - 1).clamp(-1.0, 1.0),
      above ? 1 : -1,
    );
    final panel = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: math.max(0, above ? roomAbove : maxBottom - top),
      ),
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BadNotesColors.of(context).surface,
            border: Border.all(color: BadNotesColors.of(context).hairline),
            borderRadius: const BorderRadius.all(
              Radius.circular(BnRadius.popover),
            ),
            boxShadow: BnShadows.panel,
          ),
          child: ClipRRect(
            // hard edged: a smoothed clip round scrolling content was another
            // layer for the GPU on every frame of a scroll
            clipBehavior: Clip.hardEdge,
            borderRadius: const BorderRadius.all(
              Radius.circular(BnRadius.popover - 1),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ToolPanel(first: page),
            ),
          ),
        ),
      ),
    );
    return Stack(
      children: [
        Positioned(
          left: left,
          top: above ? null : top,
          bottom: above ? screen.height - anchor.top + _gap : null,
          width: width,
          child: reduceMotion
              ? panel
              : FadeTransition(
                  opacity: curved,
                  child: ScaleTransition(
                    scale: Tween(
                      begin: BnMotion.popoverStartScale,
                      end: 1.0,
                    ).animate(curved),
                    alignment: origin,
                    child: panel,
                  ),
                ),
        ),
      ],
    );
  }
}

/// The inside of a panel: the title (with a back chevron on later pages)
/// and the page. Later pages slide in from the right.
class ToolPanel extends StatefulWidget {
  const new({super.key, required this.first, this.sheet = false});

  final PanelPage first;
  final bool sheet;

  /// Opens [page] in the panel around [context], with a way back.
  static void push(BuildContext context, PanelPage page) =>
      context.findAncestorStateOfType<_ToolPanelState>()?._push(page);

  /// Goes back to the page before, as its back button does.
  static void pop(BuildContext context) =>
      context.findAncestorStateOfType<_ToolPanelState>()?._pop();

  @override
  State<ToolPanel> createState() => _ToolPanelState();
}

class _ToolPanelState extends State<ToolPanel> {
  late final _pages = [widget.first];

  /// Whether the last change went deeper (slides in from the right) or back.
  var _forward = true;

  void _push(PanelPage page) => setState(() {
    _forward = true;
    _pages.add(page);
  });

  void _pop() => setState(() {
    _forward = false;
    _pages.removeLast();
  });

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final page = _pages.last;
    final nested = _pages.length > 1;
    final body = KeyedSubtree(
      key: ValueKey(_pages.length),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, widget.sheet ? 0 : 16, 16, 0),
            child: Row(
              children: [
                if (nested) ...[
                  BnSubButton(
                    tooltip: 'Back',
                    icon: BnIcons.back,
                    iconSize: 18,
                    onTap: _pop,
                  ),
                  const SizedBox(width: 6),
                ] else if (page.leading case final leading?) ...[
                  Builder(builder: leading),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        page.title,
                        style: BnType.section.copyWith(
                          color: colors.text,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (page.caption case final caption?)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            caption,
                            style: BnType.caption.copyWith(color: colors.muted),
                          ),
                        ),
                    ],
                  ),
                ),
                if (page.trailing case final trailing?)
                  Builder(builder: trailing),
              ],
            ),
          ),
          if (nested)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: BnDivider(),
            )
          else
            const SizedBox(height: 12),
          Flexible(
            // its own layer: scrolling a long panel (the ⋯ menu) moves it
            // without painting the rest of the panel again
            child: RepaintBoundary(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: RepaintBoundary(
                  child: StatefulBuilder(builder: page.builder),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return DefaultTextStyle.merge(
      style: BnType.body.copyWith(color: colors.text),
      child: IconTheme(
        data: IconThemeData(color: colors.text2),
        child: AnimatedSize(
          duration: reduceMotion ? Duration.zero : BnMotion.normal,
          curve: BnMotion.curve,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : BnMotion.normal,
            switchInCurve: BnMotion.curve,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [
                for (final p in previous) Positioned.fill(child: p),
                ?current,
              ],
            ),
            transitionBuilder: (child, animation) {
              final incoming = child.key == ValueKey(_pages.length);
              // the page coming in slides from the side it's going to
              final from = (incoming == _forward) ? 0.12 : -0.12;
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: Offset(from, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: body,
          ),
        ),
      ),
    );
  }
}

/// A muted label above a group of rows.
class PanelSection extends StatelessWidget {
  const new(this.title, {super.key, this.trailing, this.top = 14});

  final String title;
  final Widget? trailing;

  /// Space above it.
  final double top;

  @override
  Widget build(BuildContext context) =>
      BnPanelLabel(title, trailing: trailing, top: top);
}

/// A group of rows. Rows sit straight on the panel; groups are set apart
/// by space or a [BnDivider].
class PanelGroup extends StatelessWidget {
  const new({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}

/// A setting that's on or off, with an optional note under it.
class PanelSwitchRow extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon,
    this.description,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  /// A muted line under the row.
  final String? description;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      BnToggleRow(label: title, value: value, onChanged: onChanged, icon: icon),
      if (description case final text?) BnPanelCaption(text),
    ],
  );
}

/// A row that opens another page, or does something.
class PanelNavRow extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    required this.onTap,
    this.destructive = false,
    this.chevron = true,
    this.icon,
    this.trailing,
    this.checked = false,
    this.enabled = true,
    this.titleStyle,
  });

  final String title;
  final VoidCallback onTap;
  final bool destructive, chevron;
  final IconData? icon;

  /// Muted text on the right, such as the current value.
  final String? trailing;

  /// Shows a tick on the right.
  final bool checked;
  final bool enabled;

  /// In place of the 13/500 label, e.g. a font in its own family.
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final fg = !enabled
        ? colors.disabled
        : destructive
        ? colors.danger
        : colors.text;
    final iconColor = !enabled
        ? colors.disabled
        : destructive
        ? colors.danger
        : colors.text2;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? onTap : null,
        hoverColor: colors.rowHover,
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.control)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: icon == null ? 0 : 2),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: (titleStyle ?? BnType.body).copyWith(color: fg),
                  ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 6),
                    child: Text(
                      trailing!,
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                  ),
                if (checked)
                  Icon(BnIcons.check, size: 16, color: colors.accent)
                else if (chevron && !destructive)
                  Icon(BnIcons.forward, size: 16, color: colors.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A slider with its name and value in a row above.
class PanelSliderRow extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.valueText,
    this.min = 0,
    this.max = 1,
    this.divisions,
  });

  final String title;
  final double value, min, max;

  /// Stops it at this many even steps (5: 0, 20 … 100%), none between.
  final int? divisions;
  final ValueChanged<double> onChanged;

  /// Defaults to [value] as a percentage.
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    final shown =
        valueText ?? '${((value - min) / (max - min) * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: BnSlider(
        label: title,
        valueLabel: shown,
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

/// Cards to choose one of, each an icon over a label.
class PanelChoiceCards<T> extends StatelessWidget {
  const new({
    super.key,
    required this.choices,
    required this.value,
    required this.onChanged,
    this.gap = 4,
  });

  final List<({T value, Widget icon, String label})> choices;
  final T value;
  final ValueChanged<T> onChanged;
  final double gap;

  @override
  Widget build(BuildContext context) => BnTypeCards<T>(
    choices: choices,
    value: value,
    onChanged: onChanged,
    gap: gap,
  );
}

/// Tabs in a sunken track, as Presets / Custom / History.
class PanelSegmented extends StatelessWidget {
  const new({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => BnSegmented<int>(
    segments: [for (final (i, label) in labels.indexed) BnSegment(i, label)],
    selected: index,
    onChanged: onChanged,
  );
}

/// A number with − and + beside it, such as "4 pt Border".
class PanelStepperRow extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 40,
    this.step = 1,
    this.unit = 'pt',
  });

  final String title, unit;
  final double value, min, max, step;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    Widget button(IconData icon, String tooltip, double next) => BnSubButton(
      icon: icon,
      tooltip: tooltip,
      iconSize: 16,
      onTap: next < min || next > max ? null : () => onChanged(next),
    );
    final shown = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 42),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$shown $unit $title'.replaceAll('  ', ' '),
              style: BnType.body.copyWith(color: colors.text),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.sunkenSoft,
              borderRadius: const BorderRadius.all(
                Radius.circular(BnRadius.control),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  button(BnIcons.minus, 'Less', value - step),
                  SizedBox(
                    height: 16,
                    width: 1,
                    child: ColoredBox(color: colors.hairline),
                  ),
                  button(BnIcons.add, 'More', value + step),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
