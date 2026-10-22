import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/utils/currency.dart';

void main() {
  group('formatRupiah', () {
    test('groups thousands with dots and adds the Rp prefix', () {
      expect(formatRupiah(1500000), 'Rp 1.500.000');
      expect(formatRupiah(92000000), 'Rp 92.000.000');
      expect(formatRupiah(0), 'Rp 0');
    });

    test('shows an em dash for a missing amount', () {
      expect(formatRupiah(null), '—');
    });
  });

  group('formatRupiahInput', () {
    test('formats digits without the currency prefix', () {
      expect(formatRupiahInput(1500000), '1.500.000');
      expect(formatRupiahInput(null), '');
    });
  });

  group('parseRupiah', () {
    test('parses a grouped value', () {
      expect(parseRupiah('1.500.000'), 1500000);
      expect(parseRupiah('Rp 92.000.000'), 92000000);
    });

    test('returns null for an empty value', () {
      expect(parseRupiah(''), isNull);
      expect(parseRupiah('Rp '), isNull);
    });
  });

  group('RupiahInputFormatter', () {
    const formatter = RupiahInputFormatter();

    test('groups typed digits and keeps the cursor at the end', () {
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1500000',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );

      expect(value.text, '1.500.000');
      expect(value.selection.baseOffset, 9);
    });

    test('strips non-digit characters', () {
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: 'Rp 1.500.000',
          selection: TextSelection.collapsed(offset: 12),
        ),
      );

      expect(value.text, '1.500.000');
    });

    test('returns an empty value when all digits are removed', () {
      final value = formatter.formatEditUpdate(
        const TextEditingValue(text: '1.000'),
        TextEditingValue.empty,
      );

      expect(value.text, isEmpty);
    });
  });
}
