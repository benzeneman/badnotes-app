import 'package:background_downloader/background_downloader.dart';
import 'package:badnotes/components/settings/app_info.dart';
import 'package:badnotes/components/settings/update_manager.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_settings.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/locales.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tells the user a newer BadNotes is out, shows what changed (in their own
/// language when a translation exists) and can fetch the new version.
class const UpdateDialog({super.key}) extends StatefulWidget {
  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  /// The user's language tag, or null when the app is in English.
  late final String? _lang = LocaleSettings.currentLocale == .en
      ? null
      : LocaleSettings.currentLocale.languageTag;

  /// Where the new build for this device can be downloaded, if known.
  String? _fileUrl;

  /// True when this platform normally gets a direct download but the file
  /// for the new version hasn't been published yet.
  var _fileMissing = false;

  /// What the background download is doing, or null before it starts.
  TaskStatus? _downloadState;

  /// How far along the download is (0 to 1), or null before it starts.
  final _downloaded = ValueNotifier<double?>(null);

  String? _notesEnglish;
  String? _notesTranslated;
  var _preferTranslation = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    _downloaded.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    _fileUrl = await UpdateManager.getLatestDownloadUrl();
    if (!mounted) return;
    final expectsFile = UpdateManager.platformFileRegex.containsKey(
      defaultTargetPlatform,
    );
    _fileMissing = expectsFile && _fileUrl == null;

    _notesEnglish = await UpdateManager.getChangelog();
    if (!mounted) return;
    final lang = _lang;
    _notesTranslated = lang != null
        ? await UpdateManager.getChangelog(localeCode: lang)
        : null;
    if (!mounted) return;
    _preferTranslation = _notesTranslated != null;
    setState(() {});
  }

  /// False while the file is missing or a download is already under way.
  bool get _updateAllowed {
    final busy = _downloadState?.isNotFinalState ?? false;
    return !_fileMissing && !busy;
  }

  Future<void> _onUpdatePressed() async {
    if (!_updateAllowed) return;
    final url = _fileUrl;
    if (url == null) {
      // No file for this platform: send the user to the releases page.
      launchUrl(AppInfo.releasesUrl);
      return;
    }
    if (!mounted) return;

    await UpdateManager.directlyDownloadUpdate(
      url,
      onStatus: (status) {
        _downloadState = status;
        if (mounted) setState(() {});
      },
      onProgress: (fraction) => _downloaded.value = fraction,
    );
    if (mounted) setState(() {});
  }

  /// The changelog to show right now, if any has loaded.
  String? get _notesShown => _preferTranslation && _notesTranslated != null
      ? _notesTranslated
      : _notesEnglish;

  Widget _languageToggle() => BnChip(
    icon: LucideIcons.languages,
    onTap: () => setState(() => _preferTranslation = !_preferTranslation),
    label: _preferTranslation
        ? localeNames[_lang] ?? _lang!
        : localeNames['en']!,
  );

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final notes = _notesShown;
    return BnDialogCard(
      title: t.update.updateAvailable,
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        spacing: 10,
        children: [
          Text(t.update.updateAvailableDescription),
          if (notes != null)
            _ChangelogBox(
              notes,
              style: BnType.body.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          if (_notesEnglish != null && _notesTranslated != null)
            _languageToggle(),
          if (_fileMissing)
            Text(
              t.update.downloadNotAvailableYet,
              style: TextStyle(color: colors.danger),
            ),
          ValueListenableBuilder(
            valueListenable: _downloaded,
            builder: (context, fraction, _) => fraction == null
                ? const SizedBox()
                : Padding(
                    padding: const .only(top: 6),
                    child: BnProgressLine(value: fraction, height: 4),
                  ),
          ),
        ],
      ),
      actions: [
        BnButton(
          label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
          onPressed: () => Navigator.pop(context),
        ),
        BnButton.primary(
          label: t.update.update,
          onPressed: _updateAllowed ? _onUpdatePressed : null,
        ),
      ],
    );
  }
}

/// Holds the release notes on a softly tinted, rounded panel.
class const _ChangelogBox(final String text, {required final TextStyle style})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: BadNotesColors.of(context).previewBg,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
    child: Text(text, style: style),
  );
}
