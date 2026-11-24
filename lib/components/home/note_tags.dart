import 'dart:async';
import 'dart:convert';

import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/bn_settings.dart' show BnSettingsRow;
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The icon for tags, wherever they're offered.
const tagIcon = LucideIcons.tag;

/// Which tags there are (name → colour) and which notes have them (note
/// path → tag names), design N6. Every change gives a new book.
@immutable
class TagBook {
  const new({this.colors = const {}, this.notes = const {}});

  /// Tag name → ARGB colour, in the order the tags were made.
  final Map<String, int> colors;

  /// Note path (without extension) → its tags.
  final Map<String, List<String>> notes;

  /// The colours new tags get, in turn.
  static const palette = <int>[
    0xFF5B4FD6, // violet
    0xFFF08A24, // orange
    0xFF1E8A4C, // green
    0xFFE0483E, // red
    0xFF2D8CDB, // blue
    0xFFD6A21E, // yellow
    0xFFC64FA8, // pink
    0xFF14A3A3, // teal
  ];

  List<String> get tags => colors.keys.toList();

  List<String> tagsOf(String note) => notes[note] ?? const [];

  bool has(String note, String tag) => tagsOf(note).contains(tag);

  /// How many notes have [tag].
  int count(String tag) => notes.values.where((t) => t.contains(tag)).length;

  /// The first palette colour no tag has yet, else round again.
  int get _nextColor {
    final used = colors.values.toSet();
    return palette.firstWhere(
      (c) => !used.contains(c),
      orElse: () => palette[colors.length % palette.length],
    );
  }

  /// Gives [note] the tag [name] (an existing tag if only the case differs).
  TagBook add(String note, String name) {
    name = name.trim();
    if (name.isEmpty) return this;
    final tag = colors.keys.firstWhere(
      (t) => t.toLowerCase() == name.toLowerCase(),
      orElse: () => name,
    );
    if (has(note, tag)) return this;
    return TagBook(
      colors: colors.containsKey(tag) ? colors : {...colors, tag: _nextColor},
      notes: {
        ...notes,
        note: [...tagsOf(note), tag],
      },
    );
  }

  /// Takes [tag] off [note]; the tag itself stays.
  TagBook remove(String note, String tag) {
    if (!has(note, tag)) return this;
    final left = [...tagsOf(note)]..remove(tag);
    return TagBook(
      colors: colors,
      notes: {...notes}..[note] = left..removeWhere((_, t) => t.isEmpty),
    );
  }

  /// Renames [from] to [to] everywhere; into an existing tag, they merge.
  TagBook renameTag(String from, String to) {
    to = to.trim();
    if (to.isEmpty || to == from || !colors.containsKey(from)) return this;
    final merge = colors.containsKey(to);
    return TagBook(
      colors: {
        for (final MapEntry(:key, :value) in colors.entries)
          if (key != from)
            key: value
          else if (!merge)
            to: value,
      },
      notes: {
        for (final MapEntry(:key, :value) in notes.entries)
          key: {for (final t in value) t == from ? to : t}.toList(),
      },
    );
  }

  TagBook recolor(String tag, int color) => !colors.containsKey(tag)
      ? this
      : TagBook(colors: {...colors, tag: color}, notes: notes);

  /// Deletes [tag] and takes it off every note.
  TagBook deleteTag(String tag) => TagBook(
    colors: {...colors}..remove(tag),
    notes: {
      for (final MapEntry(:key, :value) in notes.entries)
        if (value.any((t) => t != tag))
          key: [for (final t in value) if (t != tag) t],
    },
  );

  /// A note was renamed or moved: its tags go with it.
  TagBook moveNote(String from, String to) {
    final moving = notes[from];
    if (moving == null || from == to) return this;
    return TagBook(
      colors: colors,
      notes: {...notes}
        ..remove(from)
        ..[to] = {...tagsOf(to), ...moving}.toList(),
    );
  }

  /// A note was deleted for good.
  TagBook forget(String note) => !notes.containsKey(note)
      ? this
      : TagBook(colors: colors, notes: {...notes}..remove(note));

  /// Other tags for [note], the most used first.
  List<String> suggestions(String note, {int max = 6}) => ([
    for (final t in colors.keys)
      if (!has(note, t)) t,
  ]..sort((a, b) => count(b).compareTo(count(a)))).take(max).toList();

  Map<String, dynamic> toJson() => {'colors': colors, 'notes': notes};

  static TagBook fromJson(Object? json) {
    if (json is! Map) return const TagBook();
    final colors = json['colors'], notes = json['notes'];
    return TagBook(
      colors: {
        if (colors is Map)
          for (final MapEntry(:key, :value) in colors.entries)
            if (key is String && value is int) key: value,
      },
      notes: {
        if (notes is Map)
          for (final MapEntry(:key, :value) in notes.entries)
            if (key is String && value is List && value.isNotEmpty)
              key: [for (final t in value) if (t is String) t],
      },
    );
  }
}

/// The tags, kept in `/.tags.json` beside the notes (like a folder's
/// `.style.json`), so they sync with them.
// ponytail: last write wins between devices; merge per note if two devices
// tagging at once turns out to matter.
abstract final class NoteTags {
  static const _file = '/.tags.json';

  /// Empty until [load]ed; the home screen loads it.
  static final book = ValueNotifier(const TagBook());

  static Future<void>? _loading;
  static StreamSubscription<FileOperation>? _changes;
  static Future<void> _saving = Future.value();

  static Future<void> load() => _loading ??= _read();

  static Future<void> _read() async {
    // another device changed the tags
    _changes ??= FileManager.fileWriteStream.stream.listen((event) {
      if (event.filePath == _file) unawaited(_read());
    });
    if (!FileManager.doesFileExist(_file)) return;
    final bytes = await FileManager.readFile(_file, retries: 0);
    if (bytes == null) return;
    try {
      book.value = TagBook.fromJson(jsonDecode(utf8.decode(bytes)));
    } on FormatException {
      // a broken file: keep what we have
    }
  }

  /// Changes the tags with [change] and saves them, if anything changed.
  static Future<void> update(TagBook Function(TagBook) change) async {
    await load();
    final before = book.value;
    final after = change(before);
    if (identical(after, before)) return;
    book.value = after;
    final bytes = utf8.encode(jsonEncode(after.toJson()));
    // one write at a time, quietly: not a "recent note", and no echo back
    // through the file listener
    _saving = _saving.then((_) async {
      await FileManager.writeFile(_file, bytes, quietly: true, awaitWrite: true);
      await syncer.uploader.enqueueRel(_file);
    });
    await _saving;
  }

  static String _withoutExtension(String path) {
    for (final ext in [Editor.extension, Editor.extensionOldJson]) {
      if (path.endsWith(ext)) return path.substring(0, path.length - ext.length);
    }
    return path;
  }

  /// For [FileManager]'s rename hook: paths may have the note's extension.
  static void rename(String from, String to) => unawaited(
    update(
      (b) => b.moveNote(_withoutExtension(from), _withoutExtension(to)),
    ),
  );

  /// For [FileManager]'s delete hook.
  static void forget(String path) =>
      unawaited(update((b) => b.forget(_withoutExtension(path))));
}

/// A small round dot in a tag's colour.
class TagDot extends StatelessWidget {
  const new(this.color, {super.key, this.size = 8});

  final int color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: Color(color), shape: BoxShape.circle),
  );
}

/// The dots of [notePath]'s tags, for next to its name on a card.
class TagDots extends StatelessWidget {
  const new(this.notePath, {super.key});

  final String notePath;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: NoteTags.book,
    builder: (context, book, _) {
      final tags = book.tagsOf(notePath);
      if (tags.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            for (final t in tags.take(4))
              Tooltip(message: t, child: TagDot(book.colors[t] ?? 0xFF8E8E93)),
          ],
        ),
      );
    },
  );
}

/// The row of tag chips above the notes: "All" and each tag. Hidden while
/// there are no tags.
class TagFilterRow extends StatelessWidget {
  const new({super.key, required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: NoteTags.book,
    builder: (context, book, _) {
      if (book.colors.isEmpty) return const SizedBox.shrink();
      final selected = book.colors.containsKey(this.selected)
          ? this.selected
          : null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              BnChip(
                label: 'All',
                selected: selected == null,
                onTap: () => onSelected(null),
              ),
              for (final MapEntry(key: tag, value: color)
                  in book.colors.entries)
                BnChip(
                  label: tag,
                  leading: TagDot(color),
                  selected: selected == tag,
                  onTap: () => onSelected(selected == tag ? null : tag),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// A coloured tag chip; with [onRemove], a ✕ to take it off.
class _TagChip extends StatelessWidget {
  const new({required this.tag, required this.color, this.onRemove});

  final String tag;
  final int color;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    return Container(
      height: 30,
      padding: EdgeInsets.only(left: 10, right: onRemove == null ? 12 : 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.45)),
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.chip)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TagDot(color),
          const SizedBox(width: 6),
          Text(
            tag,
            style: BnType.caption.copyWith(
              color: BadNotesColors.of(context).text,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRemove != null)
            Tooltip(
              message: 'Remove $tag',
              child: InkResponse(
                onTap: onRemove,
                radius: 14,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(BnIcons.close, size: 13, color: c),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The tags of [notePath]: take one off, add one, or pick a suggested one.
Future<void> showTagsSheet(BuildContext context, String notePath) {
  unawaited(NoteTags.load());
  return showAppleDialog<void>(
    context: context,
    builder: (context) => _TagsCard(notePath: notePath),
  );
}

class _TagsCard extends StatefulWidget {
  const new({required this.notePath});

  final String notePath;

  @override
  State<_TagsCard> createState() => _TagsCardState();
}

class _TagsCardState extends State<_TagsCard> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _add(String name) {
    unawaited(NoteTags.update((b) => b.add(widget.notePath, name)));
    _field.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final note = widget.notePath;
    return BnDialogCard(
      width: 420,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: ValueListenableBuilder(
        valueListenable: NoteTags.book,
        builder: (context, book, _) {
          final tags = book.tagsOf(note);
          final suggested = book.suggestions(note);
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BnDialogTitle(
                  title: 'Tags · ${noteName(note)}',
                  size: 20,
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 16),
                if (tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in tags)
                        _TagChip(
                          tag: t,
                          color: book.colors[t] ?? 0xFF8E8E93,
                          onRemove: () => unawaited(
                            NoteTags.update((b) => b.remove(note, t)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                BnTextInput(
                  controller: _field,
                  hint: 'Add a tag…',
                  autofocus: tags.isEmpty,
                  fontWeight: FontWeight.w500,
                  onSubmitted: _add,
                ),
                if (suggested.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Suggested:',
                        style: BnType.caption.copyWith(color: colors.muted),
                      ),
                      for (final t in suggested)
                        BnChip(
                          label: t,
                          leading: TagDot(book.colors[t]!),
                          onTap: () => _add(t),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Settings › Tags: rename, recolour or delete a tag everywhere.
Future<void> showManageTagsSheet(BuildContext context) {
  unawaited(NoteTags.load());
  return showBnSheet<void>(
    context: context,
    builder: (context) => const _ManageTags(),
  );
}

class _ManageTags extends StatelessWidget {
  const new();

  Future<void> _rename(BuildContext context, String tag) async {
    final field = TextEditingController(text: tag);
    final ok = await showBnDialog<bool>(
      context: context,
      title: 'Rename “$tag”',
      content: BnTextInput(controller: field, autofocus: true),
      actions: const [
        BnDialogAction('Cancel', value: false),
        BnDialogAction('Rename', value: true, primary: true),
      ],
    );
    // not disposed: the dialog still shows it while it closes
    final name = field.text;
    if (ok == true) await NoteTags.update((b) => b.renameTag(tag, name));
  }

  Future<void> _delete(BuildContext context, String tag, int n) async {
    final ok = await showBnDialog<bool>(
      context: context,
      title: 'Delete “$tag”?',
      message: n == 0
          ? 'No notes have it.'
          : 'It comes off $n note${n == 1 ? '' : 's'}; the notes stay.',
      actions: const [
        BnDialogAction('Cancel', value: false),
        BnDialogAction('Delete', value: true, primary: true, destructive: true),
      ],
    );
    if (ok == true) await NoteTags.update((b) => b.deleteTag(tag));
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return ValueListenableBuilder(
      valueListenable: NoteTags.book,
      builder: (context, book, _) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          BnDialogTitle(
            title: 'Tags',
            size: 22,
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 6),
          Text(
            book.colors.isEmpty
                ? 'No tags yet. Hold a note › Tags to add one.'
                : 'Tap a dot for the next colour.',
            style: BnType.caption.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 10),
          for (final MapEntry(key: tag, value: color) in book.colors.entries)
            Builder(
              builder: (context) {
                final n = book.count(tag);
                final next = TagBook.palette[
                    (TagBook.palette.indexOf(color) + 1) %
                        TagBook.palette.length];
                return BnSettingsRow(
                  minHeight: 40,
                  leading: Tooltip(
                    message: 'Change colour',
                    child: InkResponse(
                      onTap: () => unawaited(
                        NoteTags.update((b) => b.recolor(tag, next)),
                      ),
                      radius: 18,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: TagDot(color, size: 16),
                      ),
                    ),
                  ),
                  title: tag,
                  subtitle: '$n note${n == 1 ? '' : 's'}',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BnIconButton(
                        icon: BnIcons.rename,
                        tooltip: 'Rename',
                        onPressed: () => _rename(context, tag),
                      ),
                      BnIconButton(
                        icon: BnIcons.trash,
                        tooltip: 'Delete',
                        color: colors.danger,
                        onPressed: () => _delete(context, tag, n),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
