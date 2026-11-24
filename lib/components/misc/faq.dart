import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

/// Questions with answers that open when tapped.
class FaqListView extends StatelessWidget {
  const FaqListView({super.key, required this.items, this.shrinkWrap = false});

  final List<FaqItem> items;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: shrinkWrap,
    children: [
      for (final item in items)
        YaruExpandable(
          header: Text(item.question),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(item.answer),
          ),
        ),
    ],
  );
}

/// One question and its answer.
class FaqItem {
  const FaqItem(this.question, this.answer);

  final String question;
  final String answer;
}
