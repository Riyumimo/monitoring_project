import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/timeline.dart';
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
}
