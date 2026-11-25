import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_controls.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:badnotes/components/ui/bn_surfaces.dart';
import 'package:flutter/material.dart';

/// Pieces shared by the home screen's dialogs (new folder, move, delete,
/// rename, the document studio): the big rounded card, its title row, field
/// labels, text inputs, pill buttons and colour dots.

/// The white card a home dialog is drawn on: a hairline, a soft shadow and
/// big round corners.
class BnDialogCard extends StatelessWidget {
  const new({
    super.key,
    required this.child,
    this.width = 480,
    this.radius = 28,
    this.padding = const EdgeInsets.fromLTRB(28, 26, 28, 26),
  });

  final Widget child;
  final double? width;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final screen = MediaQuery.sizeOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width == null ? double.infinity : width!,
            maxHeight: screen.height - 32,
          ),
          child: Material(
            color: colors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(color: colors.hairline),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dialog title with an optional round close button at the right.
class BnDialogTitle extends StatelessWidget {
  const new({super.key, required this.title, this.onClose, this.size = 26});

  final String title;
  final VoidCallback? onClose;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              height: 1.2,
              color: colors.text,
            ),
          ),
        ),
        if (onClose != null) BnRoundClose(onPressed: onClose!),
      ],
    );
  }
}

/// A 40 px round close button on a soft grey.
class BnRoundClose extends StatelessWidget {
  const new({super.key, required this.onPressed, this.tooltip = 'Close'});

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.sunkenSoft,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 40,
            child: Icon(BnIcons.close, size: 18, color: colors.text),
          ),
        ),
      ),
    );
  }
}

/// The small bold muted label over a field or a row of choices.
class BnFieldLabel extends StatelessWidget {
  const new(this.text, {super.key, this.bottom = 6});

  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Text(
        text,
        style: BnType.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: BadNotesColors.of(context).muted,
        ),
      ),
    );
  }
}

/// A text input with a hairline that turns accent with a soft ring when
/// focused. Works in a [Form] through [validator].
class BnTextInput extends StatelessWidget {
  const new({
    super.key,
    required this.controller,
    this.hint,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.height = 48,
    this.radius = 14,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.clearButton = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
  });

  /// More than one line: Enter starts a new line rather than submitting.
  final int minLines, maxLines;
  final TextInputType? keyboardType;

  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final double height, radius, fontSize;
  final FontWeight fontWeight;

  /// A small round × at the right that empties the field.
  final bool clearButton;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
    final vertical = (height - fontSize * 1.25) / 2;
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.done,
      cursorColor: colors.accent,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: colors.text,
        height: 1.25,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.surface,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: colors.faint,
        ),
        errorStyle: BnType.caption.copyWith(color: colors.danger),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: vertical,
        ),
        border: border(colors.hairline, 1),
        enabledBorder: border(colors.hairline, 1),
        focusedBorder: border(colors.accent, 1.5),
        errorBorder: border(colors.danger, 1),
        focusedErrorBorder: border(colors.danger, 1.5),
        suffixIconConstraints: const BoxConstraints(minWidth: 40),
        suffixIcon: clearButton
            ? ListenableBuilder(
                listenable: controller,
                builder: (context, _) => controller.text.isEmpty
                    ? const SizedBox.shrink()
                    : Center(
                        widthFactor: 1,
                        child: GestureDetector(
                          onTap: controller.clear,
                          child: Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: colors.toggleOff,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              BnIcons.close,
                              size: 12,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ),
              )
            : null,
      ),
    );
  }
}

enum BnPillKind { secondary, tint, danger, accent }

/// A round-ended button: secondary (white with a hairline), tint (the soft
/// accent the home dialogs use for their main action), danger (red) or
/// accent (filled).
class BnPillButton extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = BnPillKind.secondary,
    this.icon,
    this.height = 48,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final BnPillKind kind;
  final IconData? icon;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final (bg, fg) = switch (kind) {
      BnPillKind.secondary => (colors.surface, colors.text),
      BnPillKind.tint => (colors.accentTint, colors.text),
      BnPillKind.danger => (colors.danger, Colors.white),
      BnPillKind.accent => (colors.accent, Colors.white),
    };
    final main = kind != BnPillKind.secondary;
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: BnMotion.fast,
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          boxShadow: main && enabled ? BnShadows.floating : null,
        ),
        child: Material(
          color: bg,
          shape: StadiumBorder(
            side: BorderSide(
              color: kind == BnPillKind.danger || kind == BnPillKind.accent
                  ? bg
                  : colors.hairline,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: const StadiumBorder(),
            child: Container(
              height: height,
              padding: EdgeInsets.symmetric(horizontal: main ? 24 : 22),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: main ? 16 : 15,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round colour swatch; the chosen one has a white gap and an accent ring.
class BnSwatchDot extends StatelessWidget {
  const new({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.size = 40,
    this.label,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: colors.hairline),
            boxShadow: selected
                ? [
                    BoxShadow(color: colors.surface, spreadRadius: 2),
                    BoxShadow(color: colors.accent, spreadRadius: 4),
                  ]
                : const [],
          ),
        ),
      ),
    );
  }
}

/// The little round tick a chosen row shows at its end.
class BnCheckBadge extends StatelessWidget {
  const new({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.accentTint,
        shape: BoxShape.circle,
        border: Border.all(color: colors.hairline),
      ),
      child: Icon(BnIcons.check, size: size * 0.55, color: colors.text),
    );
  }
}

/// A small flat folder: a tab and a body in [color].
class BnFolderGlyph extends StatelessWidget {
  const new({
    super.key,
    required this.color,
    this.width = 34,
    this.outlined = true,
  });

  final Color color;
  final double width;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final hairline = BadNotesColors.of(context).hairline;
    final side = outlined ? BorderSide(color: hairline) : BorderSide.none;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: width * 0.42,
            height: width * 0.16,
            decoration: BoxDecoration(
              color: color,
              border: Border(top: side, left: side, right: side),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
            ),
          ),
          Container(
            height: width * 0.65,
            decoration: BoxDecoration(
              color: color,
              border: Border.fromBorderSide(side),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A box drawn with a dashed hairline, e.g. for "add" tiles.
class BnDashedBox extends StatelessWidget {
  const new({
    super.key,
    required this.child,
    this.radius = const BorderRadius.all(Radius.circular(6)),
    this.width,
    this.height,
  });

  final Widget child;
  final BorderRadius radius;
  final double? width, height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(BadNotesColors.of(context).faint, radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  const new(this.color, this.radius);

  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(radius.toRRect(Offset.zero & size).deflate(0.75));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.radius != radius;
}

/// A tick box with its label on a soft card, both tappable.
class BnConfirmRow extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Semantics(
      checked: value,
      button: true,
      enabled: onChanged != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: value ? colors.accentTint : colors.sunkenSoft,
            borderRadius: BorderRadius.circular(BnRadius.card),
          ),
          child: Row(
            spacing: 10,
            children: [
              AnimatedContainer(
                duration: BnMotion.fast,
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: value ? colors.accent : colors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: value ? colors.accent : colors.faint,
                    width: 1.5,
                  ),
                ),
                child: value
                    ? const Icon(BnIcons.check, size: 13, color: Colors.white)
                    : null,
              ),
              Expanded(
                child: Text(
                  label,
                  style: BnType.body.copyWith(color: colors.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small popover-style dialog for renaming (design N25): a title, one
/// field with a clear button, Cancel and Save.
class BnRenameForm extends StatelessWidget {
  const new({
    super.key,
    required this.formKey,
    required this.title,
    required this.label,
    required this.controller,
    required this.validator,
    required this.saveLabel,
    required this.onSave,
    this.cancelLabel,
  });

  final GlobalKey<FormState> formKey;
  final String title, label, saveLabel;
  final String? cancelLabel;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BnPopover(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: BnType.title.copyWith(color: colors.text)),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: BnType.caption.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                BnTextInput(
                  controller: controller,
                  autofocus: true,
                  validator: validator,
                  onSubmitted: (_) => onSave(),
                  height: 44,
                  radius: BnRadius.control,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  clearButton: true,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    BnButton(
                      label:
                          cancelLabel ??
                          MaterialLocalizations.of(context).cancelButtonLabel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    BnButton.primary(label: saveLabel, onPressed: onSave),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
