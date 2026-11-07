part of '../../offering_form_screen.dart';

extension _FormLineItemNarrowSections on _OfferingFormScreenState {
  Widget _narrowLineItem(int index) {
    final item = _lineItems[index];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: item.excludeFromTotal
            ? AppColors.inProgress.withValues(alpha: 0.10)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'No.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 42, child: _numberField(index, compact: true)),
              _nestingButton(index),
              Text(
                'Level ${item.indent}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              _removeLineItemButton(index),
            ],
          ),
          const SizedBox(height: 4),
          RichTextShortcuts(
            controller: item.description,
            child: TextFormField(
              controller: item.description,
              focusNode: item.descriptionFocus,
              decoration: const InputDecoration(
                labelText: 'Description of work',
                hintText: 'Enter work description',
              ),
              maxLines: 2,
              minLines: 1,
              textInputAction: TextInputAction.next,
              validator: (_) => _validateLineItemDescription(item),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.qty,
                  enabled: !item.excludeFromTotal,
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    hintText: item.excludeFromTotal ? '' : '1',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.uom,
                  enabled: !item.excludeFromTotal,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    hintText: item.excludeFromTotal ? '' : 'Lot',
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CheckboxListTile(
            value: item.excludeFromTotal,
            onChanged: (value) => _setLineItemExcluded(index, value ?? false),
            title: const Text(
              "Don't count to total",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Qty and Unit are cleared and this row total is skipped.',
              style: TextStyle(fontSize: 11.5, height: 1.3),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: item.amount,
            decoration: const InputDecoration(
              labelText: 'Total',
              prefixText: 'Rp ',
              hintText: '0',
            ),
            style: _rowTextStyle(item),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: const [RupiahInputFormatter()],
            onChanged: (_) => _setState(() {}),
            onFieldSubmitted: (_) => _addLineItemAfter(index),
            validator: (_) => _validateLineItemAmount(index),
          ),
        ],
      ),
    );
  }
}
