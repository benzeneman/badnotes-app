import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The colors of the ink bench and the new page panel, from the app's theme.
class InkPalette {
  InkPalette._(this.desk, this.raised, this.accent, this.onAccent, this.text, this.muted);

  factory InkPalette.of(BuildContext context) {
    final scheme = ColorScheme.of(context);
    return InkPalette._(
      scheme.surface,
      scheme.surfaceContainerHighest,
      scheme.primary,
      scheme.onPrimary,
      scheme.onSurface,
      scheme.onSurfaceVariant,
    );
  }

  /// The strip of paper in the ink bench, as a page looks in this theme.
  static Color paperOf(BuildContext context) =>
      Theme.brightnessOf(context) == Brightness.dark
      ? const Color(0xFF23262F)
      : const Color(0xFFFCFBF6);

  final Color desk, raised, accent, onAccent, text, muted;
}

/// A setting on a slider: its name, its value, then the slider.
class InkSlider extends StatelessWidget {
  const InkSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.valueText,
  });

  final String label;

  /// From 0 to 1.
  final double value;
  final ValueChanged<double> onChanged;

  /// What it shows on the right, instead of a percentage.
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    final ink = InkPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: ink.text, fontSize: 14),
              ),
            ),
            Text(
              valueText ?? '${(value * 100).round()}%',
              style: TextStyle(color: ink.muted, fontSize: 14),
            ),
          ],
        ),
        CupertinoSlider(
          value: value.clamp(0.0, 1.0),
          activeColor: ink.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// A rounded label to tap, lit up when [on].
class InkPill extends StatelessWidget {
  const InkPill({
    super.key,
    required this.label,
    required this.onTap,
    this.on = false,
    this.icon,
    this.tooltip,
  });

  final String label;
  final VoidCallback onTap;
  final bool on;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final ink = InkPalette.of(context);
    final color = on ? ink.onAccent : ink.text;
    final pill = Material(
      color: on ? ink.accent : ink.raised,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              if (icon != null) Icon(icon, size: 16, color: color),
              Text(label, style: TextStyle(color: color, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip, child: pill);
  }
}
