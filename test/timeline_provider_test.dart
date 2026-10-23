import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/timeline.dart';
import 'package:geoterra_monitoring/models/user.dart';
import 'package:geoterra_monitoring/providers/timeline_provider.dart';

void main() {
  test('seeds people and tasks for the timeline', () {
    final provider = TimelineProvider();

    expect(provider.people, isNotEmpty);
    expect(provider.tasks, isNotEmpty);
    expect(provider.tasksFor(provider.people.first.id), isNotEmpty);
    expect(provider.colorFor(provider.people.first.id), isA<Color>());

    provider.dispose();
  });

  test('supports adding, updating, and removing tasks', () {
    final provider = TimelineProvider();
    final person = provider.people.first;
    final task = TimelineTask(
      id: 't-test',
      personId: person.id,
      title: 'Test task',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 3),
      color: provider.colorFor(person.id),
    );

    provider.addTask(task);
    expect(provider.tasks.any((item) => item.id == 't-test'), isTrue);

    provider.updateTask(task.copyWith(title: 'Updated task'));
    expect(
      provider.tasks.firstWhere((item) => item.id == 't-test').title,
      'Updated task',
    );

    provider.removeTask('t-test');
    expect(provider.tasks.any((item) => item.id == 't-test'), isFalse);

    provider.dispose();
  });

  test('syncs people and tasks when workers change', () {
    final provider = TimelineProvider();
    final original = provider.people.first;
    final originalTaskIds = provider.tasksFor(original.id).length;
    expect(originalTaskIds, greaterThan(0));

    provider.syncWorkers(
      [
        User(
          id: original.id,
          name: 'Renamed Worker',
          email: 'renamed@geoterra.com',
          role: 'FieldWorker',
          workerTypes: const [WorkerType.field, WorkerType.cad],
        ),
        User(
          id: 'new-worker',
          name: 'New Worker',
          email: 'new@geoterra.com',
          role: 'FieldWorker',
        ),
      ],
      hasLoaded: true,
    );

    expect(provider.people.length, 2);
    expect(provider.people.first.name, 'Renamed Worker');
    expect(provider.people.first.roleLabel, 'Field Worker, CAD');
    expect(provider.tasksFor(original.id).length, originalTaskIds);
    expect(provider.tasksFor('new-worker'), isEmpty);

    provider.syncWorkers(const [], hasLoaded: true);
    expect(provider.people, isEmpty);
    expect(provider.tasks, isEmpty);

    provider.dispose();
  });

  test('does not clear the seeded timeline before workers load', () {
    final provider = TimelineProvider();
    final peopleCount = provider.people.length;
    final taskCount = provider.tasks.length;

    provider.syncWorkers(const [], hasLoaded: false);

    expect(provider.people.length, peopleCount);
    expect(provider.tasks.length, taskCount);

    provider.dispose();
  });
}
