import 'package:flutter/material.dart';

/// What an audience sees while presenting on a TV or projector.
enum LiveMode {
  everything(
    'Everything Live',
    'Your audience follows your whole screen, tools and all.',
    Icons.cast,
  ),
  inkOnly(
    'Ink Only',
    'Just your page and your ink. Every tool steps out of sight.',
    Icons.draw_outlined,
  ),
  wholePage(
    'Full Page Focus',
    'Always the whole page in frame. No tools, no zooming.',
    Icons.fit_screen_outlined,
  );

  const LiveMode(this.title, this.description, this.icon);

  final String title, description;
  final IconData icon;

  /// Whether this mode clears the tools off the screen.
  bool get hidesTools => this != everything;
}

/// Asks how to present. Null means not after all. [connect] opens the device's
/// screen casting.
Future<LiveMode?> showGoLiveSheet(
  BuildContext context, {
  required VoidCallback connect,
  required bool canFitPages,
}) => showModalBottomSheet<LiveMode>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('Go Live', style: TextTheme.of(context).titleLarge),
        ),
        for (final mode in LiveMode.values)
          if (mode != .wholePage || canFitPages)
            ListTile(
              leading: Icon(mode.icon),
              title: Text(mode.title),
              subtitle: Text(mode.description),
              onTap: () => Navigator.pop(context, mode),
            ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.connected_tv),
          title: const Text('Connect a screen'),
          subtitle: const Text(
            'Cast or plug in a TV or projector. '
            'This device shows the same view as your audience.',
          ),
          onTap: connect,
        ),
      ],
    ),
  ),
);
