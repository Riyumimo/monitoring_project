import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/project.dart';
import 'package:geoterra_monitoring/models/user.dart';
import 'package:geoterra_monitoring/providers/project_provider.dart';
import 'package:geoterra_monitoring/providers/worker_provider.dart';

void main() {
  test('workers can be added, updated, and deleted', () async {
    final provider = WorkerProvider();
    await provider.fetchWorkers();
    final initialCount = provider.workers.length;

    final worker = User(
      id: 'local-worker',
      name: 'Local Worker',
      email: 'local@geoterra.com',
      role: 'FieldWorker',
    );
    await provider.addWorker(worker);
    expect(provider.workers.length, initialCount + 1);
    expect(provider.workerById(worker.id)?.name, 'Local Worker');

    await provider.updateWorker(
      User(
        id: worker.id,
        name: 'Renamed Worker',
        email: worker.email,
        role: worker.role,
        workerTypes: const [WorkerType.cad],
      ),
    );
    expect(provider.workerById(worker.id)?.name, 'Renamed Worker');
    expect(provider.workerById(worker.id)?.workerTypes, [WorkerType.cad]);

    await provider.deleteWorker(worker.id);
    expect(provider.workerById(worker.id), isNull);
    expect(provider.workers.length, initialCount);

    provider.dispose();
  });

  test('email must be unique except for the worker being edited', () async {
    final provider = WorkerProvider();
    await provider.ensureWorkersLoaded();
    final existing = provider.workers.first;

    expect(provider.emailTaken(existing.email.toUpperCase()), isTrue);
    expect(provider.emailTaken(existing.email, ignoreId: existing.id), isFalse);
    expect(
      provider.emailTaken(existing.email, ignoreId: 'another-worker'),
      isTrue,
    );

    provider.dispose();
  });

  test('renaming and deleting a worker updates project teams', () async {
    final projects = ProjectProvider();
    final project = Project(
      id: 'project-with-worker',
      name: 'Project',
      offeringId: 'offering',
      owner: 'Owner',
      address: 'Address',
      assignedWorkerIds: const ['worker-1', 'worker-2'],
      assignedWorkerNames: const ['Old Name', 'Other Worker'],
    );
    await projects.addProject(project);

    projects.syncWorker(
      User(
        id: 'worker-1',
        name: 'New Name',
        email: 'worker1@geoterra.com',
        role: 'FieldWorker',
      ),
    );
    expect(projects.projectById(project.id)?.assignedWorkerNames, [
      'New Name',
      'Other Worker',
    ]);

    projects.removeWorkerFromProjects('worker-1');
    final updated = projects.projectById(project.id);
    expect(updated?.assignedWorkerIds, ['worker-2']);
    expect(updated?.assignedWorkerNames, ['Other Worker']);

    projects.dispose();
  });
}
