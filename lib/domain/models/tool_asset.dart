class ToolAsset {
  final String name;
  final String category;
  final int total;
  final int available;

  const ToolAsset({
    required this.name,
    required this.category,
    required this.total,
    required this.available,
  });

  int get inUse => total - available;

  double get availability => total == 0 ? 0 : available / total;
}
