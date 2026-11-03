import 'package:flutter/material.dart';

enum ButtonType { primary, light, lightFilled, lightError, errorFilled }

class _ColorScheme {
  final Color primary;
  final Color text;
  final Color? border;

  const _ColorScheme({required this.primary, required this.text, this.border});
}

class ButtonWidget extends StatefulWidget {
  final Function() onTap;
  final String text;
  final IconData? icon;
  final ButtonType type;
  final bool loading;
  final bool isEnabled;
  final bool fitContent;

  const ButtonWidget({
    super.key,
    required this.onTap,
    required this.text,
    this.type = ButtonType.primary,
    this.icon,
    this.loading = false,
    this.isEnabled = true,
    this.fitContent = false,
  });

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  bool loading = false;

  _ColorScheme color() {
    Color primaryColor = Theme.of(context).colorScheme.primary;
    Color warningColor = Theme.of(context).colorScheme.error;

    if (!widget.isEnabled) {
      return _ColorScheme(
        primary: primaryColor.withAlpha(50),
        text: Colors.white.withAlpha(50),
        border: primaryColor.withAlpha(50),
      );
    }
    Map<ButtonType, _ColorScheme> colorSchemeLight = {
      ButtonType.primary: _ColorScheme(
        primary: primaryColor,
        text: Colors.white,
      ),
      ButtonType.light: _ColorScheme(
        primary: Colors.transparent,
        text: primaryColor,
        border: primaryColor,
      ),
      ButtonType.lightFilled: _ColorScheme(
        primary: primaryColor.withAlpha(30),
        text: primaryColor,
        border: primaryColor,
      ),
      ButtonType.lightError: _ColorScheme(
        primary: Colors.transparent,
        text: warningColor,
        border: warningColor,
      ),
      ButtonType.errorFilled: _ColorScheme(
        primary: warningColor,
        text: Colors.white,
      ),
    };

    return colorSchemeLight[widget.type] ??
        colorSchemeLight[ButtonType.primary]!;
  }

  void _handleOnTap() async {
    if (!widget.isEnabled) return;
    setState(() {
      loading = true;
    });
    await widget.onTap();
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schemeColor = color();
    final isLoading = loading || widget.loading;
    return TextButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(schemeColor.primary),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: schemeColor.border != null
                ? BorderSide(color: schemeColor.border!)
                : BorderSide.none,
          ),
        ),
      ),
      onPressed: isLoading ? null : _handleOnTap,
      child: Row(
        mainAxisSize: widget.fitContent ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: schemeColor.text,
              ),
            ),
          if (widget.icon != null && !isLoading)
            ClipRect(child: Icon(widget.icon, color: schemeColor.text)),
          if (widget.icon != null || isLoading) const SizedBox(width: 13),
          Flexible(
            child: Text(
              widget.text,
              softWrap: true,
              textAlign: TextAlign.center,
              style: TextStyle(color: schemeColor.text),
            ),
          ),
        ],
      ),
    );
  }
}
