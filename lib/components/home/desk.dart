import 'package:badnotes/components/home/cloud_status.dart';
import 'package:badnotes/components/home/delete_folder_button.dart';
import 'package:badnotes/components/home/delete_note_button.dart';
import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/home/move_note_button.dart';
import 'package:badnotes/components/home/notebook_cover.dart';
import 'package:badnotes/components/home/note_tags.dart';
import 'package:badnotes/components/home/rename_note_button.dart';
import 'package:badnotes/components/home/folder_info.dart';
import 'package:badnotes/components/home/home_menus.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/favorites.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// What can be done with the folders on the desk.
class FolderActions {
  const new({
    required this.onTap,
    required this.doesFolderExist,
    required this.rename,
    required this.isEmpty,
    required this.delete,
  });

  final void Function(String) onTap;
  final bool Function(String) doesFolderExist;
  final Future<void> Function(String oldName, String newName) rename;
  final Future<bool> Function(String) isEmpty;
  final Future<void> Function(String) delete;
}

/// A folder on the desk: its colour, icon, count and the covers peeking out,
/// each filled in as soon as it's known. Long press for its menu.
class DeskFolderTile extends HookWidget {
  const new({
    super.key,
    required this.name,
    required this.path,
    required this.actions,
  });

  final String name;

  /// e.g. `/College`.
  final String path;
  final FolderActions actions;

  @override
  Widget build(BuildContext context) {
    final info = useValueListenable(FolderInfos.of(path));
    final style = useValueListenable(FolderStyles.of(path));
    return Builder(
      builder: (context) => AnimatedSwitcher(
        duration: BnMotion.fast,
        child: BnFolderTile(
          key: ValueKey(style),
          name: name,
          count: info?.itemsLabel ?? '',
          color: style.color,
          icon: style.icon,
          peeks: info?.peeks ?? const [],
          onTap: () => actions.onTap(name),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            showFolderMenu(context, name: name, path: path, actions: actions);
          },
        ),
      ),
    );
  }
}

/// A small folder drawn in [color]'s two tones, e.g. beside a folder's title.
class FolderGlyph extends StatelessWidget {
  const new({super.key, this.color = BnFolderColor.lavender, this.width = 52});

  final BnFolderColor color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final w = width, h = width * 0.78;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: w * 0.42,
            height: h * 0.3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.back,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(w * 0.1),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: h * 0.16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.back,
                borderRadius: BorderRadius.circular(w * 0.12),
              ),
            ),
          ),
          Positioned.fill(
            top: h * 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.front,
                borderRadius: BorderRadius.circular(w * 0.12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The rect of [context]'s widget on screen.
Rect globalRect(BuildContext context) {
  final box = context.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// The menu of a long-pressed folder (design N03): open, rename, its colour,
/// star, delete.
void showFolderMenu(
  BuildContext context, {
  required String name,
  required String path,
  required FolderActions actions,
}) {
  final anchor = globalRect(context);
  showLiftedMenu<void>(
    context,
    anchor: anchor,
    width: 310,
    tilt: -2,
    raise: 12,
    lifted: _LiftedFolder(name: name, path: path),
    menu: (menu) => _FolderMenu(
      name: name,
      path: path,
      actions: actions,
      page: context,
      menu: menu,
    ),
  );
}

class _LiftedFolder extends HookWidget {
  const _LiftedFolder({required this.name, required this.path});

  final String name, path;

  @override
  Widget build(BuildContext context) {
    final info = useValueListenable(FolderInfos.of(path));
    final style = useValueListenable(FolderStyles.of(path));
    return BnFolderTile(
      name: name,
      count: info?.itemsLabel ?? '',
      color: style.color,
      icon: style.icon,
      peeks: info?.peeks ?? const [],
    );
  }
}

class _FolderMenu extends HookWidget {
  const _FolderMenu({
    required this.name,
    required this.path,
    required this.actions,
    required this.page,
    required this.menu,
  });

  final String name, path;
  final FolderActions actions;

  /// The desk, to open dialogs from after the menu closes.
  final BuildContext page;
  final BuildContext menu;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final info = useValueListenable(FolderInfos.of(path));
    final style = useValueListenable(FolderStyles.of(path));
    final favorites = useValueListenable(stows.favoriteNotes);
    final starred = favorites.contains(path);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: style.color.front,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                alignment: Alignment.center,
                child: style.icon == null
                    ? Icon(BnIcons.folder, size: 17, color: style.color.ink)
                    : BnPathIcon(
                        style.icon!.path,
                        size: 17,
                        color: style.color.ink,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BnType.section.copyWith(color: colors.text),
                    ),
                    if (info != null)
                      Text(
                        info.summary,
                        style: BnType.micro.copyWith(color: colors.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        MenuRow(
          icon: BnIcons.folderOpen,
          label: 'Open',
          onTap: closeThen(menu, () => actions.onTap(name)),
        ),
        MenuRow(
          icon: BnIcons.rename,
          label: 'Edit folder',
          onTap: closeThen(
            menu,
            () => showEditFolder(page, name: name, path: path, actions: actions),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Text(
            'Folder color',
            style: BnType.caption.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
          child: Wrap(
            spacing: 2,
            children: [
              for (final color in BnFolderColor.values)
                BnColorDot(
                  color: color.back,
                  size: 30,
                  label: color.name,
                  selected: color == style.color,
                  onTap: () =>
                      FolderStyles.save(path, style.copyWith(color: color)),
                ),
            ],
          ),
        ),
        MenuRow(
          icon: BnIcons.favorites,
          label: starred ? 'Remove from Favorites' : 'Add to Favorites',
          onTap: closeThen(menu, () => Favorites.toggle(path)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: SizedBox(height: 1, child: ColoredBox(color: colors.divider)),
        ),
        MenuRow(
          icon: BnIcons.trash,
          label: t.home.deleteFolder.deleteFolder,
          destructive: true,
          onTap: closeThen(
            menu,
            () => DeleteFolderButton(
              folderName: name,
              deleteFolder: actions.delete,
              isFolderEmpty: actions.isEmpty,
            ).open(page),
          ),
        ),
      ],
    );
  }
}

/// A dashed tile that adds something, e.g. "New notebook" at the end of a
/// folder's notebooks.
class DashedAddTile extends StatelessWidget {
  const new({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: BnNewFolderTile(
            label: label,
            onTap: onTap,
            height: double.infinity,
          ),
        ),
      ],
    );
  }
}

/// The desk with nothing on it yet (design N22).
class EmptyDesk extends StatelessWidget {
  const new({
    super.key,
    required this.onCreate,
    required this.onImport,
    required this.onTemplate,
  });

  final VoidCallback onCreate, onImport;

  /// 0 lecture notes, 1 daily planner, 2 sketchbook.
  final ValueChanged<int> onTemplate;

  static const _templates = [
    ('Lecture notes', 'Cornell layout', BnColors.sky),
    ('Daily planner', 'Week + to-dos', BnColors.blush),
    ('Sketchbook', 'Blank cream paper', BnColors.sand),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 36),
            const _EmptyIllustration(),
            const SizedBox(height: 26),
            Text(
              'Your desk is empty',
              textAlign: TextAlign.center,
              style: BnType.display.copyWith(color: colors.text),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Create your first notebook, or bring in a PDF to start '
                'writing on it.',
                textAlign: TextAlign.center,
                style: BnType.bodyLarge.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                BnButton.primary(
                  label: 'Create notebook',
                  icon: BnIcons.add,
                  onPressed: onCreate,
                ),
                BnButton(
                  label: 'Import PDF',
                  icon: BnIcons.file,
                  onPressed: onImport,
                ),
              ],
            ),
            const SizedBox(height: 46),
            Text(
              'Or start from a template',
              style: BnType.caption.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: [
                for (final (i, (title, caption, color)) in _templates.indexed)
                  SizedBox(
                    width: 240,
                    child: Material(
                      color: colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(BnRadius.card),
                        ),
                        side: BorderSide(color: colors.hairline),
                      ),
                      child: InkWell(
                        onTap: () => onTemplate(i),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(BnRadius.card),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 44,
                                height: 58,
                                child: BnCoverFrame(
                                  child: ColoredBox(color: color),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: BnType.body.copyWith(
                                        color: colors.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      caption,
                                      style: BnType.caption.copyWith(
                                        color: colors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class const _EmptyIllustration() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return SizedBox(
      width: 200,
      height: 160,
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 10,
            width: 108,
            height: 144,
            child: Transform.rotate(
              angle: -0.1,
              child: const BnCoverFrame(
                child: ColoredBox(color: BnColors.lavender),
              ),
            ),
          ),
          Positioned(
            left: 78,
            top: 2,
            width: 108,
            height: 144,
            child: Transform.rotate(
              angle: 0.07,
              child: BnCoverFrame(
                outlined: true,
                child: ColoredBox(
                  color: Colors.white,
                  child: Align(
                    alignment: const Alignment(0.6, 0.55),
                    child: BnPathIcon(
                      BnToolIcons.logo,
                      size: 50,
                      color: colors.accent,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bar that replaces the header while notebooks are selected (N24).
class SelectionTopBar extends StatelessWidget {
  const new({
    super.key,
    required this.count,
    required this.onCancel,
    required this.onSelectAll,
  });

  final int count;
  final VoidCallback onCancel, onSelectAll;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: colors.text,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 40),
            ),
            child: Text(
              'Cancel',
              style: BnType.bodyLarge.copyWith(fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              '$count selected',
              textAlign: TextAlign.center,
              style: BnType.section.copyWith(color: colors.text),
            ),
          ),
          TextButton(
            onPressed: onSelectAll,
            style: TextButton.styleFrom(
              foregroundColor: colors.accent,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 40),
            ),
            child: Text(
              'Select all',
              style: BnType.body.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One action of the [SelectionActionBar].
class SelectionAction {
  const new(this.label, this.icon, this.onTap, {this.destructive = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}

/// The floating bar of what to do with the selected notebooks (N24).
class SelectionActionBar extends StatelessWidget {
  const new({super.key, required this.actions});

  final List<SelectionAction> actions;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    Widget button(SelectionAction a) {
      final fg = a.destructive ? colors.danger : colors.text2;
      return TextButton.icon(
        onPressed: a.onTap,
        style: TextButton.styleFrom(
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(0, 44),
          shape: const StadiumBorder(),
        ),
        icon: Icon(a.icon, size: 16, color: fg),
        label: Text(
          a.label,
          style: BnType.body.copyWith(color: fg, fontWeight: FontWeight.w500),
        ),
      );
    }

    final normal = actions.where((a) => !a.destructive);
    final destructive = actions.where((a) => a.destructive);
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.hairline),
          borderRadius: const BorderRadius.all(Radius.circular(BnRadius.pill)),
          boxShadow: BnShadows.floating,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in normal) button(a),
              if (destructive.isNotEmpty) const BnBarDivider(height: 22),
              for (final a in destructive) button(a),
            ],
          ),
        ),
      ),
    );
  }
}

/// What to do with the notebooks in [selectedFiles] (design N24), shown in
/// place of the dock while any are picked.
class NotebookSelectionBar extends StatelessWidget {
  const new({super.key, required this.selectedFiles});

  final ValueNotifier<List<String>> selectedFiles;

  @override
  Widget build(BuildContext context) {
    final selected = selectedFiles.value;
    void unselect() => selectedFiles.value = [];
    final allStarred = selected.every(Favorites.contains);
    return SelectionActionBar(
      actions: [
        SelectionAction(
          t.home.moveNote.moveNote,
          BnIcons.move,
          () => MoveNoteButton(
            filesToMove: [...selected],
            unselectNotes: unselect,
          ).open(context),
        ),
        SelectionAction(allStarred ? 'Unstar' : 'Star', BnIcons.favorites, () {
          for (final file in selected) {
            if (Favorites.contains(file) == allStarred) Favorites.toggle(file);
          }
        }),
        if (selected.length == 1)
          SelectionAction(
            'Rename',
            BnIcons.rename,
            () => RenameNoteButton(
              existingPath: selected.single,
              unselectNotes: unselect,
            ).open(context),
          ),
        if (selected.length == 1)
          SelectionAction(
            'Tags',
            tagIcon,
            () => showTagsSheet(context, selected.single),
          ),
        SelectionAction('Duplicate', BnIcons.copy, () async {
          await duplicateNotes([...selected]);
          unselect();
        }),
        SelectionAction(
          'Cover',
          BnIcons.palette,
          () => CoverNoteButton(
            selectedFiles: [...selected],
            unselectNotes: unselect,
          ).open(context),
        ),
        SelectionAction(
          'Export',
          BnIcons.export,
          () => showNotesShareCard(context, [...selected]),
        ),
        SelectionAction(
          'Delete',
          BnIcons.trash,
          () => DeleteNoteButton(
            filesToDelete: [...selected],
            unselectNotes: unselect,
          ).open(context),
          destructive: true,
        ),
      ],
    );
  }
}

/// A home tab's frame: the header (or the selection bar's top while
/// picking), the title row, the tab's [slivers], and the selection bar.
class HomePageFrame extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    required this.slivers,
    this.caption,
    this.trailing,
    this.selectedFiles,
    this.selectable = const [],
  });

  final String title;
  final String? caption;
  final Widget? trailing;
  final List<Widget> slivers;

  /// The notebooks picked for the selection bar, if the tab allows it.
  final ValueNotifier<List<String>>? selectedFiles;

  /// What "Select all" picks.
  final List<String> selectable;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final margin = HomeChrome.margin(context);
    final selecting = selectedFiles?.value.isNotEmpty ?? false;
    return Scaffold(
      backgroundColor: colors.desk,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  MediaQuery.paddingOf(context).top + (selecting ? 14 : 26),
                  margin,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: selecting
                      ? SelectionTopBar(
                          count: selectedFiles!.value.length,
                          onCancel: () => selectedFiles!.value = [],
                          onSelectAll: () =>
                              selectedFiles!.value = [...selectable],
                        )
                      : const HomeHeader(),
                ),
              ),
              if (selecting)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SizedBox(
                      height: 1,
                      child: ColoredBox(color: colors.hairline),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(margin, 30, margin, 22),
                sliver: SliverToBoxAdapter(
                  child: HomeTitle(
                    title: title,
                    caption: caption,
                    trailing: trailing,
                  ),
                ),
              ),
              for (final sliver in slivers)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: margin),
                  sliver: sliver,
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: HomeChrome.bottomRoom(context)),
              ),
            ],
          ),
          const SyncErrorBanner(),
          if (selecting)
            Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 18,
              child: Center(
                child: NotebookSelectionBar(selectedFiles: selectedFiles!),
              ),
            ),
        ],
      ),
    );
  }
}

/// Changes a folder's name, colour and icon (design N27), with a live
/// preview. The name goes through the usual rename; the colour and icon
/// are saved in the folder's style file.
Future<void> showEditFolder(
  BuildContext context, {
  required String name,
  required String path,
  required FolderActions actions,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: BadNotesColors.of(context).scrim,
  transitionDuration: BnMotion.normal,
  pageBuilder: (context, _, _) => BnAboveKeyboard(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _EditFolder(name: name, path: path, actions: actions),
      ),
    ),
  ),
  transitionBuilder: (context, animation, _, child) =>
      bnPopIn(context, animation, child),
);

class _EditFolder extends StatefulWidget {
  const _EditFolder({
    required this.name,
    required this.path,
    required this.actions,
  });

  final String name, path;
  final FolderActions actions;

  @override
  State<_EditFolder> createState() => _EditFolderState();
}

class _EditFolderState extends State<_EditFolder> {
  late final _name = TextEditingController(text: widget.name);
  late var _style = FolderStyles.of(widget.path).value;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'A folder needs a name');
    if (name != widget.name && widget.actions.doesFolderExist(name)) {
      return setState(() => _error = 'There is a folder with that name');
    }
    final parent = widget.path.substring(
      0,
      widget.path.length - widget.name.length,
    );
    final path = '$parent$name';
    Navigator.of(context).pop();
    if (name != widget.name) {
      FolderStyles.moved(widget.path, path);
      Favorites.rename(widget.path, path);
      await widget.actions.rename(widget.name, name);
      FolderInfos.clear();
    }
    FolderStyles.save(path, _style);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final info = FolderInfos.of(widget.path).value;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    Widget label(String text, [String? trailing]) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: BnType.caption.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null)
            Text(trailing, style: BnType.caption.copyWith(color: colors.muted)),
        ],
      ),
    );
    final preview = Container(
      color: colors.previewBg,
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            child: BnFolderTile(
              name: _name.text.trim().isEmpty ? widget.name : _name.text.trim(),
              count: info?.itemsLabel ?? '',
              color: _style.color,
              icon: _style.icon,
              peeks: info?.peeks ?? const [],
              height: 150,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Live preview',
            style: BnType.caption.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
    final form = Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit folder',
                  style: BnType.title.copyWith(color: colors.text),
                ),
              ),
              BnIconButton(
                icon: BnIcons.close,
                size: 32,
                iconSize: 18,
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          label('Name'),
          TextField(
            controller: _name,
            autofocus: false,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(errorText: _error),
          ),
          label('Color'),
          Wrap(
            spacing: 2,
            children: [
              for (final color in BnFolderColor.values)
                BnColorDot(
                  color: color.back,
                  size: 30,
                  label: color.name,
                  selected: color == _style.color,
                  onTap: () =>
                      setState(() => _style = _style.copyWith(color: color)),
                ),
            ],
          ),
          label('Icon', _style.icon?.label ?? 'None'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _IconChoice(
                selected: _style.icon == null,
                onTap: () => setState(() => _style = _style.copyWith(noIcon: true)),
                child: Text(
                  'None',
                  style: BnType.micro.copyWith(color: colors.muted),
                ),
              ),
              for (final icon in BnFolderIcon.all)
                _IconChoice(
                  selected: _style.icon == icon,
                  onTap: () =>
                      setState(() => _style = _style.copyWith(icon: icon)),
                  child: BnPathIcon(
                    icon.path,
                    size: 18,
                    color: _style.icon == icon ? colors.accent : colors.text2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              BnButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
              BnButton.primary(label: 'Save', onPressed: _save),
            ],
          ),
        ],
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: wide ? 780 : 460),
      child: BnPopover(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(BnRadius.popover),
          ),
          child: SingleChildScrollView(
            child: wide
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 300, child: preview),
                        Expanded(child: form),
                      ],
                    ),
                  )
                : Column(children: [preview, form]),
          ),
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: BnMotion.fast,
        width: 46,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.accentTint : colors.sunkenSoft,
          borderRadius: const BorderRadius.all(Radius.circular(BnRadius.control)),
        ),
        child: child,
      ),
    );
  }
}
