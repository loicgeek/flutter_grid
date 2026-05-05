import 'package:flutter/material.dart';

/// A widget that renders [text] with occurrences of [highlight] marked.
class HighlightText extends StatelessWidget {
  final String text;
  final String? highlight;
  final TextStyle? style;
  final TextStyle? highlightStyle;

  const HighlightText({
    super.key,
    required this.text,
    this.highlight,
    this.style,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight == null || highlight!.isEmpty) {
      return Text(text, style: style);
    }

    final lower = text.toLowerCase();
    final hlLower = highlight!.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(hlLower, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + highlight!.length),
        style: (highlightStyle ??
            const TextStyle(
              fontWeight: FontWeight.bold,
              backgroundColor: Color(0xFFFFEB3B),
            )),
      ));
      start = idx + highlight!.length;
    }

    return Text.rich(TextSpan(children: spans));
  }
}
