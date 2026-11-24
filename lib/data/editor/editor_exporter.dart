import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:badnotes/components/canvas/_circle_stroke.dart';
import 'package:badnotes/components/canvas/_rectangle_stroke.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/canvas_preview.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/is_this_a_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image/image.dart' as im;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pool/pool.dart';
import 'package:screenshot/screenshot.dart';

/// Turns a note into things that leave the app: a PDF document, or a
/// bitmap of a single page.
///
/// A PDF page is built in two layers. The bottom layer is a bitmap of the
/// page (background, pictures, text and any ink that has to be a bitmap).
/// On top of that, every remaining stroke is drawn again as real vector
/// paths so it stays sharp at any zoom.
abstract class EditorExporter {
  /// True when [stroke] has to go into the page bitmap instead of being
  /// drawn as a vector path in the PDF.
  ///
  /// That is the case for the highlighter (a PDF path here cannot be
  /// see-through) and for the pencil (its grain comes from a shader).
  static bool shouldRasterizeStroke(Stroke stroke) {
    return switch (stroke.toolId) {
      .highlighter || .pencil => true,
      _ => false,
    };
  }

  /// Builds a PDF of every page in [coreInfo].
  ///
  /// A blank page at the very end is left out of the document.
  /// [context] is accepted for callers that have one but is not needed.
  /// [onProgress] hears how many pages are drawn so far, of how many.
  static Future<pw.Document> generatePdf(
    EditorCoreInfo coreInfo, [
    BuildContext? context,
    void Function(int done, int total)? onProgress,
  ]) async {
    final note = _withoutBlankLastPage(coreInfo);
    final bitmaps = await _bitmapsOfAllPages(note, onProgress);

    final document = pw.Document();
    for (var i = 0; i < bitmaps.length; i++) {
      document.addPage(_pdfPage(note, note.pages[i], bitmaps[i]));
    }
    return document;
  }

  static EditorCoreInfo _withoutBlankLastPage(EditorCoreInfo note) {
    final pages = note.pages;
    if (pages.isEmpty || pages.last.isNotEmpty) return note;
    return note.copyWith(pages: pages.toList()..removeLast());
  }

  /// Renders all pages to bitmaps, a few at a time, keeping page order.
  static Future<List<im.Image>> _bitmapsOfAllPages(
    EditorCoreInfo note, [
    void Function(int done, int total)? onProgress,
  ]) {
    final workers = (Platform.numberOfProcessors ~/ 2).clamp(1, 4);
    final pool = Pool(workers);
    final jobs = <Future<im.Image>>[];
    final total = note.pages.length;
    var done = 0;
    onProgress?.call(0, total);
    for (var i = 0; i < total; i++) {
      jobs.add(
        pool.withResource(() => _bitmapOfPage(note, i)).then((bitmap) {
          onProgress?.call(++done, total);
          return bitmap;
        }),
      );
    }
    return Future.wait(jobs);
  }

  static Future<im.Image> _bitmapOfPage(EditorCoreInfo note, int index) async {
    final shot = await screenshotPage(coreInfo: note, pageIndex: index);
    final rgba = await shot.toByteData(format: ui.ImageByteFormat.rawRgba);
    assert(rgba != null, 'raw RGBA bytes of a ui.Image were missing');
    final bitmap = im.Image.fromBytes(
      width: shot.width,
      height: shot.height,
      bytes: rgba!.buffer,
      order: im.ChannelOrder.rgba,
    );
    shot.dispose();
    return bitmap;
  }

  static pw.Page _pdfPage(
    EditorCoreInfo note,
    EditorPage page,
    im.Image bitmap,
  ) {
    final size = page.size;
    return pw.Page(
      pageFormat: PdfPageFormat(size.width, size.height),
      build: (pw.Context _) => pw.SizedBox(
        width: size.width,
        height: size.height,
        child: pw.CustomPaint(
          foregroundPainter: (PdfGraphics canvas, PdfPoint _) =>
              _drawVectorInk(canvas, note, page),
          child: pw.Image(
            pw.ImageImage(bitmap),
            width: size.width,
            height: size.height,
          ),
        ),
      ),
    );
  }

  /// Draws every stroke that is not in the page bitmap as a vector path.
  ///
  /// PDF colours here are opaque, so each stroke colour is blended onto the
  /// page colour first.
  static void _drawVectorInk(
    PdfGraphics canvas,
    EditorCoreInfo note,
    EditorPage page,
  ) {
    final paper =
        page.backgroundColor ??
        note.backgroundColor ??
        InnerCanvas.defaultBackgroundColor;
    final paperPdf = PdfColor.fromInt(paper.toARGB32()).flatten();
    final pageHeight = page.size.height;

    for (final stroke in page.strokes) {
      if (shouldRasterizeStroke(stroke)) continue;

      final colour = PdfColor.fromInt(stroke.color.toARGB32())
          .flatten(background: paperPdf);

      final isOutline = _tracePath(canvas, stroke, pageHeight);
      if (isOutline) {
        canvas
          ..setStrokeColor(colour)
          ..setLineWidth(stroke.options.size)
          ..strokePath();
      } else {
        canvas
          ..setFillColor(colour)
          ..fillPath();
      }
    }
  }

  /// Adds the path of [stroke] to [canvas] (PDF y runs upwards, so y is
  /// flipped against [pageHeight]).
  ///
  /// Returns true for shapes that are drawn as an outline, false for
  /// freehand ink whose path is already the filled outline of the line.
  static bool _tracePath(PdfGraphics canvas, Stroke stroke, double pageHeight) {
    switch (stroke) {
      case CircleStroke(:final center, :final radius):
        canvas.drawEllipse(
          center.dx,
          pageHeight - center.dy,
          radius,
          radius,
          clockwise: false,
        );
        return true;
      case RectangleStroke(:final rect):
        final corner = stroke.options.size / 4;
        canvas.drawRRect(
          rect.left,
          pageHeight - rect.bottom,
          rect.width,
          rect.height,
          corner,
          corner,
        );
        return true;
      default:
        canvas.drawShape(stroke.toSvgPath());
        return false;
    }
  }

  /// Renders page [pageIndex] of [coreInfo] to a [ui.Image].
  ///
  /// By default the image leaves out the strokes that [generatePdf] draws
  /// as vectors (see [shouldRasterizeStroke]); pass
  /// [rasterizeAllStrokes] = true to get every stroke in the image.
  /// [cropHeight] cuts the page off at that height, [targetSize] is the
  /// logical size of the result (the page size if left out).
  ///
  /// The caller owns the returned image and has to dispose it.
  static Future<ui.Image> screenshotPage({
    required EditorCoreInfo coreInfo,
    required int pageIndex,
    bool rasterizeAllStrokes = false,
    Size? targetSize,
    double? cropHeight,
    double pixelRatio = 2,
  }) async {
    final page = coreInfo.pages[pageIndex].cloneForRasterization(
      rasterizeAllStrokes: rasterizeAllStrokes,
    );
    final loadedHere = await _loadPicturesOf(page);

    try {
      final size = targetSize ?? page.size;
      // every slot points at the clone, so [pageIndex] finds it
      final view = coreInfo.copyWith(
        pages: List.filled(coreInfo.pages.length, page, growable: true),
      );
      return await ScreenshotController.widgetToUiImage(
        EditorExporterTheme(
          targetSize: size,
          child: CanvasPreview(
            pageIndex: pageIndex,
            height: cropHeight,
            coreInfo: view,
          ),
        ),
        pixelRatio: pixelRatio,
        targetSize: size,
        delay: isThisATest ? .zero : const Duration(milliseconds: 200),
      );
    } finally {
      for (final picture in loadedHere) {
        unawaited(picture.loadOut());
      }
      page.disposeClonedData();
    }
  }

  /// Loads the pictures of [page] that are not in memory yet, waiting at
  /// most ten seconds, and returns the ones it started loading so they can
  /// be unloaded again afterwards.
  static Future<List<EditorImage>> _loadPicturesOf(EditorPage page) async {
    final notLoaded = <EditorImage>[
      if (page.backgroundImage case final background? when !background.loadedIn)
        background,
      for (final picture in page.images)
        if (!picture.loadedIn) picture,
    ];
    await Future.wait(notLoaded.map((picture) => picture.loadIn()))
        .timeout(const Duration(seconds: 10), onTimeout: () => const []);
    return notLoaded;
  }
}

/// Wraps an export in a fixed light theme, an English locale and a fixed
/// size, so exported pages look the same whatever the device or the
/// user's settings are.
class EditorExporterTheme extends StatelessWidget {
  const new({super.key, required this.targetSize, required this.child});

  final Size targetSize;
  final Widget child;

  static final theme = ThemeData(
    brightness: .light,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.red,
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget result = SizedBox(
      width: targetSize.width,
      height: targetSize.height,
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.topLeft,
        child: child,
      ),
    );
    result = DefaultTextStyle(
      style: theme.textTheme.bodyMedium!,
      child: result,
    );
    result = Theme(data: theme, child: result);
    // the rich-text editor asks for localizations even though nothing
    // in an export shows translated text
    result = Localizations(
      locale: const Locale('en', 'US'),
      delegates: GlobalMaterialLocalizations.delegates,
      child: result,
    );
    return MediaQuery(
      data: MediaQueryData(size: targetSize),
      child: result,
    );
  }
}
