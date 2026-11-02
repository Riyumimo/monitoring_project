/// A catalog entry. Rates are IDR per unit per rental day.
class RentalTool {
  final String id, name, description, category, unit;
  final double rentalRate;
  final int stock;

  const RentalTool({required this.id, required this.name,
    required this.description, required this.category,
    required this.rentalRate, this.unit = 'unit', required this.stock});

  factory RentalTool.fromJson(Map<String, dynamic> json) => RentalTool(
    id: json['id'] as String, name: json['name'] as String,
    description: json['description'] as String, category: json['category'] as String,
    rentalRate: (json['rentalRate'] as num).toDouble(),
    unit: json['unit'] as String? ?? 'unit', stock: json['stock'] as int);

  Map<String, dynamic> toJson() => {'id': id, 'name': name,
    'description': description, 'category': category, 'rentalRate': rentalRate,
    'unit': unit, 'stock': stock};
}

/// Immutable price/name snapshot: catalog changes never reprice saved offers.
class RentalOfferingItem {
  final RentalTool tool;
  final int quantity, duration;
  final DateTime startsAt;
  final double rate;

  RentalOfferingItem({required this.tool, required this.quantity,
    required this.duration, required DateTime startsAt, required this.rate})
      : startsAt = DateTime(startsAt.year, startsAt.month, startsAt.day) {
    if (quantity < 1 || duration < 1 || !rate.isFinite || rate < 0) {
      throw ArgumentError('Positive quantity/duration and a finite nonnegative rate required');
    }
  }

  DateTime get endsAt => DateTime(startsAt.year, startsAt.month, startsAt.day + duration - 1);
  double get total => quantity * duration * rate;
  factory RentalOfferingItem.fromJson(Map<String, dynamic> json) => RentalOfferingItem(
    tool: RentalTool.fromJson(Map<String, dynamic>.from(json['tool'] as Map)),
    quantity: json['quantity'] as int, duration: json['duration'] as int,
    startsAt: DateTime.parse(json['startsAt'] as String),
    rate: (json['rate'] as num).toDouble());
  Map<String, dynamic> toJson() => {'tool': tool.toJson(), 'quantity': quantity,
    'duration': duration, 'startsAt': startsAt.toIso8601String(), 'rate': rate};
}

const rentalToolCatalog = <RentalTool>[
  RentalTool(id: 'rent-ts', name: 'Total Station Topcon GM-52', description: 'Tripod, prism and batteries included', category: 'Survey', rentalRate: 350000, stock: 4),
  RentalTool(id: 'rent-gnss', name: 'GNSS RTK CHCNAV i73', description: 'Base and rover set with controller', category: 'GNSS', rentalRate: 750000, unit: 'set', stock: 3),
  RentalTool(id: 'rent-level', name: 'Automatic Level Sokkia B40A', description: 'Tripod and levelling staff included', category: 'Levelling', rentalRate: 100000, stock: 6),
  RentalTool(id: 'rent-drone', name: 'DJI Phantom 4 RTK', description: 'Aircraft, controller and three batteries; no pilot', category: 'Drone', rentalRate: 1500000, unit: 'set', stock: 2),
  RentalTool(id: 'rent-laser', name: 'Bosch GLM 50 Laser Meter', description: '50 metre handheld distance meter', category: 'Measurement', rentalRate: 50000, stock: 8),
];
