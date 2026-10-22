/// Field teams are split between general field workers and CAD specialists.
enum WorkerType { field, cad }

/// Where a worker currently is. Field workers can only take on extra
/// assignments while they are in office / in town.
enum WorkAvailability { inOffice, outOfTown }

class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'Manager' or 'FieldWorker'
  final String? phone;
  final WorkerType workerType;
  final WorkAvailability availability;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.workerType = WorkerType.field,
    this.availability = WorkAvailability.inOffice,
  });

  String get workerTypeLabel =>
      workerType == WorkerType.cad ? 'CAD' : 'Field Worker';

  String get availabilityLabel =>
      availability == WorkAvailability.inOffice ? 'In Office' : 'Out of Town';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'],
      workerType: _workerTypeFromString(json['workerType'] as String?),
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
      'workerType': _workerTypeToString(workerType),
      'availability': _availabilityToString(availability),
    };
  }

  static WorkerType _workerTypeFromString(String? value) {
    switch (value) {
      case 'cad':
        return WorkerType.cad;
      case 'field':
      default:
        return WorkerType.field;
    }
  }

  static String _workerTypeToString(WorkerType value) {
    switch (value) {
      case WorkerType.cad:
        return 'cad';
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
