import 'package:flutter/material.dart';
import 'package:badnotes/components/ui/bn_overlays.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A layout ready to fill in. It goes on the board like a picture: move and
/// resize it with the lasso, and write on top of it.
class BoardKit {
  const BoardKit(this.name, this.svg);

  final String name;
  final String svg;

  static String _box(
    num x,
    num y,
    num w,
    num h,
    String fill, {
    String title = '',
    num radius = 14,
  }) =>
      '<rect x="$x" y="$y" width="$w" height="$h" rx="$radius" fill="$fill" '
      'stroke="#3D4356" stroke-width="2.5"/>'
      '${title.isEmpty ? '' : _label(x + w / 2, y + 30, title)}';

  static String _label(num x, num y, String text, {num size = 22}) =>
      '<text x="$x" y="$y" font-family="sans-serif" font-size="$size" '
      'font-weight="bold" text-anchor="middle" fill="#2A2F3F">$text</text>';

  /// Text from its left end, for rows and headings.
  static String _text(num x, num y, String text, {num size = 20}) =>
      '<text x="$x" y="$y" font-family="sans-serif" font-size="$size" '
      'font-weight="bold" fill="#2A2F3F">$text</text>';

  /// A box to tick.
  static String _tick(num x, num y) =>
      '<rect x="$x" y="$y" width="24" height="24" rx="5" fill="#FFFFFF" '
      'stroke="#3D4356" stroke-width="2.5"/>';

  /// A thin rule to write on.
  static String _rule(num x1, num y, num x2) =>
      '<line x1="$x1" y1="$y" x2="$x2" y2="$y" stroke="#B9C3D6" '
      'stroke-width="2"/>';

  static String _line(num x1, num y1, num x2, num y2) =>
      '<line x1="$x1" y1="$y1" x2="$x2" y2="$y2" stroke="#3D4356" '
      'stroke-width="3" stroke-linecap="round"/>';

  static String _arrow(num x1, num y1, num x2, num y2) {
    final horizontal = y1 == y2;
    final sign = (horizontal ? x2 > x1 : y2 > y1) ? 1 : -1;
    final a = horizontal
        ? '${x2 - 14 * sign},${y2 - 8} ${x2 - 14 * sign},${y2 + 8}'
        : '${x2 - 8},${y2 - 14 * sign} ${x2 + 8},${y2 - 14 * sign}';
    return '${_line(x1, y1, x2, y2)}'
        '<polygon points="$x2,$y2 $a" fill="#3D4356"/>';
  }

  static String _svg(num width, num height, String body) =>
      '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" '
      'viewBox="0 0 $width $height">$body</svg>';

  /// The layouts by what they're for: the same kinds as the picker's list.
  static Map<String, List<BoardKit>> get sections => {
    for (final MapEntry(:key, :value) in _kinds.entries)
      key: [
        for (final name in value) all.firstWhere((kit) => kit.name == name),
      ],
  };

  static final all = <BoardKit>[
    BoardKit(
      'Mind map',
      _svg(900, 600, '''
${_line(450, 300, 180, 110)}${_line(450, 300, 720, 110)}
${_line(450, 300, 180, 490)}${_line(450, 300, 720, 490)}
${_line(450, 300, 110, 300)}${_line(450, 300, 790, 300)}
<ellipse cx="450" cy="300" rx="130" ry="72" fill="#FFD27F" stroke="#3D4356" stroke-width="3"/>
${_label(450, 308, 'Main idea', size: 26)}
${_box(70, 70, 220, 80, '#CFE8FF')}${_box(610, 70, 220, 80, '#D8F3DC')}
${_box(70, 450, 220, 80, '#F7D6E6')}${_box(610, 450, 220, 80, '#E4DCFB')}
${_box(10, 260, 200, 80, '#FFE9C7')}${_box(690, 260, 200, 80, '#D3F4F4')}
'''),
    ),
    BoardKit(
      'Task board',
      _svg(960, 620, '''
${_box(10, 10, 300, 600, '#FBE4E4', title: 'To do')}
${_box(330, 10, 300, 600, '#FFF2CC', title: 'Doing')}
${_box(650, 10, 300, 600, '#DFF3E3', title: 'Done')}
${_line(30, 56, 290, 56)}${_line(350, 56, 610, 56)}${_line(670, 56, 930, 56)}
'''),
    ),
    BoardKit(
      'Flow chart',
      _svg(640, 760, '''
<rect x="210" y="10" width="220" height="80" rx="40" fill="#D8F3DC" stroke="#3D4356" stroke-width="2.5"/>
${_label(320, 58, 'Start')}
${_arrow(320, 90, 320, 150)}
${_box(190, 150, 260, 90, '#CFE8FF', radius: 8)}
${_arrow(320, 240, 320, 300)}
<polygon points="320,300 460,390 320,480 180,390" fill="#FFE9C7" stroke="#3D4356" stroke-width="2.5"/>
${_label(320, 398, 'Yes or no?')}
${_arrow(460, 390, 510, 390)}${_label(484, 376, 'No', size: 18)}
${_box(510, 345, 120, 90, '#F7D6E6', radius: 8)}
${_arrow(320, 480, 320, 540)}${_label(346, 520, 'Yes', size: 18)}
${_box(190, 540, 260, 90, '#CFE8FF', radius: 8)}
${_arrow(320, 630, 320, 670)}
<rect x="210" y="670" width="220" height="80" rx="40" fill="#E4DCFB" stroke="#3D4356" stroke-width="2.5"/>
${_label(320, 718, 'End')}
'''),
    ),
    BoardKit(
      'Timeline',
      _svg(1000, 340, '''
${_arrow(20, 170, 980, 170)}
${[
        for (final (i, color) in const ['#CFE8FF', '#D8F3DC', '#FFE9C7', '#F7D6E6', '#E4DCFB'].indexed) '<circle cx="${110 + i * 190}" cy="170" r="14" fill="$color" stroke="#3D4356" stroke-width="3"/>${_line(110 + i * 190, i.isEven ? 156 : 184, 110 + i * 190, i.isEven ? 120 : 220)}${_box(30 + i * 190, i.isEven ? 20 : 220, 160, 100, color)}',
      ].join()}
'''),
    ),
    BoardKit(
      'For and against',
      _svg(800, 600, '''
${_box(10, 10, 380, 580, '#DFF3E3', title: 'For')}
${_box(410, 10, 380, 580, '#FBE4E4', title: 'Against')}
${_line(30, 56, 370, 56)}${_line(430, 56, 770, 56)}
'''),
    ),
    BoardKit(
      'Four squares',
      _svg(800, 800, '''
${_box(10, 10, 380, 380, '#DFF3E3', title: 'Strengths')}
${_box(410, 10, 380, 380, '#FBE4E4', title: 'Weaknesses')}
${_box(10, 410, 380, 380, '#CFE8FF', title: 'Chances')}
${_box(410, 410, 380, 380, '#FFE9C7', title: 'Risks')}
'''),
    ),
    BoardKit(
      'Week plan',
      _svg(1000, 520, '''
${[
        for (final (i, day) in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexed) _box(6 + i * 142, 6, 134, 508, i > 4 ? '#FFF2CC' : '#EEF3FB', title: day, radius: 10),
      ].join()}
'''),
    ),
    BoardKit(
      'Two circles',
      _svg(840, 540, '''
<circle cx="300" cy="270" r="250" fill="#CFE8FF" fill-opacity="0.65" stroke="#3D4356" stroke-width="3"/>
<circle cx="540" cy="270" r="250" fill="#F7D6E6" fill-opacity="0.65" stroke="#3D4356" stroke-width="3"/>
${_label(170, 270, 'First')}${_label(670, 270, 'Second')}${_label(420, 270, 'Both')}
'''),
    ),
    BoardKit(
      'Cause and effect',
      _svg(1000, 560, '''
${_arrow(30, 280, 800, 280)}
${_box(800, 220, 190, 120, '#FBE4E4', title: 'Effect')}
${_line(200, 60, 320, 280)}${_line(460, 60, 580, 280)}
${_line(200, 500, 320, 280)}${_line(460, 500, 580, 280)}
${_box(90, 10, 220, 60, '#CFE8FF')}${_box(350, 10, 220, 60, '#D8F3DC')}
${_box(90, 490, 220, 60, '#FFE9C7')}${_box(350, 490, 220, 60, '#E4DCFB')}
'''),
    ),
    BoardKit(
      'Study loop',
      _svg(700, 700, '''
${_line(470, 70, 570, 70)}${_arrow(570, 70, 570, 220)}
${_line(570, 320, 570, 600)}${_arrow(570, 600, 470, 600)}
${_line(230, 600, 130, 600)}${_arrow(130, 600, 130, 380)}
${_line(130, 280, 130, 70)}${_arrow(130, 70, 230, 70)}
${_box(230, 20, 240, 100, '#CFE8FF', title: 'Read')}
${_box(450, 220, 240, 100, '#D8F3DC', title: 'Write it down')}
${_box(230, 550, 240, 100, '#FFE9C7', title: 'Test yourself')}
${_box(10, 280, 240, 100, '#F7D6E6', title: 'Fix the gaps')}
'''),
    ),

    BoardKit(
      'Cornell notes',
      _svg(820, 1000, '''
${_box(10, 10, 800, 980, '#FFFFFF', radius: 10)}
${_line(250, 10, 250, 760)}${_line(10, 760, 810, 760)}
${_text(30, 50, 'Cues')}${_text(270, 50, 'Notes')}${_text(30, 800, 'Summary')}
${[for (var y = 100; y < 750; y += 44) _rule(270, y, 790)].join()}
'''),
    ),
    BoardKit(
      'KWL chart',
      _svg(960, 640, '''
${_box(10, 10, 300, 620, '#CFE8FF', title: 'What I know')}
${_box(330, 10, 300, 620, '#FFF2CC', title: 'What I want to know')}
${_box(650, 10, 300, 620, '#DFF3E3', title: 'What I learned')}
'''),
    ),
    BoardKit(
      'Priority matrix',
      _svg(820, 820, '''
${_box(10, 10, 395, 395, '#FBE4E4', title: 'Urgent, important')}
${_box(415, 10, 395, 395, '#FFF2CC', title: 'Important, not urgent')}
${_box(10, 415, 395, 395, '#CFE8FF', title: 'Urgent, not important')}
${_box(415, 415, 395, 395, '#EDEDEA', title: 'Neither')}
'''),
    ),
    BoardKit(
      'Habit tracker',
      _svg(980, 520, '''
${_box(10, 10, 960, 500, '#FFFFFF', radius: 10)}
${[
        for (final (i, d) in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'].indexed) _label(330 + i * 90, 50, d),
      ].join()}
${[
        for (var r = 0; r < 6; r++) '${_rule(30, 110 + r * 70, 270)}${[for (var c = 0; c < 7; c++) _tick(318 + c * 90, 88 + r * 70)].join()}',
      ].join()}
'''),
    ),
    BoardKit(
      'Meeting notes',
      _svg(820, 900, '''
${_box(10, 10, 800, 880, '#FFFFFF', radius: 10)}
${_text(30, 55, 'Meeting', size: 26)}${_rule(160, 55, 790)}
${_text(30, 105, 'Date')}${_rule(100, 105, 400)}${_text(420, 105, 'People')}${_rule(520, 105, 790)}
${_box(30, 140, 760, 300, '#F0EDFC', title: 'Notes')}
${_box(30, 460, 370, 410, '#FFF2CC', title: 'Decisions')}
${_box(420, 460, 370, 410, '#DFF3E3', title: 'To do')}
'''),
    ),
    BoardKit(
      'Storyboard',
      _svg(980, 700, '''
${[for (var i = 0; i < 6; i++) '${_box(10 + (i % 3) * 325, 10 + (i ~/ 3) * 345, 305, 230, '#FFFFFF', radius: 8)}${_rule(20 + (i % 3) * 325, 280 + (i ~/ 3) * 345, 305 + (i % 3) * 325)}${_rule(20 + (i % 3) * 325, 320 + (i ~/ 3) * 345, 305 + (i % 3) * 325)}'].join()}
'''),
    ),
    BoardKit(
      'Flash cards',
      _svg(900, 620, '''
${_box(10, 10, 430, 290, '#FFF4CC', title: 'Question')}${_box(460, 10, 430, 290, '#E9F1FB', title: 'Answer')}
${_box(10, 320, 430, 290, '#FFF4CC', title: 'Question')}${_box(460, 320, 430, 290, '#E9F1FB', title: 'Answer')}
'''),
    ),
    BoardKit(
      'Lab report',
      _svg(820, 1040, '''
${_box(10, 10, 800, 150, '#DFF3E3', title: 'Aim')}
${_box(10, 180, 390, 260, '#CFE8FF', title: 'Apparatus')}
${_box(420, 180, 390, 260, '#FFF2CC', title: 'Method')}
${_box(10, 460, 800, 300, '#FFFFFF', title: 'Observations')}
${_box(10, 780, 800, 250, '#FBE4E4', title: 'Result and conclusion')}
'''),
    ),
    BoardKit(
      'Decision tree',
      _svg(960, 620, '''
${_arrow(480, 120, 240, 270)}${_arrow(480, 120, 720, 270)}
${_arrow(240, 360, 120, 480)}${_arrow(240, 360, 360, 480)}
${_arrow(720, 360, 600, 480)}${_arrow(720, 360, 840, 480)}
${_box(360, 20, 240, 100, '#FFE9C7', title: 'Question')}
${_box(130, 270, 220, 90, '#CFE8FF', title: 'Yes')}${_box(610, 270, 220, 90, '#FBE4E4', title: 'No')}
${_box(30, 480, 180, 100, '#FFFFFF')}${_box(270, 480, 180, 100, '#FFFFFF')}
${_box(510, 480, 180, 100, '#FFFFFF')}${_box(750, 480, 180, 100, '#FFFFFF')}
'''),
    ),
    BoardKit(
      'Daily planner',
      _svg(900, 960, '''
${_box(10, 10, 880, 80, '#F0EDFC')}${_text(30, 60, 'Today', size: 28)}
${_box(10, 110, 530, 840, '#FFFFFF', title: 'Schedule')}
${[for (var h = 0; h < 12; h++) '${_text(26, 196 + h * 62, '${(h + 7) % 12 + 1}:00', size: 16)}${_rule(100, 200 + h * 62, 525)}'].join()}
${_box(560, 110, 330, 420, '#FFF2CC', title: 'To do')}
${[for (var i = 0; i < 7; i++) '${_tick(580, 168 + i * 50)}${_rule(615, 190 + i * 50, 870)}'].join()}
${_box(560, 550, 330, 400, '#DFF3E3', title: 'Notes')}
'''),
    ),
    BoardKit(
      'Exam checklist',
      _svg(820, 900, '''
${_box(10, 10, 800, 880, '#FFFFFF', radius: 10)}
${_text(30, 60, 'Exam:', size: 28)}${_rule(130, 60, 790)}
${_label(500, 115, 'Read')}${_label(620, 115, 'Revised')}${_label(740, 115, 'Tested')}
${[for (var i = 0; i < 12; i++) '${_rule(30, 180 + i * 58, 430)}${_tick(488, 158 + i * 58)}${_tick(608, 158 + i * 58)}${_tick(728, 158 + i * 58)}'].join()}
'''),
    ),
    BoardKit(
      'Book summary',
      _svg(820, 980, '''
${_box(10, 10, 800, 120, '#F0EDFC')}${_text(30, 60, 'Title', size: 26)}${_rule(120, 60, 790)}${_text(30, 105, 'Author')}${_rule(120, 105, 790)}
${_box(10, 150, 800, 260, '#FFFFFF', title: 'In short')}
${_box(10, 430, 390, 300, '#CFE8FF', title: 'Big ideas')}
${_box(420, 430, 390, 300, '#FFF2CC', title: 'Quotes')}
${_box(10, 750, 800, 220, '#DFF3E3', title: 'What I think')}
'''),
    ),
    BoardKit(
      'Formula sheet',
      _svg(900, 760, '''
${[
        for (var i = 0; i < 6; i++) _box(10 + (i % 2) * 445, 10 + (i ~/ 2) * 250, 435, 235, const ['#CFE8FF', '#FFF2CC', '#DFF3E3', '#FBE4E4', '#E4DCFB', '#FFE9C7'][i], title: 'Topic'),
      ].join()}
'''),
    ),
    BoardKit(
      'Concept map',
      _svg(960, 660, '''
${_line(480, 330, 200, 140)}${_line(480, 330, 760, 140)}${_line(480, 330, 200, 520)}${_line(480, 330, 760, 520)}
${_line(200, 140, 200, 520)}${_line(760, 140, 760, 520)}
<rect x="360" y="280" width="240" height="100" rx="50" fill="#FFD27F" stroke="#3D4356" stroke-width="3"/>
${_label(480, 338, 'Concept', size: 24)}
${_box(90, 95, 220, 90, '#CFE8FF')}${_box(650, 95, 220, 90, '#D8F3DC')}
${_box(90, 475, 220, 90, '#F7D6E6')}${_box(650, 475, 220, 90, '#E4DCFB')}
'''),
    ),
    BoardKit(
      'Comparison table',
      _svg(960, 700, '''
${_box(10, 10, 940, 680, '#FFFFFF', radius: 10)}
${_box(10, 10, 940, 70, '#F0EDFC', radius: 10)}
${_line(250, 10, 250, 690)}${_line(483, 10, 483, 690)}${_line(716, 10, 716, 690)}
${_label(366, 55, 'Option A')}${_label(600, 55, 'Option B')}${_label(833, 55, 'Option C')}
${[for (var r = 1; r < 7; r++) _line(10, 80 + r * 87, 950, 80 + r * 87)].join()}
'''),
    ),
    BoardKit(
      'Weekly review',
      _svg(900, 820, '''
${_box(10, 10, 435, 390, '#DFF3E3', title: 'Went well')}
${_box(455, 10, 435, 390, '#FBE4E4', title: 'To do better')}
${_box(10, 420, 435, 390, '#CFE8FF', title: 'Learned')}
${_box(455, 420, 435, 390, '#FFF2CC', title: 'Next week')}
'''),
    ),
    BoardKit(
      'Reading log',
      _svg(960, 760, '''
${_box(10, 10, 940, 740, '#FFFFFF', radius: 10)}
${_box(10, 10, 940, 64, '#F0EDFC', radius: 10)}
${_text(30, 52, 'Date')}${_text(180, 52, 'Book')}${_text(560, 52, 'Pages')}${_text(700, 52, 'Thoughts')}
${_line(160, 10, 160, 750)}${_line(540, 10, 540, 750)}${_line(680, 10, 680, 750)}
${[for (var r = 1; r < 11; r++) _line(10, 74 + r * 67, 950, 74 + r * 67)].join()}
'''),
    ),
    BoardKit(
      'Goal ladder',
      _svg(820, 900, '''
${_box(210, 10, 400, 110, '#FFD27F', title: 'Goal')}
${_arrow(410, 230, 410, 130)}
${_box(160, 240, 500, 110, '#E4DCFB', title: 'Step 3')}
${_arrow(410, 460, 410, 360)}
${_box(110, 470, 600, 110, '#CFE8FF', title: 'Step 2')}
${_arrow(410, 690, 410, 590)}
${_box(60, 700, 700, 110, '#DFF3E3', title: 'Step 1: start here')}
'''),
    ),
  ];
}

/// What each layout is for, for the picker's list (design 18).
const _kinds = <String, List<String>>{
  'Study': [
    'Cornell notes',
    'KWL chart',
    'Flash cards',
    'Formula sheet',
    'Exam checklist',
    'Lab report',
    'Book summary',
    'Reading log',
    'Study loop',
    'Timeline',
  ],
  'Plan': [
    'Daily planner',
    'Week plan',
    'Task board',
    'Habit tracker',
    'Weekly review',
    'Goal ladder',
  ],
  'Think': [
    'Mind map',
    'Concept map',
    'Two circles',
    'For and against',
    'Four squares',
    'Comparison table',
    'Storyboard',
  ],
  'Diagrams': ['Flow chart', 'Decision tree', 'Cause and effect'],
  'Work': ['Meeting notes', 'Priority matrix'],
};

/// Which ready-made layout to put on the page (design 18): kinds down the
/// side, a search, and every layout as a picture of itself.
Future<BoardKit?> showBoardKitPicker(BuildContext context) =>
    showGeneralDialog<BoardKit>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: const Color(0x47141416),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, _) =>
          const BnAboveKeyboard(child: _KitPicker()),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.97, end: 1.0).animate(animation),
          child: child,
        ),
      ),
    );

class _KitPicker extends StatefulWidget {
  const _KitPicker();

  @override
  State<_KitPicker> createState() => _KitPickerState();
}

class _KitPickerState extends State<_KitPicker> {
  String? _kind;
  var _search = '';

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.of(context);
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 760;
    final kits = [
      for (final kit in BoardKit.all)
        if ((_kind == null || (_kinds[_kind]?.contains(kit.name) ?? false)) &&
            kit.name.toLowerCase().contains(_search.toLowerCase()))
          kit,
    ];
    Widget kindRow(String? kind, String label, int count) {
      final selected = _kind == kind;
      return Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          onTap: () => setState(() => _kind = kind),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              '$label · $count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
            ),
          ),
        ),
      );
    }

    final kinds = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 2,
      children: [
        kindRow(null, 'All', BoardKit.all.length),
        for (final MapEntry(:key, :value) in _kinds.entries)
          kindRow(key, key, value.length),
      ],
    );
    final grid = GridView.extent(
      maxCrossAxisExtent: 180,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.82,
      children: [
        for (final kit in kits)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context, kit),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: SvgPicture.string(kit.svg),
                  ),
                ),
                Text(
                  kit.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Search layouts',
            prefixIcon: const Icon(Icons.search, size: 18),
            isDense: true,
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        Expanded(
          child: kits.isEmpty
              ? const Center(child: Text('No layout has that name'))
              : grid,
        ),
      ],
    );
    return Center(
      child: Material(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: (size.width - 48).clamp(320.0, 1120.0),
          height: (size.height - 96).clamp(420.0, 720.0),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 220,
                      color: scheme.surfaceContainerLow,
                      padding: const EdgeInsets.fromLTRB(12, 22, 12, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 0, 12, 14),
                            child: Text(
                              'Layouts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          kinds,
                          const Spacer(),
                          Text(
                            'Placed where you are; move, resize and write on '
                            'every part.',
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: body,
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final kind in [null, ..._kinds.keys])
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(kind ?? 'All'),
                                  selected: _kind == kind,
                                  onSelected: (_) =>
                                      setState(() => _kind = kind),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: body),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
