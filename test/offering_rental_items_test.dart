import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/offering.dart';
import 'package:geoterra_monitoring/models/rental_tool.dart';

void main() {
  test('Offering.rentalItems round-trips and calculates budget', () {
    final offering = Offering(
      id: 'o-rental',
      name: 'GNSS Rental',
      serviceType: 'Rent Tool',
      owner: 'Client',
      address: 'Address',
      rentalItems: [
        RentalOfferingItem(tool: rentalToolCatalog[1], quantity: 2, duration: 5, startsAt: DateTime(2026, 10, 1), rate: 750000),
      ],
    );
    expect(offering.budgetAmount, 2 * 5 * 750000);
    final restored = Offering.fromJson(offering.toJson());
    expect(restored.rentalItems, hasLength(1));
    expect(restored.rentalItems.first.tool.id, 'rent-gnss');
    expect(restored.rentalTotal, 2 * 5 * 750000);
    expect(restored.budgetAmount, 2 * 5 * 750000);
  });

  test('isRentalService Offering recomputes budget from rentalItems', () {
    final offering = Offering(
      id: 'o-rental-multi',
      name: 'Multiple Rentals',
      serviceType: 'Rent Tool',
      owner: 'Client',
      address: 'Address',
      budgetAmount: 999999,
      rentalItems: [
        RentalOfferingItem(tool: rentalToolCatalog[0], quantity: 1, duration: 10, startsAt: DateTime(2026, 9, 1), rate: 350000),
        RentalOfferingItem(tool: rentalToolCatalog[2], quantity: 2, duration: 7, startsAt: DateTime(2026, 9, 2), rate: 100000),
      ],
    );
    expect(offering.budgetAmount, 1 * 10 * 350000 + 2 * 7 * 100000);
  });
}
