import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/services/client_directory.dart';

void main() {
  test('loads clients from the clients table', () {
    final clients = ClientDirectory.all();

    expect(clients, isNotEmpty);
    expect(clients.first.id, isNotEmpty);
    expect(clients.first.name, isNotEmpty);
  });

  test('finds a client by name ignoring case and whitespace', () {
    final client = ClientDirectory.all().first;

    final found = ClientDirectory.findByName(
      '  ${client.name.toUpperCase()}  ',
    );

    expect(found?.id, client.id);
  });

  test('returns null for an unknown client', () {
    expect(ClientDirectory.findByName('Unknown Client'), isNull);
    expect(ClientDirectory.findByName(''), isNull);
  });
}
