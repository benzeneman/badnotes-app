@Tags(['design'])
library;

import 'package:badnotes/components/settings/nextcloud_profile.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/pages/home/settings.dart';
import 'package:badnotes/pages/user/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_mock_channel_handlers.dart';
import '../utils/test_user.dart';
import 'design_shot.dart';

/// Screenshots of the settings (N21, N31, N32 and the parts the mockups
/// don't show), compared with the mockups when `OUT` and `MOCKUPS` are set.
void main() {
  setUp(() {
    FlavorConfig.setup();
    setupMockPathProvider();
    stows.username.value = 'testuser';
    stows.ncPassword.value = 'testpassword';
    stows.encPassword.value = 'encpassword';
    stows.key.value = 'encryptionkey';
    stows.iv.value = 'encryptioniv';
    stows.lastStorageQuota.value = TestUser.getQuota();
    stows.syncOnlyOnWifi.value = true;
    NextcloudProfile.forceLoginStep = .done;
  });
  tearDown(() => NextcloudProfile.forceLoginStep = null);

  Future<void> Function(WidgetTester) openPart(String label) =>
      (tester) async {
        await tester.tap(find.text(label).first);
        await tester.pump(const Duration(milliseconds: 300));
      };

  testWidgets('N31_AccountSync', (tester) async {
    await designShot(tester, 'N31_AccountSync', designApp(const SettingsPage()));
    expect(find.text('Up to date'), findsOneWidget);
    expect(find.text('Cloud sync'), findsOneWidget);
  });

  testWidgets('N21_Settings', (tester) async {
    await designShot(
      tester,
      'N21_Settings',
      designApp(const SettingsPage()),
      setUp: openPart('Writing'),
    );
    expect(find.text('Hold the pen button'), findsOneWidget);
  });

  testWidgets('N32_Backup', (tester) async {
    await designShot(
      tester,
      'N32_Backup',
      designApp(const SettingsPage()),
      setUp: openPart('Backup & restore'),
    );
    expect(find.text('Save a backup'), findsOneWidget);
  });

  testWidgets('settings_general', (tester) async {
    await designShot(
      tester,
      'settings_general',
      designApp(const SettingsPage()),
      mockup: 'N21_Settings',
      setUp: openPart('General'),
    );
    expect(find.text('Atkinson Hyperlegible font'), findsOneWidget);
    // the readable font is a real setting
    final before = stows.hyperlegibleFont.value;
    await tester.tap(find.text('Atkinson Hyperlegible font'));
    expect(stows.hyperlegibleFont.value, !before);
    stows.hyperlegibleFont.value = before;
  });

  for (final (name, label) in [
    ('settings_editor', 'Editor'),
    ('settings_storage', 'Storage'),
    ('settings_advanced', 'Advanced'),
    ('settings_about', 'About BadNotes'),
  ]) {
    testWidgets(name, (tester) async {
      await designShot(
        tester,
        name,
        designApp(const SettingsPage()),
        mockup: 'N21_Settings',
        setUp: openPart(label),
      );
    });
  }

  testWidgets('settings_stylus_menu', (tester) async {
    await designShot(
      tester,
      'settings_stylus_menu',
      designApp(const SettingsPage()),
      mockup: 'N21_Settings',
      setUp: (tester) async {
        await openPart('Writing')(tester);
        await tester.tap(find.text('Eraser').first);
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
    expect(find.text('Highlighter'), findsOneWidget);
  });

  testWidgets('settings_logged_out_dark', (tester) async {
    NextcloudProfile.forceLoginStep = .nc;
    await designShot(
      tester,
      'settings_logged_out_dark',
      designApp(const SettingsPage(), brightness: Brightness.dark),
      mockup: 'N31_AccountSync',
    );
    expect(find.text('Logged out'), findsOneWidget);
  });

  testWidgets('settings_portrait', (tester) async {
    await designShot(
      tester,
      'settings_portrait',
      designApp(const SettingsPage()),
      size: tabletPortrait,
    );
    expect(find.text('Preferences'), findsOneWidget);
  });

  testWidgets('settings_phone_page', (tester) async {
    await designShot(
      tester,
      'settings_phone_page',
      designApp(const SettingsPage()),
      size: const Size(390, 844),
      setUp: (tester) async {
        await tester.tap(find.text('Writing'));
        await tester.pump(const Duration(milliseconds: 600));
      },
    );
    expect(find.text('Hold the pen button'), findsOneWidget);
  });

  testWidgets('settings_login', (tester) async {
    await designShot(
      tester,
      'settings_login',
      designApp(
        const NcLoginPage(forceAppBarLeading: true, forceCurrentStep: .nc),
      ),
      size: const Size(390, 844),
    );
  });
}
