part of '../../client_form_dialog.dart';

extension _ClientFormFieldSections on _ClientFormDialogState {
  Widget _section({
    required int index,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final expanded = _expandedSections.contains(index);
    return Container(
      key: _sectionKeys[index],
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: index != 0,
            expanded: expanded,
            child: InkWell(
              onTap: index == 0 ? null : () => _toggleSection(index),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (index != 0)
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index < children.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(children: [first, const SizedBox(height: 8), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool required = false,
    bool readOnly = false,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<String>? autofillHints,
    bool submitOnDone = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : submitOnDone
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: maxLines > 1
          ? null
          : submitOnDone
          ? (_) => _save()
          : (_) => FocusScope.of(context).nextFocus(),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      validator:
          validator ??
          (required
              ? (value) => value == null || value.trim().isEmpty
                    ? 'Please enter $label'
                    : null
              : null),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<(String, String)> options,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option.$1, child: Text(option.$2)),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }

  Widget _relationshipOption(String value) {
    return InkWell(
      onTap: () => _rebuild(() => _relationshipType = value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: value,
              groupValue: _relationshipType,
              onChanged: (next) {
                if (next != null) _rebuild(() => _relationshipType = next);
              },
            ),
            Text(value),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email';
    }
    if (ClientDirectory.emailTaken(email)) return 'This email is already used';
    return null;
  }
}
