import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// What the licence server said.
sealed class LicenceReply {
  const LicenceReply();
}

/// Pro, with a fresh signed [licence].
class LicenceGranted extends LicenceReply {
  const new(this.licence);
  final String licence;
}

/// No Pro for this account.
class LicenceNone extends LicenceReply {
  const new();
}

/// The server turned it down: [code] is one of `unauthorized`,
/// `invalid_purchase`, `refunded`, `pending`, `other_account`, `not_ready`,
/// `slow_down`, `server_error`; [message] is for people.
class LicenceRefused extends LicenceReply {
  const new(this.code, this.message, {this.status = 0});
  final String code, message;
  final int status;

  /// Worth trying again later with the same purchase.
  bool get retryLater =>
      code == 'not_ready' ||
      code == 'slow_down' ||
      code == 'server_error' ||
      code == 'pending' ||
      code == 'offline';
}

/// The two calls to https://api.badnotes.space (see the server's README).
abstract final class LicenceApi {
  static const _configured = String.fromEnvironment('LICENCE_API');
  static String get base =>
      _configured.isEmpty ? 'https://api.badnotes.space' : _configured;

  /// Swapped in tests.
  static http.Client client = http.Client();

  /// Whether [accessToken]'s account has Pro.
  static Future<LicenceReply> status(String accessToken) =>
      _post('/v1/status', {'accessToken': accessToken});

  /// Records a Google Play purchase for [accessToken]'s account.
  static Future<LicenceReply> verifyPlay({
    required String accessToken,
    required String productId,
    required String purchaseToken,
    String? orderId,
  }) => _post('/v1/play/verify', {
    'accessToken': accessToken,
    'productId': productId,
    'purchaseToken': purchaseToken,
    'orderId': ?orderId,
  });

  static Future<LicenceReply> _post(String path, Map<String, Object> body) async {
    final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse('$base$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      return const LicenceRefused(
        'offline',
        "Couldn't reach BadNotes. Check your connection.",
      );
    }
    Map<String, Object?> json;
    try {
      json = (jsonDecode(response.body) as Map).cast<String, Object?>();
    } catch (_) {
      json = const {};
    }
    if (response.statusCode == 200) {
      final licence = json['licence'];
      if (json['pro'] == true && licence is String) {
        return LicenceGranted(licence);
      }
      return const LicenceNone();
    }
    return LicenceRefused(
      json['error'] as String? ?? 'server_error',
      json['message'] as String? ?? 'Something went wrong. Try again later.',
      status: response.statusCode,
    );
  }
}
