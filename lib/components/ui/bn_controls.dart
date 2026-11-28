import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:flutter/material.dart';

/// One choice of a [BnSegmented].
class BnSegment<T> {
  const new(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A sunken track with the chosen segment as a white chip, which slides to
/// the next one chosen. Segments are equally wide: with [expand] they share
/// the width, otherwise each is as wide as the longest label.
class BnSegmented<T> extends StatelessWidget {
  const new({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expand = true,
    this.height = 30,
  });

  final List<BnSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Segments share the width; otherwise each is as wide as the longest
  /// label.
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : BnMotion.normal;
    final chosen = segments.indexWhere((s) => s.value == selected);
    final n = segments.length;

    Widget segment(BnSegment<T> s) {
      final on = s.value == selected;
      return Semantics(
        selected: on,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(s.value),
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: expand ? 8 : 14),
            alignment: Alignment.center,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: on ? colors.text : colors.text2),
              duration: duration,
              curve: BnMotion.curve,
              builder: (context, color, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (s.icon != null) ...[
                    Icon(s.icon, size: 15, color: color),
                    if (s.label.isNotEmpty) const SizedBox(width: 6),
                  ],
                  if (s.label.isNotEmpty)
                    Flexible(
                      child: Text(
                        s.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // one weight for both, so a label doesn't change
                        // width when chosen
                        style: BnType.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final track = Stack(
      fit: StackFit.passthrough,
      children: [
        if (chosen >= 0)
          Positioned.fill(
            child: AnimatedAlign(
              duration: duration,
              curve: BnMotion.curve,
              alignment: Alignment(n == 1 ? 0 : -1 + 2 * chosen / (n - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(BnRadius.chip),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Row(children: [for (final s in segments) Expanded(child: segment(s))]),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.sunken,
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.control)),
      ),
      // equal shares of the longest label's width
      child: expand ? track : IntrinsicWidth(child: track),
    );
  }
}

/// A 40×24 switch: accent when on, a white knob with a shadow.
class BnToggle extends StatelessWidget {
  const new({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          width: 40,
          height: 24,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: (value ? colors.accent : colors.toggleOff).withValues(
              alpha: enabled ? 1 : 0.5,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(99)),
          ),
          child: AnimatedAlign(
            duration: BnMotion.fast,
            curve: BnMotion.curve,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: SizedBox.square(dimension: 20),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row with a label (and description) on the left and a [BnToggle].
class BnToggleRow extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.icon,
  });

  final String label;
  final String? description;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 42),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: colors.text2),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: BnType.body.copyWith(color: colors.text)),
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: Text(
                        description!,
                        style: BnType.caption.copyWith(
                          color: colors.muted,
                          height: 1.45,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            BnToggle(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// A slider with its label and value in a row above: a 4 px track, accent
/// fill, a 20 px white knob.
class BnSlider extends StatelessWidget {
  const new({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.valueLabel,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeEnd,
  });

  final double value, min, max;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? label;

  /// At the right of the label, e.g. "42%".
  final String? valueLabel;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final labelStyle = BnType.caption.copyWith(
      color: colors.muted,
      fontWeight: FontWeight.w500,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || valueLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(child: Text(label ?? '', style: labelStyle)),
                if (valueLabel != null) Text(valueLabel!, style: labelStyle),
              ],
            ),
          ),
        SizedBox(
          height: 22,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: colors.accent,
              inactiveTrackColor: colors.hairline,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10,
                elevation: 2,
                pressedElevation: 3,
              ),
              overlayShape: SliderComponentShape.noOverlay,
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ),
      ],
    );
  }
}

/// A 30 px chip with a hairline; chosen = tinted.
class BnChip extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// In place of [icon], e.g. a colour dot.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final fg = selected ? colors.accentStrong : colors.text2;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? colors.accentTint : colors.surface,
            border: Border.all(
              color: selected ? colors.accentTintBorder : colors.hairline,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(BnRadius.chip),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 6)],
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: BnType.caption.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum BnButtonKind { primary, secondary, destructive, quiet }

/// A 40 px button: [BnButtonKind.primary] is accent with white text,
/// secondary white with a hairline, destructive red text.
class BnButton extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = BnButtonKind.secondary,
    this.icon,
    this.expand = false,
    this.height = 40,
  });

  const new primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.height = 40,
  }) : kind = BnButtonKind.primary;

  const new destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.height = 40,
  }) : kind = BnButtonKind.destructive;

  final String label;
  final VoidCallback? onPressed;
  final BnButtonKind kind;
  final IconData? icon;

  /// As wide as it can be.
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final enabled = onPressed != null;
    final (bg, fg, border) = switch (kind) {
      .primary => (colors.accent, Colors.white, colors.accent),
      .secondary => (colors.surface, colors.text, colors.hairline),
      .destructive => (colors.surface, colors.danger, colors.hairline),
      .quiet => (Colors.transparent, colors.text2, Colors.transparent),
    };
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BnType.body.copyWith(
              color: fg,
              fontWeight: kind == BnButtonKind.primary
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(BnRadius.control),
          ),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.all(
            Radius.circular(BnRadius.control),
          ),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
