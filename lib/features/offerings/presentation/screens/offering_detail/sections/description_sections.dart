part of '../../offering_detail_screen.dart';

extension _DescriptionSections on _OfferingDetailScreenState {
  Widget _descriptionCard(Offering offering) {
    final items = offering.lineItems;
    final numbers = lineItemLabels(items, style: offering.numberingStyle);
    final hasItems = items.isNotEmpty;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Description of Work')),
              if (hasItems)
                _miniPill(
                  '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                  AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 14),
          if (!hasItems)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'No description of work recorded for this offering.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final useTable = constraints.maxWidth >= 620;
                return useTable
                    ? _descriptionTable(items, numbers)
                    : _descriptionList(items, numbers);
              },
            ),
          const SizedBox(height: 14),
          _descriptionTotal(offering),
        ],
      ),
    );
  }

  Widget _descriptionTable(List<OfferingLineItem> items, List<String> numbers) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(56),
        1: FlexColumnWidth(5),
        2: FixedColumnWidth(60),
        3: FixedColumnWidth(64),
        4: FixedColumnWidth(132),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: AppColors.border),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.72),
          ),
          children: const [
            _DescriptionHeader('NO.', alignment: TextAlign.center),
            _DescriptionHeader('DESCRIPTION OF WORK'),
            _DescriptionHeader('QTY', alignment: TextAlign.center),
            _DescriptionHeader('UNIT', alignment: TextAlign.center),
            _DescriptionHeader('TOTAL', alignment: TextAlign.right),
          ],
        ),
        for (var index = 0; index < items.length; index++)
          _descriptionTableRow(items[index], numbers[index]),
      ],
    );
  }

  TableRow _descriptionTableRow(OfferingLineItem item, String number) {
    final description = item.description.trim().isEmpty
        ? 'Untitled work item'
        : item.description;

    return TableRow(
      decoration: item.excludeFromTotal
          ? BoxDecoration(color: AppColors.inProgress.withValues(alpha: 0.10))
          : null,
      children: [
        _descriptionNumber(number, item),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Text.rich(
            lineItemTextSpan(
              description,
              item.descriptionRuns,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        _descriptionValue(item.qty, alignment: TextAlign.center),
        _descriptionValue(item.uom, alignment: TextAlign.center),
        _descriptionAmount(item),
      ],
    );
  }

  Widget _descriptionNumber(String number, OfferingLineItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
      child: Text(
        number,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ).copyWith(
              fontWeight: item.rowBold ? FontWeight.w900 : FontWeight.w700,
              fontStyle: item.rowItalic ? FontStyle.italic : FontStyle.normal,
            ),
      ),
    );
  }

  Widget _descriptionValue(
    String value, {
    TextAlign alignment = TextAlign.start,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      child: Text(
        value.trim().isEmpty ? ' ' : value,
        textAlign: alignment,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _descriptionAmount(OfferingLineItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Text(
        item.amount > 0 ? formatRupiah(item.amount) : ' ',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 12,
          fontWeight: item.rowBold ? FontWeight.w900 : FontWeight.w700,
          fontStyle: item.rowItalic ? FontStyle.italic : FontStyle.normal,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _descriptionList(List<OfferingLineItem> items, List<String> numbers) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++)
            _descriptionListRow(
              items[index],
              numbers[index],
              index,
              items.length,
            ),
        ],
      ),
    );
  }

  Widget _descriptionListRow(
    OfferingLineItem item,
    String number,
    int index,
    int count,
  ) {
    final description = item.description.trim().isEmpty
        ? 'Untitled work item'
        : item.description;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: item.excludeFromTotal
            ? AppColors.inProgress.withValues(alpha: 0.10)
            : null,
        border: index == count - 1
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 38,
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: item.rowBold
                        ? FontWeight.w900
                        : FontWeight.w700,
                    fontStyle: item.rowItalic
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  lineItemTextSpan(
                    description,
                    item.descriptionRuns,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              _descriptionMeta('Qty', item.qty),
              const SizedBox(width: 14),
              _descriptionMeta('Unit', item.uom),
              const Spacer(),
              Text(
                item.amount > 0 ? formatRupiah(item.amount) : ' ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: item.rowBold ? FontWeight.w900 : FontWeight.w700,
                  fontStyle: item.rowItalic
                      ? FontStyle.italic
                      : FontStyle.normal,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _descriptionMeta(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          TextSpan(
            text: value.trim().isEmpty ? ' ' : value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionTotal(Offering offering) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Offering budget',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            formatRupiah(offering.budgetAmount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsCard(Offering offering) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Payment Terms'),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 14),
          if (offering.terms.isEmpty)
            const Text(
              'No payment terms recorded.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 480
                  ? Table(
                      border: TableBorder.all(color: AppColors.border),
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FixedColumnWidth(80),
                        2: FixedColumnWidth(140),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.72),
                          ),
                          children: const [
                            _DescriptionHeader('MILESTONE'),
                            _DescriptionHeader(
                              '%',
                              alignment: TextAlign.center,
                            ),
                            _DescriptionHeader(
                              'AMOUNT',
                              alignment: TextAlign.right,
                            ),
                          ],
                        ),
                        for (final term in offering.terms)
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  term.name,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              _descriptionValue(
                                '${term.percentage.toStringAsFixed(term.percentage % 1 == 0 ? 0 : 1)}%',
                                alignment: TextAlign.center,
                              ),
                              _descriptionValue(
                                formatRupiah(term.amount),
                                alignment: TextAlign.right,
                              ),
                            ],
                          ),
                      ],
                    )
                  : Column(
                      children: [
                        for (final term in offering.terms)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(term.name),
                            subtitle: Text(
                              '${term.percentage.toStringAsFixed(term.percentage % 1 == 0 ? 0 : 1)}%',
                            ),
                            trailing: Text(
                              formatRupiah(term.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
