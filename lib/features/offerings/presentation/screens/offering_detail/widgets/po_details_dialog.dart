part of '../../offering_detail_screen.dart';

typedef _PoDetails = ({String number, DateTime date});

String _poFieldRequiredMessage(BuildContext context, {required bool isDate}) {
  final isIndonesian = Localizations.localeOf(context).languageCode == 'id';
  if (isDate) {
    return isIndonesian ? 'Tanggal PO wajib diisi.' : 'PO date is required.';
  }
  return isIndonesian ? 'Nomor PO wajib diisi.' : 'PO number is required.';
}

class _PoDetailsDialog extends StatefulWidget {
  const _PoDetailsDialog();

  @override
  State<_PoDetailsDialog> createState() => _PoDetailsDialogState();
}

class _PoDetailsDialogState extends State<_PoDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _poNumberController = TextEditingController();
  DateTime? _poDate;

  @override
  void dispose() {
    _poNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectPoDate(FormFieldState<DateTime> field) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _poDate ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 10),
    );
    if (selected == null || !mounted) return;
    setState(() => _poDate = selected);
    field.didChange(selected);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final date = _poDate;
    if (date == null) return;
    Navigator.pop<_PoDetails>(context, (
      number: _poNumberController.text.trim(),
      date: date,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return AlertDialog(
      title: const Text('PO details'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _poNumberController,
                autofocus: true,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'PO number',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? _poFieldRequiredMessage(context, isDate: false)
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              FormField<DateTime>(
                validator: (value) => value == null
                    ? _poFieldRequiredMessage(context, isDate: true)
                    : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'PO date',
                        errorText: field.errorText,
                        prefixIcon: const Icon(Icons.event_outlined),
                      ),
                      child: InkWell(
                        onTap: () => _selectPoDate(field),
                        child: Semantics(
                          button: true,
                          label: 'Select PO date',
                          value: _poDate == null
                              ? null
                              : localizations.formatMediumDate(_poDate!),
                          child: Text(
                            _poDate == null
                                ? 'Select date'
                                : localizations.formatMediumDate(_poDate!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}
