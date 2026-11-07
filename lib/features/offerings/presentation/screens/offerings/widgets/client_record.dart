part of '../../offerings_page.dart';

class _ClientRecord {
  final String number;
  final String type;
  final String name;
  final String contact;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String notes;
  final String updatedAt;

  const _ClientRecord({
    required this.number,
    required this.type,
    required this.name,
    required this.contact,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.notes,
    required this.updatedAt,
  });

  factory _ClientRecord.fromRow(List<String> row) {
    String at(int index) => index < row.length ? row[index] : '';
    return _ClientRecord(
      number: at(1),
      type: at(2),
      name: at(3),
      contact: at(4),
      email: at(5),
      phone: at(6),
      address: at(7),
      city: at(8),
      notes: at(10),
      updatedAt: at(12),
    );
  }

  factory _ClientRecord.fromClient(ClientRecord client) => _ClientRecord(
    number: client.number,
    type: client.type,
    name: client.name,
    contact: client.contactPerson,
    email: client.email,
    phone: client.phone,
    address: client.address,
    city: client.city,
    notes: client.notes,
    updatedAt: client.updatedAt,
  );

  bool get isBusiness => type == 'company' || type == 'organization';

  bool get isGovernment => type == 'government';

  String get typeLabel => switch (type.toLowerCase()) {
    'company' => 'Company',
    'government' => 'Government',
    'organization' => 'Organization',
    'individual' => 'Individual',
    _ => type.isEmpty ? 'Other' : type[0].toUpperCase() + type.substring(1),
  };

  Color get typeColor => switch (type.toLowerCase()) {
    'company' => AppColors.primary,
    'government' => AppColors.inProgress,
    'organization' => AppColors.pending,
    'individual' => AppColors.accepted,
    _ => AppColors.textSecondary,
  };

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get fullAddress {
    final parts = [address, city].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'No address' : parts.join(', ');
  }

  String get updatedLabel {
    if (updatedAt.length >= 10) return updatedAt.substring(0, 10);
    return updatedAt.isEmpty ? '—' : updatedAt;
  }

  bool matches(String query) {
    return [
      number,
      typeLabel,
      name,
      contact,
      email,
      phone,
      address,
      city,
      notes,
    ].any((value) => value.toLowerCase().contains(query));
  }
}
