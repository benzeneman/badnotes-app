import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:sbn/font_fallbacks.dart';

/// Everything the app logged since it started, for the logs page.
final logsHistory = _LogsHistory();

class _LogsHistory extends ChangeNotifier {
  final List<LogRecord> _records = [];
  List<LogRecord>? _paused;

  /// What the page shows: the records as they were when it was paused, or
  /// all of them. Do not change this list.
  List<LogRecord> get history => _paused ?? _records;

  bool get isFrozen => _paused != null;

  /// Stops new records from appearing on the page (they're still kept).
  void freeze() {
    _paused = List.of(_records, growable: false);
    notifyListeners();
  }

  void unfreeze() {
    _paused = null;
    notifyListeners();
  }

  void add(LogRecord record) {
    _records.add(record);
    notifyListeners();
  }

  void clear() {
    _records.clear();
    _paused = null;
    notifyListeners();
  }

  /// All shown records as plain text, for copying.
  String asText() {
    final out = StringBuffer();
    for (final r in history) {
      out
        ..writeln('${r.level.name} at ${r.time}')
        ..writeln(r.message);
      if (r.error != null) out.writeln(r.error);
      if (r.stackTrace != null) out.writeln(r.stackTrace);
      out.writeln();
    }
    return out.toString();
  }
}

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.logs.logs),
        scrolledUnderElevation: 1,
        actions: [
          ListenableBuilder(
            listenable: logsHistory,
            builder: (context, _) => Row(
              children: [
                IconButton(
                  tooltip: logsHistory.isFrozen ? 'Resume' : 'Pause',
                  icon: Icon(
                    logsHistory.isFrozen ? Icons.play_arrow : Icons.pause,
                  ),
                  onPressed: logsHistory.isFrozen
                      ? logsHistory.unfreeze
                      : logsHistory.freeze,
                ),
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy),
                  onPressed: logsHistory.history.isEmpty
                      ? null
                      : () => Clipboard.setData(
                          ClipboardData(text: logsHistory.asText()),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: logsHistory,
        builder: (context, _) {
          final records = logsHistory.history;
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 72,
                      color: scheme.outline,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      t.logs.noLogs,
                      style: TextStyle(color: scheme.onSurface, fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.logs.useTheApp,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }
          // newest first
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, i) =>
                _LogRow(record: records[records.length - 1 - i]),
          );
        },
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.record});

  final LogRecord record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bad = record.level >= Level.SEVERE;
    final warn = record.level == Level.WARNING;
    final (back, front) = bad
        ? (scheme.error, scheme.onError)
        : warn
        ? (scheme.tertiary, scheme.onTertiary)
        : (scheme.surfaceContainer, scheme.onSurface);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: back,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(record.level.name, style: TextStyle(color: front)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(record.message),
          ),
          if (record.stackTrace != null)
            Container(
              width: double.infinity,
              color: const Color(0xCC000000),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  '${record.stackTrace}',
                  style: const TextStyle(
                    fontFamily: 'FiraMono',
                    fontFamilyFallback: badnotesMonoFontFallbacks,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
