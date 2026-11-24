import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:badnotes/components/settings/update_dialog.dart';
import 'package:badnotes/components/ui/bn_settings.dart';
import 'package:badnotes/data/badnotes_version.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/version.dart' as version;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:open_file/open_file.dart';

/// Looks on GitHub for a newer BadNotes and offers it.
abstract class UpdateManager {
  static final log = Logger('UpdateManager');

  /// The newest version number, as the `version.dart` on the main branch.
  static final Uri versionUrl = Uri.parse(
    'https://raw.githubusercontent.com/benzeneman/badnotes/main/lib/data/version.dart',
  );

  /// The newest release and its files.
  static final Uri apiUrl = Uri.parse(
    'https://api.github.com/repos/benzeneman/badnotes/releases/latest',
  );

  /// Whether there's an update, as far as is known.
  static final ValueNotifier<UpdateStatus> status = ValueNotifier(.upToDate);

  /// The newest build number found, once looked up.
  static int? newestVersion;

  static var _offered = false;

  /// Shows the update dialog: always when the user asked ([userTriggered]),
  /// otherwise once per run, and only if looking for updates is on and an
  /// update is worth telling about.
  static Future<void> showUpdateDialog(
    BuildContext context, {
    bool userTriggered = false,
  }) async {
    // Play Store builds are updated by Play, so nothing is looked up by
    // itself; the old GitHub release feed no longer exists.
    if (!userTriggered) return;
    if (!userTriggered) {
      if (status.value == .upToDate) {
        await stows.shouldCheckForUpdates.waitUntilRead();
        if (!stows.shouldCheckForUpdates.value) return;
        status.value = await _lookUp();
      }
      if (_offered || status.value != .updateRecommended) return;
    }
    if (!context.mounted) return;
    _offered = true;
    await showBnSettingsDialog<void>(
      context: context,
      builder: (context) => const UpdateDialog(),
    );
  }

  static Future<UpdateStatus> _lookUp() async {
    try {
      newestVersion = await getNewestVersion();
    } catch (e, st) {
      log.severe('Failed to check for update: $e', e, st);
      return .upToDate;
    }
    return getUpdateStatus(version.buildNumber, newestVersion ?? 0);
  }

  /// The build number in the newest `version.dart`: the first number in
  /// [latestVersionFile] (fetched from [versionUrl] if not given). Null if
  /// there's none.
  @visibleForTesting
  static Future<int?> getNewestVersion([String? latestVersionFile]) async {
    final text = latestVersionFile ?? await _fetch(versionUrl, 'version.dart');
    final digits = RegExp(r'\d+').firstMatch(text)?[0];
    final number = int.tryParse(digits ?? '') ?? 0;
    return number == 0 ? null : number;
  }

  /// The body at [url], or a [SocketException] naming [what] failed.
  static Future<String> _fetch(Uri url, String what) async {
    final http.Response response;
    try {
      response = await http.get(url);
    } catch (e) {
      throw SocketException('Failed to download $what, $e');
    }
    if (response.statusCode >= 400) {
      throw SocketException(
        'Failed to download $what, HTTP status code ${response.statusCode}',
      );
    }
    return response.body;
  }

  /// How much an update from [currentVersionNumber] to [newestVersionNumber]
  /// matters (revisions don't count). Unless the user wants every update,
  /// a jump of under two patches, or to a x.y.0 that may still have bugs,
  /// isn't worth interrupting for.
  @visibleForTesting
  static UpdateStatus getUpdateStatus(
    int currentVersionNumber,
    int newestVersionNumber,
  ) {
    BadNotesVersion releaseOf(int number) =>
        BadNotesVersion.fromNumber(number).copyWith(revision: 0);
    final current = releaseOf(currentVersionNumber);
    final newest = releaseOf(newestVersionNumber);

    final ahead = newest.buildNumber - current.buildNumber;
    if (ahead <= 0) return .upToDate;
    if (stows.shouldAlwaysAlertForUpdates.value) return .updateRecommended;

    final twoPatches = BadNotesVersion(0, 0, 2).buildNumber;
    if (ahead < twoPatches || newest.patch == 0) return .updateOptional;
    return .updateRecommended;
  }

  /// Where to download the newest release for [platform] (this one by
  /// default), or null where updates come from a store instead or no file
  /// matches. [apiResponse] stands in for the GitHub reply in tests.
  static Future<String?> getLatestDownloadUrl([
    @visibleForTesting String? apiResponse,
    @visibleForTesting TargetPlatform? platform,
  ]) async {
    final fileName = platformFileRegex[platform ?? defaultTargetPlatform];
    if (fileName == null) return null;

    final reply = apiResponse ?? await _fetchRelease();
    final assets =
        (jsonDecode(reply) as Map<String, dynamic>)['assets'] as List;
    for (final asset in assets.cast<Map<String, dynamic>>()) {
      if (fileName.hasMatch(asset['name'])) {
        return asset['browser_download_url'];
      }
    }
    return null;
  }

  static Future<String> _fetchRelease() async {
    final http.Response response;
    try {
      response = await http.get(apiUrl);
    } catch (e) {
      throw const SocketException('Failed to fetch latest release');
    }
    if (response.statusCode >= 400) {
      throw SocketException(
        'Failed to fetch latest release, HTTP status code ${response.statusCode}',
      );
    }
    return response.body;
  }

  /// The release file to download, by platform. The other platforms get
  /// their updates from an app store; only Windows downloads its own.
  static final Map<TargetPlatform, RegExp> platformFileRegex = {
    .windows: RegExp(r'\.exe'),
  };

  /// Downloads the file at [downloadUrl] and opens it to install it.
  static Future<void> directlyDownloadUpdate(
    String downloadUrl, {
    required void Function(TaskStatus)? onStatus,
    required void Function(double)? onProgress,
  }) async {
    final task = DownloadTask(
      url: downloadUrl,
      filename: downloadUrl.split('/').last,
      baseDirectory: BaseDirectory.temporary,
    );
    await FileDownloader().configure(
      globalConfig: [
        (Config.skipExistingFiles, 1),
        (Config.checkAvailableSpace, 1),
      ],
    );
    final result = await FileDownloader().download(
      task,
      onStatus: onStatus,
      onProgress: onProgress,
    );
    if (result.status != TaskStatus.complete) {
      log.severe(
        'Failed to download update from $downloadUrl: '
        '${result.status} ${result.exception} ${result.responseBody}',
      );
      return;
    }
    log.info('Update downloaded successfully: ${result.status}');
    await OpenFile.open(await task.filePath());
  }

  /// What's new in [newestVersion] (the one found, by default), in
  /// [localeCode], or null if there are no notes for it.
  static Future<String?> getChangelog({
    String localeCode = 'en-US',
    @visibleForTesting int? newestVersion,
  }) async {
    newestVersion ??= UpdateManager.newestVersion;
    assert(newestVersion != null);
    final url = Uri.parse(
      'https://raw.githubusercontent.com/benzeneman/badnotes/main/'
      'metadata/$localeCode/changelogs/$newestVersion.txt',
    );
    log.info('Downloading changelog from $url');
    try {
      final response = await http.get(url);
      if (response.statusCode >= 400 || response.body.isEmpty) return null;
      return response.body;
    } catch (e, st) {
      log.severe('Failed to download changelog: $e', e, st);
      return null;
    }
  }
}

enum UpdateStatus {
  /// No newer version, or looking failed.
  upToDate,

  /// There's a newer version, not worth interrupting for.
  updateOptional,

  /// There's a newer version the user should hear about.
  updateRecommended,
}
