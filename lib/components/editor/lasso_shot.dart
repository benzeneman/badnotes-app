import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:badnotes/components/editor/note_clipboard.dart';
import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:flutter/material.dart';

/// How a lasso screenshot is cut and what's in it.
typedef LassoShotLook = ({bool lassoShape, bool withPaper});

/// The lasso's Screenshot (design 15): a small card by the selection with
/// the picture, cut to the lasso or as a rectangle, with the paper or
/// without it, and Copy, Share, Save and Pin.
Future<void> showLassoShot(
  BuildContext context, {
  required Rect near,
  required String fileName,
  required Future<Uint8List?> Function(LassoShotLook look) make,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Close',
  barrierColor: Colors.transparent,
  transitionDuration: const Duration(milliseconds: 160),
  pageBuilder: (context, _, _) =>
      _LassoShotCard(near: near, fileName: fileName, make: make),
  transitionBuilder: (context, animation, _, child) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween(begin: 0.96, end: 1.0).animate(animation),
      child: child,
    ),
  ),
);

class _LassoShotCard extends StatefulWidget {
  const _LassoShotCard({
    required this.near,
    required this.fileName,
    required this.make,
  });

  final Rect near;
  final String fileName;
  final Future<Uint8List?> Function(LassoShotLook look) make;

  @override
  State<_LassoShotCard> createState() => _LassoShotCardState();
}

class _LassoShotCardState extends State<_LassoShotCard> {
  static var _lassoShape = true, _withPaper = true;
  Uint8List? _png;
  var _busy = true;

  @override
  void initState() {
    super.initState();
    _remake();
  }

  Future<void> _remake() async {
    setState(() => _busy = true);
    final png = await widget.make((
      lassoShape: _lassoShape,
      withPaper: _withPaper,
    ));
    if (!mounted) return;
    setState(() {
      _png = png;
      _busy = false;
    });
  }

  Future<void> _act(Future<String?> Function(Uint8List png) action) async {
    final png = _png;
    if (png == null || _busy) return;
    setState(() => _busy = true);
    String? message;
    try {
      message = await action(png);
    } catch (e) {
      message = 'That didn\'t work';
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    if (message != null) showBanner(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final screen = MediaQuery.sizeOf(context);
    const width = 300.0;
    // beside the selection, on whichever side has room
    final left = widget.near.right + 16 + width < screen.width
        ? widget.near.right + 16
        : (widget.near.left - 16 - width).clamp(8.0, screen.width - width - 8);
    final top = widget.near.top.clamp(72.0, screen.height - 420);

    Widget toggle(String a, String b, bool first, ValueChanged<bool> set) =>
        BnSegmented<bool>(
          segments: [BnSegment(true, a), BnSegment(false, b)],
          selected: first,
          height: 32,
          onChanged: (v) {
            set(v);
            _remake();
          },
        );

    Widget action(String label, IconData icon, VoidCallback onTap) => Expanded(
      child: Material(
        color: colors.sunkenSoft,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          onTap: _busy ? null : onTap,
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: colors.text),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: BnType.micro.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: width,
          child: Material(
            color: colors.surface,
            elevation: 12,
            shadowColor: Colors.black38,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: colors.sunkenSoft,
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: _png == null
                        ? Center(
                            child: _busy
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Nothing to show',
                                    style: BnType.caption.copyWith(
                                      color: colors.muted,
                                    ),
                                  ),
                          )
                        : Image.memory(_png!, fit: BoxFit.contain),
                  ),
                  toggle(
                    'Lasso shape',
                    'Rectangle',
                    _lassoShape,
                    (v) => _lassoShape = v,
                  ),
                  toggle(
                    'With paper',
                    'No paper',
                    _withPaper,
                    (v) => _withPaper = v,
                  ),
                  Row(
                    spacing: 6,
                    children: [
                      action('Copy', Icons.copy_outlined, () {
                        _act((png) async {
                          // to paste in this note or another, as a picture
                          NoteClipboard.strokes = [];
                          NoteClipboard.images = [
                            (bytes: png, extension: '.png'),
                          ];
                          NoteClipboard.offered.value = true;
                          return null; // the Paste pill says it's copied
                        });
                      }),
                      action('Share', Icons.ios_share, () {
                        _act((png) async {
                          await FileManager.exportFile(
                            widget.fileName,
                            png,
                            context: context,
                          );
                          return null;
                        });
                      }),
                      action('Save', Icons.download_outlined, () {
                        _act((png) async {
                          final saved = await FileManager.exportFile(
                            widget.fileName,
                            png,
                            isImage: true,
                            context: context,
                          );
                          return saved ? 'Saved' : 'Could not save it';
                        });
                      }),
                      action('Pin', Icons.push_pin_outlined, () {
                        _act((png) async {
                          await QuickBoard.load();
                          // the board keeps photos as JPEG: see-through
                          // parts would turn black
                          await QuickBoard.addPhoto(await _onWhite(png));
                          return 'Pinned to your quick notes';
                        });
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// [png] over white, for a place that can't keep see-through parts.
Future<Uint8List> _onWhite(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..drawColor(Colors.white, BlendMode.src)
    ..drawImage(image, Offset.zero, Paint());
  final flat = await recorder.endRecording().toImage(image.width, image.height);
  image.dispose();
  final bytes = await flat.toByteData(format: ui.ImageByteFormat.png);
  flat.dispose();
  return bytes!.buffer.asUint8List();
}
