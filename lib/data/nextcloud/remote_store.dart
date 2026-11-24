import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/nextcloud/errors.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/quota.dart';
import 'package:badnotes/data/version.dart';

/// A file in the app's folder on the sync server.
class RemoteFile {
  const RemoteFile({
    required this.path,
    this.size,
    this.lastModified,
    this.id,
  });

  /// e.g. `Saber/abc.sbe`, the same for every provider.
  final String path;

  /// 0 means the note was deleted on another device.
  final int? size;
  final DateTime? lastModified;

  /// The provider's id for the file (Google Drive and OneDrive only).
  final String? id;

  String get name => path.substring(path.lastIndexOf('/') + 1);
}

class RemoteNotFound implements Exception {}

/// Google or Microsoft need the user to sign in again.
class CloudAuthRequired implements Exception {}

/// Files in the cloud can't be opened with the key saved on this device,
/// e.g. they were locked on another device with a different password.
class CloudCannotDecrypt implements Exception {
  const new(this.count);

  /// How many cloud files could not be opened.
  final int count;

  @override
  String toString() => '$count cloud files cannot be opened with this key';
}

class CloudHttpException implements Exception {
  CloudHttpException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'CloudHttpException($statusCode): $body';
}

/// Where synced notes live: Google Drive or OneDrive.
abstract class RemoteStore {
  static const rootDirectory = FileManager.remoteRootDirectory;
  static const configFileName = 'config.sbc';
  static const configPath = '$rootDirectory/$configFileName';

  /// Mixed into the encryption password before hashing it.
  /// Never change this, or existing notes can't be decrypted.
  static const reproducibleSalt = r'8MnPs64@R&mF8XjWeLrD';

  static final userAgent =
      'BadNotes/$buildName '
      '(${Platform.operatingSystem}) '
      'Dart/${Platform.version.split(' ').first}';
  static IOClient newHttpClient() =>
      IOClient(HttpClient()..userAgent = userAgent);

  /// Every file in the app's folder.
  Future<Set<RemoteFile>> list();

  /// Fresh details of one file, or null if it doesn't exist.
  Future<RemoteFile?> stat(String path);

  /// Throws [RemoteNotFound] if the file doesn't exist.
  Future<Uint8List> get(String path);

  Future<void> put(Uint8List bytes, String path, {DateTime? lastModified});

  /// How much storage the account has used.
  Future<Quota> quota();

  /// Saves [bytes] as [name] in a separate folder the user can open and share
  /// from, unencrypted. Replaces the file of that name if there is one.
  /// Returns false if this store can't.
  Future<bool> putReadable(
    Uint8List bytes,
    String name, {
    String mimeType = 'application/pdf',
    String? folder,
  });

  static RemoteStore? fromSavedDetails() {
    if (!stows.loggedIn) return null;
    return forLinkedAccount();
  }

  /// The store of the linked cloud account, before the notes password is
  /// known (enough to look for the encryption config). Null with no account.
  static RemoteStore? forLinkedAccount() {
    final account = stows.username.value;
    if (account.isEmpty || stows.ncPassword.value.isEmpty) return null;
    return switch (stows.syncProvider.value) {
      .googleDrive => GoogleDriveStore(account),
      .oneDrive => OneDriveStore(account),
    };
  }
}

/// Shared code for Google Drive and OneDrive.
///
/// Keeps an index of the remote folder and only asks the server what changed
/// since the last sync, so a refresh costs one small request.
abstract class _CloudStore implements RemoteStore {
  _CloudStore(this.provider, this.account) {
    _loadIndex();
  }

  final SyncProvider provider;

  /// The user's email address.
  final String account;

  final _http = RemoteStore.newHttpClient();

  /// The provider's delta token, or null to list everything.
  String? _cursor;

  /// The provider's id of the app folder (Google Drive only).
  String? _rootId;

  /// Remote files by name.
  final _files = <String, RemoteFile>{};

  /// Set when the app folder (or its config file) was deleted remotely.
  /// The next [list] then throws [RemoteNotFound] so the syncer
  /// re-uploads the config and every note.
  var _folderLost = false;

  void _loseFolder() {
    _rootId = null;
    _cursor = null;
    _files.clear();
    _folderLost = true;
  }

  Future<({int used, int total})> _usage();

  @override
  Future<bool> putReadable(
    Uint8List bytes,
    String name, {
    String mimeType = 'application/pdf',
    String? folder,
  }) async => false;

  @override
  Future<Quota> quota() async {
    final (:used, :total) = await _usage();
    return Quota(QuotaRaw(used: used, total: total));
  }

  Future<String> accessToken({bool forceRefresh = false});

  /// Applies the changes since [cursor] (or everything if null) to [_files]
  /// and returns the next cursor.
  Future<String> _pullChanges(String? cursor);

  /// Asks the server about [name]. Throws [RemoteNotFound] if missing.
  Future<RemoteFile> _fetch(String name);

  Future<Uint8List> _download(String id);

  /// Creates or replaces [name] and returns the new remote file.
  Future<RemoteFile> _upload(
    String name,
    String? id,
    Uint8List bytes,
    DateTime lastModified,
  );

  RemoteFile _file(String name, String id, int size, DateTime lastModified) =>
      RemoteFile(
        path: '${RemoteStore.rootDirectory}/$name',
        id: id,
        size: size,
        lastModified: lastModified,
      );

  void _removeId(String id) => _files.removeWhere((_, f) => f.id == id);

  static String _nameOf(String path) => path.substring(path.lastIndexOf('/') + 1);

  /// RFC 3339 with milliseconds, which both APIs accept.
  static String _rfc3339(DateTime date) => DateTime.fromMillisecondsSinceEpoch(
    date.millisecondsSinceEpoch,
    isUtc: true,
  ).toIso8601String();

  void _loadIndex() {
    try {
      final state = jsonDecode(stows.cloudSyncState.value);
      if (state['provider'] != provider.name || state['account'] != account) {
        return;
      }
      _cursor = state['cursor'] as String?;
      _rootId = state['root'] as String?;
      for (final f in state['files'] as List) {
        final name = f[0] as String;
        _files[name] = _file(
          name,
          f[1] as String,
          f[2] as int,
          DateTime.fromMillisecondsSinceEpoch(f[3] as int, isUtc: true),
        );
      }
    } catch (_) {
      // No saved index (or a broken one): list everything on the next sync
      _cursor = null;
      _files.clear();
    }
  }

  void _saveIndex() {
    stows.cloudSyncState.value = jsonEncode({
      'provider': provider.name,
      'account': account,
      'cursor': _cursor,
      'root': _rootId,
      'files': [
        for (final f in _files.values)
          [f.name, f.id, f.size, f.lastModified!.millisecondsSinceEpoch],
      ],
    });
  }

  @override
  Future<Set<RemoteFile>> list() async {
    final configName = _nameOf(RemoteStore.configPath);
    final hadConfig = _files.containsKey(configName);
    try {
      _cursor = await _pullChanges(_cursor);
    } on CloudHttpException catch (e) {
      // An expired delta token: start over with a full listing
      if (_cursor == null || (e.statusCode != 400 && e.statusCode != 410)) {
        rethrow;
      }
      _files.clear();
      _cursor = await _pullChanges(null);
    }
    if (hadConfig && !_files.containsKey(configName)) _folderLost = true;
    _saveIndex();
    stows.syncNeedsLogin.value = false;
    if (_folderLost) {
      _folderLost = false;
      throw RemoteNotFound();
    }
    return _files.values.toSet();
  }

  @override
  Future<RemoteFile?> stat(String path) async {
    final name = _nameOf(path);
    try {
      return _files[name] = await _fetch(name);
    } on RemoteNotFound {
      _files.remove(name);
      return null;
    }
  }

  @override
  Future<Uint8List> get(String path) async {
    final cachedId = _files[_nameOf(path)]?.id;
    if (cachedId != null) {
      try {
        return await _download(cachedId);
      } on RemoteNotFound {
        // The file was replaced since we listed it
      }
    }
    final file = await stat(path);
    if (file == null) throw RemoteNotFound();
    return _download(file.id!);
  }

  @override
  Future<void> put(
    Uint8List bytes,
    String path, {
    DateTime? lastModified,
  }) async {
    final name = _nameOf(path);
    lastModified ??= DateTime.now();
    RemoteFile file;
    final cachedId = _files[name]?.id;
    try {
      file = await _upload(name, cachedId, bytes, lastModified);
    } on RemoteNotFound {
      if (cachedId == null) {
        // Creating failed, so the app folder itself is gone
        _loseFolder();
      } else {
        // Our cached id is stale
        _files.remove(name);
      }
      file = await _upload(name, null, bytes, lastModified);
    }
    _files[name] = file;
    _saveIndex();
  }

  /// Sends an authorized request. Retries once with a fresh token on 401.
  Future<http.Response> _send(
    String method,
    Uri url, {
    Object? body,
    Map<String, String>? headers,
    bool auth = true,
    bool followRedirects = true,
  }) async {
    for (var attempt = 0; ; attempt++) {
      final request = http.Request(method, url)
        ..followRedirects = followRedirects;
      if (headers != null) request.headers.addAll(headers);
      if (auth) {
        final String token;
        try {
          token = await accessToken(forceRefresh: attempt > 0);
        } on CloudAuthRequired {
          stows.syncNeedsLogin.value = true;
          rethrow;
        }
        request.headers['Authorization'] = 'Bearer $token';
      }
      switch (body) {
        case Uint8List bytes:
          request.bodyBytes = bytes;
        case Map json:
          request.headers['Content-Type'] = 'application/json; charset=utf-8';
          request.body = jsonEncode(json);
      }

      final response = await http.Response.fromStream(
        await _http.send(request),
      );
      if (response.statusCode == HttpStatus.unauthorized && auth) {
        if (attempt == 0) continue;
        // Still refused with a fresh token: access was revoked
        stows.syncNeedsLogin.value = true;
        throw CloudAuthRequired();
      }
      if (response.statusCode == HttpStatus.notFound) throw RemoteNotFound();
      if (response.statusCode >= 400) {
        throw CloudHttpException(response.statusCode, response.body);
      }
      return response;
    }
  }

  Future<Map<String, dynamic>> _json(
    String method,
    Uri url, {
    Object? body,
  }) async {
    final response = await _send(method, url, body: body);
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}

class GoogleDriveStore extends _CloudStore {
  GoogleDriveStore(String account) : super(.googleDrive, account);

  /// Only the files BadNotes creates, so no Google security audit is needed.
  static const scopes = ['https://www.googleapis.com/auth/drive.file'];
  static const folderName = 'BadNotes';
  static const _api = 'https://www.googleapis.com/drive/v3';
  static const _uploadApi = 'https://www.googleapis.com/upload/drive/v3';
  static const _fileFields = 'id,name,size,modifiedTime,trashed,parents';

  /// [GoogleSignIn.initialize] must run exactly once per isolate.
  static final _initialized = GoogleSignIn.instance.initialize();

  static Future<String?> _authorize(String? email, {required bool prompt}) async {
    await _initialized;
    final tokens = await GoogleSignInPlatform.instance
        .clientAuthorizationTokensForScopes(
          ClientAuthorizationTokensForScopesParameters(
            request: AuthorizationRequestDetails(
              scopes: scopes,
              userId: null,
              email: email,
              promptIfUnauthorized: prompt,
            ),
          ),
        );
    return tokens?.accessToken;
  }

  /// The picture of the account [login] last signed in, if it has one.
  static Uint8List? lastPhoto;

  /// Shows Google's account picker and returns the chosen email.
  static Future<String> login() async {
    lastPhoto = null;
    final token = await _authorize(null, prompt: true);
    if (token == null) throw CloudAuthRequired();
    final response = await http.get(
      Uri.parse('$_api/about?fields=user(emailAddress,photoLink)'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != HttpStatus.ok) {
      throw CloudHttpException(response.statusCode, response.body);
    }
    final user = jsonDecode(response.body)['user'] as Map;
    lastPhoto = await _fetchPhoto(user['photoLink'] as String?);
    return user['emailAddress'] as String;
  }

  /// The profile picture at [link], or null if there is none or it can't be
  /// fetched (the avatar then shows the account's letter).
  static Future<Uint8List?> _fetchPhoto(String? link) async {
    if (link == null || link.isEmpty) return null;
    try {
      final sized = link.replaceFirst(RegExp(r'=s\d+(-c)?$'), '=s128-c');
      final response = await http
          .get(Uri.parse(sized))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != HttpStatus.ok) return null;
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  String? _token;

  @override
  Future<String> accessToken({bool forceRefresh = false}) async {
    if (forceRefresh && _token != null) {
      await _initialized;
      await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(
        accessToken: _token!,
      );
      _token = null;
    }
    return _token ??= await _authorize(account, prompt: false) ??
        (throw CloudAuthRequired());
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_api$path').replace(queryParameters: query);

  RemoteFile _toRemoteFile(Map file) => _file(
    file['name'] as String,
    file['id'] as String,
    int.parse(file['size'] as String? ?? '0'),
    DateTime.parse(file['modifiedTime'] as String),
  );

  void _apply(Map file) {
    final parents = file['parents'] as List? ?? const [];
    if (file['trashed'] == true || !parents.contains(_rootId)) {
      _removeId(file['id'] as String);
    } else {
      _files[file['name'] as String] = _toRemoteFile(file);
    }
  }

  /// Where readable copies go: next to the app's folder, so syncing never
  /// sees them as notes.
  static const readableFolderName = 'BadNotes PDFs';
  static const backupFolderName = 'BadNotes Backups';
  final _readableFolderIds = <String, String>{};

  Future<String> _readableFolder(String name) async {
    if (_readableFolderIds[name] case final id?) return id;
    final found = await _json(
      'GET',
      _uri('/files', {
        'q':
            "name='$name' and "
            "mimeType='application/vnd.google-apps.folder' and "
            "'root' in parents and trashed=false",
        'fields': 'files(id)',
      }),
    );
    final folders = found['files'] as List;
    if (folders.isNotEmpty) {
      return _readableFolderIds[name] = folders.first['id'] as String;
    }
    final created = await _json(
      'POST',
      _uri('/files', {'fields': 'id'}),
      body: {'name': name, 'mimeType': 'application/vnd.google-apps.folder'},
    );
    return _readableFolderIds[name] = created['id'] as String;
  }

  @override
  Future<bool> putReadable(
    Uint8List bytes,
    String name, {
    String mimeType = 'application/pdf',
    String? folder,
  }) async {
    final folderId = await _readableFolder(folder ?? readableFolderName);
    final escaped = name.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    final found = await _json(
      'GET',
      _uri('/files', {
        'q': "name='$escaped' and '$folderId' in parents and trashed=false",
        'fields': 'files(id)',
      }),
    );
    final existing = (found['files'] as List).firstOrNull?['id'] as String?;
    final session = await _send(
      existing == null ? 'POST' : 'PATCH',
      Uri.parse(
        '$_uploadApi/files${existing == null ? '' : '/$existing'}',
      ).replace(queryParameters: {'uploadType': 'resumable', 'fields': 'id'}),
      body: {
        'mimeType': mimeType,
        if (existing == null) ...{'name': name, 'parents': [folderId]},
      },
    );
    await _send('PUT', Uri.parse(session.headers['location']!), body: bytes);
    return true;
  }

  /// Finds or creates the visible "BadNotes" folder in the user's Drive.
  Future<String> _folder() async {
    if (_rootId != null) return _rootId!;
    final found = await _json(
      'GET',
      _uri('/files', {
        'q':
            "name='$folderName' and "
            "mimeType='application/vnd.google-apps.folder' and "
            "'root' in parents and trashed=false",
        'fields': 'files(id)',
      }),
    );
    final folders = found['files'] as List;
    if (folders.isNotEmpty) return _rootId = folders.first['id'] as String;

    final created = await _json(
      'POST',
      _uri('/files', {'fields': 'id'}),
      body: {
        'name': folderName,
        'mimeType': 'application/vnd.google-apps.folder',
      },
    );
    return _rootId = created['id'] as String;
  }

  @override
  Future<String> _pullChanges(String? cursor) async {
    final folder = await _folder();

    if (cursor == null) {
      final start = await _json('GET', _uri('/changes/startPageToken'));
      _files.clear();
      String? page;
      do {
        final result = await _json(
          'GET',
          _uri('/files', {
            'q': "'$folder' in parents and trashed=false",
            'fields': 'nextPageToken,files($_fileFields)',
            'pageSize': '1000',
            'pageToken': ?page,
          }),
        );
        for (final file in result['files'] as List) {
          _apply(file as Map);
        }
        page = result['nextPageToken'] as String?;
      } while (page != null);
      return start['startPageToken'] as String;
    }

    var token = cursor;
    while (true) {
      final result = await _json(
        'GET',
        _uri('/changes', {
          'pageToken': token,
          'pageSize': '1000',
          'fields':
              'nextPageToken,newStartPageToken,'
              'changes(fileId,removed,file($_fileFields))',
        }),
      );
      for (final change in result['changes'] as List) {
        final file = change['file'] as Map?;
        final gone =
            change['removed'] == true || file == null || file['trashed'] == true;
        if (gone && change['fileId'] == _rootId) {
          // The user deleted the BadNotes folder: find or make a new one
          _loseFolder();
          return _pullChanges(null);
        }
        if (change['removed'] == true || file == null) {
          _removeId(change['fileId'] as String);
        } else {
          _apply(file);
        }
      }
      if (result['newStartPageToken'] case final String next) return next;
      token = result['nextPageToken'] as String;
    }
  }

  @override
  Future<RemoteFile> _fetch(String name) async {
    final result = await _json(
      'GET',
      _uri('/files', {
        'q': "name='$name' and '${await _folder()}' in parents and trashed=false",
        'fields': 'files($_fileFields)',
      }),
    );
    final files = result['files'] as List;
    if (files.isEmpty) throw RemoteNotFound();
    return _toRemoteFile(files.first as Map);
  }

  @override
  Future<Uint8List> _download(String id) async =>
      (await _send('GET', _uri('/files/$id', {'alt': 'media'}))).bodyBytes;

  @override
  Future<({int used, int total})> _usage() async {
    final result = await _json(
      'GET',
      _uri('/about', {'fields': 'storageQuota(limit,usage)'}),
    );
    final quota = result['storageQuota'] as Map;
    return (
      used: int.parse(quota['usage'] as String),
      // No limit means unlimited storage
      total: int.parse(quota['limit'] as String? ?? '-1'),
    );
  }

  @override
  Future<RemoteFile> _upload(
    String name,
    String? id,
    Uint8List bytes,
    DateTime lastModified,
  ) async {
    // Another device may have created it since our last listing.
    // Drive allows duplicate names, so look before creating.
    if (id == null) {
      try {
        id = (await _fetch(name)).id;
      } on RemoteNotFound {
        // A new file
      }
    }

    // Resumable upload: one request for the metadata, one for the bytes.
    // Works for any file size.
    final session = await _send(
      id == null ? 'POST' : 'PATCH',
      Uri.parse(
        '$_uploadApi/files${id == null ? '' : '/$id'}',
      ).replace(
        // Drive only honours `fields` on the request that starts the upload
        queryParameters: {'uploadType': 'resumable', 'fields': _fileFields},
      ),
      body: {
        'modifiedTime': _CloudStore._rfc3339(lastModified),
        if (id == null) ...{
          'name': name,
          'parents': [await _folder()],
        },
      },
    );
    final location = session.headers['location']!;
    final uploaded = await _send('PUT', Uri.parse(location), body: bytes);
    final file = jsonDecode(uploaded.body) as Map;
    if (file['modifiedTime'] != null) return _toRemoteFile(file);
    // Drive sent a short reply (just id and name): ask for the rest
    return _toRemoteFile(
      await _json('GET', _uri('/files/${file['id']}', {'fields': _fileFields})),
    );
  }
}

class OneDriveStore extends _CloudStore {
  OneDriveStore(String account) : super(.oneDrive, account);

  /// From the Azure app registration, set at build time with
  /// `--dart-define=ONEDRIVE_CLIENT_ID=...`.
  static const clientId = String.fromEnvironment('ONEDRIVE_CLIENT_ID');
  static bool get isConfigured => clientId.isNotEmpty;

  static const _callbackScheme = 'com.badnotes.app';
  static const _redirectUri = '$_callbackScheme://auth';

  /// Only the app's own folder (OneDrive/Apps/BadNotes).
  static const _scope = 'Files.ReadWrite.AppFolder User.Read offline_access';
  static const _authApi = 'https://login.microsoftonline.com/common/oauth2/v2.0';
  static const _driveApi = 'https://graph.microsoft.com/v1.0/me/drive';
  static const _itemFields = 'id,name,size,file,deleted,fileSystemInfo';

  static Future<Map<String, dynamic>> _tokenRequest(
    Map<String, String> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_authApi/token'),
      body: {'client_id': clientId, 'scope': _scope, ...body},
    );
    if (response.statusCode != HttpStatus.ok) {
      if (response.statusCode == HttpStatus.badRequest &&
          response.body.contains('invalid_grant')) {
        throw CloudAuthRequired();
      }
      throw CloudHttpException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Opens Microsoft's sign-in page (OAuth with PKCE).
  static Future<({String email, String refreshToken})> login() async {
    final random = Random.secure();
    final verifier = base64UrlEncode([
      for (var i = 0; i < 48; i++) random.nextInt(256),
    ]).replaceAll('=', '');
    final challenge = base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');

    final result = await FlutterWebAuth2.authenticate(
      url: Uri.parse('$_authApi/authorize').replace(
        queryParameters: {
          'client_id': clientId,
          'response_type': 'code',
          'redirect_uri': _redirectUri,
          'scope': _scope,
          'code_challenge': challenge,
          'code_challenge_method': 'S256',
          'prompt': 'select_account',
        },
      ).toString(),
      callbackUrlScheme: _callbackScheme,
    );
    final query = Uri.parse(result).queryParameters;
    final code = query['code'];
    if (code == null) {
      throw Exception(query['error_description'] ?? 'Login cancelled');
    }

    final tokens = await _tokenRequest({
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': _redirectUri,
      'code_verifier': verifier,
    });
    final me = await http.get(
      Uri.parse(r'https://graph.microsoft.com/v1.0/me?$select=mail,userPrincipalName'),
      headers: {'Authorization': 'Bearer ${tokens['access_token']}'},
    );
    final user = jsonDecode(me.body) as Map;
    return (
      email: (user['mail'] ?? user['userPrincipalName']) as String,
      refreshToken: tokens['refresh_token'] as String,
    );
  }

  String? _token;
  var _tokenExpiry = DateTime(0);

  @override
  Future<String> accessToken({bool forceRefresh = false}) async {
    if (!forceRefresh && _token != null && DateTime.now().isBefore(_tokenExpiry)) {
      return _token!;
    }
    // The refresh token is kept in stows.ncPassword
    final tokens = await _tokenRequest({
      'grant_type': 'refresh_token',
      'refresh_token': stows.ncPassword.value,
    });
    if (tokens['refresh_token'] case final String refreshToken) {
      stows.ncPassword.value = refreshToken;
    }
    _tokenExpiry = DateTime.now().add(
      Duration(seconds: (tokens['expires_in'] as int) - 60),
    );
    return _token = tokens['access_token'] as String;
  }

  String _itemPath(String name) =>
      '$_driveApi/special/approot:/${Uri.encodeComponent(name)}';

  RemoteFile _toRemoteFile(Map item) => _file(
    item['name'] as String,
    item['id'] as String,
    item['size'] as int? ?? 0,
    DateTime.parse(
      (item['fileSystemInfo'] as Map?)?['lastModifiedDateTime'] as String? ??
          item['lastModifiedDateTime'] as String,
    ),
  );

  @override
  Future<String> _pullChanges(String? cursor) async {
    if (cursor == null) _files.clear();
    var url =
        cursor ?? '$_driveApi/special/approot/delta?\$select=$_itemFields';
    while (true) {
      final result = await _json('GET', Uri.parse(url));
      for (final item in result['value'] as List) {
        if (item['deleted'] != null) {
          _removeId(item['id'] as String);
        } else if (item['file'] != null) {
          _files[item['name'] as String] = _toRemoteFile(item as Map);
        }
      }
      if (result['@odata.deltaLink'] case final String deltaLink) {
        return deltaLink;
      }
      url = result['@odata.nextLink'] as String;
    }
  }

  @override
  Future<({int used, int total})> _usage() async {
    final result = await _json('GET', Uri.parse('$_driveApi?\$select=quota'));
    final quota = result['quota'] as Map;
    return (used: quota['used'] as int, total: quota['total'] as int);
  }

  @override
  Future<RemoteFile> _fetch(String name) async => _toRemoteFile(
    await _json('GET', Uri.parse('${_itemPath(name)}?\$select=$_itemFields')),
  );

  @override
  Future<Uint8List> _download(String id) async {
    // Graph redirects to a pre-signed URL, which mustn't get our token
    final response = await _send(
      'GET',
      Uri.parse('$_driveApi/items/$id/content'),
      followRedirects: false,
    );
    final location = response.headers['location'];
    if (location == null) return response.bodyBytes;
    return (await _send('GET', Uri.parse(location), auth: false)).bodyBytes;
  }

  @override
  Future<RemoteFile> _upload(
    String name,
    String? id,
    Uint8List bytes,
    DateTime lastModified,
  ) async {
    final fileSystemInfo = {
      'fileSystemInfo': {
        'lastModifiedDateTime': _CloudStore._rfc3339(lastModified),
      },
    };

    // Small files: upload, then set the date
    if (bytes.length <= 4 << 20) {
      final item = await _json(
        'PUT',
        Uri.parse('${_itemPath(name)}:/content'),
        body: bytes,
      );
      return _toRemoteFile(
        await _json(
          'PATCH',
          Uri.parse('$_driveApi/items/${item['id']}'),
          body: fileSystemInfo,
        ),
      );
    }

    // Big files need an upload session
    final session = await _json(
      'POST',
      Uri.parse('${_itemPath(name)}:/createUploadSession'),
      body: {
        'item': {
          '@microsoft.graph.conflictBehavior': 'replace',
          ...fileSystemInfo,
        },
      },
    );
    final uploadUrl = Uri.parse(session['uploadUrl'] as String);
    // Each chunk must be a multiple of 320 KiB and at most 60 MiB
    const chunkSize = 320 * 1024 * 192;
    late http.Response response;
    for (var start = 0; start < bytes.length; start += chunkSize) {
      final end = min(start + chunkSize, bytes.length);
      response = await _send(
        'PUT',
        uploadUrl,
        auth: false,
        headers: {'Content-Range': 'bytes $start-${end - 1}/${bytes.length}'},
        body: Uint8List.sublistView(bytes, start, end),
      );
    }
    return _toRemoteFile(jsonDecode(response.body) as Map);
  }
}

/// Opens Google's or Microsoft's sign-in.
abstract final class CloudLogin {
  /// The credential goes in [stows.ncPassword]:
  /// the OneDrive refresh token, or `google` for Google Drive.
  static Future<({String email, String credential})> signIn(
    SyncProvider provider,
  ) async => switch (provider) {
    .googleDrive => (
      email: await GoogleDriveStore.login(),
      credential: 'google',
    ),
    .oneDrive => await OneDriveStore.login().then(
      (r) => (email: r.email, credential: r.refreshToken),
    ),
  };

  /// Whether [error] just means the user closed the sign-in screen.
  static bool isCancelled(Object error) =>
      (error is PlatformException && error.code == 'CANCELED') ||
      (error is GoogleSignInException &&
          error.code == GoogleSignInExceptionCode.canceled);
}

/// The notes encryption key lives in a config file next to the notes,
/// itself encrypted with the user's encryption password.
extension RemoteStoreConfig on RemoteStore {
  Future<Map<String, String>> getConfig() async {
    final Uint8List bytes;
    try {
      bytes = await get(RemoteStore.configPath);
    } on RemoteNotFound {
      return {};
    }
    final json = utf8.decode(bytes, allowMalformed: true);
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.cast<String, String>();
  }

  /// Generates a config using known values (i.e. from [stows]),
  /// updating the given [config] in place.
  ///
  /// This is usually preceded by a call to [getConfig]
  /// and followed by a call to [setConfig].
  Future<Map<String, String>> generateConfig({
    required Map<String, String> config,
    Encrypter? encrypter,
    IV? iv,
    Key? key,
  }) async {
    encrypter ??= this.encrypter;
    iv ??= IV.fromBase64(stows.iv.value);
    key ??= Key.fromBase64(stows.key.value);

    config[stows.key.key] = encrypter.encrypt(key.base64, iv: iv).base64;
    config[stows.iv.key] = iv.base64;

    return config;
  }

  Future<void> setConfig(Map<String, String> config) => put(
    Uint8List.fromList(utf8.encode(jsonEncode(config))),
    RemoteStore.configPath,
  );

  Future<String> loadEncryptionKey({bool generateKeyIfMissing = true}) async {
    final Encrypter encrypter = this.encrypter;

    final Map<String, String> config = await getConfig();
    if (config.containsKey(stows.key.key) && config.containsKey(stows.iv.key)) {
      final IV iv = IV.fromBase64(config[stows.iv.key]!);
      final encryptedKey = config[stows.key.key]!;
      try {
        final key = encrypter.decrypt64(encryptedKey, iv: iv);
        stows.key.value = key;
        stows.iv.value = iv.base64;
        return key;
      } catch (e) {
        // can't decrypt, so we need to get the previous encryption key (user's password)
        throw EncLoginFailure();
      }
    }

    if (!generateKeyIfMissing) throw EncLoginFailure();

    final Key key = Key.fromSecureRandom(32);
    final IV iv = IV.fromSecureRandom(16);

    await generateConfig(
      config: config,
      encrypter: encrypter,
      iv: iv,
      key: key,
    );
    await setConfig(config);

    stows.key.value = key.base64;
    stows.iv.value = iv.base64;

    return key.base64;
  }

  Encrypter get encrypter {
    final List<int> encodedPassword = utf8.encode(
      stows.encPassword.value + RemoteStore.reproducibleSalt,
    );
    final hashedPasswordBytes = Uint8List.fromList(
      sha256.convert(encodedPassword).bytes,
    );
    return Encrypter(AES(Key(hashedPasswordBytes)));
  }
}
