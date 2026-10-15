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
        ),
      ];

  static List<Project> projects() => [
        Project(
          id: 'p1',
          name: 'Padang Riverside Survey',
          owner: 'PT Sumatra Hijau',
          address: 'Jl. Batang Arau, Padang, Sumatera Barat',
          latitude: -0.9471,
          longitude: 100.4172,
          status: ProjectStatus.inProgress,
          paidStatus: PaidStatus.partiallyPaid,
          tools: const ['GPS', 'Total Station'],
          assignedWorkerId: 'u2',
          assignedWorkerName: 'Bob Worker',
        ),
        Project(
          id: 'p2',
          name: 'Medan Boundary Mapping',
          owner: 'PT Deli Estates',
          address: 'Jl. Gatot Subroto, Medan, Sumatera Utara',
          latitude: 3.5952,
          longitude: 98.6722,
          status: ProjectStatus.pending,
          paidStatus: PaidStatus.unpaid,
          tools: const ['GPS'],
          assignedWorkerId: 'u2',
          assignedWorkerName: 'Bob Worker',
        ),
        Project(
          id: 'p3',
          name: 'Jambi Land Plot Mapping',
          owner: 'PT Batanghari Agro',
          address: 'Jl. Jenderal Sudirman, Jambi, Jambi',
          latitude: -1.6101,
          longitude: 103.6131,
          status: ProjectStatus.completed,
          paidStatus: PaidStatus.paid,
          tools: const ['Drone', 'GPS'],
        ),
        Project(
          id: 'p4',
          name: 'Palembang Farmland Division',
          owner: 'PT Musi Sejahtera',
          address: 'Jl. Demang Lebar Daun, Palembang, Sumatera Selatan',
          latitude: -2.9761,
          longitude: 104.7754,
          status: ProjectStatus.onHold,
          paidStatus: PaidStatus.unpaid,
          tools: const ['Total Station'],
          assignedWorkerId: 'u2',
          assignedWorkerName: 'Bob Worker',
        ),
      ];
}
