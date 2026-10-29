import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/rich_text_controller.dart';

/// Adds Ctrl+B / Ctrl+I (and Cmd+B / Cmd+I on macOS) to a rich text field.
class RichTextShortcuts extends StatelessWidget {
  final RichTextEditingController controller;
  final Widget child;

  const RichTextShortcuts({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            controller.toggleBold,
        const SingleActivator(LogicalKeyboardKey.keyI, control: true):
            controller.toggleItalic,
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
            controller.toggleBold,
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true):
            controller.toggleItalic,
      },
      child: child,
    );
  }
}
