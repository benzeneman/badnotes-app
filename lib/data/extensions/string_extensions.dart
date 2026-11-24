extension StringExtensions on String {
  /// Like [String.replaceAllMapped], for a [replace] that has to wait for
  /// something: every replacement is worked out at once, then put in.
  Future<String> replaceAllMappedAsync(
    Pattern exp,
    Future<String> Function(Match match) replace,
  ) async {
    final found = exp.allMatches(this).toList();
    final withWhat = await Future.wait(found.map(replace));
    final out = StringBuffer();
    var from = 0;
    for (final (i, match) in found.indexed) {
      out
        ..write(substring(from, match.start))
        ..write(withWhat[i]);
      from = match.end;
    }
    return (out..write(substring(from))).toString();
  }

  /// This, or null if it's empty.
  String? get ifNotEmpty => isEmpty ? null : this;
}
