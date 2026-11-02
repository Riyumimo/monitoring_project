import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/rental_tool.dart';

void main() {
  test('RentalOfferingItem enforces valid quantity, duration, and rate', () {
    final tool = rentalToolCatalog.first;
    expect(
      () => RentalOfferingItem(tool: tool, quantity: 0, duration: 1, startsAt: DateTime(2026, 10, 1), rate: 1000),
      throwsArgumentError,
    );
    expect(
      () => RentalOfferingItem(tool: tool, quantity: 1, duration: -5, startsAt: DateTime(2026, 10, 1), rate: 1000),
      throwsArgumentError,
    );
    expect(
      () => RentalOfferingItem(tool: tool, quantity: 1, duration: 1, startsAt: DateTime(2026, 10, 1), rate: double.infinity),
      throwsArgumentError,
    );
  });

  test('duration calculates end date and total correctly', () {
    final tool = rentalToolCatalog[1];
    final item = RentalOfferingItem(tool: tool, quantity: 2, duration: 5, startsAt: DateTime(2026, 10, 20), rate: 750000);
    expect(item.endsAt, DateTime(2026, 10, 24));
    expect(item.total, 2 * 5 * 750000);
  });

  test('RentalOfferingItem round-trips through JSON', () {
    final tool = rentalToolCatalog[2];
    final item = RentalOfferingItem(tool: tool, quantity: 3, duration: 10, startsAt: DateTime(2026, 11, 5), rate: 100000);
    final restored = RentalOfferingItem.fromJson(item.toJson());
    expect(restored.tool.id, tool.id);
    expect(restored.quantity, 3);
    expect(restored.duration, 10);
    expect(restored.startsAt, DateTime(2026, 11, 5));
    expect(restored.rate, 100000);
  });
}
