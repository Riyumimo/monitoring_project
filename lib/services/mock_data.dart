import '../models/offering.dart';
import '../models/project.dart';
import '../models/tool_asset.dart';
import '../models/user.dart';

class MockData {
  MockData._();

  static const List<Map<String, String>> accounts = [
    {
      'id': 'u1',
      'name': 'Alice Manager',
      'email': 'manager@geoterra.com',
      'password': 'manager123',
      'role': 'Manager',
    },
    {
      'id': 'u2',
      'name': 'Bob Worker',
      'email': 'worker@geoterra.com',
      'password': 'worker123',
      'role': 'FieldWorker',
    },
  ];

  static User? authenticate(String email, String password) {
    for (final account in accounts) {
      if (account['email'] == email && account['password'] == password) {
        return User(
          id: account['id']!,
          name: account['name']!,
          email: account['email']!,
          role: account['role']!,
        );
      }
    }
    return null;
  }

  static List<ToolAsset> tools() => const [
        ToolAsset(
            name: 'GPS Receiver',
            category: 'Survey',
            total: 12,
            available: 7),
        ToolAsset(
            name: 'Total Station',
            category: 'Survey',
            total: 6,
            available: 2),
        ToolAsset(
            name: 'Survey Drone',
            category: 'Aerial',
            total: 4,
            available: 4),
        ToolAsset(
            name: 'Theodolite',
            category: 'Survey',
            total: 5,
            available: 1),
        ToolAsset(
            name: 'Ground Penetrating Radar',
            category: 'Geophysics',
            total: 2,
            available: 0),
        ToolAsset(
            name: 'Leveling Staff',
            category: 'Survey',
            total: 10,
            available: 8),
        ToolAsset(
            name: 'RTK Base Station',
            category: 'Survey',
            total: 3,
            available: 3),
        ToolAsset(
            name: 'Handheld GIS Unit',
            category: 'Mapping',
            total: 8,
            available: 5),
      ];

  static const List<String> serviceTypes = [
    'Land Survey',
    'Boundary Mapping',
    'Land Plot Mapping',
    'Farmland Survey',
    'Topographic Survey',
    'Peatland Survey',
    'GIS Mapping',
    'Rent Tool',
    'Calibrate Service',
  ];

  static List<User> workers() => [
        User(
          id: 'u2',
          name: 'Bob Worker',
          email: 'worker@geoterra.com',
          role: 'FieldWorker',
          phone: '+62 812-3456-7890',
        ),
        User(
          id: 'u3',
          name: 'Carlos Rivera',
          email: 'carlos@geoterra.com',
          role: 'FieldWorker',
          phone: '+62 813-2233-4455',
          availability: WorkAvailability.outOfTown,
        ),
        User(
          id: 'u4',
          name: 'Dana Putri',
          email: 'dana@geoterra.com',
          role: 'FieldWorker',
          phone: '+62 815-7788-9900',
        ),
        User(
          id: 'u5',
          name: 'Erik Larsen',
          email: 'erik@geoterra.com',
          role: 'FieldWorker',
          phone: '+62 817-1122-3344',
          availability: WorkAvailability.outOfTown,
        ),
        User(
          id: 'u6',
          name: 'Farah CAD',
          email: 'farah@geoterra.com',
          role: 'FieldWorker',
          phone: '+62 818-5566-7788',
          workerTypes: const [WorkerType.cad],
        ),
      ];

  static List<Offering> offerings() => [
        Offering(
          id: 'o1',
          number: 'OFF-001',
          name: 'Padang Riverside Survey',
          serviceType: 'Land Survey',
          owner: 'PT Sumatra Hijau',
          address: 'Jl. Batang Arau, Padang, Sumatera Barat',
          latitude: -0.9471,
          longitude: 100.4172,
          status: OfferingStatus.accepted,
          paidStatus: PaidStatus.partiallyPaid,
          budgetAmount: 150000000,
          projectId: 'pr1',
        ),
        Offering(
          id: 'o2',
          number: 'OFF-002',
          name: 'Medan Boundary Mapping',
          serviceType: 'Boundary Mapping',
          owner: 'PT Deli Estates',
          address: 'Jl. Gatot Subroto, Medan, Sumatera Utara',
          latitude: 3.5952,
          longitude: 98.6722,
          status: OfferingStatus.sent,
          paidStatus: PaidStatus.unpaid,
          budgetAmount: 85000000,
        ),
        Offering(
          id: 'o3',
          number: 'OFF-003',
          name: 'Jambi Land Plot Mapping',
          serviceType: 'Land Plot Mapping',
          owner: 'PT Batanghari Agro',
          address: 'Jl. Jenderal Sudirman, Jambi, Jambi',
          latitude: -1.6101,
          longitude: 103.6131,
          status: OfferingStatus.accepted,
          paidStatus: PaidStatus.paid,
          budgetAmount: 92000000,
          projectId: 'pr2',
        ),
        Offering(
          id: 'o4',
          number: 'OFF-004',
          name: 'Palembang Farmland Division',
          serviceType: 'Farmland Survey',
          owner: 'PT Musi Sejahtera',
          address: 'Jl. Demang Lebar Daun, Palembang, Sumatera Selatan',
          latitude: -2.9761,
          longitude: 104.7754,
          status: OfferingStatus.rejected,
          paidStatus: PaidStatus.unpaid,
          budgetAmount: 45000000,
        ),
        Offering(
          id: 'o5',
          number: 'OFF-005',
          name: 'Bukit Tinggi Topographic Map',
          serviceType: 'Topographic Survey',
          owner: 'PT Agam Lestari',
          address: 'Jl. Sudirman, Bukittinggi, Sumatera Barat',
          latitude: -0.3055,
          longitude: 100.3694,
          status: OfferingStatus.accepted,
          paidStatus: PaidStatus.unpaid,
          budgetAmount: 65000000,
          projectId: 'pr3',
        ),
        Offering(
          id: 'o6',
          number: 'OFF-006',
          name: 'Pekanbaru Peatland Survey',
          serviceType: 'Peatland Survey',
          owner: 'PT Riau Green',
          address: 'Jl. Jenderal Sudirman, Pekanbaru, Riau',
          latitude: 0.5071,
          longitude: 101.4478,
          status: OfferingStatus.draft,
          paidStatus: PaidStatus.unpaid,
          budgetAmount: 55000000,
        ),
        Offering(
          id: 'o7',
          number: 'OFF-007',
          name: 'Padang Survey Equipment Rental',
          serviceType: 'Rent Tool',
          owner: 'PT Andalas Geospasial',
          address: 'Jl. Khatib Sulaiman, Padang, Sumatera Barat',
          latitude: -0.9121,
          longitude: 100.3548,
          status: OfferingStatus.sent,
          paidStatus: PaidStatus.unpaid,
          budgetAmount: 15000000,
        ),
        Offering(
          id: 'o8',
          number: 'OFF-008',
          name: 'Medan Instrument Calibration',
          serviceType: 'Calibrate Service',
          owner: 'PT Deli Estates',
          address: 'Jl. Gatot Subroto, Medan, Sumatera Utara',
          status: OfferingStatus.draft,
          paidStatus: PaidStatus.unpaid,
          budgetAmount: 10000000,
        ),
      ];

  static List<Project> projects() => [
        Project(
          id: 'pr1',
          number: 'PRJ-001',
          name: 'Padang Riverside Survey',
          offeringId: 'o1',
          owner: 'PT Sumatra Hijau',
          address: 'Jl. Batang Arau, Padang, Sumatera Barat',
          latitude: -0.9471,
          longitude: 100.4172,
          status: ProjectStatus.inProgress,
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 6, 30),
          budgetAmount: 150000000,
          progressPercentage: 45,
          tools: const ['GPS Receiver', 'Total Station'],
          assignedWorkerIds: const ['u2', 'u4'],
          assignedWorkerNames: const ['Bob Worker', 'Dana Putri'],
        ),
        Project(
          id: 'pr2',
          number: 'PRJ-002',
          name: 'Jambi Land Plot Mapping',
          offeringId: 'o3',
          owner: 'PT Batanghari Agro',
          address: 'Jl. Jenderal Sudirman, Jambi, Jambi',
          latitude: -1.6101,
          longitude: 103.6131,
          status: ProjectStatus.completed,
          startDate: DateTime(2025, 8, 1),
          endDate: DateTime(2025, 12, 15),
          budgetAmount: 92000000,
          progressPercentage: 100,
          tools: const ['Survey Drone', 'GPS Receiver'],
          assignedWorkerIds: const ['u4', 'u6'],
          assignedWorkerNames: const ['Dana Putri', 'Farah CAD'],
        ),
        Project(
          id: 'pr3',
          number: 'PRJ-003',
          name: 'Bukit Tinggi Topographic Map',
          offeringId: 'o5',
          owner: 'PT Agam Lestari',
          address: 'Jl. Sudirman, Bukittinggi, Sumatera Barat',
          latitude: -0.3055,
          longitude: 100.3694,
          status: ProjectStatus.planning,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 10, 20),
          budgetAmount: 65000000,
          progressPercentage: 0,
          tools: const ['Survey Drone'],
          assignedWorkerIds: const ['u6'],
          assignedWorkerNames: const ['Farah CAD'],
        ),
      ];
}
