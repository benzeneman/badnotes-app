import 'dart:io';

import 'package:badnotes/components/editor_ui/option_previews.dart';
import 'package:badnotes/components/settings/pen_input_settings.dart';
import 'package:badnotes/components/settings/app_info.dart';
import 'package:badnotes/components/settings/nextcloud_profile.dart';
import 'package:badnotes/components/settings/settings_directory_selector.dart';
import 'package:badnotes/components/theming/apple_ui.dart' show showBanner;
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_settings.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/backup.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/locales.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/home/note_tags.dart';
import 'package:badnotes/components/home/trash.dart';
import 'package:badnotes/pages/home/home.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One part of the settings: a page of its own on a phone, a pane next to
/// the side menu on a tablet.
enum _Part {
  account,
  backup,
  general,
  writing,
  editor,
  storage,
  advanced,
  about,
}

extension on _Part {
  String get title => switch (this) {
    .account => 'Account & Sync',
    .backup => 'Backup & restore',
    .general => t.settings.prefCategories.general,
    .writing => t.settings.prefCategories.writing,
    .editor => t.settings.prefCategories.editor,
    .storage => 'Storage',
    .advanced => t.settings.prefCategories.advanced,
    .about => 'About BadNotes',
  };

  String? get caption => switch (this) {
    .account => null,
    .backup => 'All your notes in one file, or in Google Drive',
    .general => 'Theme and language',
    .writing => 'Stylus, fingers and eraser',
    .editor => 'Toolbar and pages',
    .storage => 'Autosave and where notes are kept',
    .advanced => null,
    .about => null,
  };

  IconData get icon => switch (this) {
    .account => LucideIcons.cloud,
    .backup => LucideIcons.archive,
    .general => LucideIcons.palette,
    .writing => LucideIcons.pencil,
    .editor => LucideIcons.layoutGrid,
    .storage => LucideIcons.hardDrive,
    .advanced => LucideIcons.wrench,
    .about => LucideIcons.info,
  };

  Widget get body => switch (this) {
    .account => const _AccountSettings(),
    .backup => const _BackupSettings(),
    .general => const _GeneralSettings(),
    .writing => const _WritingSettings(),
    .editor => const _EditorSettings(),
    .storage => const _StorageSettings(),
    .advanced => const _AdvancedSettings(),
    .about => const _AboutSettings(),
  };
}

class SettingsPage extends StatefulWidget {
  const new({super.key});

  /// From this width on, the parts are listed at the left and the chosen
  /// one is shown next to them.
  static const twoPaneFromWidth = 880.0;

  /// The part to open next time the settings open (`writing`, `backup`…),
  /// e.g. from the profile menu.
  static String? openPart;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// The part shown next to the side menu, on a wide screen.
  final _chosen = ValueNotifier(_Part.account);

  @override
  void initState() {
    super.initState();
    final asked = SettingsPage.openPart;
    SettingsPage.openPart = null;
    final part = _Part.values.where((p) => p.name == asked).firstOrNull;
    if (part == null) return;
    _chosen.value = part;
    // on a narrow screen the parts are pages of their own
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.sizeOf(context).width < SettingsPage.twoPaneFromWidth) {
        _open(context, part);
      }
    });
  }

  @override
  void dispose() {
    _chosen.dispose();
    super.dispose();
  }

  void _open(BuildContext context, _Part part) {
    if (part == .about) return AppInfo.show(context);
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => BnSettingsScaffold(
          title: part.title,
          caption: part.caption,
          previousTitle: t.home.titles.settings,
          children: [part.body],
        ),
      ),
    );
  }

  void _goHome(BuildContext context) =>
      context.go(HomeRoutes.browseFilePath(null));

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return PopScope(
      // the settings aren't in the dock, so back goes to the documents
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(
        backgroundColor: colors.desk,
        body: ValueListenableBuilder(
          // the whole page is in the chosen language
          valueListenable: stows.locale,
          builder: (context, _, _) => SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  constraints.maxWidth >= SettingsPage.twoPaneFromWidth
                  ? _twoPanes(context, constraints)
                  : _onePage(context, constraints),
            ),
          ),
        ),
      ),
    );
  }

  /// The home tabs' header: logo, search, sync and the account.
  Widget _topBar(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 26, bottom: 22),
    child: HomeHeader(),
  );

  /// A tablet: the side menu at the left, the chosen part at the right.
  Widget _twoPanes(BuildContext context, BoxConstraints constraints) {
    final colors = BadNotesColors.of(context);
    final margin = bnSettingsMargin(constraints.maxWidth);
    final bottom = MediaQuery.paddingOf(context).bottom + 32;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(context),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 250,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: bottom),
                    child: ValueListenableBuilder(
                      valueListenable: _chosen,
                      builder: (context, chosen, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            t.home.titles.settings,
                            style: BnType.display.copyWith(color: colors.text),
                          ),
                          const SizedBox(height: 20),
                          for (final part in _Part.values) ...[
                            BnSettingsNavItem(
                              label: part.title,
                              selected: part == chosen,
                              onTap: () => _chosen.value = part,
                            ),
                            const SizedBox(height: 2),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _chosen,
                    builder: (context, chosen, _) => AnimatedSwitcher(
                      duration: BnMotion.fast,
                      switchInCurve: BnMotion.curve,
                      switchOutCurve: BnMotion.curve,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, ?current],
                      ),
                      child: ListView(
                        key: ValueKey(chosen),
                        padding: EdgeInsets.only(top: 6, bottom: bottom),
                        children: [
                          BnSettingsPaneTitle(
                            chosen.title,
                            caption: chosen.caption,
                          ),
                          chosen.body,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A phone or a narrow window: the account first, then a row for each
  /// other part, which opens it as a page.
  Widget _onePage(BuildContext context, BoxConstraints constraints) {
    final colors = BadNotesColors.of(context);
    final margin = bnSettingsMargin(constraints.maxWidth);
    final side = constraints.maxWidth > 720 + 2 * margin
        ? (constraints.maxWidth - 720) / 2
        : margin;
    Widget row(_Part part) => BnSettingsRow(
      icon: part.icon,
      title: part.title,
      subtitle: part.caption,
      value: part == .about ? AppInfo.info : null,
      chevron: true,
      minHeight: 40,
      onTap: () => _open(context, part),
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(
        side,
        0,
        side,
        MediaQuery.paddingOf(context).bottom + 32,
      ),
      children: [
        _topBar(context),
        Text(
          t.home.titles.settings,
          style: BnType.display.copyWith(color: colors.text),
        ),
        const SizedBox(height: 6),
        const _AccountSettings(),
        BnSettingsGroup(
          label: 'Preferences',
          children: [
            for (final part in [
              _Part.general,
              _Part.writing,
              _Part.editor,
              _Part.storage,
            ])
              row(part),
          ],
        ),
        BnSettingsGroup(
          label: 'More',
          children: [
            for (final part in [_Part.backup, _Part.advanced, _Part.about])
              row(part),
          ],
        ),
      ],
    );
  }
}

class _AccountSettings extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const NextcloudProfile(),
        BnSettingsGroup(
          label: 'When to sync',
          children: [
            BnPrefSwitchRow(
              title: t.settings.prefLabels.syncOnlyOnWifi,
              subtitle: t.settings.prefDescriptions.syncOnlyOnWifi,
              pref: stows.syncOnlyOnWifi,
            ),
            BnPrefSwitchRow(
              title: t.settings.prefLabels.syncPreviewsOnMobileData,
              subtitle: t.settings.prefDescriptions.syncPreviewsOnMobileData,
              pref: stows.syncPreviewsOnMobileData,
            ),
          ],
        ),
        BnSettingsGroup(
          label: 'Google Drive',
          children: [
            BnPrefSwitchRow(
              title: 'PDF copies in Google Drive',
              subtitle:
                  'A PDF of each note you change, in the "BadNotes PDFs" '
                  'folder, to open and share from Drive. Not encrypted.',
              pref: stows.drivePdfCopies,
            ),
          ],
        ),
      ],
    );
  }
}

class _GeneralSettings extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BnSettingsGroup(
          label: 'Appearance',
          children: [
            BnPrefSegmentRow<ThemeMode>(
              title: t.settings.prefLabels.appTheme,
              pref: stows.appTheme,
              options: {
                ThemeMode.system: t.settings.themeModes.system,
                ThemeMode.light: t.settings.themeModes.light,
                ThemeMode.dark: t.settings.themeModes.dark,
              },
            ),
            BnPrefSwitchRow(
              title: t.settings.prefLabels.hyperlegibleFont,
              subtitle: t.settings.prefDescriptions.hyperlegibleFont,
              pref: stows.hyperlegibleFont,
            ),
          ],
        ),
        BnSettingsGroup(
          label: 'Version history',
          children: [
            BnPrefSwitchRow(
              icon: Icons.history,
              title: 'Keep versions',
              subtitle:
                  'While you write, a copy of the note is kept every 2 hours. '
                  'Kept: every copy from the last day, then the last one of '
                  'each day for a week, then one a week for a month; older '
                  'ones are deleted. Only on this device (not synced). '
                  'See them in a note: ⋯ › Version History.',
              pref: stows.keepVersions,
            ),
          ],
        ),
        BnSettingsGroup(
          label: 'Tags',
          children: [
            BnSettingsRow(
              icon: tagIcon,
              title: 'Tags',
              subtitle: 'Rename, recolour or delete a tag everywhere',
              chevron: true,
              onTap: () => showManageTagsSheet(context),
            ),
          ],
        ),
        BnSettingsGroup(
          label: t.settings.prefLabels.locale,
          children: [
            ValueListenableBuilder(
              valueListenable: stows.locale,
              builder: (context, locale, _) => BnSettingsRow(
                title: t.settings.prefLabels.locale,
                value: locale.isEmpty
                    ? t.settings.systemLanguage
                    : localeNames[locale] ?? locale,
                chevron: true,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (context) => const _LanguagePage(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LanguagePage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final codes = [
      '',
      for (final locale in AppLocaleUtils.supportedLocales)
        locale.toLanguageTag(),
    ];
    return BnSettingsScaffold(
      title: t.settings.prefLabels.locale,
      previousTitle: t.home.titles.settings,
      children: [
        ValueListenableBuilder(
          valueListenable: stows.locale,
          builder: (context, chosen, _) {
            final colors = BadNotesColors.of(context);
            return BnSettingsGroup(
              children: [
                for (final code in codes)
                  BnSettingsRow(
                    minHeight: 26,
                    title: code.isEmpty
                        ? t.settings.systemLanguage
                        : localeNames[code] ?? code,
                    titleStyle: code == chosen
                        ? TextStyle(
                            color: colors.accentStrong,
                            fontWeight: FontWeight.w600,
                          )
                        : null,
                    trailing: code == chosen
                        ? Icon(
                            LucideIcons.check,
                            size: 16,
                            color: colors.accent,
                          )
                        : null,
                    onTap: () => stows.locale.value = code,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WritingSettings extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final labels = t.settings.prefLabels;
    final about = t.settings.prefDescriptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BnSettingsGroup(
          label: 'Input',
          children: [
            BnPrefSwitchRow(
              title: labels.autoDisableFingerDrawingWhenStylusDetected,
              subtitle: about.autoDisableFingerDrawingWhenStylusDetected,
              pref: stows.autoDisableFingerDrawingWhenStylusDetected,
            ),
            BnPrefSwitchRow(
              title: labels.hideFingerDrawingToggle,
              pref: stows.hideFingerDrawingToggle,
            ),
          ],
        ),
        const PressureCurveSettings(),
        const PalmRejectionSettings(),
        BnSettingsGroup(
          label: 'Stylus button',
          children: [
            BnPrefChoiceRow<int>(
              title: 'Hold the pen button',
              subtitle: 'What holding the button on the pen does',
              pref: stows.stylusButtonTool,
              options: const {0: 'Eraser', 1: 'Lasso', 2: 'Highlighter'},
            ),
          ],
        ),
        BnSettingsGroup(
          label: 'Eraser',
          children: [
            BnPrefSwitchRow(
              title: labels.disableEraserAfterUse,
              subtitle: about.disableEraserAfterUse,
              pref: stows.disableEraserAfterUse,
            ),
          ],
        ),
        BnSettingsGroup(
          label: 'Whiteboard',
          children: [
            BnPrefSwitchRow(
              title: labels.autoClearWhiteboardOnExit,
              subtitle: about.autoClearWhiteboardOnExit,
              pref: stows.autoClearWhiteboardOnExit,
            ),
          ],
        ),
      ],
    );
  }
}

class _EditorSettings extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final labels = t.settings.prefLabels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BnSettingsGroup(
          label: 'Toolbar',
          children: [
            BnPrefSegmentRow<bool>(
              title: 'Toolbar style',
              pref: stows.toolbarDocked,
              options: const {false: 'Floating', true: 'Docked'},
            ),
            BnPrefSegmentRow<bool>(
              title: 'Docked tools on a phone',
              pref: stows.dockedToolsBottom,
              options: const {false: 'Top', true: 'Bottom'},
            ),
            BnPrefSegmentRow<AxisDirection>(
              title: labels.editorToolbarAlignment,
              pref: stows.editorToolbarAlignment,
              options: {
                for (final direction in AxisDirection.values)
                  direction: t.settings.axisDirections[direction.index],
              },
            ),
            BnPrefSwitchRow(
              title: labels.editorToolbarShowInFullscreen,
              pref: stows.editorToolbarShowInFullscreen,
            ),
          ],
        ),
        BnSettingsGroup(
          label: 'Pages',
          children: [
            BnPrefSegmentRow<bool>(
              title: 'Pages go',
              pref: stows.editorHorizontalScroll,
              options: const {false: 'Top to bottom', true: 'Side by side'},
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                BnPrefSwitchRow(
                  title: labels.editorAutoInvert,
                  pref: stows.editorAutoInvert,
                ),
                // the app going dark, and the page with it when this is on
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: DarkInkPreview(),
                ),
              ],
            ),
            BnPrefSwitchRow(
              title: labels.editorPromptRename,
              subtitle: t.settings.prefDescriptions.editorPromptRename,
              pref: stows.editorPromptRename,
            ),
          ],
        ),
      ],
    );
  }
}

class _BackupSettings extends StatefulWidget {
  const new();

  @override
  State<_BackupSettings> createState() => _BackupSettingsState();
}

class _BackupSettingsState extends State<_BackupSettings> {
  /// What's running, shown instead of the buttons' subtitles.
  String? _busy;

  Future<void> _run(String doing, Future<String> Function() action) async {
    if (_busy != null) return;
    setState(() => _busy = doing);
    String message;
    try {
      message = await action();
    } catch (e, st) {
      Backup.log.warning('$doing failed', e, st);
      message = "That didn't work. Please try again.";
    }
    if (!mounted) return;
    setState(() => _busy = null);
    showBanner(context, message, duration: const Duration(seconds: 4));
  }

  Future<String> _save() async {
    final zip = await Backup.create();
    if (!mounted) return '';
    await FileManager.exportFile(Backup.fileName(), zip, context: context);
    return 'Backup ready (${(zip.length / 1024 / 1024).toStringAsFixed(1)} MB)';
  }

  Future<String> _restore() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    final path = file?.path;
    if (path == null) return 'No backup chosen';
    final bytes = await File(path).readAsBytes();
    final restored = await Backup.restore(bytes);
    return restored == 0
        ? 'Nothing to restore: every file is already here'
        : 'Restored $restored files. Notes already here were kept.';
  }

  Future<String> _toDrive() async => await Backup.backUpToDrive()
      ? 'Backed up to the "BadNotes Backups" folder in Google Drive'
      : 'Log in to Google Drive in settings first';

  @override
  Widget build(BuildContext context) {
    final last = stows.lastDriveBackup.value;
    final lastText = last == 0
        ? 'Not yet'
        : MaterialLocalizations.of(context)
              .formatMediumDate(DateTime.fromMillisecondsSinceEpoch(last));
    final idle = _busy == null;
    void save() => _run('Making the backup…', _save);
    void restore() => _run('Restoring…', _restore);
    void toDrive() => _run('Backing up…', _toDrive);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BnSettingsGroup(
          label: 'Backup',
          children: [
            BnSettingsRow(
              title: 'Save a backup',
              subtitle:
                  _busy ?? 'One zip file of every note, picture and folder',
              onTap: save,
              trailing: BnButton.primary(
                label: 'Save',
                height: 34,
                onPressed: idle ? save : null,
              ),
            ),
            BnSettingsRow(
              title: 'Restore from a backup',
              subtitle:
                  'Brings back missing notes; keeps the ones already here',
              onTap: restore,
              trailing: BnButton(
                label: 'Choose…',
                height: 34,
                onPressed: idle ? restore : null,
              ),
            ),
          ],
        ),
        BnSettingsGroup(
          label: 'Automatic',
          children: [
            BnPrefSwitchRow(
              title: 'Weekly backup to Google Drive',
              subtitle:
                  'In the "BadNotes Backups" folder. Drive keeps the older '
                  'versions. Not encrypted.',
              pref: stows.autoDriveBackup,
            ),
            BnSettingsRow(
              title: 'Back up to Google Drive now',
              subtitle: 'Last backup: $lastText',
              onTap: toDrive,
              trailing: BnButton(
                label: 'Back up',
                height: 34,
                onPressed: idle ? toDrive : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StorageSettings extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final labels = t.settings.prefLabels;
    return BnSettingsGroup(
      label: 'Notes',
      children: [
        BnPrefSegmentRow<int>(
          title: labels.autosave,
          subtitle: t.settings.prefDescriptions.autosave,
          pref: stows.autosaveDelay,
          options: {5000: '5s', 10000: '10s', -1: t.settings.autosaveDisabled},
        ),
        if (Platform.isAndroid)
          SettingsDirectorySelector(
            title: labels.customDataDir,
            icon: LucideIcons.folder,
          ),
        // deleted notes, kept for 30 days (design §7.3, N20)
        ValueListenableBuilder(
          valueListenable: Trash.entries,
          builder: (context, entries, _) => BnSettingsRow(
            title: 'Trash',
            subtitle: 'Deleted notes stay for 30 days',
            icon: LucideIcons.trash2,
            value: entries.isEmpty ? null : '${entries.length}',
            chevron: true,
            onTap: () {
              Trash.load();
              context.go('${RoutePaths.prefixOfHome}/${HomePage.trashSubpage}');
            },
          ),
        ),
      ],
    );
  }
}

class _AdvancedSettings extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return BnSettingsGroup(
      children: [
        BnSettingsRow(
          title: t.logs.viewLogs,
          subtitle: t.logs.debuggingInfo,
          chevron: true,
          onTap: () => context.push(RoutePaths.logs),
        ),
      ],
    );
  }
}

class _AboutSettings extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return BnSettingsGroup(
      children: [
        BnSettingsRow(
          title: 'BadNotes',
          subtitle: 'Version, license and privacy policy',
          value: AppInfo.info,
          chevron: true,
          onTap: () => AppInfo.show(context),
        ),
      ],
    );
  }
}
