import 'dart:typed_data';

import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The BadNotes app icon (paper square, ink line, amber dot), the same
/// picture as the launcher icon, with a hairline so it keeps its edge on
/// a paper-coloured page.
class BnLogo extends StatelessWidget {
  const new({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final radius = BorderRadius.all(Radius.circular(size * 0.22));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.hairline),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SvgPicture.asset(
          'assets/icon/icon.svg',
          width: size,
          height: size,
        ),
      ),
    );
  }
}

/// The signed in account's picture in a circle: the Google profile photo
/// if there is one, otherwise the account's first letter (or a person
/// when nobody is signed in).
class BnAvatar extends StatelessWidget {
  const new({
    super.key,
    required this.size,
    required this.username,
    required this.signedIn,
    required this.textStyle,
    this.iconSize = 17,
  });

  final double size, iconSize;
  final String username;
  final bool signedIn;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: stows.pfp,
      builder: (context, photo, _) {
        final showPhoto = signedIn && photo != null && photo.isNotEmpty;
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: showPhoto
              ? Image.memory(
                  photo,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: (size * 3).round(),
                  errorBuilder: (_, _, _) => _initial(colors),
                )
              : _initial(colors),
        );
      },
    );
  }

  Widget _initial(BadNotesColors colors) => signedIn
      ? Text(username.characters.first.toUpperCase(), style: textStyle)
      : Icon(BnIcons.user, size: iconSize, color: colors.accentStrong);
}
