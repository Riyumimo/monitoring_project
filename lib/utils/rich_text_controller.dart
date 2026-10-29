import 'package:flutter/material.dart';

import '../models/line_item_text_run.dart';

/// A [TextEditingController] that keeps simple bold/italic character styles
/// alongside the plain text.
///
/// The styles are rendered directly by the text field, so the user sees bold
/// and italic text without any markup characters.
class RichTextEditingController extends TextEditingController {
  RichTextEditingController({
    String text = '',
    List<LineItemTextRun> runs = const [],
    this.onFormatChanged,
  }) : _styles = List<_CharStyle>.filled(text.length, const _CharStyle()),
       super(text: text) {
    _previousText = text;
    _previousSelection = selection;
    _applyRuns(runs);
    addListener(_handleValueChanged);
  }

  List<_CharStyle> _styles;
  late String _previousText;
  late TextSelection _previousSelection;
  bool? _pendingBold;
  bool? _pendingItalic;

  void Function({bool? bold, bool? italic})? onFormatChanged;

  /// Non-overlapping style ranges for the current text.
  List<LineItemTextRun> get formatRuns {
    if (text.isEmpty || _styles.length != text.length) return const [];
    final runs = <LineItemTextRun>[];
    var start = 0;
    for (var index = 1; index <= text.length; index++) {
      final boundary =
          index == text.length || !_styles[index].sameAs(_styles[start]);
      if (boundary) {
        final style = _styles[start];
        if (!style.isPlain) {
          runs.add(
            LineItemTextRun(
              start: start,
              end: index,
              bold: style.bold,
              italic: style.italic,
            ),
          );
        }
        start = index;
      }
    }
    return runs;
  }

  void toggleBold() => _toggle(bold: true);

  void toggleItalic() => _toggle(bold: false);

  void _toggle({required bool bold}) {
    final currentSelection = selection;
    if (!currentSelection.isValid) return;

    if (currentSelection.isCollapsed) {
      final base = _baseStyleAt(currentSelection.start);
      if (bold) {
        _pendingBold = _pendingBold == null ? !base.bold : !_pendingBold!;
        onFormatChanged?.call(bold: _pendingBold);
      } else {
        _pendingItalic = _pendingItalic == null
            ? !base.italic
            : !_pendingItalic!;
        onFormatChanged?.call(italic: _pendingItalic);
      }
      return;
    }

    final start = currentSelection.start.clamp(0, text.length).toInt();
    final end = currentSelection.end.clamp(0, text.length).toInt();
    if (start == end) return;

    final makeBold = bold ? !_allBold(start, end) : false;
    final makeItalic = bold ? false : !_allItalic(start, end);
    final nextStyles = List<_CharStyle>.from(_styles);
    for (var index = start; index < end; index++) {
      nextStyles[index] = _CharStyle(
        bold: bold ? makeBold : nextStyles[index].bold,
        italic: bold ? nextStyles[index].italic : makeItalic,
      );
    }
    _styles = nextStyles;
    if (bold) {
      _pendingBold = makeBold;
      onFormatChanged?.call(bold: makeBold);
    } else {
      _pendingItalic = makeItalic;
      onFormatChanged?.call(italic: makeItalic);
    }
    notifyListeners();
  }

  bool _allBold(int start, int end) {
    for (var index = start; index < end; index++) {
      if (!_styles[index].bold) return false;
    }
    return true;
  }

  bool _allItalic(int start, int end) {
    for (var index = start; index < end; index++) {
      if (!_styles[index].italic) return false;
    }
    return true;
  }

  void _applyRuns(List<LineItemTextRun> runs) {
    for (final run in runs) {
      final start = run.start.clamp(0, text.length).toInt();
      final end = run.end.clamp(0, text.length).toInt();
      if (end <= start) continue;
      for (var index = start; index < end; index++) {
        _styles[index] = _CharStyle(
          bold: _styles[index].bold || run.bold,
          italic: _styles[index].italic || run.italic,
        );
      }
    }
  }

  void _handleValueChanged() {
    final newText = text;
    final newSelection = selection;
    if (newText != _previousText) {
      _styles = _adjustStyles(_previousText, newText);
      _previousText = newText;
    } else if (newSelection != _previousSelection) {
      _pendingBold = null;
      _pendingItalic = null;
    }
    _previousSelection = newSelection;
  }

  List<_CharStyle> _adjustStyles(String oldText, String newText) {
    final oldStyles = _styles;
    if (oldText.isEmpty) {
      return List<_CharStyle>.filled(
        newText.length,
        _insertionStyle(0, oldStyles),
      );
    }

    var prefix = 0;
    final maxPrefix = oldText.length < newText.length
        ? oldText.length
        : newText.length;
    while (prefix < maxPrefix &&
        oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }

    var suffix = 0;
    final maxSuffix = (oldText.length - prefix) < (newText.length - prefix)
        ? (oldText.length - prefix)
        : (newText.length - prefix);
    while (suffix < maxSuffix &&
        oldText.codeUnitAt(oldText.length - 1 - suffix) ==
            newText.codeUnitAt(newText.length - 1 - suffix)) {
      suffix++;
    }

    final insertedLength = newText.length - prefix - suffix;
    final insertedStyle = _insertionStyle(prefix, oldStyles);
    final result = <_CharStyle>[];
    result.addAll(oldStyles.take(prefix));
    result.addAll(List<_CharStyle>.filled(insertedLength, insertedStyle));
    if (suffix > 0) {
      result.addAll(oldStyles.skip(oldText.length - suffix));
    }
    return result;
  }

  _CharStyle _insertionStyle(int position, List<_CharStyle> styles) {
    final base = _styleAt(position, styles);
    return _CharStyle(
      bold: _pendingBold ?? base.bold,
      italic: _pendingItalic ?? base.italic,
    );
  }

  _CharStyle _baseStyleAt(int position) => _styleAt(position, _styles);

  _CharStyle _styleAt(int position, List<_CharStyle> styles) {
    if (styles.isEmpty) return const _CharStyle();
    if (position > 0) {
      return styles[(position - 1).clamp(0, styles.length - 1).toInt()];
    }
    return styles[0];
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty || _styles.length != text.length) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final composing = withComposing ? value.composing : TextRange.empty;
    final children = <TextSpan>[];
    var start = 0;
    for (var index = 1; index <= text.length; index++) {
      final boundary =
          index == text.length || !_styles[index].sameAs(_styles[start]);
      if (boundary) {
        final charStyle = _styles[start];
        final isComposing =
            composing.isValid &&
            composing.start < index &&
            composing.end > start;
        children.add(
          TextSpan(
            text: text.substring(start, index),
            style: TextStyle(
              fontWeight: charStyle.bold ? FontWeight.w700 : null,
              fontStyle: charStyle.italic ? FontStyle.italic : null,
              decoration: isComposing ? TextDecoration.underline : null,
            ),
          ),
        );
        start = index;
      }
    }
    return TextSpan(style: style, children: children);
  }

  @override
  void dispose() {
    removeListener(_handleValueChanged);
    super.dispose();
  }
}

class _CharStyle {
  final bool bold;
  final bool italic;

  const _CharStyle({this.bold = false, this.italic = false});

  bool get isPlain => !bold && !italic;

  bool sameAs(_CharStyle other) => bold == other.bold && italic == other.italic;
}
