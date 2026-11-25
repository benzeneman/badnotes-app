import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:badnotes/components/editor/sticky_note_dialog.dart';
import 'package:badnotes/components/editor_ui/editor_ui_colors.dart';
import 'package:badnotes/components/editor_ui/text_format_bar.dart';
import 'package:badnotes/components/editor_ui/tool_chips.dart';
import 'package:badnotes/components/theming/apple_ui.dart';

/// Font families a text box can use, with the name shown for each.
const textBoxFonts = <String, String>{
  'AtkinsonHyperlegibleNext': 'Clean',
  'Inter': 'Inter',
  'Poppins': 'Poppins',
  'Nunito': 'Nunito',
  'Lora': 'Lora',
  'Kalam': 'Kalam',
  'PatrickHand': 'Patrick Hand',
  'JetBrainsMono': 'JetBrains Mono',
  'Caveat': 'Caveat',
  'IndieFlower': 'Indie Flower',
  'ShadowsIntoLight': 'Shadows',
  'Neucha': 'Neucha',
  'Dekko': 'Dekko',
  'DancingScript': 'Dancing',
  'Pacifico': 'Pacifico',
  'Lobster': 'Lobster',
  'PlayfairDisplay': 'Playfair',
  'FiraMono': 'Mono',
};

/// How a text box's text looks: a [StickyNoteResult] with no text and no
/// note color, of which only the text and box settings count.
typedef TextFormat = StickyNoteResult;

/// The format of new text boxes when none has been used yet.
const defaultTextFormat = StickyNoteResult(
  '',
  null,
  font: 'AtkinsonHyperlegibleNext',
  fontSize: 24,
);

/// The inside margin of a text box, in its own units.
const textBoxPadding = 4.0;

/// Typing right where the text box will sit on the page, with the font and
/// size choices along the top. Tapping anywhere else finishes it.
class TextBoxOverlay extends StatefulWidget {
  const new({
    super.key,
    required this.repositioned,
    required this.position,
    required this.scale,
    required this.maxWidth,
    required this.text,
    required this.format,
    required this.onDone,
    this.inverted = false,
    this.liftBy,
  });

  /// Moves the page up by this many screen pixels, so the box being typed
  /// in isn't hidden under the keyboard.
  final void Function(double dy)? liftBy;

  /// Fires when the page moves under the text box.
  final Listenable repositioned;

  /// The box's top left corner in this overlay.
  final Offset Function() position;

  /// Screen pixels per unit of the text box.
  final double Function() scale;

  /// How wide the box can get before leaving the page, in its own units.
  final double maxWidth;
  final String text;

  /// The box's format, or null for the last one used.
  final TextFormat? format;
  final void Function(String text, TextFormat format) onDone;

  /// Whether the page's ink is drawn inverted, as on a page turned dark: the
  /// text is then shown light, as it will be once placed.
  final bool inverted;

  /// The last format used, for the next text box and the text tool's bar.
  static var lastFormat = defaultTextFormat;

  @override
  State<TextBoxOverlay> createState() => _TextBoxOverlayState();
}

class _TextBoxOverlayState extends State<TextBoxOverlay>
    with WidgetsBindingObserver {
  late final _controller = TextEditingController(text: widget.text)
    ..addListener(_keepAboveKeyboard);
  final _focus = FocusNode();
  late var _format = widget.format ?? TextBoxOverlay.lastFormat;
  var _done = false;
  final _boxKey = GlobalKey();

  static const _ink = Color(0xFF202124);

  /// Room kept between the box and the top of the keyboard.
  static const _aboveKeyboard = 24.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => _keepAboveKeyboard();

  /// After this frame: if the keyboard covers the bottom of the box (it came
  /// up, or the text went onto a new line), the page moves up just enough.
  void _keepAboveKeyboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _done) return;
      final box = _boxKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final view = View.of(context);
      final keyboard = view.viewInsets.bottom / view.devicePixelRatio;
      if (keyboard <= 0) return;
      final screen = view.physicalSize.height / view.devicePixelRatio;
      final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
      final over = bottom - (screen - keyboard - _aboveKeyboard);
      if (over > 1) widget.liftBy?.call(over);
    });
  }

  // ---- voice typing ----

  final _speech = SpeechToText();
  var _listening = false;

  /// Spoken in Hindi rather than English (Indian English), for every box.
  static var _hindi = false;

  /// The text before and after where the spoken words go.
  var _voiceBefore = '', _voiceAfter = '';

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ready = await _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (!ready) {
      showBanner(
        context,
        'Voice typing needs the microphone and Google speech',
        kind: BannerKind.warning,
      );
      return;
    }
    final text = _controller.text;
    final selection = _controller.selection;
    final at = selection.isValid
        ? selection.baseOffset.clamp(0, text.length)
        : text.length;
    _voiceBefore = text.substring(0, at);
    _voiceAfter = text.substring(at);
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final words = result.recognizedWords;
        final space =
            words.isNotEmpty &&
            _voiceBefore.isNotEmpty &&
            !_voiceBefore.endsWith(' ') &&
            !_voiceBefore.endsWith('\n');
        final spoken = '${space ? ' ' : ''}$words';
        _controller.value = TextEditingValue(
          text: '$_voiceBefore$spoken$_voiceAfter',
          selection: TextSelection.collapsed(
            offset: _voiceBefore.length + spoken.length,
          ),
        );
        if (result.finalResult) _voiceBefore += spoken;
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        localeId: _hindi ? 'hi_IN' : 'en_IN',
      ),
    );
  }

  @override
  void dispose() {
    if (_listening) _speech.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    TextBoxOverlay.lastFormat = _format.copyWith(text: '');
    widget.onDone(_controller.text, _format);
  }

  Widget _toolbar() => RepaintBoundary(
    child: Material(
      color: EditorUi.of(context).bar,
      elevation: 4,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(EditorUi.barRadius),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TextFormatBar(
            format: _format,
            onChanged: (f) => setState(() => _format = f),
            afterPanel: () {
              if (mounted && !_done) _focus.requestFocus();
            },
            trailing: [
              const BarDivider(axis: Axis.horizontal),
              ToolChip(
                icon: Icon(
                  _listening ? Icons.mic : Icons.mic_none,
                  color: _listening ? const Color(0xFFD93A2B) : null,
                ),
                tooltip: _listening ? 'Stop voice typing' : 'Voice typing',
                selected: _listening,
                selectedColor: const Color(0x33D93A2B),
                onTap: _toggleVoice,
              ),
              ToolChip(
                icon: Text(
                  _hindi ? 'हिं' : 'EN',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                tooltip: _hindi
                    ? 'Voice typing in Hindi'
                    : 'Voice typing in English',
                onTap: () => setState(() => _hindi = !_hindi),
              ),
              const BarDivider(axis: Axis.horizontal),
              ToolChip(
                icon: const Icon(Icons.check),
                tooltip: 'Done',
                onTap: _finish,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final f = _format;
    final size = f.fontSize ?? 24;
    final style = TextStyle(
      fontFamily: f.font,
      fontWeight: f.bold ? FontWeight.bold : null,
      fontStyle: f.italic ? FontStyle.italic : null,
      decoration: TextDecoration.combine([
        if (f.underline) TextDecoration.underline,
        if (f.strike) TextDecoration.lineThrough,
      ]),
      height: f.lineHeight ?? 4 / 3,
    );
    final padding = (f.boxPadding ?? textBoxPadding) + f.boxBorderWidth;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _finish(),
      child: ListenableBuilder(
        listenable: widget.repositioned,
        builder: (context, _) {
          final at = widget.position();
          final scale = widget.scale();
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _finish,
                ),
              ),
              Positioned(
                left: at.dx,
                top: at.dy,
                width: widget.maxWidth * scale,
                child: Container(
                  key: _boxKey,
                  decoration: BoxDecoration(
                    color: f.boxFill,
                    borderRadius: BorderRadius.circular(f.boxRadius * scale),
                    border: f.boxBorder != null && f.boxBorderWidth > 0
                        ? Border.all(
                            color: f.boxBorder!,
                            width: f.boxBorderWidth * scale,
                          )
                        : null,
                  ),
                  padding: EdgeInsets.all(padding * scale),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: true,
                    maxLines: null,
                    textAlign: f.align,
                    cursorColor: colorScheme.primary,
                    style: style.copyWith(
                      fontSize: size * scale,
                      color: widget.inverted
                          ? const Color(0xFFECEDEF)
                          : f.textColor ?? _ink,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Type something here',
                      hintStyle: style.copyWith(
                        fontSize: size * scale,
                        color: const Color(0x88000000),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                child: Center(child: _toolbar()),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Typing right on a sticky note (a double tap on it): the note stays on the
/// page as paper only, grown as the text needs, and the text is typed over
/// it in its own font and size. Tapping anywhere else, ✓ or back finishes.
class NoteTextOverlay extends StatefulWidget {
  const new({
    super.key,
    required this.repositioned,
    required this.position,
    required this.scale,
    required this.note,
    required this.onChanged,
    required this.onDone,
  });

  /// Fires when the page moves under the note.
  final Listenable repositioned;

  /// The note's top left corner in this overlay.
  final Offset Function() position;

  /// Screen pixels per unit of the note.
  final double Function() scale;
  final StickyNoteResult note;

  /// The text as it's typed, so the note can grow.
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onDone;

  @override
  State<NoteTextOverlay> createState() => _NoteTextOverlayState();
}

class _NoteTextOverlayState extends State<NoteTextOverlay> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.note.text,
  )
    ..addListener(() => widget.onChanged(_controller.text));
  var _done = false;

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final area = widget.note.textArea;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _finish(),
      child: ListenableBuilder(
        listenable: widget.repositioned,
        builder: (context, _) {
          final at = widget.position();
          final scale = widget.scale();
          final size = area.style.fontSize! * scale;
          // ponytail: a turned note is typed on unturned; turn the field
          // with it if turned notes get typed on often
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _finish,
                ),
              ),
              Positioned(
                left: at.dx + area.left * scale,
                top: at.dy + area.top * scale,
                width: area.width * scale,
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  textAlign: widget.note.align,
                  cursorColor: ColorScheme.of(context).primary,
                  style: area.style.copyWith(
                    fontSize: size,
                    height: area.line / area.style.fontSize!,
                    color: widget.note.textColor ?? const Color(0xFF202124),
                  ),
                  decoration: const InputDecoration.collapsed(hintText: ''),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                child: Center(
                  child: Material(
                    color: EditorUi.of(context).bar,
                    elevation: 4,
                    shadowColor: Colors.black45,
                    borderRadius: BorderRadius.circular(EditorUi.barRadius),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ToolChip(
                        icon: const Icon(Icons.check),
                        tooltip: 'Done',
                        onTap: _finish,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
