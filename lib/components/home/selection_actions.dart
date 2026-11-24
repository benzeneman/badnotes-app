import 'package:collapsible/collapsible.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/components/home/delete_note_button.dart';
import 'package:badnotes/components/home/export_note_button.dart';
import 'package:badnotes/components/home/move_note_button.dart';
import 'package:badnotes/components/home/notebook_cover.dart';
import 'package:badnotes/components/home/rename_note_button.dart';

/// The buttons for the selected documents, or null with none selected.
List<Widget>? selectionActions(ValueNotifier<List<String>> selectedFiles) {
  final selected = selectedFiles.value;
  if (selected.isEmpty) return null;
  void unselect() => selectedFiles.value = [];
  return [
    Collapsible(
      axis: CollapsibleAxis.vertical,
      collapsed: selected.length != 1,
      child: RenameNoteButton(
        existingPath: selected.first,
        unselectNotes: unselect,
      ),
    ),
    MoveNoteButton(filesToMove: selected, unselectNotes: unselect),
    DeleteNoteButton(filesToDelete: selected, unselectNotes: unselect),
    ExportNoteButton(selectedFiles: selected),
    CoverNoteButton(selectedFiles: selected, unselectNotes: unselect),
  ];
}
