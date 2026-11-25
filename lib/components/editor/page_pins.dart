import 'dart:convert';

import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/components/editor/sticky_note_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

enum PinKind { link, comment }

/// A link or comment placed on a page. It's an SVG image like a sticky note,
/// so it saves, moves, undoes and exports with the page's other pictures.
class const PagePin(final PinKind kind, final String text, {final String? url});

const _inkBlue = '#1a73e8';
const _linkFontSize = 26.0;
const _linkPadding = 14.0;
const _commentSide = 64.0;

/// A web address the user typed as something safe to open: http(s) is assumed
/// when no scheme is given, and nothing that could run in the app is allowed.
Uri? parseLink(String typed) {
  final text = typed.trim();
  if (text.isEmpty || text.contains(' ')) return null;
  final uri = Uri.tryParse(text.contains(':') ? text : 'https://$text');
  if (uri == null) return null;
  return switch (uri.scheme) {
    'http' || 'https' => uri.host.isEmpty ? null : uri,
    'mailto' || 'tel' => uri,
    _ => null,
  };
}

String _linkLabel(PagePin pin) {
  final label = pin.text.isEmpty ? pin.url ?? '' : pin.text;
  return label.length > 40 ? '${label.substring(0, 40)}…' : label;
}

Size pinSize(PagePin pin) {
  if (pin.kind == .comment) return const Size.square(_commentSide);
  final painter = TextPainter(
    text: TextSpan(
      text: _linkLabel(pin),
      style: const TextStyle(fontSize: _linkFontSize),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final size = Size(painter.width + _linkPadding * 2, _linkFontSize * 1.8);
  painter.dispose();
  return size;
}

String pinToSvg(PagePin pin) {
  final size = pinSize(pin);
  final meta = base64Url.encode(
    utf8.encode(
      jsonEncode({'kind': pin.kind.name, 'text': pin.text, 'url': pin.url}),
    ),
  );
  final body = pin.kind == .comment
      ? '<path d="M8 6h48a4 4 0 0 1 4 4v32a4 4 0 0 1-4 4H26l-12 13V46H8a4 4 0 '
            '0 1-4-4V10a4 4 0 0 1 4-4z" fill="#ffc107" stroke="#b28704" '
            'stroke-width="2"/>'
            '<path d="M15 19h34M15 29h24" stroke="#5f4b00" stroke-width="4" '
            'stroke-linecap="round"/>'
      : '<rect x="1" y="1" width="${size.width - 2}" '
            'height="${size.height - 2}" rx="10" fill="#e8f0fe" '
            'stroke="$_inkBlue" stroke-width="2"/>'
            '<text x="$_linkPadding" y="${_linkFontSize * 1.2}" '
            'font-family="sans-serif" font-size="$_linkFontSize" '
            'fill="$_inkBlue">${xmlEscape(_linkLabel(pin))}</text>';
  return '<svg xmlns="http://www.w3.org/2000/svg" width="${size.width}" '
      'height="${size.height}" viewBox="0 0 ${size.width} ${size.height}">'
      '<!--badnotes-pin:$meta-->$body</svg>';
}

/// Reads back what [pinToSvg] made, or null if [svg] isn't a pin.
PagePin? pinFromSvg(String svg) {
  final match = RegExp('<!--badnotes-pin:([A-Za-z0-9_=-]+)-->').firstMatch(svg);
  if (match == null) return null;
  final json = jsonDecode(utf8.decode(base64Url.decode(match.group(1)!)));
  return PagePin(
    PinKind.values.byName(json['kind'] as String),
    json['text'] as String,
    url: json['url'] as String?,
  );
}

/// Asks for a new or changed link or comment. Null means cancelled.
Future<PagePin?> showPinEditor(
  BuildContext context,
  PinKind kind, [
  PagePin? pin,
]) => showAppleDialog<PagePin>(
  context: context,
  builder: (context) => _PinEditor(kind, pin),
);

class _PinEditor extends StatefulWidget {
  const _PinEditor(this.kind, this.pin);

  final PinKind kind;
  final PagePin? pin;

  @override
  State<_PinEditor> createState() => _PinEditorState();
}

class _PinEditorState extends State<_PinEditor> {
  late final _text = TextEditingController(text: widget.pin?.text);
  late final _url = TextEditingController(text: widget.pin?.url);
  var _badLink = false;

  @override
  void dispose() {
    _text.dispose();
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.kind == .comment) {
      final text = _text.text.trim();
      Navigator.pop(context, text.isEmpty ? null : PagePin(.comment, text));
      return;
    }
    final link = parseLink(_url.text);
    if (link == null) return setState(() => _badLink = true);
    Navigator.pop(
      context,
      PagePin(.link, _text.text.trim(), url: link.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComment = widget.kind == .comment;
    return BnDialogCard(
      width: 440,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            BnDialogTitle(
              title: isComment ? 'Comment' : 'Link',
              size: 22,
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 18),
            if (!isComment) ...[
              const BnFieldLabel('Web address'),
              BnTextInput(
                controller: _url,
                hint: 'example.com',
                autofocus: true,
                keyboardType: TextInputType.url,
                fontWeight: FontWeight.w500,
                onChanged: (_) {
                  if (_badLink) setState(() => _badLink = false);
                },
                onSubmitted: (_) => _submit(),
              ),
              if (_badLink)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    "This address can't be opened",
                    style: BnType.caption.copyWith(
                      color: BadNotesColors.of(context).danger,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
            ],
            BnFieldLabel(isComment ? 'Comment' : 'Text to show (optional)'),
            BnTextInput(
              controller: _text,
              autofocus: isComment,
              hint: isComment ? 'Write a comment' : null,
              fontWeight: FontWeight.w500,
              minLines: isComment ? 3 : 1,
              maxLines: isComment ? 6 : 1,
              onSubmitted: isComment ? null : (_) => _submit(),
            ),
            const SizedBox(height: 22),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: BnPillButton(
                    label: 'Cancel',
                    expand: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: BnPillButton(
                    label: 'Save',
                    kind: BnPillKind.accent,
                    expand: true,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum PinAction { edit, delete }

/// Shows a pin. Returns what the user wants to change, if anything.
Future<PinAction?> showPinDialog(
  BuildContext context,
  PagePin pin, {
  required bool editable,
}) => showAppleDialog<PinAction>(
  context: context,
  builder: (context) {
    final url = pin.url;
    final link = url == null ? null : parseLink(url);
    final colors = BadNotesColors.of(context);
    return BnDialogCard(
      width: 440,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            BnDialogTitle(
              title: pin.kind == .comment
                  ? 'Comment'
                  : pin.text.isEmpty
                  ? 'Link'
                  : pin.text,
              size: 22,
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            SelectableText(
              pin.kind == .comment ? pin.text : url ?? '',
              style: BnType.bodyLarge.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.45,
                color: pin.kind == .comment ? colors.text : colors.accent,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              spacing: 10,
              children: [
                if (editable) ...[
                  BnPillButton(
                    label: 'Delete',
                    icon: BnIcons.trash,
                    onPressed: () => Navigator.pop(context, PinAction.delete),
                  ),
                  BnPillButton(
                    label: 'Edit',
                    icon: BnIcons.rename,
                    onPressed: () => Navigator.pop(context, PinAction.edit),
                  ),
                ],
                const Spacer(),
                if (link != null)
                  BnPillButton(
                    label: 'Open',
                    kind: BnPillKind.accent,
                    onPressed: () {
                      Navigator.pop(context);
                      launchUrl(link, mode: LaunchMode.externalApplication);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);

/// Whether [svg] is a link to a page or another note, from a build that had
/// them: those were taken out, and are removed from notes as they open.
bool isRemovedNotesLink(String svg) {
  final match = RegExp('<!--badnotes-pin:([A-Za-z0-9_=-]+)-->').firstMatch(svg);
  if (match == null) return false;
  try {
    final json = jsonDecode(utf8.decode(base64Url.decode(match.group(1)!)));
    return json is Map &&
        (json.containsKey('page') ||
            json.containsKey('note') ||
            json.containsKey('over'));
  } catch (_) {
    return false;
  }
}
