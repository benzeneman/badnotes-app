import 'package:badnotes/components/home/desk.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/home/preview_card.dart';
import 'package:badnotes/components/home/home_layout_button.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/extensions/change_notifier_extensions.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:flutter/material.dart';

/// Notebooks as a grid of covers or a list of rows (in a card), lazily.
class DocumentGrid extends StatelessWidget {
  const DocumentGrid({
    super.key,
    this.forceGrid = false,
    required this.files,
    required this.selectedFiles,
    this.onNew,
    this.newLabel = 'New notebook',
  });

  /// Ignores the grid or list setting.
  final bool forceGrid;
  final List<String> files;
  final ValueNotifier<List<String>> selectedFiles;

  /// Adds a dashed "New notebook" tile at the end of the grid.
  final VoidCallback? onNew;
  final String newLabel;

  void _toggle(String file, bool selected) {
    if (selected) {
      selectedFiles.value.add(file);
    } else {
      selectedFiles.value.remove(file);
    }
    selectedFiles.notifyListenersPlease();
  }

  Widget _fileAt(int index, {required bool asRow}) {
    final file = files[index];
    // No fade in: it replayed on every card that scrolled back into view, each
    // frame of it drawing the card offscreen.
    return RepaintBoundary(
      child: PreviewCard(
        filePath: file,
        toggleSelection: _toggle,
        selected: selectedFiles.value.contains(file),
        isAnythingSelected: selectedFiles.value.isNotEmpty,
        asRow: asRow,
      ),
    );
  }

  /// The narrowest a cover may be for [coverSize] (0 small, 1 medium,
  /// 2 large), on a wide screen or a narrower one.
  static double minCoverWidth(int coverSize, {required bool wide}) {
    final medium = wide ? 130.0 : 160.0;
    return switch (coverSize) {
      0 => medium * 0.78,
      2 => medium * 1.3,
      _ => medium,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isList = !forceGrid && stows.homeLayout.value == HomeLayout.list;
    final count = files.length;

    if (isList) {
      final colors = BadNotesColors.of(context);
      if (count == 0) return const SliverToBoxAdapter();
      return DecoratedSliver(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.hairline),
          borderRadius: const BorderRadius.all(Radius.circular(BnRadius.card)),
          boxShadow: BnShadows.card,
        ),
        sliver: SliverList.separated(
          itemCount: count,
          separatorBuilder: (context, _) =>
              SizedBox(height: 1, child: ColoredBox(color: colors.divider)),
          itemBuilder: (context, i) => _fileAt(i, asRow: true),
        ),
      );
    }

    final withNew = onNew != null;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final wide = HomeChrome.isWide(context);
        const gap = 18.0;
        final minWidth = minCoverWidth(stows.homeCoverSize.value, wide: wide);
        final columns = ((width + gap) / (minWidth + gap)).floor().clamp(2, 10);
        final tileWidth = (width - gap * (columns - 1)) / columns;
        // the cover (3:4), then the title and date under it
        final tileHeight = tileWidth * 4 / 3 + 10 + 40;
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: 22,
            mainAxisExtent: tileHeight,
          ),
          itemCount: count + (withNew ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == count) {
              return DashedAddTile(label: newLabel, onTap: onNew!);
            }
            return _fileAt(i, asRow: false);
          },
        );
      },
    );
  }
}
