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
