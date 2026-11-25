import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:badnotes/data/is_this_a_test.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/pro/pro.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

/// Where buying Pro is up to.
enum ProBuyStep {
  /// Nothing going on.
  idle,

  /// Google Play's sheet is up.
  buying,

  /// Paid; the licence server is checking the purchase.
  activating,

  /// Paid with something that takes a while (UPI, cash): Pro turns on
  /// when Google says it went through.
  pending,

  /// Paid, but the server couldn't be reached: it's kept and tried again.
  waiting,

  /// Pro is on.
  done,

  /// It didn't work; see [ProBilling.message].
  failed,
}

/// Buying Pro with Google Play Billing: the one-time product
/// [productId], tied to the signed-in Google account on the licence server.
abstract final class ProBilling {
  static final log = Logger('ProBilling');

  static const productId = 'pro_lifetime';

  /// The product as Google Play has it (its price is in the user's
  /// currency); null until loaded or where Play isn't there.
  static final product = ValueNotifier<ProductDetails?>(null);

  static final step = ValueNotifier(ProBuyStep.idle);

  /// What to tell the user about [step], when there's something to say.
  static final message = ValueNotifier<String?>(null);

  /// Only the Play Store version of the app can buy.
  static bool get supported => Platform.isAndroid && !isThisATest;

  static StreamSubscription<List<PurchaseDetails>>? _purchases;
  static Future<void>? _loading;

  /// Listens for purchases and loads the product. Safe to call again.
  static Future<void> init() async {
    if (!supported) return;
    _purchases ??= InAppPurchase.instance.purchaseStream.listen(
      (list) => unawaited(_onPurchases(list)),
      onError: (Object e) => log.warning('Purchase stream: $e'),
    );
    await loadProduct();
    await retryWaiting();
  }

  /// Fetches [product] from Google Play if it isn't loaded yet.
  static Future<void> loadProduct() {
    if (!supported || product.value != null) return Future.value();
    return _loading ??= () async {
      try {
        final iap = InAppPurchase.instance;
        if (!await iap.isAvailable()) {
          log.info('Google Play Billing is not available');
          return;
        }
        final reply = await iap.queryProductDetails({productId});
        if (reply.productDetails.isNotEmpty) {
          product.value = reply.productDetails.first;
        } else {
          log.info('No product $productId: ${reply.notFoundIDs}');
        }
      } catch (e) {
        log.warning('Could not load the product: $e');
      } finally {
        _loading = null;
      }
    }();
  }

  /// The id Google Play keeps with the purchase, so the server can check
  /// it was bought for this account: SHA-256 of the email, in hex.
  static String accountId(String email) =>
      sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

  static void _set(ProBuyStep to, [String? text]) {
    step.value = to;
    message.value = text;
  }

  /// Opens Google Play's purchase sheet. The signed-in account must be a
  /// Google one ([Pro.account]).
  static Future<void> buy() async {
    final email = Pro.account;
    if (email == null) {
      _set(.failed, 'Sign in with Google first.');
      return;
    }
    await loadProduct();
    final details = product.value;
    if (details == null) {
      _set(
        .failed,
        "Google Play isn't ready on this device. Check that you're signed "
        'in to the Play Store and try again.',
      );
      return;
    }
    _set(.buying);
    try {
      final started = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: details,
          applicationUserName: accountId(email),
        ),
      );
      if (!started) _set(.idle);
    } catch (e) {
      log.warning('buy: $e');
      _set(.failed, "Couldn't open Google Play. Try again.");
    }
  }

  /// Asks Google Play for purchases made before (new phone, reinstall).
  static Future<void> restore() async {
    if (!supported) return;
    _set(.activating);
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      log.warning('restore: $e');
    }
    // Play sends nothing back when there was nothing bought: ask the server
    final reply = await Pro.refresh(force: true);
    if (step.value == ProBuyStep.activating) {
      if (Pro.has) {
        _set(.done);
      } else {
        _set(
          .failed,
          reply == null
              ? 'Sign in with the Google account you bought Pro with.'
              : 'No purchase found for this Google account.',
        );
      }
    }
  }

  static Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;
      switch (purchase.status) {
        case .pending:
          _set(
            .pending,
            'Your payment is processing. Pro turns on by itself when it '
            'goes through.',
          );
        case .canceled:
          _set(.idle);
        case .error:
          _set(.failed, purchase.error?.message ?? 'The purchase failed.');
        case .purchased || .restored:
          await _activate(purchase);
      }
    }
  }

  static Future<void> _activate(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;
    // kept until the server has it, so a paid purchase is never lost
    stows.proWaiting.value = jsonEncode({
      'token': token,
      'order': purchase.purchaseID,
    });
    _set(.activating);
    final refused = await Pro.verifyPlay(
      productId: productId,
      purchaseToken: token,
      orderId: purchase.purchaseID,
    );
    if (refused == null) {
      stows.proWaiting.value = '';
      // acknowledges it to Play, which refunds unacknowledged purchases
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
      _set(.done);
    } else if (refused.retryLater) {
      _set(
        refused.code == 'pending' ? ProBuyStep.pending : ProBuyStep.waiting,
        refused.code == 'pending'
            ? 'Your payment is processing. Pro turns on by itself when it '
                  'goes through.'
            : "Payment received. We'll finish turning on Pro when you're "
                  'online.',
      );
    } else {
      stows.proWaiting.value = '';
      _set(.failed, refused.message);
    }
  }

  /// Sends a purchase that was paid but not yet recorded by the server.
  static Future<void> retryWaiting() async {
    if (!supported) return;
    await stows.proWaiting.waitUntilRead();
    final saved = stows.proWaiting.value;
    if (saved.isEmpty) return;
    try {
      final json = jsonDecode(saved) as Map;
      final refused = await Pro.verifyPlay(
        productId: productId,
        purchaseToken: json['token'] as String,
        orderId: json['order'] as String?,
      );
      if (refused == null) {
        stows.proWaiting.value = '';
        _set(.done);
        // acknowledge it now: restoring hands the purchase back
        await InAppPurchase.instance.restorePurchases();
      } else if (!refused.retryLater) {
        stows.proWaiting.value = '';
      }
    } catch (e) {
      log.warning('retryWaiting: $e');
    }
  }
}
