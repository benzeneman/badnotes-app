import 'package:flutter/material.dart';
import 'package:badnotes/components/theming/adaptive_circular_progress_indicator.dart';
import 'package:badnotes/i18n/strings.g.dart';

typedef ExportAction = Future Function(BuildContext);

/// The row of export buttons (BNA, PDF, PNG) in the toolbar. While one is
/// working it shows a spinner and the others wait.
class ExportBar extends StatefulWidget {
  const ExportBar({
    super.key,
    required this.axis,
    required this.toggleExportBar,
    required this.exportAsSba,
    required this.exportAsPdf,
    required this.exportAsPng,
  });

  final Axis axis;
  final VoidCallback toggleExportBar;
  final ExportAction? exportAsSba;
  final ExportAction? exportAsPdf;
  final ExportAction? exportAsPng;

  @override
  State<ExportBar> createState() => _ExportBarState();
}

class _ExportBarState extends State<ExportBar> {
  /// The export in progress, if any.
  ExportAction? _running;

  Future<void> _run(BuildContext context, ExportAction action) async {
    setState(() => _running = action);
    await action(context);
    widget.toggleExportBar();
    // the bar may have gone away with the toggle
    if (mounted) setState(() => _running = null);
  }

  Widget _button(String label, ExportAction? action) {
    return Builder(
      builder: (context) {
        final idle = _running == null;
        return TextButton(
          onPressed: idle && action != null
              ? () => _run(context, action)
              : null,
          child: action != null && identical(_running, action)
              ? AdaptiveCircularProgressIndicator.textStyled(alpha: 0.4)
              : Text(label),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: widget.axis,
          child: Flex(
            direction: widget.axis,
            children: [
              Text(t.editor.toolbar.exportAs),
              const SizedBox.square(dimension: 8),
              _button('SBA', widget.exportAsSba),
              _button('PDF', widget.exportAsPdf),
              _button('PNG', widget.exportAsPng),
            ],
          ),
        ),
      ),
    );
  }
}
