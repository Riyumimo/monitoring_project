import '../../../domain/models/offering.dart';

/// Builds official invoice numbers in the Geoterra document format:
///
/// ```
/// 001/INV/SWA-GTI/X/2026
///  │    │   │   │  └─ year
///  │    │   │   └──── issue month as a Roman numeral (X = October)
///  │    │   └──────── service code + company code (SWA = sewa, GTI = Geoterra)
///  │    └──────────── document type (INV = invoice)
///  └───────────────── 3-digit sequence per service type
/// ```
class InvoiceNumbering {
  InvoiceNumbering._();

  static const String invoiceCode = 'INV';
  static const String companyCode = 'GTI';

  /// `SWA` — *sewa*, the code used for Rent Tool invoices.
  static const String rentalServiceCode = 'SWA';

  static const List<String> _romanMonths = [
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

  /// Zero-pads [sequence] to at least three digits (`1` -> `001`).
  static String paddedSequence(int sequence) {
    if (sequence < 1) {
      throw ArgumentError.value(
        sequence,
        'sequence',
        'Must be greater than 0.',
      );
    }
    return sequence.toString().padLeft(3, '0');
  }

  /// [month] as a Roman numeral (`10` -> `X`).
  static String romanMonth(int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Must be between 1 and 12.');
    }
    return _romanMonths[month - 1];
  }

  /// Rent Tool invoice number, e.g. `001/INV/SWA-GTI/X/2026`.
  static String rental({required int sequence, required DateTime issuedAt}) {
    return '${paddedSequence(sequence)}/$invoiceCode/'
        '$rentalServiceCode-$companyCode/'
        '${romanMonth(issuedAt.month)}/${issuedAt.year}';
  }

  /// 1-based sequence of [offering] among the Rent Tool offerings in
  /// [offerings]. Numbers are derived from the stored offering data (ordered by
  /// `number`, then `id`), so an existing offering keeps the same sequence.
  ///
  /// An offering that is not in [offerings] yet is numbered last.
  static int rentalSequence(Iterable<Offering> offerings, Offering offering) {
    final rentals = offerings.where((item) => item.isRentalService).toList()
      ..sort(_compareOfferings);

    final index = rentals.indexWhere((item) => item.id == offering.id);
    return index >= 0 ? index + 1 : rentals.length + 1;
  }

  static int _compareOfferings(Offering a, Offering b) {
    final byNumber = a.number.compareTo(b.number);
    return byNumber != 0 ? byNumber : a.id.compareTo(b.id);
  }
}
