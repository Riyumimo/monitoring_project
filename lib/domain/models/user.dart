/// Field teams are split between general field workers and CAD specialists.
/// A worker can hold more than one type.
enum WorkerType { field, cad, manager, owner }

extension WorkerTypeX on WorkerType {
  String get label => switch (this) {
    WorkerType.field => 'Field Worker',
    WorkerType.cad => 'CAD',
    WorkerType.manager => 'Manager',
    WorkerType.owner => 'Owner',
  };
}

/// Where a worker currently is. Field workers can only take on extra
/// assignments while they are in office / in town.
enum WorkAvailability { inOffice, outOfTown }

class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'Manager' or 'FieldWorker'
  final String? phone;
  final List<WorkerType> workerTypes;
  final WorkAvailability availability;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.workerTypes = const [WorkerType.field],
    this.availability = WorkAvailability.inOffice,
  });

  bool hasWorkerType(WorkerType type) => workerTypes.contains(type);

  bool get isCad => hasWorkerType(WorkerType.cad);

  String get workerTypesLabel {
    if (workerTypes.isEmpty) return 'No Type';
    return workerTypes.map((type) => type.label).join(', ');
  }

  String get availabilityLabel =>
      availability == WorkAvailability.inOffice ? 'In Office' : 'Out of Town';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'],
      workerTypes: _workerTypesFromJson(json),
      availability: _availabilityFromString(json['availability'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'workerTypes': [
        for (final type in workerTypes) _workerTypeToString(type),
      ],
      'availability': _availabilityToString(availability),
    };
  }

  static List<WorkerType> _workerTypesFromJson(Map<String, dynamic> json) {
    final values = json['workerTypes'];
    if (values is List) {
      final types = <WorkerType>[];
      for (final value in values) {
        if (value is! String) continue;
        final type = _workerTypeFromString(value);
        if (type != null && !types.contains(type)) types.add(type);
      }
      if (types.isNotEmpty) return types;
    }

    // Backwards compatibility with sessions saved before multi-type workers.
    final legacy = _workerTypeFromString(json['workerType'] as String?);
    return [legacy ?? WorkerType.field];
  }

  static WorkerType? _workerTypeFromString(String? value) {
    switch (value) {
      case 'cad':
        return WorkerType.cad;
      case 'manager':
        return WorkerType.manager;
      case 'owner':
        return WorkerType.owner;
      case 'field':
        return WorkerType.field;
      default:
        return null;
    }
  }

  static String _workerTypeToString(WorkerType value) {
    switch (value) {
      case WorkerType.cad:
        return 'cad';
      case WorkerType.manager:
        return 'manager';
      case WorkerType.owner:
        return 'owner';
      case WorkerType.field:
        return 'field';
    }
  }

  static WorkAvailability _availabilityFromString(String? value) {
    switch (value) {
      case 'outOfTown':
        return WorkAvailability.outOfTown;
      case 'inOffice':
      default:
        return WorkAvailability.inOffice;
    }
  }

  static String _availabilityToString(WorkAvailability value) {
    switch (value) {
      case WorkAvailability.outOfTown:
        return 'outOfTown';
      case WorkAvailability.inOffice:
        return 'inOffice';
    }
  }
}
