import 'package:flutter/material.dart';

class NotesSearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const NotesSearchBarWidget({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      hintText: hintText,
      elevation: const WidgetStatePropertyAll(0),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
      leading: const Icon(Icons.search),
      trailing: [
        if (controller.text.isNotEmpty)
          IconButton(icon: const Icon(Icons.close), onPressed: onClear),
      ],
      onChanged: onChanged,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
    );
  }
}
