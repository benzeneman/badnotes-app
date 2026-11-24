import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';

/// A pill at the top of the screen while something is exported, saying what
/// is being made and how far along it is ("Making PDF… 3 / 40 pages"), so a
/// big note doesn't look stuck.
abstract final class ExportProgress {
  static final _status = ValueNotifier<({String text, double? done})?>(null);
  static OverlayEntry? _entry;

  /// Shows the pill with [text] while [work] runs. Nested runs share the
  /// outer one's pill.
  static Future<T> run<T>(
    BuildContext context,
    String text,
    Future<T> Function() work,
  ) async {
    if (_entry != null) return work();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return work();
    _status.value = (text: text, done: null);
    final entry = _entry = OverlayEntry(builder: (_) => const _Pill());
    overlay.insert(entry);
    try {
      return await work();
    } finally {
      entry.remove();
      _entry = null;
      _status.value = null;
    }
  }

  /// [done] of [total] pages are ready.
  static void pages(String text, int done, int total) {
    if (_entry == null || total <= 0) return;
    _status.value = (
      text: '$text $done / $total ${total == 1 ? 'page' : 'pages'}',
      done: done / total,
    );
  }

  /// A step with no count, e.g. "Saving…".
  static void step(String text) {
    if (_entry == null) return;
    _status.value = (text: text, done: null);
  }
}

class _Pill extends StatelessWidget {
  const _Pill();

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 12,
      child: Center(
        child: ValueListenableBuilder(
          valueListenable: ExportProgress._status,
          builder: (context, status, _) => status == null
              ? const SizedBox.shrink()
              : Material(
                  type: MaterialType.transparency,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.hairline),
                      boxShadow: BnShadows.card,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          status.text,
                          style: BnType.caption.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: status.done,
                            minHeight: 4,
                            color: colors.accent,
                            backgroundColor: colors.hairline,
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
