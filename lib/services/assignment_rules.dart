import '../models/project.dart';
import '../models/user.dart';

/// Business rules for assigning workers to projects.
///
/// - CAD workers can take on as many engagements as needed (no cap).
/// - Field workers based in town/office can take up to [fieldInOfficeMax].
/// - Field workers who are out of town can only hold [fieldOutOfTownMax].
///
/// An engagement counts towards a worker's load while it is still open:
/// projects that are not completed/cancelled. Field team assignment only
/// exists on projects, so offerings no longer occupy capacity.
class AssignmentRules {
  AssignmentRules._();

  static const int fieldInOfficeMax = 2;
  static const int fieldOutOfTownMax = 1;

  /// Maximum number of concurrent engagements a worker may hold, or `null`
  /// when there is no limit.
  static int? maxProjects(User worker) {
    if (worker.isCad) return null;
    return worker.availability == WorkAvailability.outOfTown
        ? fieldOutOfTownMax
        : fieldInOfficeMax;
  }

  /// Engagements that currently occupy the worker's capacity.
  static int activeLoad(
    String workerId, {
    List<Project> projects = const [],
  }) {
    return projects
        .where((p) =>
            p.isAssignedTo(workerId) &&
            p.status != ProjectStatus.completed &&
            p.status != ProjectStatus.cancelled)
        .length;
  }

  /// Whether [worker] can still be given another assignment.
  ///
  /// [ignoreProjectId] excludes the record currently being edited so an
  /// already-assigned worker is not counted against themselves.
  static bool canAssign(
    User worker, {
    List<Project> projects = const [],
    String? ignoreProjectId,
  }) {
    final max = maxProjects(worker);
    if (max == null) return true;
    final load = activeLoad(
      worker.id,
      projects: projects.where((p) => p.id != ignoreProjectId).toList(),
    );
    return load < max;
  }

  /// Human readable summary of a worker's capacity.
  static String capacityLabel(
    User worker, {
    List<Project> projects = const [],
    String? ignoreProjectId,
  }) {
    final load = activeLoad(
      worker.id,
      projects: projects.where((p) => p.id != ignoreProjectId).toList(),
    );
    final max = maxProjects(worker);
    if (max == null) {
      return '${worker.workerTypesLabel} • no limit ($load active)';
    }
    return '${worker.availabilityLabel} • $load/$max active';
  }

  /// Explains why a worker cannot be assigned, or `null` when they can.
  static String? blockedReason(
    User worker, {
    List<Project> projects = const [],
    String? ignoreProjectId,
  }) {
    if (canAssign(
      worker,
      projects: projects,
      ignoreProjectId: ignoreProjectId,
    )) {
      return null;
    }
    final max = maxProjects(worker);
    if (worker.hasWorkerType(WorkerType.field) &&
        worker.availability == WorkAvailability.outOfTown) {
      return 'Out of town — max $max engagement.';
    }
    return 'Already at the $max engagement limit.';
  }
}
