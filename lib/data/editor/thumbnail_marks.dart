import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;

/// A note's thumbnail says whether it should stay as it is in dark mode, for
/// a first page whose paper color was picked: dark mode keeps those pages as
/// they are (see `InnerCanvas.invertsInk`), so their thumbnails must too.
///
/// The mark is a PNG text chunk right after the header, so it's read with
/// the first few bytes of the file instead of a file of its own.
abstract final class ThumbnailMarks {
  static const _keyword = 'badnotes-keep-colors';

  /// [png] with the mark added.
  static Uint8List markKeepColors(Uint8List png) {
    // 8 byte signature, then the IHDR chunk: 4 length + 4 type + 13 + 4 crc
    const afterHeader = 8 + 25;
    if (png.length < afterHeader) return png;
    final data = Uint8List.fromList([..._keyword.codeUnits, 0, ...'1'.codeUnits]);
    final typeAndData = Uint8List.fromList([...'tEXt'.codeUnits, ...data]);
    final chunk = BytesBuilder()
      ..add(_uint32(data.length))
      ..add(typeAndData)
      ..add(_uint32(getCrc32(typeAndData)));
    return (BytesBuilder()
          ..add(png.sublist(0, afterHeader))
          ..add(chunk.takeBytes())
          ..add(png.sublist(afterHeader)))
        .takeBytes();
  }

  /// Whether the thumbnail in [file] keeps its colors in dark mode.
  static bool keepsColors(File file) {
    try {
      final raf = file.openSync();
      try {
        final head = raf.readSync(80);
        return String.fromCharCodes(head).contains(_keyword);
      } finally {
        raf.closeSync();
      }
    } on FileSystemException {
      return false;
    }
  }

  static Uint8List _uint32(int value) =>
      Uint8List(4)..buffer.asByteData().setUint32(0, value);
}
