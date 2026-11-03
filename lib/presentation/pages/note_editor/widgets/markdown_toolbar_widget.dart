import 'package:flutter/material.dart';

class MarkdownToolbarWidget extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onStrikethrough;
  final VoidCallback onList;

  const MarkdownToolbarWidget({
    super.key,
    required this.onBold,
    required this.onItalic,
    required this.onStrikethrough,
    required this.onList,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.format_bold), onPressed: onBold),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: onItalic,
            ),
            IconButton(
              icon: const Icon(Icons.format_strikethrough),
              onPressed: onStrikethrough,
            ),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: onList,
            ),
          ],
        ),
      ),
    );
  }
}
