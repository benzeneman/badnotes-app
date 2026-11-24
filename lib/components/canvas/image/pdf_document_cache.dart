import 'dart:async';
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

/// Each PDF a note's pages come from, opened once and shared by all of them.
class PdfDocumentCache {
  final Map<String, FutureOr<PdfDocument>> _open = {};

  /// The PDF at [filePath], opened the first time it's asked for: from
  /// [pdfBytes] when given, from disk otherwise. Pages are read as needed.
  FutureOr<PdfDocument> load(String filePath, {Uint8List? pdfBytes}) =>
      _open[filePath] ??= pdfBytes == null
      ? PdfDocument.openFile(filePath, useProgressiveLoading: true)
      : PdfDocument.openData(
          pdfBytes,
          useProgressiveLoading: true,
          sourceName: filePath,
        );

  /// Closes every PDF (once it has finished opening).
  void dispose() {
    for (final opening in _open.values) {
      Future.value(opening).then((document) => document.dispose());
    }
    _open.clear();
  }
}
