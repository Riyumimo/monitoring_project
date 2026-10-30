import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/services/client_directory.dart';
import 'package:geoterra_monitoring/services/mock_data.dart';

void main() {
  test('mock 12-item offering has a complete description of work', () {
    final offering = MockData.offerings().firstWhere((item) => item.id == 'o9');

    expect(offering.number, 'OFF-009');
    expect(offering.name, 'Bintan Coastal Survey');
    expect(offering.lineItems, hasLength(12));
    expect(offering.budgetAmount, 1000000000);
    expect(offering.lineItems.map((item) => item.numberLabel), [
      'A',
      'B',
      '1',
      '2',
      '3',
      '4',
      'a',
      'b',
      'c',
      'd',
      '5',
      '6',
    ]);

    final indirect = offering.lineItems
        .firstWhere((item) => item.numberLabel == 'A')
        .amount;
    final direct = offering.lineItems
        .where((item) => item.indent == 1)
        .fold<double>(0, (total, item) => total + item.amount);
    expect(indirect + direct, 1000000000);

    expect(offering.clientId, isNotNull);
    expect(ClientDirectory.findById(offering.clientId!), isNotNull);
  });
}
