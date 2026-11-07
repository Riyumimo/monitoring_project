part of '../../offering_form_screen.dart';

extension _FormRentalEditorSections on _OfferingFormScreenState {
  Future<void> _editRentalItem([int? index]) async {
    final existing = index == null ? null : _rentalItems[index];
    if (existing == null && rentalToolCatalog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The rental catalog is empty.')),
      );
      return;
    }

    var tool = existing?.tool ?? rentalToolCatalog.first;
    var start = existing?.startsAt ?? DateTime.now();
    final quantity = TextEditingController(text: '${existing?.quantity ?? 1}');
    final duration = TextEditingController(text: '${existing?.duration ?? 1}');
    final rate = TextEditingController(
      text: formatRupiahInput(existing?.rate ?? tool.rentalRate),
    );
    final formKey = GlobalKey<FormState>();
    final toolOptions = {
      for (final item in rentalToolCatalog) item.id: item,
      tool.id: tool,
    };

    RentalOfferingItem? result;
    try {
      result = await showDialog<RentalOfferingItem>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) {
            final qty = int.tryParse(quantity.text) ?? 0;
            final days = int.tryParse(duration.text) ?? 0;
            final dailyRate = parseRupiah(rate.text) ?? 0.0;
            final estimate = (qty * days * dailyRate).toDouble();
            final fieldBorder = OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            );

            void save() {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.of(dialogContext).pop(
                RentalOfferingItem(
                  tool: tool,
                  quantity: int.parse(quantity.text),
                  duration: int.parse(duration.text),
                  startsAt: start,
                  rate: parseRupiah(rate.text)!,
                ),
              );
            }

            final quantityField = TextFormField(
              controller: quantity,
              decoration: InputDecoration(
                labelText: 'Quantity',
                suffixText: tool.unit,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => update(() {}),
              validator: (value) {
                final amount = int.tryParse((value ?? '').trim());
                if (amount == null || amount < 1) return 'Enter at least 1';
                if (amount > tool.stock) return 'Maximum ${tool.stock}';
                return null;
              },
            );
            final durationField = TextFormField(
              controller: duration,
              decoration: const InputDecoration(
                labelText: 'Duration',
                suffixText: 'days',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => update(() {}),
              validator: (value) => (int.tryParse(value?.trim() ?? '') ?? 0) < 1
                  ? 'Enter at least 1 day'
                  : null,
            );

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.86,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  existing == null
                                      ? 'Add rental item'
                                      : 'Edit rental item',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Choose equipment and set its rental terms.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close dialog',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, size: 19),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: Theme(
                        data: Theme.of(dialogContext).copyWith(
                          inputDecorationTheme: Theme.of(dialogContext)
                              .inputDecorationTheme
                              .copyWith(
                                filled: true,
                                fillColor: AppColors.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                border: fieldBorder,
                                enabledBorder: fieldBorder,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButtonFormField<String>(
                                  key: ValueKey('rental-tool-${tool.id}'),
                                  initialValue: tool.id,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Catalog equipment',
                                  ),
                                  items: [
                                    for (final item in toolOptions.values)
                                      DropdownMenuItem<String>(
                                        value: item.id,
                                        child: Text(
                                          item.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                  onChanged: (id) {
                                    final selected = id == null
                                        ? null
                                        : toolOptions[id];
                                    if (selected == null) return;
                                    update(() {
                                      tool = selected;
                                      rate.text = formatRupiahInput(
                                        tool.rentalRate,
                                      );
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tool.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (tool.description
                                          .trim()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          tool.description,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Stock\n${tool.stock} ${tool.unit}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                height: 1.5,
                                                fontWeight: FontWeight.w600,
                                                color: tool.stock > 0
                                                    ? AppColors.completed
                                                    : AppColors.onHold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Catalog rate\n${formatRupiah(tool.rentalRate)} / day',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                height: 1.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                LayoutBuilder(
                                  builder: (context, constraints) =>
                                      constraints.maxWidth < 360
                                      ? Column(
                                          children: [
                                            quantityField,
                                            const SizedBox(height: 12),
                                            durationField,
                                          ],
                                        )
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: quantityField),
                                            const SizedBox(width: 12),
                                            Expanded(child: durationField),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: rate,
                                  decoration: const InputDecoration(
                                    labelText: 'Daily rental rate',
                                    prefixText: 'Rp ',
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: const [
                                    RupiahInputFormatter(),
                                  ],
                                  onChanged: (_) => update(() {}),
                                  validator: (value) {
                                    final amount = parseRupiah(value ?? '');
                                    return amount == null ||
                                            !amount.isFinite ||
                                            amount < 0
                                        ? 'Enter a valid rate'
                                        : null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _dateField(
                                  label: 'Start date',
                                  value: start,
                                  onPick: (date) => update(() => start = date),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.07,
                                    ),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$qty ${tool.unit} × $days days',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          formatRupiah(estimate),
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
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
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: save,
                            child: Text(
                              existing == null ? 'Add item' : 'Save changes',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      quantity.dispose();
      duration.dispose();
      rate.dispose();
    }

    if (!mounted || result == null) return;
    _setState(() {
      if (index == null) {
        _rentalItems.add(result!);
      } else {
        _rentalItems[index] = result!;
      }
      _rentalUntil = _rentalItems
          .map((item) => item.endsAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    });
  }
}
