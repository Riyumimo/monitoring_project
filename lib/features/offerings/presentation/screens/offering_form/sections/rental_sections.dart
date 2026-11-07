part of '../../offering_form_screen.dart';

extension _FormRentalSections on _OfferingFormScreenState {
  Widget _rentalItemsCard() {
    final rentalTotal = _rentalItems.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

    String dateLabel(DateTime date) =>
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';

    Widget headerCell(String label, {TextAlign align = TextAlign.left}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          label,
          textAlign: align,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return _sectionCard(
      title: 'Rental Tools',
      children: [
        const Text(
          'Rates are saved with this offering. Rental dates include both the '
          'start and end day.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_rentalItems.length.toString().padLeft(2, '0')} '
                '${_rentalItems.length == 1 ? 'ITEM' : 'ITEMS'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _editRentalItem,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Add rental tool'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_rentalItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Column(
              children: [
                Text(
                  'No rental tools added',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add equipment to include it in this offering.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth < 900
                  ? 900.0
                  : constraints.maxWidth;

              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      columnWidths: const {
                        0: FixedColumnWidth(44),
                        1: FlexColumnWidth(4),
                        2: FlexColumnWidth(3.2),
                        3: FlexColumnWidth(1.1),
                        4: FlexColumnWidth(2.1),
                        5: FlexColumnWidth(2.1),
                        6: FixedColumnWidth(80),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: const TableBorder(
                        horizontalInside: BorderSide(color: AppColors.border),
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                          ),
                          children: [
                            headerCell('NO.'),
                            headerCell('EQUIPMENT'),
                            headerCell('RENTAL PERIOD'),
                            headerCell('QTY', align: TextAlign.center),
                            headerCell('RATE / DAY', align: TextAlign.right),
                            headerCell('SUBTOTAL', align: TextAlign.right),
                            headerCell(''),
                          ],
                        ),
                        for (
                          var index = 0;
                          index < _rentalItems.length;
                          index++
                        )
                          _rentalTableRow(index, dateLabel: dateLabel),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'RENTAL TOTAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                formatRupiah(rentalTotal),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rentalTableCell(
    Widget child, {
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Align(alignment: alignment, child: child),
    );
  }

  TableRow _rentalTableRow(
    int index, {
    required String Function(DateTime) dateLabel,
  }) {
    final item = _rentalItems[index];
    final durationLabel =
        '${item.duration} day${item.duration == 1 ? '' : 's'}';

    return TableRow(
      children: [
        _rentalTableCell(
          Text(
            (index + 1).toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        _rentalTableCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.tool.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.tool.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _rentalTableCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dateLabel(item.startsAt)} – ${dateLabel(item.endsAt)}',
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                durationLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _rentalTableCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.tool.unit,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          alignment: Alignment.center,
        ),
        _rentalTableCell(
          Text(
            formatRupiah(item.rate),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
          alignment: Alignment.centerRight,
        ),
        _rentalTableCell(
          Text(
            formatRupiah(item.total),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          alignment: Alignment.centerRight,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Edit rental tool',
                onPressed: () => _editRentalItem(index),
                visualDensity: VisualDensity.compact,
                iconSize: 17,
                color: AppColors.secondary,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Remove rental tool',
                onPressed: () => _setState(() => _rentalItems.removeAt(index)),
                visualDensity: VisualDensity.compact,
                iconSize: 17,
                color: AppColors.textSecondary,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rentalCard() {
    return _sectionCard(
      title: 'Rental Period',
      children: [
        _dateField(
          label: 'Until Date',
          value: _rentalUntil,
          onPick: (date) => _setState(() => _rentalUntil = date),
        ),
        const SizedBox(height: 12),
        const Text(
          'Rent Tool offerings do not create a project. Set the date when the '
          'rental ends.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
