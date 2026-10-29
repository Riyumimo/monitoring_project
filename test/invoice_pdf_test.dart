import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/line_item_text_run.dart';
import 'package:geoterra_monitoring/models/offering.dart';
import 'package:geoterra_monitoring/models/offering_line_item.dart';
import 'package:geoterra_monitoring/models/payment.dart';
import 'package:geoterra_monitoring/services/client_directory.dart';
import 'package:geoterra_monitoring/services/invoice_pdf.dart';

void main() {
  const client = ClientRecord(
    id: 'CLT-1',
    number: 'CLT-2026-001',
    type: 'company',
    name: 'PT Riau Green Energy',
    contactPerson: 'Siti Rahma',
    email: 'finance@riau-green.test',
    phone: '+62 761 000 111',
    address: 'Jl. Sudirman 10',
    city: 'Pekanbaru',
  );

  Offering offering() => Offering(
    id: 'OFR-1',
    number: 'OFR-2026-014',
    name: 'Topographic Survey',
    serviceType: 'Topographic Survey',
    owner: client.name,
    address: 'Sungai Kapuas, Kalimantan Barat',
    status: OfferingStatus.accepted,
    paidStatus: PaidStatus.partiallyPaid,
    budgetAmount: 25000000,
    amountPaid: 10000000,
  );

  test('builds a client invoice PDF with payment history', () async {
    final bytes = await buildOfferingInvoicePdf(
      offering: offering(),
      client: client,
      payments: [
        Payment(
          id: 'PAY-1',
          offeringId: 'OFR-1',
          amount: 10000000,
          paidAt: DateTime(2026, 10, 27),
          method: PaymentMethod.transfer,
          invoiceNumber: 'INV-EXT-8842',
          note: 'First installment',
        ),
      ],
      issuedAt: DateTime(2026, 10, 28),
    );

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });

  test('builds an invoice from the offering description of work', () async {
    final bytes = await buildOfferingInvoicePdf(
      offering: Offering(
        id: 'OFR-ITEMS',
        number: 'OFR-2026-015',
        name: 'Itemised Survey',
        serviceType: 'Topographic Survey',
        owner: client.name,
        address: 'Sungai Kapuas, Kalimantan Barat',
        status: OfferingStatus.accepted,
        paidStatus: PaidStatus.unpaid,
        budgetAmount: 30000000,
        lineItems: const [
          OfferingLineItem(
            description: 'Field survey',
            descriptionRuns: [
              LineItemTextRun(start: 0, end: 5, bold: true),
              LineItemTextRun(start: 6, end: 12, italic: true),
            ],
            qty: '1',
            uom: 'Lot',
            amount: 30000000,
          ),
          OfferingLineItem(
            description: 'Topographic survey',
            qty: '120',
            uom: 'Ha',
            amount: 20000000,
            indent: 1,
          ),
          OfferingLineItem(
            description: 'Reporting and deliverables',
            qty: '1',
            uom: 'Lot',
            amount: 10000000,
            indent: 1,
          ),
        ],
      ),
      client: client,
      issuedAt: DateTime(2026, 10, 28),
    );

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });

  test('builds an invoice when the budget is not set', () async {
    final bytes = await buildOfferingInvoicePdf(
      offering: Offering(
        id: 'OFR-2',
        name: 'Rent Total Station',
        serviceType: 'Rent Tool',
        owner: 'Walk-in client',
        address: 'Site office',
        rentalUntil: DateTime(2026, 11, 2),
      ),
      issuedAt: DateTime(2026, 10, 28),
    );

    expect(bytes.length, greaterThan(500));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });

  test(
    'builds a template invoice with PO, tax, bank and custom items',
    () async {
      final bytes = await buildOfferingInvoicePdf(
        offering: offering(),
        client: client,
        issuedAt: DateTime(2026, 10, 28),
        poNumber: '002/SMI/X/2026',
        poDate: DateTime(2026, 10, 19),
        taxRate: 0.11,
        bankName: 'Bank Mandiri',
        bankAccountNumber: '123-00-4567890-1',
        bankAccountName: 'PT. GeoTerra Indonesia',
        items: const [
          InvoiceLineItem(
            sn: 'A',
            description: 'Indirect Cost, mobilization & demobilization',
            amount: 5000000,
            emphasized: true,
          ),
          InvoiceLineItem(
            sn: '1',
            description: 'Topographic Survey - 120 ha',
            qty: '1',
            uom: 'Lot',
            amount: 20000000,
            indent: 1,
          ),
        ],
      );

      expect(bytes.length, greaterThan(1000));
      expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    },
  );

  test('formats amounts in Indonesian words', () {
    expect(terbilangRupiah(0), 'Nol rupiah');
    expect(terbilangRupiah(1000000), 'Satu juta rupiah');
    expect(terbilangRupiah(1500000), 'Satu juta lima ratus ribu rupiah');
    expect(terbilangRupiah(111000000), 'Seratus sebelas juta rupiah');
  });

  test('creates a safe invoice file name', () {
    expect(invoicePdfFileName(offering()), 'Invoice-OFR-2026-014.pdf');
    expect(
      invoicePdfFileName(
        Offering(id: 'OFR 3/2026', name: 'X', owner: 'A', address: 'B'),
      ),
      'Invoice-OFR-3-2026.pdf',
    );
  });
}
