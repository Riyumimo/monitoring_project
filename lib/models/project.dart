enum ProjectStatus { pending, inProgress, completed, onHold }

enum PaidStatus { unpaid, partiallyPaid, paid }

class Project {
  final String id;
  final String name;
  final String owner;
  final String address;
  final double? latitude;
  final double? longitude;
  final ProjectStatus status;
  final PaidStatus paidStatus;
  final List<String> tools;
  final String? assignedWorkerId;
  final String? assignedWorkerName;

  Project({
    required this.id,
    required this.name,
    required this.owner,
    required this.address,
    this.latitude,
    this.longitude,
    this.status = ProjectStatus.pending,
    this.paidStatus = PaidStatus.unpaid,
    this.tools = const [],
    this.assignedWorkerId,
    this.assignedWorkerName,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      owner: json['owner'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: _statusFromString(json['status'] ?? 'pending'),
      paidStatus: _paidStatusFromString(json['paidStatus'] ?? 'unpaid'),
      tools: List<String>.from(json['tools'] ?? []),
      assignedWorkerId: json['assignedWorkerId'],
      assignedWorkerName: json['assignedWorkerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner': owner,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': _statusToString(status),
      'paidStatus': _paidStatusToString(paidStatus),
      'tools': tools,
      'assignedWorkerId': assignedWorkerId,
      'assignedWorkerName': assignedWorkerName,
    };
  }

  static ProjectStatus _statusFromString(String status) {
    switch (status) {
      case 'inProgress':
        return ProjectStatus.inProgress;
      case 'completed':
        return ProjectStatus.completed;
      case 'onHold':
        return ProjectStatus.onHold;
      case 'pending':
      default:
        return ProjectStatus.pending;
    }
  }

  static String _statusToString(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inProgress:
        return 'inProgress';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.onHold:
        return 'onHold';
      case ProjectStatus.pending:
        return 'pending';
    }
  }

  static PaidStatus _paidStatusFromString(String status) {
    switch (status) {
      case 'partiallyPaid':
        return PaidStatus.partiallyPaid;
      case 'paid':
        return PaidStatus.paid;
      case 'unpaid':
      default:
        return PaidStatus.unpaid;
    }
  }

  static String _paidStatusToString(PaidStatus status) {
    switch (status) {
      case PaidStatus.partiallyPaid:
        return 'partiallyPaid';
      case PaidStatus.paid:
        return 'paid';
      case PaidStatus.unpaid:
        return 'unpaid';
    }
  }
}
