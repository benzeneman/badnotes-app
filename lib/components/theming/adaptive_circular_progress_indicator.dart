import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

/// A loading spinner that matches the platform it runs on: Yaru's spinner on
/// Linux, and Flutter's adaptive one (Material or Cupertino) elsewhere.
class AdaptiveCircularProgressIndicator extends CircularProgressIndicator {
  const new({
    super.key,
    super.value,
    super.backgroundColor,
    super.valueColor,
    super.strokeWidth,
    super.semanticsLabel,
    super.semanticsValue,
    super.strokeCap,
    super.strokeAlign,
    super.constraints,
    super.trackGap,
    super.padding,
  }) : super.adaptive();

  /// A spinner as tall as the text around it, drawn in that text's colour
  /// (faded by [alpha]), so it can stand in for a word or an icon.
  static Widget textStyled({double? value, double alpha = 1.0}) =>
      _InlineSpinner(value: value, alpha: alpha);

  @override
  State<AdaptiveCircularProgressIndicator> createState() => _SpinnerState();
}

class _SpinnerState extends State<AdaptiveCircularProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    final w = widget;
    if (Theme.of(context).platform != .linux) {
      return CircularProgressIndicator.adaptive(
        value: w.value,
        backgroundColor: w.backgroundColor,
        valueColor: w.valueColor,
        strokeWidth: w.strokeWidth,
        semanticsLabel: w.semanticsLabel,
        semanticsValue: w.semanticsValue,
        strokeCap: w.strokeCap,
        strokeAlign: w.strokeAlign,
        constraints: w.constraints,
        trackGap: w.trackGap,
        // ignore: deprecated_member_use
        year2023: w.year2023,
        padding: w.padding,
      );
    }
    return YaruCircularProgressIndicator(
      value: w.value,
      strokeWidth: w.strokeWidth,
      color: w.color,
      valueColor: w.valueColor,
      trackColor: w.backgroundColor,
      semanticsLabel: w.semanticsLabel,
      semanticsValue: w.semanticsValue,
    );
  }
}

/// Reads the surrounding [DefaultTextStyle] to size and colour the spinner.
class const _InlineSpinner({
  required final double? value,
  required final double alpha,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final size = style.fontSize ?? 14;
    final colour = style.color ?? ColorScheme.of(context).onSurface;
    return SizedBox.square(
      dimension: size,
      child: AdaptiveCircularProgressIndicator(
        value: value,
        strokeWidth: size / 4,
        valueColor: AlwaysStoppedAnimation(colour.withValues(alpha: alpha)),
      ),
    );
  }
}
