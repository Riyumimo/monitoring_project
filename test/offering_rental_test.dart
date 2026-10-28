import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/line_item_number_style.dart';
import 'package:geoterra_monitoring/models/offering.dart';
import 'package:geoterra_monitoring/models/offering_line_item.dart';
import 'package:geoterra_monitoring/services/mock_data.dart';
import 'package:geoterra_monitoring/utils/offering_line_items.dart';

void main() {
  test('Rent Tool offerings are rentals and preserve their until date', () {
    final offering = Offering(
      id: 'o-rent',
      name: 'Equipment Rental',
      serviceType: 'Rent Tool',
      owner: 'Owner',
      address: 'Address',
      rentalUntil: DateTime(2026, 12, 31),
    );

    expect(offering.isRentalService, isTrue);
    expect(offering.isCalibrationService, isFalse);

    final restored = Offering.fromJson(offering.toJson());
    expect(restored.rentalUntil, DateTime(2026, 12, 31));
  });

  test('recent client offer flag survives serialization', () {
    final offering = Offering(
      id: 'o-recent',
      name: 'Repeat Client Survey',
      owner: 'Client',
      address: 'Address',
      clientHasRecentOffer: true,
    );

    final restored = Offering.fromJson(offering.toJson());
    expect(restored.clientHasRecentOffer, isTrue);
  });

  test('numbering style survives serialization and defaults to numbers', () {
    final offering = Offering(
      id: 'o-style',
      name: 'Letter Numbering',
      owner: 'Client',
      address: 'Address',
      numberingStyle: LineItemNumberStyle.upperAlpha,
    );

    final restored = Offering.fromJson(offering.toJson());
    expect(restored.numberingStyle, LineItemNumberStyle.upperAlpha);

    final legacy = Offering.fromJson({
      'id': 'o-style-legacy',
      'name': 'Legacy Style',
      'owner': 'Client',
      'address': 'Address',
    });
    expect(legacy.numberingStyle, LineItemNumberStyle.numeric);
  });

  test('client offer flag defaults to false for older records', () {
    final restored = Offering.fromJson({
      'id': 'o-legacy',
      'name': 'Legacy Offering',
      'owner': 'Client',
      'address': 'Address',
    });

    expect(restored.clientHasRecentOffer, isFalse);
  });

  test('legacy paid statuses derive a matching amount paid', () {
    final partial = Offering(
      id: 'o-partial',
      name: 'Partial Payment',
      owner: 'Client',
      address: 'Address',
      paidStatus: PaidStatus.partiallyPaid,
      budgetAmount: 100000000,
    );
    final paid = Offering(
      id: 'o-paid',
      name: 'Fully Paid',
      owner: 'Client',
      address: 'Address',
      paidStatus: PaidStatus.paid,
      budgetAmount: 100000000,
    );

    expect(partial.amountPaid, 50000000);
    expect(partial.remainingAmount, 50000000);
    expect(paid.amountPaid, 100000000);
    expect(paid.isFullyPaid, isTrue);
  });

  test('recorded payment amount survives serialization', () {
    final offering = Offering(
      id: 'o-payment',
      name: 'Recorded Payment',
      owner: 'Client',
      address: 'Address',
      paidStatus: PaidStatus.partiallyPaid,
      budgetAmount: 100000000,
      amountPaid: 76000000,
    );

    final restored = Offering.fromJson(offering.toJson());
    expect(restored.amountPaid, 76000000);
    expect(restored.remainingAmount, 24000000);
  });

  test('survey offerings are not rentals', () {
    final offering = Offering(
      id: 'o-survey',
      name: 'Land Survey',
      serviceType: 'Land Survey',
      owner: 'Owner',
      address: 'Address',
    );

    expect(offering.isRentalService, isFalse);
    expect(offering.rentalUntil, isNull);
  });

  test('line items round-trip and derive the budget total', () {
    final offering = Offering(
      id: 'o-items',
      name: 'Itemised Survey',
      owner: 'Client',
      address: 'Address',
      lineItems: const [
        OfferingLineItem(
          description: 'Topographic survey',
          qty: '120',
          uom: 'Ha',
          amount: 75000000,
        ),
        OfferingLineItem(
          description: 'Reporting',
          qty: '1',
          uom: 'Lot',
          amount: 25000000,
        ),
      ],
    );

    final restored = Offering.fromJson(offering.toJson());

    expect(restored.lineItems, hasLength(2));
    expect(restored.lineItems.first.description, 'Topographic survey');
    expect(restored.lineItems.first.qty, '120');
    expect(restored.lineItems.first.uom, 'Ha');
    expect(restored.lineItems.first.amount, 75000000);
    expect(restored.lineItems.first.excludeFromTotal, isFalse);
    expect(restored.budgetAmount, 100000000);
  });

  test('nested line items keep their level and avoid double counting', () {
    final offering = Offering(
      id: 'o-nested',
      name: 'Nested Survey',
      owner: 'Client',
      address: 'Address',
      lineItems: const [
        OfferingLineItem(
          description: 'Field survey',
          qty: '1',
          uom: 'Lot',
          amount: 100000000,
        ),
        OfferingLineItem(
          description: 'Topographic survey',
          qty: '120',
          uom: 'Ha',
          amount: 70000000,
          indent: 1,
        ),
        OfferingLineItem(
          description: 'Reporting',
          qty: '1',
          uom: 'Lot',
          amount: 30000000,
          indent: 1,
        ),
      ],
    );

    final restored = Offering.fromJson(offering.toJson());

    expect(restored.lineItems[1].indent, 1);
    expect(restored.lineItems[2].indent, 1);
    expect(restored.budgetAmount, 100000000);
  });

  test('a section row can take its total from nested children', () {
    final offering = Offering(
      id: 'o-section',
      name: 'Sectioned Survey',
      owner: 'Client',
      address: 'Address',
      lineItems: const [
        OfferingLineItem(description: 'Field work', amount: 0),
        OfferingLineItem(
          description: 'Topographic survey',
          amount: 70000000,
          indent: 1,
        ),
        OfferingLineItem(description: 'Reporting', amount: 30000000, indent: 1),
      ],
    );

    final restored = Offering.fromJson(offering.toJson());

    expect(restored.budgetAmount, 100000000);
  });

  test('an excluded parent keeps its amount but counts only children', () {
    final offering = Offering(
      id: 'o-excluded',
      name: 'Sectioned Survey',
      owner: 'Client',
      address: 'Address',
      lineItems: const [
        OfferingLineItem(
          description: 'Direct Cost',
          amount: 90000000,
          excludeFromTotal: true,
        ),
        OfferingLineItem(
          description: 'Topographic survey',
          amount: 70000000,
          indent: 1,
        ),
        OfferingLineItem(description: 'Reporting', amount: 30000000, indent: 1),
      ],
    );

    final restored = Offering.fromJson(offering.toJson());

    expect(restored.lineItems.first.excludeFromTotal, isTrue);
    expect(restored.budgetAmount, 100000000);
  });

  test('mock offerings have line items that add up to their budget', () {
    for (final offering in MockData.offerings()) {
      final json = Map<String, dynamic>.from(offering.toJson())
        ..remove('budgetAmount');
      final derived = Offering.fromJson(json);

      expect(offering.lineItems, isNotEmpty, reason: offering.id);
      expect(derived.budgetAmount, offering.budgetAmount, reason: offering.id);
    }
  });

  test('line item numbers support numeric and alphabet styles', () {
    const items = [
      OfferingLineItem(description: 'Top level', amount: 1),
      OfferingLineItem(description: 'Child one', amount: 1, indent: 1),
      OfferingLineItem(description: 'Child two', amount: 1, indent: 1),
      OfferingLineItem(description: 'Second top level', amount: 1),
    ];

    expect(lineItemNumbers(items), ['1', '1.1', '1.2', '2']);
    expect(lineItemNumbersForIndents([0, 1, 1, 0]), ['1', '1.1', '1.2', '2']);
    expect(lineItemNumbers(items, style: LineItemNumberStyle.lowerAlpha), [
      '1',
      'a',
      'b',
      '2',
    ]);
    expect(lineItemNumbers(items, style: LineItemNumberStyle.upperAlpha), [
      '1',
      'A',
      'B',
      '2',
    ]);
    expect(
      lineItemNumbersForIndents([
        0,
        1,
        2,
        0,
      ], style: LineItemNumberStyle.lowerAlpha),
      ['1', 'a', 'A', '2'],
    );
    expect(
      lineItemNumbersForIndents([
        0,
        1,
        2,
        0,
      ], style: LineItemNumberStyle.upperAlpha),
      ['1', 'A', 'a', '2'],
    );
  });

  test('manual number labels override generated numbers', () {
    const items = [
      OfferingLineItem(description: 'Top level', amount: 1, numberLabel: '1'),
      OfferingLineItem(
        description: 'Child one',
        amount: 1,
        indent: 1,
        numberLabel: 'a',
      ),
      OfferingLineItem(
        description: 'Child two',
        amount: 1,
        indent: 1,
        numberLabel: 'b',
      ),
      OfferingLineItem(
        description: 'Second top level',
        amount: 1,
        numberLabel: '2',
      ),
      OfferingLineItem(description: 'Third top level', amount: 1),
    ];

    expect(lineItemLabels(items), ['1', 'a', 'b', '2', '3']);
    expect(lineItemLabels(items, style: LineItemNumberStyle.upperAlpha), [
      '1',
      'a',
      'b',
      '2',
      '3',
    ]);

    final restored = OfferingLineItem.fromJson(items[1].toJson());
    expect(restored.numberLabel, 'a');
  });

  test('typed number seeds increment numbers and letters', () {
    expect(lineItemLabelAfter('1', 3), '4');
    expect(lineItemLabelAfter('a', 2), 'c');
    expect(lineItemLabelAfter('A', 2), 'C');
    expect(lineItemLabelAfter('z', 1), 'aa');
    expect(lineItemLabelAfter('Z', 1), 'AA');

    expect(isLineItemNumberSeed('1'), isTrue);
    expect(isLineItemNumberSeed('a'), isTrue);
    expect(isLineItemNumberSeed('A'), isTrue);
    expect(isLineItemNumberSeed('1a'), isFalse);
    expect(isLineItemNumberSeed(''), isFalse);
  });

  test('legacy budget survives when a record has no line items', () {
    final restored = Offering.fromJson({
      'id': 'o-legacy-budget',
      'name': 'Legacy Budget',
      'owner': 'Client',
      'address': 'Address',
      'budgetAmount': 42000000,
    });

    expect(restored.lineItems, isEmpty);
    expect(restored.budgetAmount, 42000000);
  });
}
