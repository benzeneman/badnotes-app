/// Why the editor refuses to let the user change a note.
///
/// An editable note has no reason at all (the field is null).
enum ReadOnlyReason {
  /// The file was written by a newer BadNotes than this one. Parts of it may
  /// not have been understood, so saving could throw data away.
  versionTooNew,

  /// The note mirrors live updates from a server. Editing while mirroring is
  /// not supported, so the note stays read-only.
  watchingServer,

  /// An empty stand-in shown while the real note is still loading.
  placeholder,

  /// Loading failed because the file is missing or damaged. Editing is off so
  /// the file on disk is never overwritten with an empty note.
  corrupted,
}
