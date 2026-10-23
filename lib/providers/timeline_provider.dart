import 'package:flutter/material.dart';

import '../models/timeline.dart';
import '../models/user.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';

/// Holds the people and task rows shown by the Timeline page.
class TimelineProvider extends ChangeNotifier {
  TimelineProvider() {
    _people = [
      for (final worker in MockData.workers())
        TimelinePerson(
          id: worker.id,
          name: worker.name,
          roleLabel: worker.workerTypesLabel,
        ),
    ];
    _tasks = _seedTasks(_people);
  }

  static const List<Color> _palette = [
    AppColors.primary,
    AppColors.inProgress,
    AppColors.pending,
    AppColors.accepted,
    AppColors.completed,
    AppColors.onHold,
  ];

  late List<TimelinePerson> _people;
  late List<TimelineTask> _tasks;

  List<TimelinePerson> get people => List.unmodifiable(_people);
  List<TimelineTask> get tasks => List.unmodifiable(_tasks);

  List<TimelineTask> tasksFor(String personId) =>
      _tasks.where((task) => task.personId == personId).toList();

  Color colorFor(String personId) {
    final index = _people.indexWhere((person) => person.id == personId);
    return _palette[(index < 0 ? 0 : index) % _palette.length];
  }

  void addTask(TimelineTask task) {
    _tasks.add(task);
    notifyListeners();
  }

  void updateTask(TimelineTask task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
    notifyListeners();
  }

  void removeTask(String id) {
    final before = _tasks.length;
    _tasks.removeWhere((task) => task.id == id);
    if (_tasks.length != before) notifyListeners();
  }

  /// Keeps the timeline people rows in sync with the worker directory.
  ///
  /// Added workers get a new row, renamed workers update in place, and tasks
  /// belonging to deleted workers are removed.
  void syncWorkers(List<User> workers, {required bool hasLoaded}) {
    // Before the worker directory has loaded, keep the seeded timeline intact.
    if (!hasLoaded && workers.isEmpty) return;

    final people = [
      for (final worker in workers)
        TimelinePerson(
          id: worker.id,
          name: worker.name,
          roleLabel: worker.workerTypesLabel,
        ),
    ];
    final ids = {for (final person in people) person.id};
    final retainedTasks = [
      for (final task in _tasks)
        if (ids.contains(task.personId)) task,
    ];

    _people = people;
    _tasks = [
      for (final task in retainedTasks)
        task.copyWith(color: colorFor(task.personId)),
    ];
    notifyListeners();
  }

  List<TimelineTask> _seedTasks(List<TimelinePerson> people) {
    if (people.isEmpty) return [];

    final now = DateTime.now();
    DateTime day(int value) =>
        DateTime(now.year, now.month, value.clamp(1, 28));

    final tasks = <TimelineTask>[];
    void add(int personIndex, int index, String title, int start, int end) {
      final person = people[personIndex % people.length];
      tasks.add(
        TimelineTask(
          id: 'seed-$personIndex-$index',
          personId: person.id,
          title: title,
          startDate: day(start),
          endDate: day(end),
          color: colorFor(person.id),
        ),
      );
    }

    add(0, 1, 'Site Survey - Kapuas', 2, 6);
    add(0, 2, 'Client Progress Meeting', 12, 13);
    add(1, 1, 'Boundary Mapping - Riau', 3, 10);
    add(1, 2, 'Field Validation', 18, 24);
    add(2, 1, 'Topographic Survey', 5, 14);
    add(2, 2, 'Data Review', 20, 22);
    add(3, 1, 'Peatland Sampling', 8, 16);
    add(3, 2, 'Equipment Check', 25, 27);
    add(4, 1, 'CAD Drafting', 6, 12);
    add(4, 2, 'Map Finalization', 15, 21);

    return tasks;
  }
}
