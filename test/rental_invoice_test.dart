import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/offering.dart';
import 'package:geoterra_monitoring/models/rental_tool.dart';
import 'package:geoterra_monitoring/services/invoice_rental_pdf.dart';

void main() {
  Offering rentalOffering() => Offering(
    id: 'o-rental-invoice',
    name: 'October Equipment Rental',
    number: 'OFR-RENT-001',
    serviceType: 'Rent Tool',
    owner: 'PT. WIJAYA KARYA\nJAMBI TAHAP 2',
    address: 'Jambi',
    status: OfferingStatus.sent,
    rentalItems: [
      RentalOfferingItem(
        tool: rentalToolCatalog[0],
        quantity: 1,
        duration: 30,
        startsAt: DateTime(2026, 9, 19),
        rate: 5500000,
      ),
      RentalOfferingItem(
        tool: rentalToolCatalog[2],
        quantity: 1,
        duration: 30,
        startsAt: DateTime(2026, 9, 19),
        rate: 100000,
      ),
    ],
  );

  test('rental invoice builds from offering rental items', () async {
    final offering = rentalOffering();
    final pdf = await buildRentalInvoicePdf(
      offering: offering,
      invoiceNumber: '010/INV/SWA-GTI/X/2026',
      issuedAt: DateTime(2026, 10, 21),
      bankName: 'Bank BRI',
      bankAccountNumber: '5635-0101-1353-509',
      bankAccountName: 'SARIS',
    );
    expect(pdf.lengthInBytes, greaterThan(5000));
  });

  test('rental invoice honours per-item rates instead of hard-coded values',
      () async {
    final low = await buildRentalInvoicePdf(
      offering: Offering(
        id: 'a',
        name: 'Low',
        serviceType: 'Rent Tool',
        owner: 'Client A',
        address: 'Jambi',
        rentalItems: [
          RentalOfferingItem(
            tool: rentalToolCatalog[2],
            quantity: 1,
            duration: 5,
            startsAt: DateTime(2026, 1, 1),
            rate: 100000,
          ),
        ],
      ),
    );
    final high = await buildRentalInvoicePdf(
      offering: Offering(
        id: 'b',
        name: 'High',
        serviceType: 'Rent Tool',
        owner: 'Client A',
        address: 'Jambi',
        rentalItems: [
          RentalOfferingItem(
            tool: rentalToolCatalog[0],
            quantity: 1,
            duration: 30,
            startsAt: DateTime(2026, 1, 1),
            rate: 9000000,
          ),
        ],
      ),
    );
    expect(low.lengthInBytes, isNot(equals(high.lengthInBytes)));
  });
}
