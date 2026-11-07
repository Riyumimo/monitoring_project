part of '../../offering_form_screen.dart';

extension _FormHelpers on _OfferingFormScreenState {
  Widget _tableField(
    TextEditingController controller, {
    String? hintText,
    String? prefixText,
    int maxLines = 1,
    TextAlign textAlign = TextAlign.start,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextStyle? style,
    FocusNode? focusNode,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: _tableFieldDecoration(
        hintText: hintText,
        prefixText: prefixText,
      ),
      enabled: enabled,
      maxLines: maxLines,
      minLines: 1,
      textAlign: textAlign,
      textAlignVertical: TextAlignVertical.center,
      style: style,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
    );
  }

  InputDecoration _tableFieldDecoration({
    String? hintText,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      errorStyle: const TextStyle(fontSize: 10.5),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
  }) {
    final text = value == null
        ? ''
        : '${value.year}-${value.month.toString().padLeft(2, '0')}-'
              '${value.day.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now.add(const Duration(days: 7)),
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(
          text.isEmpty ? 'Select date' : text,
          style: TextStyle(
            fontSize: 14,
            color: text.isEmpty
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
