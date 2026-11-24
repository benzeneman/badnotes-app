import 'package:stow_codecs/stow_codecs.dart';

/// The orders the file browser can list notes in.
///
/// The choice is saved in prefs through [codec], so new orders may only be
/// added at the end and the existing ones must keep their place.
enum SortMetric {
  /// Alphabetical.
  nameAToZ,

  /// Reverse alphabetical.
  nameZToA,

  /// Most recently changed first.
  lastModifiedNewToOld,

  /// Least recently changed first.
  lastModifiedOldToNew;

  static const codec = EnumCodec(values);
}
