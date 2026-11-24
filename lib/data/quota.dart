import 'package:flutter/foundation.dart';
import 'package:badnotes/data/nextcloud/readable_bytes.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:stow_codecs/stow_codecs.dart';

/// How much of the cloud storage is used, and how much there is, in bytes.
/// [total] is negative when there's no limit.
class QuotaRaw {
  const QuotaRaw({required this.used, required this.total});

  /// From a reply with `used` and `total` (other keys are ignored).
  factory QuotaRaw.fromJson(Map<String, dynamic> json) => QuotaRaw(
    used: (json['used'] as num).toInt(),
    total: (json['total'] as num).toInt(),
  );

  final int used;
  final int total;

  int get free => total - used;

  /// How much is used, as a percentage.
  double get relative => used / total * 100;
}

/// [QuotaRaw] as shown in settings: a bar and a line of text.
extension type Quota(@visibleForTesting QuotaRaw raw) {
  /// With no limit, using this much fills the bar halfway.
  static const _halfwayBytes = 5 << 30;

  /// The bar's fill, 0 to 1. Without a limit it creeps towards full as more
  /// is used, so it still says something.
  double get usedRatio => isUncapped
      ? 1 - 1 / (1 + raw.used / _halfwayBytes)
      : raw.used / raw.total;

  /// Whether there's no limit to the storage.
  bool get isUncapped => raw.total < 0;

  /// [usedRatio] for a progress bar: never under 4%, where its round ends
  /// looked broken, nor over 100% (an unknown ratio shows full).
  double get progressIndicatorValue => usedRatio.clamp(0.04, 1.0);

  /// The percentage used to one decimal place (`50`, `33.3`); 100 when it
  /// can't be worked out. Only for storage with a limit.
  double get _percent {
    assert(!isUncapped, 'Percentages do not make sense with uncapped quotas.');
    final ratio = usedRatio;
    return ratio.isFinite ? (ratio * 100 * 10).round() / 10 : 100.0;
  }

  /// A sentence for settings, e.g. "You're using 1.00 GB of 3.00 GB (33.3%)".
  String describe() => isUncapped
      ? t.profile.quotaUsageUncapped(used: readableBytes(raw.used))
      : t.profile.quotaUsage(
          used: readableBytes(raw.used),
          total: readableBytes(raw.total),
          percent: _percent,
        );

  /// Just the sizes, e.g. `819 MB / 2.00 GB` (or only what's used, without
  /// a limit).
  String describeConcise() => isUncapped
      ? readableBytes(raw.used)
      : '${readableBytes(raw.used)} / ${readableBytes(raw.total)}';

  static String describePlaceholder() =>
      t.profile.quotaUsageUncapped(used: '... B');
  static String describeConcisePlaceholder() => '... B / ... B';
}

/// Keeps a [Quota] in settings as its two numbers, written out as text.
class QuotaCodec extends AbstractCodec<Quota, List> {
  const QuotaCodec();

  @override
  List<String> encode(Quota input) => [
    '${input.raw.used}',
    '${input.raw.total}',
  ];

  @override
  Quota decode(List<dynamic> encoded) {
    if (encoded.length != 2) {
      throw FormatException('Invalid quota format: $encoded');
    }
    int number(Object? text) => int.tryParse('$text') ?? 0;
    return Quota(QuotaRaw(used: number(encoded[0]), total: number(encoded[1])));
  }
}
