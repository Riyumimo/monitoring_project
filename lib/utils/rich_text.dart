import 'package:flutter/material.dart';

import '../models/line_item_text_run.dart';

/// Builds a Flutter text span for a line item description.
TextSpan lineItemTextSpan(
  String text,
  List<LineItemTextRun> runs, {
  TextStyle? style,
}) {
  if (text.isEmpty) return TextSpan(text: text, style: style);
  return TextSpan(
    style: style,
    children: [
      for (final run in normalizedLineItemTextRuns(text, runs))
        TextSpan(
          text: text.substring(run.start, run.end),
          style: run.isPlain
              ? null
              : TextStyle(
                  fontWeight: run.bold ? FontWeight.w700 : null,
                  fontStyle: run.italic ? FontStyle.italic : null,
                ),
        ),
    ],
  );
}
