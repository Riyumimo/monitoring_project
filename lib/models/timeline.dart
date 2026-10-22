import 'package:flutter/material.dart';

/// A person/resource row in the Gantt chart.
class TimelinePerson {
  final String id;
  final String name;
  final String roleLabel;

  const TimelinePerson({
    required this.id,
    required this.name,
    this.roleLabel = '',
  });
}

/// A scheduled block on the Gantt chart.
class TimelineTask {
  final String id;
  final String personId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;

  /// Set for read-only task blocks generated from a project's schedule.
  final String? projectId;

  bool get isProjectSchedule => projectId != null;

  const TimelineTask({
    required this.id,
    required this.personId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.color,
    this.projectId,
  });

  TimelineTask copyWith({
    String? personId,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    Color? color,
  }) {
    return TimelineTask(
      id: id,
      personId: personId ?? this.personId,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
      projectId: projectId,
    );
  }
}
