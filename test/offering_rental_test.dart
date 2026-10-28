import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/offering.dart';

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
}
