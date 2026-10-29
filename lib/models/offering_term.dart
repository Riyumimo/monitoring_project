/// A scheduled payment milestone attached to an offering.
class OfferingTerm {
  final String name;
  final double percentage;
  final double amount;

  const OfferingTerm({
    required this.name,
    required this.percentage,
    required this.amount,
  });

  factory OfferingTerm.fromJson(Map<String, dynamic> json) => OfferingTerm(
    name: json['name']?.toString() ?? '',
    percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'percentage': percentage,
    'amount': amount,
  };
}
