import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// A BadNotes Pro licence as the licence server signs it:
/// `base64url(payload) "." base64url(Ed25519 signature of the payload)`,
/// without padding. The payload is `{email, pro, src, iat, exp}`.
class Licence {
  const new({
    required this.email,
    required this.source,
    required this.issued,
    required this.expires,
  });

  final String email;

  /// Where it was bought: `play`, `play-test`, `manual`, …
  final String source;
  final DateTime issued, expires;

  /// The server's public key, base64. A build can swap it with
  /// `--dart-define=LICENCE_PUBKEY=…`.
  static const publicKey = String.fromEnvironment(
    'LICENCE_PUBKEY',
    defaultValue: 'EJxtuey9KnMt2fc0a2BMlz7BSJZ6EIZv8DPYYyUP2YY=',
  );

  /// The licence in [text] if its signature is good, it belongs to [email]
  /// and it hasn't run out at [now]; otherwise null.
  static Future<Licence?> check(
    String text, {
    required String email,
    DateTime? now,
    String key = publicKey,
  }) async {
    try {
      final parts = text.split('.');
      if (parts.length != 2) return null;
      final payload = base64Url.decode(base64Url.normalize(parts[0]));
      final signature = base64Url.decode(base64Url.normalize(parts[1]));
      final good = await Ed25519().verify(
        payload,
        signature: Signature(
          signature,
          publicKey: SimplePublicKey(
            base64.decode(key),
            type: KeyPairType.ed25519,
          ),
        ),
      );
      if (!good) return null;
      final json = jsonDecode(utf8.decode(payload));
      if (json is! Map || json['pro'] != true) return null;
      final owner = (json['email'] as String? ?? '').toLowerCase();
      if (owner.isEmpty || owner != email.trim().toLowerCase()) return null;
      final licence = Licence(
        email: owner,
        source: json['src'] as String? ?? '',
        issued: DateTime.fromMillisecondsSinceEpoch(
          (json['iat'] as num).toInt() * 1000,
        ),
        expires: DateTime.fromMillisecondsSinceEpoch(
          (json['exp'] as num).toInt() * 1000,
        ),
      );
      if (!(now ?? DateTime.now()).isBefore(licence.expires)) return null;
      return licence;
    } catch (_) {
      return null;
    }
  }
}
