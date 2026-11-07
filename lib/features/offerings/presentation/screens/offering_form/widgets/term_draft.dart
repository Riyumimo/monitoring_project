part of '../../offering_form_screen.dart';

class _TermDraft {
  final TextEditingController name;
  final TextEditingController percentage;
  _TermDraft(String label, String percent)
    : name = TextEditingController(text: label),
      percentage = TextEditingController(text: percent);
  void dispose() {
    name.dispose();
    percentage.dispose();
  }
}
