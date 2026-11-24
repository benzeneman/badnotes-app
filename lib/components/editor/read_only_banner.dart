import 'package:collapsible/collapsible.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:sbn/read_only_reason.dart';

/// Tells why a note can't be changed. Nothing shows when [reason] is null (or
/// a placeholder); with an [action] there's a button at the end of the row.
///
/// Once shown, the banner folds away rather than vanishing, and keeps its
/// last words while it does.
class ReadOnlyBanner extends StatefulWidget {
  const ReadOnlyBanner(this.reason, {super.key, this.action});

  final ReadOnlyReason? reason;
  final VoidCallback? action;

  @override
  State<ReadOnlyBanner> createState() => _ReadOnlyBannerState();
}

class _ReadOnlyBannerState extends State<ReadOnlyBanner> {
  /// Whether the banner was ever wanted: after that it stays in the tree so
  /// it can fold away.
  var _everShown = false;
  var _words = '';

  /// What to say for [reason], or null when there's nothing to say.
  String? _say(ReadOnlyReason? reason) => switch (reason) {
    null || ReadOnlyReason.placeholder => null,
    ReadOnlyReason.versionTooNew => t.editor.versionTooNew.title,
    ReadOnlyReason.watchingServer => t.editor.readOnlyBanner.watchingServer,
    ReadOnlyReason.corrupted => t.editor.readOnlyBanner.corrupted,
  };

  @override
  Widget build(BuildContext context) {
    final say = _say(widget.reason);
    if (say != null) {
      _everShown = true;
      _words = say;
    }
    if (!_everShown) return const SizedBox.shrink();

    final action = widget.action;
    return Collapsible(
      collapsed: say == null,
      axis: CollapsibleAxis.vertical,
      child: SafeArea(
        child: ListTile(
          onTap: action,
          leading: const Icon(Icons.edit_off),
          title: Text(t.editor.readOnlyBanner.title),
          subtitle: Text(_words),
          trailing: action == null
              ? null
              : IconButton(
                  onPressed: action,
                  icon: const Icon(Icons.open_in_new),
                ),
        ),
      ),
    );
  }
}
