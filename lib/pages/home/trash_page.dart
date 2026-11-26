import 'package:badnotes/components/home/desk.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/home/new_note_button.dart';
import 'package:badnotes/components/home/trash.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

/// Deleted notes, kept for 30 days (design N20).
class TrashPage extends HookWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      Trash.load();
      return null;
    }, const []);
    HomeChrome.newMenu.value = const NewDocumentMenu();
    final entries = useValueListenable(Trash.entries);
    final colors = BadNotesColors.of(context);
    // the trash opens with go, so there is no route under it: back goes to
    // the desk rather than out of the app
    void toDesk() => context.go(HomeRoutes.browseFilePath(null));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => didPop ? null : toDesk(),
      child: HomePageFrame(
        title: 'Trash',
        caption: 'Items stay here for 30 days, then they’re gone for good',
        leading: BnIconButton(
          icon: BnIcons.back,
          tooltip: 'Back',
          onPressed: toDesk,
        ),
        trailing: entries.isEmpty
            ? null
            : BnButton.destructive(
                label: 'Empty trash',
                icon: BnIcons.trash,
                onPressed: () async {
                  final sure = await showBnDialog<bool>(
                    context: context,
                    title: 'Empty the trash?',
                    message:
                        'The ${entries.length} notes in it are deleted for '
                        "good. This can't be undone.",
                    actions: const [
                      BnDialogAction('Cancel', value: false),
                      BnDialogAction(
                        'Empty trash',
                        value: true,
                        primary: true,
                        destructive: true,
                      ),
                    ],
                  );
                  if (sure ?? false) await Trash.empty();
                },
              ),
        slivers: [
          if (entries.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Column(
                  children: [
                    Icon(BnIcons.trash, size: 36, color: colors.faint),
                    const SizedBox(height: 12),
                    Text(
                      'The trash is empty',
                      style: BnType.title.copyWith(color: colors.text),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Notes you delete wait here for 30 days.',
                      style: BnType.body.copyWith(
                        color: colors.muted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            DecoratedSliver(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.hairline),
                borderRadius: const BorderRadius.all(
                  Radius.circular(BnRadius.card),
                ),
                boxShadow: BnShadows.card,
              ),
              sliver: SliverList.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) => SizedBox(
                  height: 1,
                  child: ColoredBox(color: colors.divider),
                ),
                itemBuilder: (context, i) => _TrashRow(entry: entries[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrashRow extends StatelessWidget {
  const _TrashRow({required this.entry});

  final TrashEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final days = entry.expires.difference(DateTime.now()).inDays.clamp(0, 30);
    final wide = !HomeChrome.isPhone(context);
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          const SizedBox(width: 16),
          const SizedBox(
            width: 34,
            height: 44,
            child: BnCoverFrame(child: ColoredBox(color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.body.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Notebook · deleted ${homeShortDate(entry.deletedAt)}',
                  style: BnType.caption.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          if (wide)
            SizedBox(
              width: 140,
              child: Text(
                'Deleted forever in $days day${days == 1 ? '' : 's'}',
                style: BnType.caption.copyWith(color: colors.muted),
              ),
            ),
          const SizedBox(width: 14),
          // on phones the labelled buttons push the name off the row
          if (wide) ...[
            BnButton(
              label: 'Restore',
              height: 32,
              onPressed: () => Trash.restore(entry),
            ),
            const SizedBox(width: 14),
            BnButton.destructive(
              label: 'Delete forever',
              height: 32,
              onPressed: () => _deleteForever(context),
            ),
            const SizedBox(width: 16),
          ] else ...[
            BnIconButton(
              icon: BnIcons.restore,
              tooltip: 'Restore',
              onPressed: () => Trash.restore(entry),
            ),
            BnIconButton(
              icon: BnIcons.trash,
              tooltip: 'Delete forever',
              color: colors.danger,
              onPressed: () => _deleteForever(context),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteForever(BuildContext context) async {
    final sure = await showBnDialog<bool>(
      context: context,
      title: 'Delete “${entry.name}” forever?',
      message: "This can't be undone.",
      actions: const [
        BnDialogAction('Cancel', value: false),
        BnDialogAction(
          'Delete forever',
          value: true,
          primary: true,
          destructive: true,
        ),
      ],
    );
    if (sure ?? false) await Trash.deleteForever(entry);
  }
}
