import 'line_item_text_run.dart';

/// One row in an offering's "Description of Work" budget table.
class OfferingLineItem {
  final String description;

  /// Bold/italic ranges over [description].
  final List<LineItemTextRun> descriptionRuns;

  /// Applies the selected description formatting to the row number and total.
  final bool rowBold;
  final bool rowItalic;

  final String qty;
  final String uom;
  final double amount;

  /// Optional user-entered serial number. When empty, the row falls back to
  /// the offering's generated numbering style.
  final String numberLabel;

  /// Optional nesting depth: 0 = top level, 1 = sub-item, 2 = sub-sub-item.
  final int indent;

  /// When true, this row is shown in the description of work but its own
  /// amount is not added to the offering budget. Nested children can still be
  /// counted. Useful for section headers such as "Direct Cost".
  final bool excludeFromTotal;

  const OfferingLineItem({
    required this.description,
    this.descriptionRuns = const [],
    this.rowBold = false,
    this.rowItalic = false,
    this.qty = '',
    this.uom = '',
    required this.amount,
    this.numberLabel = '',
    this.indent = 0,
    this.excludeFromTotal = false,
  });

  bool get isBlank =>
      description.trim().isEmpty &&
      qty.trim().isEmpty &&
      uom.trim().isEmpty &&
      amount <= 0;

  factory OfferingLineItem.fromJson(Map<String, dynamic> json) {
    final rawRuns = json['descriptionRuns'];
    final descriptionRuns = rawRuns is List
        ? rawRuns
              .whereType<Map>()
              .map(
                (run) =>
                    LineItemTextRun.fromJson(Map<String, dynamic>.from(run)),
              )
              .toList(growable: false)
        : const <LineItemTextRun>[];
    return OfferingLineItem(
      description: json['description']?.toString() ?? '',
      descriptionRuns: descriptionRuns,
      rowBold: json['rowBold'] == true,
      rowItalic: json['rowItalic'] == true,
      qty: json['qty']?.toString() ?? '',
      uom: json['uom']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      numberLabel: json['numberLabel']?.toString() ?? '',
      indent: ((json['indent'] as num?)?.toInt() ?? 0).clamp(0, 2).toInt(),
      excludeFromTotal: json['excludeFromTotal'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'descriptionRuns': [for (final run in descriptionRuns) run.toJson()],
      'rowBold': rowBold,
      'rowItalic': rowItalic,
      'qty': qty,
      'uom': uom,
      'amount': amount,
      'numberLabel': numberLabel,
      'indent': indent,
      'excludeFromTotal': excludeFromTotal,
    };
  }
}
