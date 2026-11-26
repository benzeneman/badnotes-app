import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_settings.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/is_this_a_test.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/version.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class const AppInfo({super.key}) extends StatelessWidget {
  /// Where new versions are put up, when an update can't be downloaded here.
  static final Uri releasesUrl = Uri.parse(
    'https://badnotes.space',
  );

  /// Who makes BadNotes, as shown in the app.
  static const author = 'Karan Adhikari';

  static String get info => [
    // Tests use static values to improve reducibility
    if (isThisATest) 'v1.35.1' else 'v$buildName',
    if (FlavorConfig.flavor.isNotEmpty) FlavorConfig.flavor,
    if (kDebugMode && !isThisATest) t.appInfo.debug,
    if (isThisATest) '(135010)' else '($buildNumber)',
  ].join(' ');

  /// The copyright line under the about card and on the licenses page.
  static String get copyright => '© $buildYear $author';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: stows.locale,
      builder: (context, _, _) => BnButton(
        kind: BnButtonKind.quiet,
        label: info,
        onPressed: () => show(context),
      ),
    );
  }

  /// When the privacy policy and terms were last changed.
  static const policiesUpdated = '26 November 2026';

  /// Shows BadNotes's privacy policy, in the app.
  static void showPrivacyPolicy(BuildContext context) => _showPolicy(
    context,
    'Privacy policy',
    const [
      (
        'Who we are',
        'BadNotes is made and owned by $author. This policy says what the '
            'app does with your data. Last updated $policiesUpdated.',
      ),
      (
        'Your notes',
        'Your notes, pictures, recordings and settings are stored on this '
            'device. BadNotes does not collect them and cannot see them. Its '
            'only server is the one that records BadNotes Pro purchases '
            '(below), and your notes never go there.',
      ),
      (
        'Cloud sync (optional)',
        'If you sign in to Google Drive or OneDrive, your notes are copied to that account so they '
            'reach your other devices. They stay in your account, under that '
            'provider\'s own terms and privacy policy. With Google Drive and '
            'OneDrive, BadNotes can only open the files it created itself, '
            'and reads your account\'s email address and profile picture to '
            'show who is signed in. You can sign out at any time; files '
            'already in your cloud stay there until you delete them. '
            'BadNotes\'s use and transfer of information received from '
            'Google APIs follows the Google API Services User Data Policy, '
            'including its Limited Use requirements: the data is used only '
            'to sync your notes, is never sold or used for advertising, and '
            'is never shared with anyone.',
      ),
      (
        'BadNotes Pro purchases',
        'When you buy BadNotes Pro, or the app checks whether you have it, '
            'the app sends the Google purchase token and a sign-in token from '
            'your Google account to the BadNotes server at '
            'api.badnotes.space. The server reads only your account\'s email '
            'address from Google, checks the purchase with Google Play, and '
            'stores your email address, the purchase token, the order number '
            'and the purchase date, so that Pro works on every device where '
            'you sign in with that account. Payments are made through Google '
            'Play; BadNotes never sees your card, UPI or bank details. '
            'Nothing about your notes is sent. To have this record deleted, '
            'write to the address below.',
      ),
      (
        'Microphone',
        'Used only while you record audio in a note or use voice typing. '
            'Recordings stay in your note. Voice typing uses your device\'s '
            'own speech service.',
      ),
      (
        'Camera and files',
        'The camera is used only when you scan a page or add a photo, and '
            'files only when you pick them to import or export. Nothing is '
            'sent anywhere by BadNotes.',
      ),
      (
        'Handwriting search',
        'Your handwriting is read on this device. The reading models are '
            'downloaded once from Google.',
      ),
      (
        'Crash reports and analytics',
        'None. BadNotes does not send crash reports, usage statistics or '
            'any other data about you or your device to anyone.',
      ),
      (
        'Children',
        'BadNotes does not knowingly collect anything from anyone, '
            'children included.',
      ),
      (
        'Changes and questions',
        'If this policy changes, the new version is shown here with its '
            'date. Questions: write to badnotes.co@gmail.com '
            'or see badnotes.space.',
      ),
    ],
  );

  /// Shows BadNotes's terms of use, in the app.
  static void showTerms(BuildContext context) => _showPolicy(
    context,
    'Terms of use',
    const [
      (
        'Agreement',
        'BadNotes is made and owned by $author. By using the app you agree '
            'to these terms. If you do not, please do not use it. Last '
            'updated $policiesUpdated.',
      ),
      (
        'Your content',
        'Everything you write, draw, record or import is yours. BadNotes '
            'only keeps it for you on your device, and in your own cloud '
            'account if you turn sync on. You are responsible for what you '
            'put in your notes.',
      ),
      (
        'Using the app',
        'BadNotes has a free version and a paid one, BadNotes Pro. Please '
            'do not use it to break the law, to harm others, or to try to '
            'damage, copy or reverse-engineer it.',
      ),
      (
        'BadNotes Pro',
        'BadNotes Pro is a one-time purchase made through Google Play. It '
            'belongs to the Google account you are signed in with in '
            'BadNotes when you buy it, and works on every device where you '
            'sign in with that account, for as long as BadNotes is offered. '
            'If you change or close that Google account, Pro does not move '
            'to another one. Refunds follow Google Play\'s refund policy: you '
            'can ask Google Play for a refund within 48 hours of buying, and '
            'after that you can write to badnotes.co@gmail.com. If a purchase '
            'is refunded or charged back, Pro is turned off. Everything you '
            'made stays yours and keeps opening, editing and exporting; only '
            'the Pro features stop.',
      ),
      (
        'Backups',
        'Notes live on your device. Keep your own backups (the app can '
            'back up to your Google Drive, or you can export), because a '
            'lost, wiped or broken device can lose them, and so can a bug.',
      ),
      (
        'Third-party services',
        'Cloud sync, voice typing and handwriting models are provided by '
            'others (Google or Microsoft). Their own terms '
            'apply when you use them, and BadNotes is not responsible for '
            'them.',
      ),
      (
        'No warranty',
        'BadNotes is provided "as is", without any promise that it will be '
            'always available, error-free or fit for a particular purpose. '
            'To the fullest extent the law allows, BadNotes and its owners '
            'are not liable for '
            'any loss or damage, including lost notes, that comes from '
            'using it.',
      ),
      (
        'Licence',
        'BadNotes is proprietary software. You may not '
            'copy, modify or redistribute it. It uses third-party '
            'open-source components, each under its own licence; they are '
            'listed under Open-source licenses in this About page.',
      ),
      (
        'Changes',
        'These terms may change. The new version is shown here with its '
            'date, and using BadNotes after that means you accept it.',
      ),
    ],
  );

  static void _showPolicy(
    BuildContext context,
    String title,
    List<(String, String)> parts,
  ) => showBnSettingsDialog<void>(
    context: context,
    width: 460,
    builder: (context) {
      final colors = BadNotesColors.of(context);
      Widget part(String title, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
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
            const SizedBox(height: 3),
            Text(
              text,
              style: BnType.body.copyWith(
                color: colors.text2,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
      return BnDialogCard(
        title: title,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [for (final (heading, text) in parts) part(heading, text)],
          ),
        ),
        actions: [
          BnButton.primary(
            label: MaterialLocalizations.of(context).closeButtonLabel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );

  /// The third-party packages BadNotes is built with and their licenses.
  static void showLicenses(BuildContext context) => showLicensePage(
    context: context,
    applicationName: 'BadNotes',
    applicationVersion: info,
    applicationIcon: SvgPicture.asset(
      'assets/icon/icon.svg',
      width: 50,
      height: 50,
    ),
    applicationLegalese: '$copyright. All rights reserved.',
  );

  /// The about card (design 17): the app's icon and name side by side, the
  /// privacy policy and licenses, and the © line with Done. One white card:
  /// a tinted block at its top had square corners poking out of it.
  static void show(BuildContext context) => showBnSettingsDialog<void>(
    context: context,
    width: 400,
    builder: (context) {
      final colors = BadNotesColors.of(context);
      // on a card of its own: the dialog itself has no background, and the
      // screen behind showed through the text
      return BnPopover(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: SvgPicture.asset(
                    'assets/icon/icon.svg',
                    width: 64,
                    height: 64,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BadNotes',
                        style: BnType.title.copyWith(
                          color: colors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by $author',
                        style: BnType.bodyLarge.copyWith(color: colors.text2),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accentTint,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(BnRadius.pill),
                          ),
                        ),
                        child: Text(
                          'Version $info',
                          style: BnType.caption.copyWith(
                            color: colors.accentStrong,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: 6),
            BnMenuRow(
              icon: BnIcons.lock,
              label: 'Privacy policy',
              onTap: () => showPrivacyPolicy(context),
            ),
            BnMenuRow(
              icon: BnIcons.file,
              label: 'Terms of use',
              onTap: () => showTerms(context),
            ),
            BnMenuRow(
              icon: BnIcons.file,
              label: 'Open-source licenses',
              onTap: () => showLicenses(context),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    copyright,
                    style: BnType.caption.copyWith(color: colors.faint),
                  ),
                ),
                BnButton.primary(
                  label: 'Done',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
