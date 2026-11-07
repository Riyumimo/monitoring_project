part of '../../offering_form_screen.dart';

extension _FormTermsSections on _OfferingFormScreenState {
  Widget _termsCard() {
    return _sectionCard(
      title: 'Payment Terms',
      children: [
        const Text(
          'Split the offering budget into payment milestones. Amounts are calculated from the budget.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _terms.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _terms[i].name,
                  decoration: InputDecoration(
                    labelText: 'Milestone ${i + 1}',
                    hintText: 'e.g. Down payment',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: TextFormField(
                  controller: _terms[i].percentage,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Percent',
                    suffixText: '%',
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove milestone',
                onPressed: () => _setState(() => _terms.removeAt(i).dispose()),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _setState(
              () => _terms.add(_TermDraft('Termin ${_terms.length + 1}', '')),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add payment term'),
          ),
        ),
      ],
    );
  }
}
