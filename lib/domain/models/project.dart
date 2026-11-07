enum ProjectStatus { planning, inProgress, onHold, completed, cancelled }

/// The execution side of an accepted [Offering]. A project can only be
/// created once its offering is accepted, and it links back via [offeringId].
class Project {
  final String id;
  final String number;
  final String name;
  final String offeringId;
  final String owner;
  final String address;
  final double? latitude;
  final double? longitude;
  final ProjectStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? budgetAmount;
  final int progressPercentage;
  final List<String> tools;

  /// The field team assigned to this project. A project can have several
  /// workers, including both field workers and CAD specialists.
  final List<String> assignedWorkerIds;
  final List<String> assignedWorkerNames;

  Project({
    required this.id,
    this.number = '',
    required this.name,
    required this.offeringId,
    required this.owner,
    required this.address,
    this.latitude,
    this.longitude,
    this.status = ProjectStatus.planning,
    this.startDate,
    this.endDate,
    this.budgetAmount,
    this.progressPercentage = 0,
    this.tools = const [],
    this.assignedWorkerIds = const [],
    this.assignedWorkerNames = const [],
  });

  bool isAssignedTo(String workerId) => assignedWorkerIds.contains(workerId);

  Project copyWith({
    String? id,
    String? number,
    String? name,
    String? offeringId,
    String? owner,
    String? address,
    double? latitude,
    double? longitude,
    ProjectStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? budgetAmount,
    int? progressPercentage,
    List<String>? tools,
    List<String>? assignedWorkerIds,
    List<String>? assignedWorkerNames,
  }) {
    return Project(
      id: id ?? this.id,
      number: number ?? this.number,
      name: name ?? this.name,
      offeringId: offeringId ?? this.offeringId,
      owner: owner ?? this.owner,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      tools: tools ?? this.tools,
      assignedWorkerIds: assignedWorkerIds ?? this.assignedWorkerIds,
      assignedWorkerNames: assignedWorkerNames ?? this.assignedWorkerNames,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    final ids = json['assignedWorkerIds'];
    final names = json['assignedWorkerNames'];
    final legacyId = json['assignedWorkerId'];
    final legacyName = json['assignedWorkerName'];
    return Project(
      id: json['id'] ?? '',
      number: json['number'] ?? '',
      name: json['name'] ?? '',
      offeringId: json['offeringId'] ?? '',
      owner: json['owner'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: _statusFromString(json['status'] ?? 'planning'),
      startDate: _dateFromString(json['startDate']),
      endDate: _dateFromString(json['endDate']),
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble(),
      progressPercentage: (json['progressPercentage'] as num?)?.toInt() ?? 0,
      tools: List<String>.from(json['tools'] ?? []),
      assignedWorkerIds: ids is List
          ? List<String>.from(ids)
          : legacyId is String && legacyId.isNotEmpty
          ? [legacyId]
          : const [],
      assignedWorkerNames: names is List
          ? List<String>.from(names)
          : legacyName is String && legacyName.isNotEmpty
          ? [legacyName]
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'name': name,
      'offeringId': offeringId,
      'owner': owner,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': _statusToString(status),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'budgetAmount': budgetAmount,
      'progressPercentage': progressPercentage,
      'tools': tools,
      'assignedWorkerIds': assignedWorkerIds,
      'assignedWorkerNames': assignedWorkerNames,
    };
  }

  static DateTime? _dateFromString(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static ProjectStatus _statusFromString(String status) {
    switch (status) {
      case 'inProgress':
        return ProjectStatus.inProgress;
      case 'onHold':
        return ProjectStatus.onHold;
      case 'completed':
        return ProjectStatus.completed;
      case 'cancelled':
        return ProjectStatus.cancelled;
      case 'planning':
      default:
        return ProjectStatus.planning;
    }
  }

  static String _statusToString(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inProgress:
        return 'inProgress';
      case ProjectStatus.onHold:
        return 'onHold';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.cancelled:
        return 'cancelled';
      case ProjectStatus.planning:
        return 'planning';
    }
  }
}
