import '../models/line_item_number_style.dart';
import '../models/offering_line_item.dart';

/// Builds hierarchical serial numbers for a description-of-work list.
///
/// A top-level row is `1`, its children are `1.1`, `1.2`, and a child of
/// `1.1` is `1.1.1`. Alphabet styles keep top-level rows numeric and use
/// letters for nested rows, for example `1`, `a`, `A` or `1`, `A`, `a`.
List<String> lineItemNumbers(
  List<OfferingLineItem> items, {
  LineItemNumberStyle style = LineItemNumberStyle.numeric,
}) {
  return lineItemNumbersForIndents(
    items.map((item) => item.indent),
    style: style,
  );
}

/// Builds the same hierarchical serial numbers from raw indent values.
///
/// This is used by forms that hold draft rows before they become
/// [OfferingLineItem]s.
List<String> lineItemNumbersForIndents(
  Iterable<int> indents, {
  LineItemNumberStyle style = LineItemNumberStyle.numeric,
}) {
  final numbers = <String>[];
  var top = 0;
  var sub = 0;
  var subSub = 0;

  for (final indent in indents) {
    if (indent == 0) {
      top++;
      sub = 0;
      subSub = 0;
      numbers.add(_formatNumber([top], style));
    } else if (indent == 1) {
      if (top == 0) top = 1;
      sub++;
      subSub = 0;
      numbers.add(_formatNumber([top, sub], style));
    } else {
      if (top == 0) top = 1;
      if (sub == 0) sub = 1;
      subSub++;
      numbers.add(_formatNumber([top, sub, subSub], style));
    }
  }
  return numbers;
}

/// Returns the visible number for each row, preferring a label the user typed
/// directly into the No. column.
List<String> lineItemLabels(
  List<OfferingLineItem> items, {
  LineItemNumberStyle style = LineItemNumberStyle.numeric,
}) {
  final generated = lineItemNumbers(items, style: style);
  return [
    for (var index = 0; index < items.length; index++)
      items[index].numberLabel.trim().isEmpty
          ? generated[index]
          : items[index].numberLabel.trim(),
  ];
}

/// Whether [value] can be used as a starting number such as `1`, `a` or `A`.
bool isLineItemNumberSeed(String value) {
  final trimmed = value.trim();
  return RegExp(r'^\d+$').hasMatch(trimmed) ||
      RegExp(r'^[a-zA-Z]+$').hasMatch(trimmed);
}

/// Returns the label that follows [seed] by [offset] steps.
///
/// Numbers increment numerically, lowercase letters increment alphabetically,
/// and uppercase letters stay uppercase.
String lineItemLabelAfter(String seed, int offset) {
  final trimmed = seed.trim();
  if (trimmed.isEmpty) return '';

  final number = int.tryParse(trimmed);
  if (number != null) return '${number + offset}';

  if (RegExp(r'^[a-z]+$').hasMatch(trimmed)) {
    return _alphaLower(_alphaIndex(trimmed) + offset);
  }
  if (RegExp(r'^[A-Z]+$').hasMatch(trimmed)) {
    return _alphaUpper(_alphaIndex(trimmed) + offset);
  }
  return trimmed;
}

String _formatNumber(List<int> segments, LineItemNumberStyle style) {
  if (segments.isEmpty) return '';
  return switch (style) {
    LineItemNumberStyle.numeric => segments.join('.'),
    LineItemNumberStyle.lowerAlpha => _formatAlphabet(
      segments,
      firstLevelUpper: false,
    ),
    LineItemNumberStyle.upperAlpha => _formatAlphabet(
      segments,
      firstLevelUpper: true,
    ),
  };
}

String _formatAlphabet(List<int> segments, {required bool firstLevelUpper}) {
  final top = '${segments.first}';
  if (segments.length == 1) return top;

  final nested = segments[1];
  if (segments.length == 2) {
    return firstLevelUpper ? _alphaUpper(nested) : _alphaLower(nested);
  }

  final deeper = segments[2];
  return firstLevelUpper ? _alphaLower(deeper) : _alphaUpper(deeper);
}

String _alphaLower(int value) => _alpha(value, upper: false);
String _alphaUpper(int value) => _alpha(value, upper: true);

int _alphaIndex(String value) {
  var result = 0;
  for (final code in value.codeUnits) {
    final base = code >= 97 ? 96 : 64;
    result = result * 26 + (code - base);
  }
  return result;
}

String _alpha(int value, {required bool upper}) {
  if (value <= 0) return '';
  final buffer = StringBuffer();
  var number = value;
  while (number > 0) {
    number -= 1;
    buffer.writeCharCode((upper ? 65 : 97) + (number % 26));
    number ~/= 26;
  }
  return buffer.toString().split('').reversed.join();
}
