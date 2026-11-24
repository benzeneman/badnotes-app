import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:badnotes/components/home/delete_note_button.dart';
import 'package:badnotes/components/home/move_note_button.dart';
import 'package:badnotes/components/home/rename_note_button.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/components/canvas/invert_widget.dart';
import 'package:badnotes/components/editor/note_tabs.dart';
import 'package:badnotes/components/home/cover_designs.dart';
import 'package:badnotes/components/home/desk.dart';
import 'package:badnotes/components/home/documents_widgets.dart';
import 'package:badnotes/components/home/folder_info.dart';
import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/home/home_menus.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/components/home/notebook_cover.dart';
import 'package:badnotes/components/home/note_tags.dart';
import 'package:badnotes/components/home/sync_indicator.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/data/editor/thumbnail_marks.dart';
import 'package:badnotes/data/favorites.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/is_this_a_test.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/editor/editor.dart';

class PreviewCard extends StatefulWidget {
  new({
    required this.filePath,
    required this.toggleSelection,
    required this.selected,
    required this.isAnythingSelected,
    this.asRow = false,
    this.rowCaption,
    this.rowTrailing,
  }) : super(key: ValueKey('PreviewCard$filePath'));

  final String filePath;
  final bool selected;
  final bool isAnythingSelected;
  final void Function(String, bool) toggleSelection;

  /// A row in a list, instead of a page in a grid.
  final bool asRow;

  /// In a row: the line under the name, instead of when it was edited.
  final String? rowCaption;

  /// In a row: what's at its end, instead of the star and the menu button.
  final Widget? rowTrailing;

  @override
  State<PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<PreviewCard> {
  final thumbnail = _ThumbnailState();

  /// Notebook cover, or null to show the first page.
  CoverDesign? cover;

  /// Whether the name is on the cover; null for the design's default.
  bool? _showName;

  @override
  void initState() {
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );
    _load();
    super.initState();
  }

  @override
  void didUpdateWidget(PreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) _load();
  }

  /// When the note was last changed, as shown under its name.
  var _editedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Reads what the card shows from disk. Done once and on changes: it was in
  /// build and didChangeDependencies, so every card read its files again on
  /// every rebuild, theme change and keyboard opening.
  void _load() {
    cover = NotebookCovers.read(widget.filePath);
    _showName = NotebookCovers.showsName(widget.filePath);
    _editedAt = FileManager.lastModified(widget.filePath + Editor.extension);

    final imageFile = FileManager.getFile(
      '${widget.filePath}${Editor.extension}.p',
    );
    if (isThisATest) {
      // Avoid FileImages in tests
      thumbnail.image = imageFile.existsSync()
          ? MemoryImage(imageFile.readAsBytesSync())
          : null;
    } else {
      thumbnail.image = FileImage(imageFile);
    }
  }

  StreamSubscription? fileWriteSubscription;
  void fileWriteListener(FileOperation event) {
    // The thumbnail is written a moment after the note: a card made for a
    // new note in between showed no preview until the app was restarted.
    if (event.filePath == '${widget.filePath}${Editor.extension}.p') {
      thumbnail.refresh();
      if (mounted) setState(() {});
      return;
    }
    if (event.filePath != widget.filePath) return;
    if (event.type == .delete) {
      thumbnail.image = null;
    } else if (event.type == .write) {
      if (!mounted) return;
      setState(() {
        cover = NotebookCovers.read(widget.filePath);
        _showName = NotebookCovers.showsName(widget.filePath);
        _editedAt = FileManager.lastModified(widget.filePath + Editor.extension);
      });
      thumbnail.refresh();
    } else {
      throw Exception('Unknown file operation type: ${event.type}');
    }
  }

  void _toggleSelection() =>
      widget.toggleSelection(widget.filePath, !widget.selected);

  Timer? _refreshThumbnailTimer;
  void _refreshThumbnailAfterDelay() {
    _refreshThumbnailTimer?.cancel();
    _refreshThumbnailTimer = Timer(
      const Duration(milliseconds: 500),
      thumbnail.refresh,
    );
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: RoutePaths.editFilePath(widget.filePath)),
        builder: (context) => TabbedEditor(path: widget.filePath),
      ),
    );
    if (mounted) _refreshThumbnailAfterDelay();
  }

  void _onTap() => widget.isAnythingSelected ? _toggleSelection() : _open();

  void _onLongPress() {
    if (widget.isAnythingSelected) return _toggleSelection();
    HapticFeedback.mediumImpact();
    _showMenu();
  }

  /// Everything that can be done with this notebook, right where it is
  /// (design N02): it lifts, and the menu opens beside it.
  void _showMenu() {
    final page = context;
    final coverContext = _coverKey.currentContext ?? context;
    showLiftedMenu<void>(
      context,
      anchor: globalRect(coverContext),
      lifted: _cover(context, lifted: true),
      menu: (menu) => _NotebookMenu(
        path: widget.filePath,
        page: page,
        menu: menu,
        open: _open,
        select: _toggleSelection,
        edited: _edited,
      ),
    );
  }

  String get _name =>
      widget.filePath.substring(widget.filePath.lastIndexOf('/') + 1);

  final _coverKey = GlobalKey();

  /// The cover or the first page, in the notebook frame.
  Widget _cover(BuildContext context, {bool lifted = false}) {
    final theme = Theme.of(context);
    final art = ListenableBuilder(
      listenable: thumbnail,
      builder: (context, _) => cover != null
          ? NotebookCover(
              design: cover!,
              // too small to read in a row
              title: widget.asRow ? '' : _name,
              showTitle: _showName,
            )
          : InvertWidget(
              // looked up again: a save can change it
              invert:
                  theme.brightness == .dark &&
                  stows.editorAutoInvert.value &&
                  !thumbnail.keepsColors,
              child: thumbnail.doesImageExist
                  ? Image(
                      key: ValueKey(thumbnail.updateCount),
                      image: thumbnail.resized!,
                      alignment: .topCenter,
                      fit: .cover,
                      gaplessPlayback: true,
                      // thin lines broke up when scaled down
                      filterQuality: .medium,
                    )
                  : const ColoredBox(color: InnerCanvas.defaultBackgroundColor),
            ),
    );
    return ValueListenableBuilder(
      valueListenable: stows.favoriteNotes,
      builder: (context, favorites, _) => BnCoverFrame(
        key: lifted ? null : _coverKey,
        // a blank first page: its name, as on a plain cover
        label: !widget.asRow && cover == null && !thumbnail.doesImageExist
            ? _name
            : null,
        favorite: !widget.asRow && favorites.contains(widget.filePath),
        // a blank page shows inverted (black) in dark mode
        dark: cover != null
            ? coverColor(cover).computeLuminance() < 0.3
            : !thumbnail.doesImageExist &&
                  theme.brightness == .dark &&
                  stows.editorAutoInvert.value,
        outlined: cover == null,
        selected: !lifted && widget.selected,
        selecting: !lifted && widget.isAnythingSelected,
        child: Stack(
          fit: StackFit.expand,
          children: [
            art,
            if (!lifted)
              Align(
                alignment: .bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SyncBadge(
                    path: widget.filePath,
                    size: widget.asRow ? 14 : 22,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);

    if (widget.asRow) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _onTap,
          onLongPress: _onLongPress,
          onSecondaryTap: _showMenu,
          hoverColor: colors.rowHover,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                const SizedBox(width: 16),
                SizedBox(width: 34, height: 44, child: _cover(context)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _name,
                              maxLines: 1,
                              overflow: .ellipsis,
                              style: BnType.body.copyWith(
                                color: colors.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TagDots(widget.filePath),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.rowCaption ??
                            'Edited ${homeMeta(_edited, withTime: true)}',
                        maxLines: 1,
                        style: BnType.caption.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                ),
                if (widget.rowTrailing != null) ...[
                  widget.rowTrailing!,
                  const SizedBox(width: 16),
                ] else ...[
                  _FavoriteStar(filePath: widget.filePath),
                  BnIconButton(
                    icon: BnIcons.more,
                    tooltip: 'More',
                    onPressed: _showMenu,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTap: _showMenu,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Pressable(
            onTap: _onTap,
            onLongPress: _onLongPress,
            child: AspectRatio(aspectRatio: 3 / 4, child: _cover(context)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Text(
                  _name,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: BnType.body.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TagDots(widget.filePath),
            ],
          ),
          Text(
            homeMeta(_edited),
            maxLines: 1,
            overflow: .ellipsis,
            style: BnType.caption.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }

  /// When the note was last changed.
  DateTime get _edited => _editedAt;

  @override
  void dispose() {
    _refreshThumbnailTimer?.cancel();
    fileWriteSubscription?.cancel();
    thumbnail.dispose();
    super.dispose();
  }
}

class _FavoriteStar extends HookWidget {
  const _FavoriteStar({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    final favorites = useValueListenable(stows.favoriteNotes);
    final favorite = favorites.contains(filePath);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Favorites.toggle(filePath),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AnimatedScale(
          scale: favorite ? 1.08 : 1,
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          child: Icon(
            favorite ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 21,
            color: favorite
                ? BadNotesColors.of(context).accent
                : BadNotesColors.of(context).faint,
          ),
        ),
      ),
    );
  }
}

class _ThumbnailState extends ChangeNotifier {
  /// Thumbnails are small on screen, but were decoded at full size, which is
  /// most of the memory the home screen used.
  static const _decodedWidth = 540;

  var updateCount = 0;
  ImageProvider? _image;
  ResizeImage? _resized;

  void markAsChanged() {
    ++updateCount;
    notifyListeners();
  }

  /// The file changed: forget the old decoded picture.
  void refresh() {
    _resized?.evict();
    _exists = _checkExists();
    _keepsColors = _checkKeepsColors();
    markAsChanged();
  }

  bool _checkKeepsColors() => switch (image) {
    (final FileImage fileImage) => ThumbnailMarks.keepsColors(fileImage.file),
    _ => false,
  };

  ImageProvider? get image => _image;
  ResizeImage? get resized => _resized;
  set image(ImageProvider? image) {
    _image = image;
    _resized = image == null
        ? null
        : ResizeImage(image, width: _decodedWidth, allowUpscaling: false);
    _exists = _checkExists();
    _keepsColors = _checkKeepsColors();
    markAsChanged();
  }

  /// Looked up when the picture changes, not on every build.
  bool get doesImageExist => _exists;
  var _exists = false;

  /// Whether the note's first page keeps its paper color in dark mode.
  bool get keepsColors => _keepsColors;
  var _keepsColors = false;

  bool _checkExists() => switch (image) {
    (final FileImage fileImage) => fileImage.file.existsSync(),
    null => false,
    _ => true,
  };
}

/// The long-press menu of a notebook (design N02).
class _NotebookMenu extends HookWidget {
  const _NotebookMenu({
    required this.path,
    required this.page,
    required this.menu,
    required this.open,
    required this.select,
    required this.edited,
  });

  final String path;

  /// The desk, to open dialogs from after the menu closes.
  final BuildContext page;
  final BuildContext menu;
  final VoidCallback open, select;
  final DateTime edited;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final favorites = useValueListenable(stows.favoriteNotes);
    final favorite = favorites.contains(path);
    final size = useMemoized(() => noteSizeLabel(path), [path]);
    void nothing() {}
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Row(
          spacing: 6,
          children: [
            MenuQuickAction(
              icon: BnIcons.favorites,
              label: favorite ? 'Starred' : 'Star',
              active: favorite,
              onTap: () => Favorites.toggle(path),
            ),
            MenuQuickAction(
              icon: BnIcons.share,
              label: 'Share',
              onTap: closeThen(
                menu,
                () => showNotesShareCard(page, [path]),
              ),
            ),
            MenuQuickAction(
              icon: BnIcons.copy,
              label: 'Copy',
              onTap: closeThen(menu, () => duplicateNotes([path])),
            ),
            MenuQuickAction(
              icon: BnIcons.selectCircle,
              label: 'Select',
              onTap: closeThen(menu, select),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: SizedBox(height: 1, child: ColoredBox(color: colors.divider)),
        ),
        MenuRow(icon: BnIcons.open, label: 'Open', onTap: closeThen(menu, open)),
        MenuRow(
          icon: BnIcons.rename,
          label: t.home.renameNote.renameNote,
          onTap: closeThen(
            menu,
            () => RenameNoteButton(
              existingPath: path,
              unselectNotes: nothing,
            ).open(page),
          ),
        ),
        MenuRow(
          icon: BnIcons.palette,
          label: 'Change cover',
          onTap: closeThen(
            menu,
            () => CoverNoteButton(
              selectedFiles: [path],
              unselectNotes: nothing,
            ).open(page),
          ),
          trailing: Row(
            spacing: 4,
            children: [
              for (final color in const [
                Color(0xFFF08A5D),
                BnColors.lavender,
                BnColors.surface,
              ])
                Container(
                  width: 14,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(2),
                      right: Radius.circular(4),
                    ),
                    border: Border.all(color: BnColors.text.withValues(alpha: 0.5)),
                  ),
                ),
            ],
          ),
        ),
        MenuRow(
          icon: tagIcon,
          label: 'Tags',
          onTap: closeThen(menu, () => showTagsSheet(page, path)),
        ),
        MenuRow(
          icon: BnIcons.move,
          label: t.home.moveNote.moveNote,
          trailing: Icon(BnIcons.forward, size: 16, color: colors.muted),
          onTap: closeThen(
            menu,
            () => MoveNoteButton(
              filesToMove: [path],
              unselectNotes: nothing,
            ).open(page),
          ),
        ),
        MenuRow(
          icon: BnIcons.file,
          label: 'Export as PDF',
          onTap: closeThen(menu, () => exportNotes(page, [path])),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: SizedBox(height: 1, child: ColoredBox(color: colors.divider)),
        ),
        MenuRow(
          icon: BnIcons.trash,
          label: 'Move to Trash',
          destructive: true,
          onTap: closeThen(
            menu,
            () => DeleteNoteButton(
              filesToDelete: [path],
              unselectNotes: nothing,
            ).open(page),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: Text(
            [
              if (size.isNotEmpty) size,
              'edited ${homeMeta(edited, withTime: true).toLowerCase()}',
            ].join(' · '),
            style: BnType.micro.copyWith(color: colors.muted),
          ),
        ),
      ],
    );
  }
}
