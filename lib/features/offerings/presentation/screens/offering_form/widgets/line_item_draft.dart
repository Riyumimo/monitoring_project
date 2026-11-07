part of '../../offering_form_screen.dart';

class _LineItemDraft {
  _LineItemDraft({
    String numberText = '',
    String descriptionText = '',
    List<LineItemTextRun> descriptionRuns = const [],
    this.rowBold = false,
    this.rowItalic = false,
    String qtyText = '',
    String uomText = '',
    String amountText = '',
    this.indent = 0,
    this.excludeFromTotal = false,
    required VoidCallback onFormatChanged,
  }) : number = TextEditingController(text: numberText),
       description = RichTextEditingController(
         text: descriptionText,
         runs: descriptionRuns,
       ),
       qty = TextEditingController(text: qtyText),
       uom = TextEditingController(text: uomText),
       amount = TextEditingController(text: amountText) {
    description.onFormatChanged = ({bold, italic}) {
      if (bold != null) rowBold = bold;
      if (italic != null) rowItalic = italic;
      onFormatChanged();
    };
    numberFocus.addListener(_selectNumberOnFocus);
  }

  final TextEditingController number;
  final RichTextEditingController description;
  final TextEditingController qty;
  final TextEditingController uom;
  final TextEditingController amount;
  final FocusNode numberFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();
  int indent;
  bool excludeFromTotal;
  bool rowBold;
  bool rowItalic;

  bool get isBlank =>
      description.text.trim().isEmpty &&
      qty.text.trim().isEmpty &&
      uom.text.trim().isEmpty &&
      (parseRupiah(amount.text) ?? 0) <= 0;

  void _selectNumberOnFocus() {
    if (!numberFocus.hasFocus) return;
    number.selection = TextSelection(
      baseOffset: 0,
      extentOffset: number.text.length,
    );
  }

  void dispose() {
    numberFocus.removeListener(_selectNumberOnFocus);
    numberFocus.dispose();
    number.dispose();
    description.dispose();
    qty.dispose();
    uom.dispose();
    amount.dispose();
    descriptionFocus.dispose();
  }
}
