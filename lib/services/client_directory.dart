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
  final String relationshipType;
  final String additionalPhone;
  final String website;
  final String taxNumber;
  final String notes;
  final String bankName;
  final String bankAccountName;
  final String bankAccountNumber;
  final String paymentMethod;
  final String paymentTerms;
  final String accountCode;
  final String updatedAt;

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
    this.relationshipType = 'Client',
    this.additionalPhone = '',
    this.website = '',
    this.taxNumber = '',
    this.notes = '',
    this.bankName = '',
    this.bankAccountName = '',
    this.bankAccountNumber = '',
    this.paymentMethod = '',
    this.paymentTerms = '',
    this.accountCode = '',
    this.updatedAt = '',
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
      taxNumber: at(9),
      notes: at(10),
      updatedAt: at(12),
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
  static final List<ClientRecord> _addedClients = [];

  static List<ClientRecord> all() => [
    for (final row in SchemaMockData.rows('clients'))
      if (row.length > _nameIndex && row[_nameIndex].trim().isNotEmpty)
        ClientRecord.fromRow(row),
    ..._addedClients,
  ];

  static String nextClientNumber() =>
      'C-${(all().length + 1).toString().padLeft(4, '0')}';

  static bool emailTaken(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized.isNotEmpty &&
        all().any((client) => client.email.trim().toLowerCase() == normalized);
  }

  static void add(ClientRecord client) {
    _addedClients.add(client);
  }

  static ClientRecord? findByName(String name) {
    final target = name.trim().toLowerCase();
    if (target.isEmpty) return null;
    for (final client in all()) {
      if (client.name.toLowerCase() == target) return client;
    }
    return null;
  }

  static ClientRecord? findById(String id) {
    for (final client in all()) {
      if (client.id == id) return client;
    }
    return null;
  }
}
