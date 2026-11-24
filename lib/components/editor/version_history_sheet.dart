import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/note_versions.dart';
import 'package:flutter/material.dart';

/// Shows the kept versions of the note at [notePath] (without extension).
///
/// Restoring calls [beforeRestore] first (save and let go of the note),
/// then [afterRestore] (reload it). "Open as a copy" calls [openCopy] with
/// the new note's path.
Future<void> showVersionHistory(
  BuildContext context, {
  required String notePath,
  required Future<void> Function() beforeRestore,
  required void Function() afterRestore,
  required void Function(String newPath) openCopy,
}) => showAppleDialog<void>(
  context: context,
  builder: (_) => _VersionHistory(
    notePath: notePath,
    beforeRestore: beforeRestore,
    afterRestore: afterRestore,
    openCopy: openCopy,
  ),
);

class _VersionHistory extends StatefulWidget {
  const new({
    required this.notePath,
    required this.beforeRestore,
    required this.afterRestore,
    required this.openCopy,
  });

  final String notePath;
  final Future<void> Function() beforeRestore;
  final void Function() afterRestore;
  final void Function(String newPath) openCopy;

  @override
  State<_VersionHistory> createState() => _VersionHistoryState();
}

class _VersionHistoryState extends State<_VersionHistory> {
  late final _versions = NoteVersions.list(widget.notePath);
  NoteVersion? _selected;
  var _busy = false;

  Future<void> _openCopy(NoteVersion version) async {
    setState(() => _busy = true);
    final path = await NoteVersions.openAsCopy(version);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (path != null) widget.openCopy(path);
  }

  Future<void> _restore(NoteVersion version) async {
    final sure = await showAppleDialog<bool>(
      context: context,
      builder: (context) => const _ConfirmRestore(),
    );
    if (sure != true || !mounted) return;
    setState(() => _busy = true);
    await widget.beforeRestore();
    await NoteVersions.restore(version);
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.afterRestore();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final name = widget.notePath.substring(
      widget.notePath.lastIndexOf('/') + 1,
    );
    final selected = _busy ? null : _selected;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          type: MaterialType.transparency,
          child: BnPopover(
            width: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Version history',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' · $name'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.bodyLarge.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kept automatically while you work',
                  style: BnType.caption.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 12),
                FutureBuilder(
                  future: _versions,
                  builder: (context, snapshot) {
                    final versions = snapshot.data;
                    if (versions == null) {
                      return const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (versions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No versions yet. One is kept when you close '
                          'a note you changed.',
                          textAlign: TextAlign.center,
                          style: BnType.body.copyWith(color: colors.muted),
                        ),
                      );
                    }
                    final now = DateTime.now();
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: versions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (context, i) => _VersionRow(
                          version: versions[i],
                          now: now,
                          selected: versions[i] == _selected,
                          onTap: () => setState(() => _selected = versions[i]),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  spacing: 8,
                  children: [
                    BnButton(
                      label: 'Open as a copy',
                      onPressed: selected == null
                          ? null
                          : () => _openCopy(selected),
                    ),
                    BnButton.primary(
                      label: 'Restore this version',
                      onPressed: selected == null
                          ? null
                          : () => _restore(selected),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const new({
    required this.version,
    required this.now,
    required this.selected,
    required this.onTap,
  });

  final NoteVersion version;
  final DateTime now;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    const radius = BorderRadius.all(Radius.circular(BnRadius.card));
    return Material(
      color: selected ? colors.accentTint : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: selected ? colors.accent : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _Thumbnail(version: version),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      versionLabel(version.time, now),
                      style: BnType.body.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (version.pages > 0)
                      Text(
                        version.pages == 1 ? '1 page' : '${version.pages} pages',
                        style: BnType.caption.copyWith(color: colors.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The version's first page, or lined paper when there's no picture.
class _Thumbnail extends StatelessWidget {
  const new({required this.version});

  final NoteVersion version;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final thumbnail = version.thumbnail;
    return Container(
      width: 44,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: thumbnail != null
          ? Image.file(
              thumbnail,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              cacheWidth: 132,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < 6; i++)
                    Container(height: 1, color: colors.divider),
                ],
              ),
            ),
    );
  }
}

class _ConfirmRestore extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          type: MaterialType.transparency,
          child: BnPopover(
            width: 340,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Restore this version?',
                  style: BnType.title.copyWith(color: colors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  'The note as it is now is kept as a version too, '
                  'so nothing is lost.',
                  style: BnType.body.copyWith(color: colors.text2),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    BnButton(
                      label: MaterialLocalizations.of(
                        context,
                      ).cancelButtonLabel,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    BnButton.primary(
                      label: 'Restore',
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
