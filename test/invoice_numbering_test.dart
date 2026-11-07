import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/domain/models/offering.dart';
import 'package:geoterra_monitoring/features/invoices/services/invoice_numbering.dart';

Offering _offering({
  required String id,
  required String number,
  String serviceType = 'Rent Tool',
}) {
  return Offering(
    id: id,
    number: number,
    name: 'Offering $number',
    serviceType: serviceType,
    owner: 'PT Contoh',
    address: 'Jakarta',
  );
}

void main() {
  test('builds 001/INV/SWA-GTI/X/2026 for an October rental invoice', () {
    expect(
      InvoiceNumbering.rental(sequence: 1, issuedAt: DateTime(2026, 10, 7)),
      '001/INV/SWA-GTI/X/2026',
    );
  });

  test('pads the sequence to three digits and keeps longer sequences', () {
    expect(InvoiceNumbering.paddedSequence(1), '001');
    expect(InvoiceNumbering.paddedSequence(12), '012');
    expect(InvoiceNumbering.paddedSequence(999), '999');
    expect(InvoiceNumbering.paddedSequence(1234), '1234');
  });

  test('rejects a non-positive sequence', () {
    expect(() => InvoiceNumbering.paddedSequence(0), throwsArgumentError);
    expect(
      () => InvoiceNumbering.rental(sequence: -1, issuedAt: DateTime(2026)),
      throwsArgumentError,
    );
  });

  test('uses Roman numerals for every month', () {
    const expected = [
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
      'XI',
      'XII',
    ];
    for (var month = 1; month <= 12; month++) {
      expect(InvoiceNumbering.romanMonth(month), expected[month - 1]);
    }
    expect(() => InvoiceNumbering.romanMonth(0), throwsArgumentError);
    expect(() => InvoiceNumbering.romanMonth(13), throwsArgumentError);
  });

  test('sequence counts only Rent Tool offerings, ordered by number', () {
    final offerings = [
      _offering(id: 'o2', number: 'OFF-002', serviceType: 'Land Survey'),
      _offering(id: 'o7', number: 'OFF-007'),
      _offering(id: 'o3', number: 'OFF-003', serviceType: 'Calibrate Service'),
      _offering(id: 'o9', number: 'OFF-009'),
    ];

    expect(
      InvoiceNumbering.rentalSequence(offerings, offerings[3]),
      2,
      reason: 'OFF-009 is the second rental offering',
    );
    expect(InvoiceNumbering.rentalSequence(offerings, offerings[1]), 1);
    expect(
      InvoiceNumbering.rentalSequence(offerings, offerings[0]),
      3,
      reason: 'non-rental offerings are numbered last',
    );
    expect(
      InvoiceNumbering.rentalSequence(offerings, offerings[2]),
      3,
      reason: 'calibration is not a rental service',
    );
  });

  test('an offering missing from the list is numbered last', () {
    final offerings = [
      _offering(id: 'o7', number: 'OFF-007'),
      _offering(id: 'o9', number: 'OFF-009'),
    ];
    final newcomer = _offering(id: 'o10', number: 'OFF-010');

    expect(InvoiceNumbering.rentalSequence(offerings, newcomer), 3);
    expect(
      InvoiceNumbering.rental(
        sequence: InvoiceNumbering.rentalSequence(offerings, newcomer),
        issuedAt: DateTime(2026, 11, 2),
      ),
      '003/INV/SWA-GTI/XI/2026',
    );
  });
}
