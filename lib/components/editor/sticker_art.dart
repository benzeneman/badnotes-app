/// The sticker set. All of it is original artwork drawn for this app out of
/// plain SVG shapes, so there are no licenses to keep track of.
class StickerArt {
  const StickerArt(this.name, this.body);

  final String name;

  /// SVG content, on a 120 by 120 canvas.
  final String body;

  String get svg =>
      '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" '
      'viewBox="0 0 120 120">$body</svg>';
}

const _face =
    '<circle cx="60" cy="60" r="50" fill="#FFD54F"/>'
    '<path d="M60 10a50 50 0 0 1 0 100a62 62 0 0 0 0-100Z" fill="#FFB300" '
    'fill-opacity="0.35"/>';

String _badge(String fill, String ribbon, String text, double size) =>
    '<path d="M38 72L24 112L44 102L54 116L62 80Z" fill="$ribbon"/>'
    '<path d="M82 72L96 112L76 102L66 116L58 80Z" fill="$ribbon"/>'
    '<circle cx="60" cy="50" r="42" fill="$fill"/>'
    '<circle cx="60" cy="50" r="33" fill="none" stroke="#ffffff" '
    'stroke-width="3" stroke-dasharray="4 4"/>'
    '<text x="60" y="${50 + size * 0.36}" text-anchor="middle" '
    'font-family="sans-serif" font-weight="bold" font-size="$size" '
    'fill="#ffffff">$text</text>';

String _banner(String fill, String dark, String text, double size) =>
    '<path d="M4 44L24 44V84H4L14 64Z" fill="$dark"/>'
    '<path d="M116 44L96 44V84H116L106 64Z" fill="$dark"/>'
    '<rect x="14" y="34" width="92" height="44" rx="5" fill="$fill"/>'
    '<text x="60" y="${56 + size * 0.36}" text-anchor="middle" '
    'font-family="sans-serif" font-weight="bold" font-size="$size" '
    'fill="#ffffff">$text</text>';

final stickers = <StickerArt>[
  const StickerArt(
    'Star',
    '<path d="M60 8L75 42L112 46L84 71L92 108L60 89L28 108L36 71L8 46L45 42Z" '
        'fill="#FFCA28" stroke="#F57F17" stroke-width="4" '
        'stroke-linejoin="round"/>'
        '<path d="M60 22L70 45L60 40L44 49L48 53L38 51Z" fill="#ffffff" '
        'fill-opacity="0.4"/>',
  ),
  const StickerArt(
    'Heart',
    '<path d="M60 108C10 72 6 46 16 30C28 12 50 16 60 36C70 16 92 12 104 30'
        'C114 46 110 72 60 108Z" fill="#EF5350" stroke="#B71C1C" '
        'stroke-width="3"/>'
        '<ellipse cx="36" cy="38" rx="11" ry="7" fill="#ffffff" '
        'fill-opacity="0.55" transform="rotate(-35 36 38)"/>',
  ),
  const StickerArt(
    'Smile',
    '$_face<circle cx="42" cy="50" r="6" fill="#4E342E"/>'
        '<circle cx="78" cy="50" r="6" fill="#4E342E"/>'
        '<path d="M34 70C42 94 78 94 86 70" fill="none" stroke="#4E342E" '
        'stroke-width="6" stroke-linecap="round"/>',
  ),
  const StickerArt(
    'Cool',
    '$_face<path d="M20 42H100V52C100 66 84 68 72 62L66 50H54L48 62'
        'C36 68 20 66 20 52Z" fill="#263238"/>'
        '<path d="M42 80C50 90 70 90 80 76" fill="none" stroke="#4E342E" '
        'stroke-width="6" stroke-linecap="round"/>',
  ),
  const StickerArt(
    'Wow',
    '$_face<circle cx="42" cy="48" r="8" fill="#4E342E"/>'
        '<circle cx="78" cy="48" r="8" fill="#4E342E"/>'
        '<ellipse cx="60" cy="80" rx="11" ry="14" fill="#4E342E"/>',
  ),
  const StickerArt(
    'Sleepy',
    '$_face<path d="M32 50H52M68 50H88" stroke="#4E342E" stroke-width="6" '
        'stroke-linecap="round"/>'
        '<path d="M46 80H74" stroke="#4E342E" stroke-width="6" '
        'stroke-linecap="round"/>'
        '<text x="88" y="30" font-family="sans-serif" font-weight="bold" '
        'font-size="22" fill="#1E88E5">z</text>'
        '<text x="102" y="18" font-family="sans-serif" font-weight="bold" '
        'font-size="16" fill="#1E88E5">z</text>',
  ),
  const StickerArt(
    'Sun',
    '<g stroke="#FB8C00" stroke-width="7" stroke-linecap="round">'
        '<path d="M60 8V22M60 98V112M8 60H22M98 60H112M23 23L33 33M87 87L97 97'
        'M97 23L87 33M33 87L23 97"/></g>'
        '<circle cx="60" cy="60" r="28" fill="#FFCA28"/>'
        '<circle cx="50" cy="56" r="3.5" fill="#6D4C41"/>'
        '<circle cx="70" cy="56" r="3.5" fill="#6D4C41"/>'
        '<path d="M50 68C54 74 66 74 70 68" fill="none" stroke="#6D4C41" '
        'stroke-width="3.5" stroke-linecap="round"/>',
  ),
  const StickerArt(
    'Cloud',
    '<path d="M32 92C12 92 6 66 26 60C24 38 54 28 64 46C80 34 100 48 94 62'
        'C114 66 110 92 90 92Z" fill="#E3F2FD" stroke="#64B5F6" '
        'stroke-width="4" stroke-linejoin="round"/>'
        '<circle cx="48" cy="70" r="3.5" fill="#37474F"/>'
        '<circle cx="72" cy="70" r="3.5" fill="#37474F"/>'
        '<path d="M54 78C58 82 62 82 66 78" fill="none" stroke="#37474F" '
        'stroke-width="3" stroke-linecap="round"/>',
  ),
  const StickerArt(
    'Rainbow',
    '<g fill="none" stroke-width="10">'
        '<path d="M10 92A50 50 0 0 1 110 92" stroke="#EF5350"/>'
        '<path d="M20 92A40 40 0 0 1 100 92" stroke="#FFA726"/>'
        '<path d="M30 92A30 30 0 0 1 90 92" stroke="#FFEE58"/>'
        '<path d="M40 92A20 20 0 0 1 80 92" stroke="#66BB6A"/>'
        '<path d="M50 92A10 10 0 0 1 70 92" stroke="#42A5F5"/></g>'
        '<circle cx="16" cy="96" r="12" fill="#ffffff" stroke="#B0BEC5" '
        'stroke-width="2"/><circle cx="104" cy="96" r="12" fill="#ffffff" '
        'stroke="#B0BEC5" stroke-width="2"/>',
  ),
  const StickerArt(
    'Flower',
    '<g fill="#F48FB1"><circle cx="60" cy="28" r="20"/>'
        '<circle cx="90" cy="50" r="20"/><circle cx="79" cy="86" r="20"/>'
        '<circle cx="41" cy="86" r="20"/><circle cx="30" cy="50" r="20"/></g>'
        '<circle cx="60" cy="60" r="17" fill="#FFD54F"/>'
        '<circle cx="54" cy="56" r="3" fill="#FFA000"/>'
        '<circle cx="66" cy="62" r="3" fill="#FFA000"/>'
        '<circle cx="58" cy="67" r="2.5" fill="#FFA000"/>',
  ),
  const StickerArt(
    'Leaf',
    '<path d="M20 104C8 50 50 12 108 12C110 70 72 112 20 104Z" fill="#66BB6A" '
        'stroke="#2E7D32" stroke-width="4" stroke-linejoin="round"/>'
        '<path d="M12 114C36 80 60 56 90 32M46 78L44 52M46 78L72 80M66 58'
        'L64 38M66 58L88 58" fill="none" stroke="#2E7D32" stroke-width="3.5" '
        'stroke-linecap="round"/>',
  ),
  const StickerArt(
    'Bolt',
    '<path d="M70 6L24 68H54L44 114L98 46H66Z" fill="#FFEE58" stroke="#F9A825" '
        'stroke-width="5" stroke-linejoin="round"/>',
  ),
  const StickerArt(
    'Flame',
    '<path d="M62 6C70 34 100 46 100 76C100 100 82 114 60 114C38 114 20 100 '
        '20 76C20 58 32 48 38 34C42 46 48 50 52 50C56 36 54 20 62 6Z" '
        'fill="#FF7043"/>'
        '<path d="M62 56C66 70 80 76 80 90C80 104 70 112 60 112C50 112 40 104 '
        '40 90C40 80 48 76 50 70C54 76 58 68 62 56Z" fill="#FFCA28"/>',
  ),
  const StickerArt(
    'Idea',
    '<path d="M60 8C36 8 22 26 22 44C22 62 38 68 42 84H78C82 68 98 62 98 44'
        'C98 26 84 8 60 8Z" fill="#FFEE58" stroke="#F9A825" stroke-width="4"/>'
        '<path d="M46 56L54 64V84M74 56L66 64V84M54 64H66" fill="none" '
        'stroke="#F9A825" stroke-width="3"/>'
        '<rect x="44" y="84" width="32" height="10" rx="3" fill="#90A4AE"/>'
        '<rect x="46" y="96" width="28" height="9" rx="3" fill="#78909C"/>'
        '<rect x="52" y="107" width="16" height="6" rx="3" fill="#546E7A"/>',
  ),
  const StickerArt(
    'Book',
    '<path d="M60 26C46 16 26 14 8 18V98C26 94 46 96 60 106Z" fill="#42A5F5"/>'
        '<path d="M60 26C74 16 94 14 112 18V98C94 94 74 96 60 106Z" '
        'fill="#1E88E5"/>'
        '<path d="M60 32C48 24 32 22 16 24V90C32 88 48 90 60 98Z" fill="#ffffff"/>'
        '<path d="M60 32C72 24 88 22 104 24V90C88 88 72 90 60 98Z" '
        'fill="#ECEFF1"/>'
        '<path d="M24 38C34 37 44 39 52 44M24 52C34 51 44 53 52 58M24 66'
        'C34 65 44 67 52 72M96 38C86 37 76 39 68 44M96 52C86 51 76 53 68 58" '
        'fill="none" stroke="#90A4AE" stroke-width="3" stroke-linecap="round"/>',
  ),
  const StickerArt(
    'Pencil',
    '<path d="M86 10L110 34L40 104L16 80Z" fill="#FFCA28" stroke="#F57F17" '
        'stroke-width="3"/>'
        '<path d="M86 10L110 34L98 46L74 22Z" fill="#EF9A9A"/>'
        '<path d="M16 80L40 104L8 112Z" fill="#FFE0B2"/>'
        '<path d="M8 112L18 109L11 102Z" fill="#37474F"/>',
  ),
  const StickerArt(
    'Coffee',
    '<path d="M42 30C36 22 48 18 42 8M62 30C56 22 68 18 62 8" fill="none" '
        'stroke="#A1887F" stroke-width="5" stroke-linecap="round"/>'
        '<path d="M86 52H98C112 52 112 86 94 86H82" fill="none" stroke="#8D6E63" '
        'stroke-width="8"/>'
        '<path d="M18 38H88V84C88 100 76 108 64 108H42C30 108 18 100 18 84Z" '
        'fill="#A1887F"/>'
        '<ellipse cx="53" cy="40" rx="35" ry="8" fill="#5D4037"/>'
        '<path d="M46 84C30 72 44 62 53 72C62 62 76 72 60 84L53 90Z" '
        'fill="#ffffff" fill-opacity="0.85"/>',
  ),
  const StickerArt(
    'Rocket',
    '<path d="M60 4C84 26 86 66 76 90H44C34 66 36 26 60 4Z" fill="#ECEFF1" '
        'stroke="#78909C" stroke-width="3"/>'
        '<path d="M60 4C70 13 76 24 79 36H41C44 24 50 13 60 4Z" fill="#EF5350"/>'
        '<circle cx="60" cy="52" r="11" fill="#4FC3F7" stroke="#78909C" '
        'stroke-width="3"/>'
        '<path d="M42 66L22 92L44 88ZM78 66L98 92L76 88Z" fill="#EF5350"/>'
        '<path d="M48 92H72C72 104 66 110 60 116C54 110 48 104 48 92Z" '
        'fill="#FFA726"/>',
  ),
  const StickerArt(
    'Cat',
    '<path d="M18 56L16 12L46 30C54 28 66 28 74 30L104 12L102 56C112 88 88 110 '
        '60 110C32 110 8 88 18 56Z" fill="#FFB74D" stroke="#E65100" '
        'stroke-width="3" stroke-linejoin="round"/>'
        '<path d="M22 22L25 40L38 32ZM98 22L95 40L82 32Z" fill="#F8BBD0"/>'
        '<ellipse cx="42" cy="62" rx="7" ry="9" fill="#3E2723"/>'
        '<ellipse cx="78" cy="62" rx="7" ry="9" fill="#3E2723"/>'
        '<path d="M54 76H66L60 83Z" fill="#E91E63"/>'
        '<path d="M60 83C56 92 46 92 44 86M60 83C64 92 74 92 76 86M6 70L28 74'
        'M6 86L28 82M114 70L92 74M114 86L92 82" fill="none" stroke="#3E2723" '
        'stroke-width="3" stroke-linecap="round"/>',
  ),
  const StickerArt(
    'Trophy',
    '<path d="M28 18H10C8 44 18 58 36 60M92 18H110C112 44 102 58 84 60" '
        'fill="none" stroke="#F9A825" stroke-width="7"/>'
        '<path d="M28 10H92V40C92 62 76 74 60 74C44 74 28 62 28 40Z" '
        'fill="#FFCA28" stroke="#F9A825" stroke-width="3"/>'
        '<rect x="53" y="74" width="14" height="18" fill="#F9A825"/>'
        '<rect x="36" y="92" width="48" height="18" rx="3" fill="#6D4C41"/>'
        '<path d="M60 22L64 33H76L66 40L70 51L60 44L50 51L54 40L44 33H56Z" '
        'fill="#ffffff" fill-opacity="0.85"/>',
  ),
  StickerArt('A+', _badge('#43A047', '#1B5E20', 'A+', 36)),
  StickerArt('Great job', _badge('#E53935', '#8E0000', 'WOW', 24)),
  StickerArt('Done', _badge('#1E88E5', '#0D47A1', '✓', 44)),
  StickerArt('Important', _banner('#E53935', '#8E0000', 'IMPORTANT', 13.5)),
  StickerArt('Exam', _banner('#8E24AA', '#4A148C', 'EXAM', 24)),
  StickerArt('Revise', _banner('#00897B', '#004D40', 'REVISE', 20)),
  StickerArt('To do', _banner('#FB8C00', '#BF360C', 'TO DO', 22)),
  StickerArt('Note', _banner('#3949AB', '#1A237E', 'NOTE', 24)),
];
