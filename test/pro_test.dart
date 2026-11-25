import 'dart:convert';

import 'package:badnotes/components/home/cover_designs.dart';
import 'package:badnotes/data/pro/licence.dart';
import 'package:badnotes/data/pro/pro.dart';
import 'package:badnotes/data/pro/pro_billing.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

/// Signs [payload] the way the licence server does.
Future<String> _sign(SimpleKeyPair keys, Map<String, Object> payload) async {
  final bytes = utf8.encode(jsonEncode(payload));
  final signature = await Ed25519().sign(bytes, keyPair: keys);
  String b64(List<int> raw) => base64Url.encode(raw).replaceAll('=', '');
  return '${b64(bytes)}.${b64(signature.bytes)}';
}

void main() {
  late SimpleKeyPair keys;
  late String publicKey;
  final now = DateTime.utc(2026, 11, 25, 12);
  int secs(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

  setUpAll(() async {
    keys = await Ed25519().newKeyPair();
    publicKey = base64.encode((await keys.extractPublicKey()).bytes);
  });

  Map<String, Object> payload({
    String email = 'someone@gmail.com',
    Duration left = const Duration(days: 30),
  }) => {
    'email': email,
    'pro': true,
    'src': 'play',
    'iat': secs(now),
    'exp': secs(now.add(left)),
  };

  group('Licence.check', () {
    test('a good licence for the signed-in email passes', () async {
      final text = await _sign(keys, payload());
      final licence = await Licence.check(
        text,
        email: 'Someone@Gmail.com',
        now: now,
        key: publicKey,
      );
      expect(licence, isNotNull);
      expect(licence!.email, 'someone@gmail.com');
      expect(licence.source, 'play');
    });

    test("another account's licence fails", () async {
      final text = await _sign(keys, payload(email: 'other@gmail.com'));
      expect(
        await Licence.check(
          text,
          email: 'someone@gmail.com',
          now: now,
          key: publicKey,
        ),
        isNull,
      );
    });

    test('an expired licence fails', () async {
      final text = await _sign(keys, payload(left: const Duration(days: -1)));
      expect(
        await Licence.check(
          text,
          email: 'someone@gmail.com',
          now: now,
          key: publicKey,
        ),
        isNull,
      );
    });

    test('a licence signed by another key fails', () async {
      final otherKeys = await Ed25519().newKeyPair();
      final text = await _sign(otherKeys, payload());
      expect(
        await Licence.check(
          text,
          email: 'someone@gmail.com',
          now: now,
          key: publicKey,
        ),
        isNull,
      );
    });

    test('a changed payload fails', () async {
      final text = await _sign(keys, payload());
      final signature = text.split('.').last;
      final forged = base64Url
          .encode(utf8.encode(jsonEncode(payload(email: 'me@gmail.com'))))
          .replaceAll('=', '');
      expect(
        await Licence.check(
          '$forged.$signature',
          email: 'me@gmail.com',
          now: now,
          key: publicKey,
        ),
        isNull,
      );
    });

    test('garbage fails without throwing', () async {
      for (final text in ['', 'abc', 'a.b', '...', 'eyJ9.eyJ9']) {
        expect(
          await Licence.check(
            text,
            email: 'someone@gmail.com',
            now: now,
            key: publicKey,
          ),
          isNull,
        );
      }
    });

    test("the app ships the server's public key", () {
      expect(base64.decode(Licence.publicKey), hasLength(32));
    });
  });

  group('limits', () {
    test('the first four plain covers are free, designs are not', () {
      for (final color in CoverDesign.solidColors.take(4)) {
        expect(ProLimits.isFreeCover(CoverDesign.solid(color)), isTrue);
      }
      expect(
        ProLimits.isFreeCover(CoverDesign.solid(CoverDesign.solidColors[5])),
        isFalse,
      );
      expect(ProLimits.isFreeCover(CoverDesign.standard), isFalse);
      expect(ProLimits.isFreeCover(ProLimits.freeDefaultCover), isTrue);
      expect(ProLimits.isFreeCover(null), isTrue);
    });

    test('the numbers agreed for the free version', () {
      expect(ProLimits.notebooks, 5);
      expect(ProLimits.whiteboards, 1);
      expect(ProLimits.pdfs, 5);
      expect(ProLimits.pdfPages, 30);
      expect(ProLimits.pdfBytes, 10 * 1024 * 1024);
      expect(ProLimits.colors, 8);
    });

    test('tests run with Pro on unless asked not to', () {
      expect(Pro.has, isTrue);
      Pro.testFree = true;
      addTearDown(() => Pro.testFree = false);
      expect(Pro.has, isFalse);
      expect(Pro.autoSync, isFalse);
    });
  });

  test('the Play account id is the SHA-256 of the lowercased email', () {
    // sha256("someone@gmail.com")
    expect(
      ProBilling.accountId(' Someone@Gmail.com '),
      ProBilling.accountId('someone@gmail.com'),
    );
    expect(ProBilling.accountId('someone@gmail.com'), hasLength(64));
  });
}
