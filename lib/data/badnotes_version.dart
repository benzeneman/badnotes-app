/// A version like 1.35.1, and the build number it's packed into:
/// two digits each for major, minor and patch, then one for the revision
/// (1.35.1 revision 0 is 135010).
class BadNotesVersion {
  BadNotesVersion(this.major, this.minor, this.patch, [this.revision = 0])
    : assert(major >= 0 && major < 100),
      assert(minor >= 0 && minor < 100),
      assert(patch >= 0 && patch < 100),
      assert(revision >= 0 && revision < 10);

  /// From "major.minor.patch".
  factory BadNotesVersion.fromName(String name) {
    final [major, minor, patch] = name.split('.').map(int.parse).toList();
    return BadNotesVersion(major, minor, patch);
  }

  /// From a build number (see [buildNumber]).
  factory BadNotesVersion.fromNumber(int number) {
    int digits(int skip, int mod) => number ~/ skip % mod;
    return BadNotesVersion(
      digits(100000, 100),
      digits(1000, 100),
      digits(10, 100),
      digits(1, 10),
    );
  }

  final int major;
  final int minor;
  final int patch;
  final int revision;

  String get buildName => '$major.$minor.$patch';
  String get buildNameWithCommas => '$major,$minor,$patch';
  int get buildNumber => major * 100000 + minor * 1000 + patch * 10 + revision;
  int get buildNumberWithoutRevision => buildNumber - revision;

  BadNotesVersion bumpMajor() => BadNotesVersion(major + 1, 0, 0);
  BadNotesVersion bumpMinor() => BadNotesVersion(major, minor + 1, 0);
  BadNotesVersion bumpPatch() => BadNotesVersion(major, minor, patch + 1);

  BadNotesVersion copyWith({
    int? major,
    int? minor,
    int? patch,
    int? revision,
  }) => BadNotesVersion(
    major ?? this.major,
    minor ?? this.minor,
    patch ?? this.patch,
    revision ?? this.revision,
  );

  @override
  String toString() => buildName;

  /// Equal when major, minor and patch are; the revision doesn't count.
  @override
  bool operator ==(Object other) =>
      other is BadNotesVersion &&
      (major, minor, patch) == (other.major, other.minor, other.patch);

  @override
  int get hashCode => Object.hash(major, minor, patch);
}
