import 'package:flutter/material.dart';

class MarkdownToolbarWidget extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;

  const MarkdownToolbarWidget({
    super.key,
    required this.onBold,
    required this.onItalic,
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
          ],
        ),
      ),
    );
  }
}
