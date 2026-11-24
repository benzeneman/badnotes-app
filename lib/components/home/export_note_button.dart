import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// Opens Share & Export (PDF, PNG or BadNotes) for [selectedFiles].
class ExportNoteButton extends StatelessWidget {
  const new({super.key, required this.selectedFiles});

  final List<String> selectedFiles;

  @override
  Widget build(BuildContext context) => BnIconButton(
    tooltip: t.home.tooltips.exportNote,
    icon: BnIcons.export,
    onPressed: () =>
        showNotesShareCard(context, selectedFiles, anchor: rectOf(context)),
  );
}
