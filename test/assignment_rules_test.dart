import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/project.dart';
import 'package:geoterra_monitoring/models/user.dart';
import 'package:geoterra_monitoring/services/assignment_rules.dart';

User _field(WorkAvailability availability) => User(
      id: 'f1',
      name: 'Field Worker',
      email: 'field@geoterra.com',
      role: 'FieldWorker',
      availability: availability,
    );

User _cad() => User(
      id: 'c1',
      name: 'CAD Specialist',
      email: 'cad@geoterra.com',
      role: 'FieldWorker',
      workerTypes: const [WorkerType.cad],
    );

Project _project(
  String id,
  List<String> workerIds, {
  ProjectStatus status = ProjectStatus.inProgress,
}) =>
    Project(
      id: id,
      name: 'Project $id',
      offeringId: 'o-$id',
      owner: 'Owner',
      address: 'Address',
      status: status,
      assignedWorkerIds: workerIds,
      assignedWorkerNames: [for (final id in workerIds) 'Worker $id'],
    );

void main() {
  test('field worker in office can hold up to 2 active projects', () {
    final worker = _field(WorkAvailability.inOffice);
    final one = [_project('p1', ['f1'])];
    final two = [...one, _project('p2', ['f1'])];

    expect(AssignmentRules.maxProjects(worker), 2);
    expect(AssignmentRules.canAssign(worker, projects: one), isTrue);
    expect(AssignmentRules.canAssign(worker, projects: two), isFalse);
  });

  test('out-of-town field worker can only hold 1 project', () {
    final worker = _field(WorkAvailability.outOfTown);
    final one = [_project('p1', ['f1'])];

    expect(AssignmentRules.maxProjects(worker), 1);
    expect(AssignmentRules.canAssign(worker), isTrue);
    expect(AssignmentRules.canAssign(worker, projects: one), isFalse);
  });

  test('CAD worker has no assignment limit', () {
    final worker = _cad();
    final many = [for (var i = 0; i < 5; i++) _project('p$i', ['c1'])];

    expect(AssignmentRules.maxProjects(worker), isNull);
    expect(AssignmentRules.canAssign(worker, projects: many), isTrue);
  });

  test('a worker with both field and CAD types has no assignment limit', () {
    final worker = User(
      id: 'fc1',
      name: 'Field CAD Worker',
      email: 'fieldcad@geoterra.com',
      role: 'FieldWorker',
      workerTypes: const [WorkerType.field, WorkerType.cad],
      availability: WorkAvailability.outOfTown,
    );
    final many = [for (var i = 0; i < 3; i++) _project('p$i', ['fc1'])];

    expect(worker.workerTypesLabel, 'Field Worker, CAD');
    expect(AssignmentRules.maxProjects(worker), isNull);
    expect(AssignmentRules.canAssign(worker, projects: many), isTrue);
  });

  test('closed projects do not count towards the limit', () {
    final worker = _field(WorkAvailability.inOffice);
    final projects = [
      _project('p1', ['f1'], status: ProjectStatus.completed),
      _project('p2', ['f1'], status: ProjectStatus.cancelled),
    ];

    expect(AssignmentRules.activeLoad('f1', projects: projects), 0);
    expect(AssignmentRules.canAssign(worker, projects: projects), isTrue);
  });

  test('the record being edited does not count against the worker', () {
    final worker = _field(WorkAvailability.inOffice);
    final projects = [_project('p1', ['f1']), _project('p2', ['f1'])];

    expect(AssignmentRules.canAssign(worker, projects: projects), isFalse);
    expect(
      AssignmentRules.canAssign(worker, projects: projects, ignoreProjectId: 'p2'),
      isTrue,
    );
  });

  test('a project can assign several workers independently', () {
    final field = _field(WorkAvailability.inOffice);
    final cad = _cad();
    final projects = [_project('p1', ['f1', 'c1'])];

    expect(projects.first.assignedWorkerIds, ['f1', 'c1']);
    expect(AssignmentRules.activeLoad('f1', projects: projects), 1);
    expect(AssignmentRules.activeLoad('c1', projects: projects), 1);
    expect(AssignmentRules.canAssign(field, projects: projects), isTrue);
    expect(AssignmentRules.canAssign(cad, projects: projects), isTrue);
  });
}
