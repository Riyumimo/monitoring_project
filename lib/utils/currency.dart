import 'package:flutter/services.dart';

/// Formats an amount as Indonesian rupiah, e.g. `1500000` -> `Rp 1.500.000`.
///
/// Returns an em dash when [amount] is null so it can be used directly in
/// detail rows.
String formatRupiah(num? amount) {
  if (amount == null) return '—';
  final rounded = amount.round();
  final sign = rounded < 0 ? '-' : '';
  return '${sign}Rp ${_groupDigits(rounded.abs().toString())}';
}

/// Formats an amount for a text field, without the `Rp` prefix.
String formatRupiahInput(num? amount) {
  if (amount == null) return '';
  final rounded = amount.round();
  final sign = rounded < 0 ? '-' : '';
  return '$sign${_groupDigits(rounded.abs().toString())}';
}

/// Parses a formatted rupiah value such as `1.500.000` back into a number.
double? parseRupiah(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return double.tryParse(digits);
}

/// Keeps digits only and groups them with dots while preserving the cursor.
class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  static final _nonDigits = RegExp(r'[^0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(_nonDigits, '');
    if (digits.isEmpty) return TextEditingValue.empty;

    final formatted = _groupDigits(digits);
    final cursor = newValue.selection.baseOffset
        .clamp(0, newValue.text.length)
        .toInt();
    final digitsBeforeCursor = newValue.text
        .substring(0, cursor)
        .replaceAll(_nonDigits, '')
        .length;

    var offset = 0;
    var seen = 0;
    while (offset < formatted.length && seen < digitsBeforeCursor) {
      if (formatted[offset] != '.') seen++;
      offset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

String _groupDigits(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
