import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// An iOS-style alert box used on every platform.
///
/// The [content] is wrapped in a see-through [Material] so Material widgets
/// placed inside it (text fields, ink effects) still have the ancestor they
/// need.
class const AdaptiveAlertDialog({
  super.key,
  required final Widget title,
  required final Widget content,
  required final List<CupertinoDialogAction> actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final body = Material(color: Colors.transparent, child: content);
    return CupertinoAlertDialog(title: title, content: body, actions: actions);
  }
}
