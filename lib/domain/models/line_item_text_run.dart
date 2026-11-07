/// A bold and/or italic range over a line item's description.
///
/// Ranges use UTF-16 offsets, matching [String.length] and Flutter text
/// selections.
class LineItemTextRun {
  final int start;
  final int end;
  final bool bold;
  final bool italic;

  const LineItemTextRun({
    required this.start,
    required this.end,
    this.bold = false,
    this.italic = false,
  });

  bool get isPlain => !bold && !italic;

  factory LineItemTextRun.fromJson(Map<String, dynamic> json) {
    final start = ((json['start'] as num?)?.toInt() ?? 0)
        .clamp(0, 1 << 31)
        .toInt();
    final end = ((json['end'] as num?)?.toInt() ?? 0)
        .clamp(start, 1 << 31)
        .toInt();
    return LineItemTextRun(
      start: start,
      end: end,
      bold: json['bold'] == true,
      italic: json['italic'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'start': start, 'end': end, 'bold': bold, 'italic': italic};
  }

  @override
  bool operator ==(Object other) {
    return other is LineItemTextRun &&
        other.start == start &&
        other.end == end &&
        other.bold == bold &&
        other.italic == italic;
  }

  @override
  int get hashCode => Object.hash(start, end, bold, italic);
}

/// Returns non-overlapping runs covering [text].
///
/// Overlapping ranges are merged. Plain gaps are included so callers can
/// render every segment consistently.
List<LineItemTextRun> normalizedLineItemTextRuns(
  String text,
  List<LineItemTextRun> runs,
) {
  if (text.isEmpty) return const [];

  final bold = List<bool>.filled(text.length, false);
  final italic = List<bool>.filled(text.length, false);
  for (final run in runs) {
    final start = run.start.clamp(0, text.length).toInt();
    final end = run.end.clamp(0, text.length).toInt();
    if (end <= start) continue;
    for (var index = start; index < end; index++) {
      bold[index] = bold[index] || run.bold;
      italic[index] = italic[index] || run.italic;
    }
  }

  final result = <LineItemTextRun>[];
  var start = 0;
  for (var index = 1; index <= text.length; index++) {
    final boundary =
        index == text.length ||
        bold[index] != bold[start] ||
        italic[index] != italic[start];
    if (boundary) {
      result.add(
        LineItemTextRun(
          start: start,
          end: index,
          bold: bold[start],
          italic: italic[start],
        ),
      );
      start = index;
    }
  }
  return result;
}
