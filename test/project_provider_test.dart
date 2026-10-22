import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/offering.dart';
import 'package:geoterra_monitoring/providers/project_provider.dart';

void main() {
  test('reloading projects keeps locally created offerings', () async {
    final provider = ProjectProvider();
    await provider.fetchProjects();
    final initialCount = provider.offerings.length;

    final offering = Offering(
      id: 'local-offer',
      number: 'OFF-LOCAL',
      name: 'Local test offering',
      owner: 'Test Client',
      address: 'Test Address',
    );
    await provider.addOffering(offering);

    await provider.fetchProjects();

    expect(provider.offerings.length, initialCount + 1);
    expect(provider.offerings.any((item) => item.id == offering.id), isTrue);

    provider.dispose();
  });

  test('ensureProjectsLoaded does not replace existing local data', () async {
    final provider = ProjectProvider();
    final offering = Offering(
      id: 'local-only',
      name: 'Local only offering',
      owner: 'Test Client',
      address: 'Test Address',
    );
    await provider.addOffering(offering);

    await provider.ensureProjectsLoaded();

    expect(provider.offerings.length, 1);
    expect(provider.offerings.single.id, offering.id);
    expect(provider.projects, isEmpty);

    provider.dispose();
  });
}
