import 'schema_mock_data.dart';

/// A client from the `clients` table, exposed for forms that need to select
/// an existing client instead of typing a name.
class ClientRecord {
  final String id;
  final String number;
  final String type;
  final String name;
  final String contactPerson;
  final String email;
  final String phone;
  final String address;
  final String city;

  const ClientRecord({
    required this.id,
    required this.number,
    required this.type,
    required this.name,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
  });

  factory ClientRecord.fromRow(List<String> row) {
    String at(int index) => index < row.length ? row[index].trim() : '';
    return ClientRecord(
      id: at(0),
      number: at(1),
      type: at(2),
      name: at(3),
      contactPerson: at(4),
      email: at(5),
      phone: at(6),
      address: at(7),
      city: at(8),
    );
  }

  String get typeLabel => switch (type.toLowerCase()) {
    'company' => 'Company',
    'government' => 'Government',
    'organization' => 'Organization',
    'individual' => 'Individual',
    _ => type.isEmpty ? 'Other' : type[0].toUpperCase() + type.substring(1),
  };

  String get location =>
      [address, city].where((part) => part.isNotEmpty).join(', ');

  bool matches(String query) {
    return [
      number,
      typeLabel,
      name,
      contactPerson,
      email,
      phone,
      address,
      city,
    ].any((value) => value.toLowerCase().contains(query));
  }
}

class ClientDirectory {
  ClientDirectory._();

  static const _nameIndex = 3;

  static List<ClientRecord> all() => [
    for (final row in SchemaMockData.rows('clients'))
      if (row.length > _nameIndex && row[_nameIndex].trim().isNotEmpty)
        ClientRecord.fromRow(row),
  ];

  static ClientRecord? findByName(String name) {
    final target = name.trim().toLowerCase();
    if (target.isEmpty) return null;
    for (final client in all()) {
      if (client.name.toLowerCase() == target) return client;
    }
    return null;
  }
}
