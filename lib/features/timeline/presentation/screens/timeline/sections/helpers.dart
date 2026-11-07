part of '../../timeline_page.dart';

extension _TimelineHelpers on _TimelinePageState {
  List<TimelineTask> _projectScheduleTasks(
    ProjectProvider projects,
    TimelineProvider timeline,
  ) {
    final workerIds = {for (final person in timeline.people) person.id};
    final tasks = <TimelineTask>[];

    for (final project in projects.projects) {
      final start = project.startDate;
      final end = project.endDate;
      if (start == null || end == null || end.isBefore(start)) continue;

      for (final workerId in project.assignedWorkerIds.toSet()) {
        if (!workerIds.contains(workerId)) continue;
        tasks.add(
          TimelineTask(
            id: 'project:${project.id}:$workerId',
            personId: workerId,
            title: project.name,
            startDate: DateUtils.dateOnly(start),
            endDate: DateUtils.dateOnly(end),
            color: _projectColor(project.status),
            projectId: project.id,
          ),
        );
      }
    }

    return tasks;
  }

  Color _projectColor(ProjectStatus status) {
    return switch (status) {
      ProjectStatus.planning => AppColors.pending,
      ProjectStatus.inProgress => AppColors.inProgress,
      ProjectStatus.onHold => AppColors.onHold,
      ProjectStatus.completed => AppColors.completed,
      ProjectStatus.cancelled => AppColors.textSecondary,
    };
  }

  List<TimelineTask> _tasksInMonth(List<TimelineTask> tasks) {
    return tasks
        .where(
          (task) =>
              !task.endDate.isBefore(_monthStart) &&
              !task.startDate.isAfter(_monthEnd),
        )
        .toList();
  }

  Map<String, List<_TaskPlacement>> _layoutTasks(
    TimelineProvider provider,
    List<TimelineTask> allTasks,
  ) {
    final result = <String, List<_TaskPlacement>>{};

    for (final person in provider.people) {
      final tasks =
          allTasks
              .where(
                (task) =>
                    task.personId == person.id &&
                    !task.endDate.isBefore(_monthStart) &&
                    !task.startDate.isAfter(_monthEnd),
              )
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));

      final laneEnds = <DateTime>[];
      final placements = <_TaskPlacement>[];

      for (final task in tasks) {
        var lane = laneEnds.indexWhere((end) => end.isBefore(task.startDate));
        if (lane == -1) {
          lane = laneEnds.length;
          laneEnds.add(task.endDate);
        } else {
          laneEnds[lane] = task.endDate;
        }
        placements.add(_TaskPlacement(task: task, lane: lane));
      }

      result[person.id] = placements;
    }

    return result;
  }

  double _rowHeightFor(List<_TaskPlacement> placements) {
    var lanes = 1;
    for (final placement in placements) {
      if (placement.lane + 1 > lanes) lanes = placement.lane + 1;
    }
    final needed =
        _TimelinePageState._rowPadding * 2 +
        lanes * _TimelinePageState._taskHeight +
        (lanes - 1) * _TimelinePageState._taskGap;
    return needed < _TimelinePageState._baseRowHeight
        ? _TimelinePageState._baseRowHeight
        : needed;
  }

  double? _todayOffset(double dayWidth) {
    final now = DateTime.now();
    if (now.year != _monthStart.year || now.month != _monthStart.month) {
      return null;
    }
    return (now.day - 1) * dayWidth + dayWidth / 2;
  }
}
