/// How description-of-work serial numbers are rendered.
///
/// Top-level rows always use numbers. The alphabet styles letter the nested
/// rows, then switch case again for deeper rows, for example `1`, `a`, `A`
/// or `1`, `A`, `a`.
enum LineItemNumberStyle {
  numeric('Numbers', '1, 2, 3', '1'),
  lowerAlpha('Lowercase', '1, a, A', 'a'),
  upperAlpha('Uppercase', '1, A, a', 'A');

  const LineItemNumberStyle(this.label, this.description, this.sample);

  final String label;
  final String description;
  final String sample;

  /// Reads the style stored on an offering, falling back to numbers for older
  /// records or unknown values.
  static LineItemNumberStyle fromStorage(String? value) {
    return switch (value) {
      'lowerAlpha' => LineItemNumberStyle.lowerAlpha,
      'upperAlpha' => LineItemNumberStyle.upperAlpha,
      _ => LineItemNumberStyle.numeric,
    };
  }
}
