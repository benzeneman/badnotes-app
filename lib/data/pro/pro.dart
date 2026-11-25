import 'dart:async';
import 'dart:io';

import 'package:badnotes/components/home/note_facts.dart';
import 'package:badnotes/components/pro/paywall.dart';
import 'package:badnotes/data/is_this_a_test.dart';
import 'package:badnotes/data/nextcloud/remote_store.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/pro/licence.dart';
import 'package:badnotes/data/pro/licence_api.dart';
import 'package:badnotes/data/pro/pro_limits.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdfrx/pdfrx.dart';

export 'package:badnotes/data/pro/pro_limits.dart';

/// BadNotes Pro: one purchase, kept by the licence server against the Google
/// account signed in here, so it follows that account to every device.
///
/// [isPro] is true while a licence signed by the server, for the signed-in
/// email and not yet expired, is stored on this device. It's refreshed from
/// the server on start and every few days, so Pro keeps working offline.
abstract final class Pro {
  static final log = Logger('Pro');

  static final isPro = ValueNotifier(false);

  /// The licence behind [isPro], if any.
  static final licence = ValueNotifier<Licence?>(null);

  /// Builds that show the paywall's "unlock on this device" switch: debug
  /// builds, and ones made with `--dart-define=PRO_DEV=true`.
  static const devBuild =
      kDebugMode || bool.fromEnvironment('PRO_DEV');

  /// Under `flutter test` everything is unlocked unless a test sets this.
  @visibleForTesting
  static var testFree = false;

  /// Whether Pro things are open right now.
  static bool get has {
    if (isThisATest) return !testFree;
    return isPro.value;
  }

  /// The Google account Pro belongs to here, or null when there's none.
  static String? get account {
    if (!stows.loggedIn) return null;
    if (stows.syncProvider.value != SyncProvider.googleDrive) return null;
    final email = stows.username.value.trim().toLowerCase();
    return email.isEmpty ? null : email;
  }

  static Future<void>? _starting;

  /// Reads the stored licence and checks with the server now and then.
  /// Safe to call more than once: later calls wait for the first.
  static Future<void> init() => _starting ??= _start();

  static Future<void> _start() async {
    await Future.wait([
      stows.username.waitUntilRead(),
      stows.ncPassword.waitUntilRead(),
      stows.encPassword.waitUntilRead(),
      stows.syncProvider.waitUntilRead(),
      stows.proLicence.waitUntilRead(),
      stows.proCheckedMs.waitUntilRead(),
      stows.proDevUnlock.waitUntilRead(),
    ]);
    stows.username.addListener(_accountChanged);
    stows.encPassword.addListener(_accountChanged);
    stows.proDevUnlock.addListener(_recompute);
    await _recompute();
    unawaited(refresh());
  }

  static void _accountChanged() {
    unawaited(_recompute());
    unawaited(refresh(force: true));
  }

  static Future<void> _recompute() async {
    final email = account;
    final stored = stows.proLicence.value;
    final checked = email == null || stored.isEmpty
        ? null
        : await Licence.check(stored, email: email);
    licence.value = checked;
    isPro.value = checked != null || (devBuild && stows.proDevUnlock.value);
  }

  /// A Google access token for the signed-in account, without showing
  /// anything; null when signed out or Google wants the user first.
  static Future<String?> _accessToken() async {
    final email = account;
    if (email == null) return null;
    try {
      return await GoogleDriveStore.silentAccessToken(email);
    } catch (e) {
      log.info('No access token: $e');
      return null;
    }
  }

  /// Asks the server whether this account has Pro, at most every 3 days
  /// unless [force]d. Returns what the server said, or null if it wasn't
  /// asked.
  static Future<LicenceReply?> refresh({bool force = false}) async {
    if (isThisATest) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    const every = Duration(days: 3);
    if (!force &&
        isPro.value &&
        now - stows.proCheckedMs.value < every.inMilliseconds) {
      return null;
    }
    var token = await _accessToken();
    if (token == null) {
      await _recompute();
      return null;
    }
    var reply = await LicenceApi.status(token);
    if (reply case LicenceRefused(code: 'unauthorized')) {
      token = await _accessToken();
      if (token != null) reply = await LicenceApi.status(token);
    }
    switch (reply) {
      case LicenceGranted(:final licence):
        stows.proLicence.value = licence;
        stows.proCheckedMs.value = now;
      case LicenceNone():
        stows.proLicence.value = '';
        stows.proCheckedMs.value = now;
      case LicenceRefused():
        // offline or a server hiccup: keep what's stored until it expires
        break;
    }
    await _recompute();
    return reply;
  }

  /// Stores a licence the server just gave.
  static Future<void> accept(String licenceText) async {
    stows.proLicence.value = licenceText;
    stows.proCheckedMs.value = DateTime.now().millisecondsSinceEpoch;
    await _recompute();
  }

  /// Sends a Play purchase to the server; null on success, else the reply.
  static Future<LicenceRefused?> verifyPlay({
    required String productId,
    required String purchaseToken,
    String? orderId,
  }) async {
    var token = await _accessToken();
    if (token == null) {
      return const LicenceRefused(
        'unauthorized',
        'Sign in with Google to finish activating Pro.',
      );
    }
    Future<LicenceReply> send(String token) => LicenceApi.verifyPlay(
      accessToken: token,
      productId: productId,
      purchaseToken: purchaseToken,
      orderId: orderId,
    );
    var reply = await send(token);
    if (reply case LicenceRefused(code: 'unauthorized')) {
      token = await _accessToken();
      if (token != null) reply = await send(token);
    }
    switch (reply) {
      case LicenceGranted(:final licence):
        await accept(licence);
        return null;
      case LicenceNone():
        return const LicenceRefused(
          'invalid_purchase',
          "This purchase couldn't be checked.",
        );
      case final LicenceRefused refused:
        return refused;
    }
  }

  // -------------------------------------------------------------------
  // Gates
  // -------------------------------------------------------------------

  /// True if Pro is on; otherwise shows the paywall for [feature] and
  /// returns whether Pro is on once it's closed.
  static Future<bool> require(BuildContext context, ProFeature feature) async {
    if (has) return true;
    if (!context.mounted) return false;
    await showPaywall(context, reason: feature);
    return has;
  }

  /// How many notebooks, whiteboards and PDF notes there are (all devices'
  /// notes, as synced here; Trash doesn't count).
  static Future<({int notebooks, int whiteboards, int pdfs})> counts() async {
    await NoteFactsCache.scan();
    var notebooks = 0, whiteboards = 0, pdfs = 0;
    for (final MapEntry(key: path, value: facts)
        in NoteFactsCache.facts.value.entries) {
      if (path == quickWhiteboardPath) continue;
      if (facts.board) {
        whiteboards++;
      } else if (facts.pdf) {
        pdfs++;
      } else {
        notebooks++;
      }
    }
    return (notebooks: notebooks, whiteboards: whiteboards, pdfs: pdfs);
  }

  /// Where the Quick whiteboard is kept (see Whiteboard.filePath).
  static const quickWhiteboardPath = '/_whiteboard';

  /// True if one more notebook may be made, else the paywall.
  static Future<bool> mayAddNotebook(BuildContext context) async {
    if (has) return true;
    final n = await counts();
    if (n.notebooks < ProLimits.notebooks) return true;
    if (!context.mounted) return false;
    return require(context, ProFeature.notebooks);
  }

  /// True if one more whiteboard may be made, else the paywall.
  static Future<bool> mayAddWhiteboard(BuildContext context) async {
    if (has) return true;
    final n = await counts();
    if (n.whiteboards < ProLimits.whiteboards) return true;
    if (!context.mounted) return false;
    return require(context, ProFeature.whiteboards);
  }

  /// True if copies of [paths] stay within the free limits, else the
  /// paywall.
  static Future<bool> mayDuplicate(
    BuildContext context,
    List<String> paths,
  ) async {
    if (has) return true;
    final n = await counts();
    var notebooks = n.notebooks, whiteboards = n.whiteboards, pdfs = n.pdfs;
    for (final path in paths) {
      final facts = NoteFactsCache.facts.value[path];
      if (facts == null) {
        notebooks++;
      } else if (facts.board) {
        whiteboards++;
      } else if (facts.pdf) {
        pdfs++;
      } else {
        notebooks++;
      }
    }
    final over = whiteboards > ProLimits.whiteboards
        ? ProFeature.whiteboards
        : pdfs > ProLimits.pdfs
        ? ProFeature.pdfs
        : notebooks > ProLimits.notebooks
        ? ProFeature.notebooks
        : null;
    if (over == null) return true;
    if (!context.mounted) return false;
    return require(context, over);
  }

  /// True if the PDF at [path] may be brought in, else the paywall.
  static Future<bool> mayAddPdf(BuildContext context, String path) async {
    if (has) return true;
    final n = await counts();
    if (n.pdfs >= ProLimits.pdfs) {
      if (!context.mounted) return false;
      return require(context, ProFeature.pdfs);
    }
    if (!await pdfFitsFree(path)) {
      if (!context.mounted) return false;
      return require(context, ProFeature.bigPdf);
    }
    return true;
  }

  /// Whether the PDF at [path] is within the free size and page limits.
  static Future<bool> pdfFitsFree(String path) async {
    try {
      final file = File(path);
      if (await file.length() > ProLimits.pdfBytes) return false;
      final document = await PdfDocument.openFile(path);
      try {
        return document.pages.length <= ProLimits.pdfPages;
      } finally {
        await document.dispose();
      }
    } catch (e) {
      // can't tell: the editor will say if the file is broken
      log.info('Could not measure PDF $path: $e');
      return true;
    }
  }

  /// True if a row of [current] colours may get one more.
  static Future<bool> mayAddColor(BuildContext context, int current) async {
    if (has || current < ProLimits.colors) return true;
    return require(context, ProFeature.colors);
  }

  /// True if notes may sync by themselves (not only from the cloud button).
  static bool get autoSync => has;
}
