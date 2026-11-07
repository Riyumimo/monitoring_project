part of '../../offering_form_screen.dart';

extension _FormLineItemSections on _OfferingFormScreenState {
  void _addLineItem() {
    _setState(() {
      final draft = _createLineItemDraft(
        numberText: _nextNumberForNewRow(_lineItems.length, 0),
      );
      _lineItems.add(draft);
    });
  }

  /// Finds the next serial number for a new row in the sibling group that
  /// starts at [insertAt] with [indent].
  String _nextNumberForNewRow(int insertAt, int indent) {
    for (var i = insertAt - 1; i >= 0; i--) {
      final row = _lineItems[i];
      if (row.indent < indent) break;
      if (row.indent == indent) {
        final previous = row.number.text.trim();
        if (isLineItemNumberSeed(previous)) {
          return lineItemLabelAfter(previous, 1);
        }
      }
    }
    return switch (indent) {
      1 => 'a',
      2 => 'A',
      _ => '1',
    };
  }

  /// Auto-fills following siblings when the user types a starting number such
  /// as 1, a or A into a No. cell. Deeper nested rows are left untouched.
  void _autoFillNumbers(int index) {
    final item = _lineItems[index];
    final seed = item.number.text.trim();
    if (!isLineItemNumberSeed(seed)) return;

    var offset = 1;
    for (var i = index + 1; i < _lineItems.length; i++) {
      final row = _lineItems[i];
      if (row.indent < item.indent) break;
      if (row.indent != item.indent) continue;
      row.number.text = lineItemLabelAfter(seed, offset);
      offset++;
    }
  }

  /// Adds a new row below the current row (after any nested children) and
  /// focuses its description. This backs the Enter shortcut on the Total
  /// field.
  void _addLineItemAfter(int index) {
    final current = _lineItems[index];
    var insertAt = index + 1;
    while (insertAt < _lineItems.length &&
        _lineItems[insertAt].indent > current.indent) {
      insertAt++;
    }

    final draft = _createLineItemDraft(
      indent: current.indent,
      numberText: _nextNumberForNewRow(insertAt, current.indent),
    );
    _setState(() {
      _lineItems.insert(insertAt, draft);
      _autoFillNumbers(insertAt);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_lineItems.contains(draft)) return;
      draft.descriptionFocus.requestFocus();
    });
  }

  void _removeLineItem(int index) {
    _setState(() {
      final removeIndent = _lineItems[index].indent;
      var end = index + 1;
      while (end < _lineItems.length && _lineItems[end].indent > removeIndent) {
        end++;
      }
      for (var i = end - 1; i >= index; i--) {
        _lineItems.removeAt(i).dispose();
      }
      if (_lineItems.isEmpty) {
        _lineItems.add(_createLineItemDraft(numberText: '1'));
        return;
      }

      int? remainingSibling;
      if (index < _lineItems.length &&
          _lineItems[index].indent == removeIndent) {
        remainingSibling = index;
      } else {
        for (var i = index - 1; i >= 0; i--) {
          final row = _lineItems[i];
          if (row.indent < removeIndent) break;
          if (row.indent == removeIndent) {
            remainingSibling = i;
            break;
          }
        }
      }
      if (remainingSibling != null) {
        final start = _firstSiblingIndex(remainingSibling, removeIndent);
        _autoFillNumbers(start);
      }
    });
  }

  /// Finds the first row of the sibling group that contains [index].
  int _firstSiblingIndex(int index, int indent) {
    var start = index;
    for (var i = index - 1; i >= 0; i--) {
      final row = _lineItems[i];
      if (row.indent < indent) break;
      if (row.indent == indent) start = i;
    }
    return start;
  }

  double get _lineItemTotal {
    if (_lineItems.isEmpty) return 0;
    final rootIndent = _lineItems
        .map((item) => item.indent)
        .reduce((a, b) => a < b ? a : b);

    var total = 0.0;
    for (var index = 0; index < _lineItems.length; index++) {
      if (_lineItems[index].indent == rootIndent) {
        total += _effectiveAmount(index);
      }
    }
    return total;
  }

  double _draftAmount(_LineItemDraft item) =>
      parseRupiah(item.amount.text) ?? 0;

  double _effectiveAmount(int index) {
    final item = _lineItems[index];
    final own = item.excludeFromTotal ? 0.0 : _draftAmount(item);
    if (own > 0) return own;

    final baseIndent = item.indent;
    int? childIndent;
    var total = 0.0;
    for (var i = index + 1; i < _lineItems.length; i++) {
      final row = _lineItems[i];
      if (row.indent <= baseIndent) break;
      childIndent ??= row.indent;
      if (row.indent == childIndent) total += _effectiveAmount(i);
    }
    return total;
  }

  bool _hasNestedChildren(int index) =>
      index + 1 < _lineItems.length &&
      _lineItems[index + 1].indent > _lineItems[index].indent;

  int get _filledLineItemCount =>
      _lineItems.where((item) => !item.isBlank).length;

  List<OfferingLineItem> get _lineItemsForSave => [
    for (final item in _lineItems)
      if (!item.isBlank)
        OfferingLineItem(
          description: item.description.text,
          descriptionRuns: item.description.formatRuns,
          rowBold: item.rowBold,
          rowItalic: item.rowItalic,
          qty: item.excludeFromTotal ? '' : item.qty.text.trim(),
          uom: item.excludeFromTotal ? '' : item.uom.text.trim(),
          amount: parseRupiah(item.amount.text) ?? 0,
          numberLabel: item.number.text.trim(),
          indent: item.indent,
          excludeFromTotal: item.excludeFromTotal,
        ),
  ];

  String? _validateLineItemDescription(_LineItemDraft item) {
    if (item.isBlank) return null;
    return item.description.text.trim().isEmpty ? 'Enter a description' : null;
  }

  String? _validateLineItemAmount(int index) {
    final item = _lineItems[index];
    if (item.isBlank || item.excludeFromTotal) return null;
    final amount = parseRupiah(item.amount.text);
    if (amount != null && amount > 0) return null;
    if (_hasNestedChildren(index)) return null;
    return amount == null ? 'Enter total' : 'Enter a valid total';
  }

  void _setLineItemExcluded(int index, bool excluded) {
    _setState(() {
      final item = _lineItems[index];
      item.excludeFromTotal = excluded;
      if (excluded) {
        item.qty.clear();
        item.uom.clear();
      }
    });
  }

  Widget _budgetCard() {
    return _sectionCard(
      title: 'Description of Work',
      children: [
        const Text(
          'Add each work item with its quantity, unit, and total. Use the '
          'level control to nest an item under the row above; nesting is '
          'optional. Tick Exclude for a section row that should not add its '
          'own total to the budget. The total below becomes the offering '
          'budget. Press Enter in the Total field to add the next row. Select '
          'description text and press Ctrl+B for bold or Ctrl+I for italic. '
          'Type a starting number in any No. cell, such as 1, a or A, and the '
          'rows below it at the same level are numbered automatically.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 680;
            return Column(
              children: [
                wide
                    ? _lineItemTable()
                    : Column(
                        children: [
                          for (
                            var index = 0;
                            index < _lineItems.length;
                            index++
                          ) ...[
                            _narrowLineItem(index),
                            if (index != _lineItems.length - 1)
                              const SizedBox(height: 8),
                          ],
                        ],
                      ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _addLineItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Item'),
                    ),
                    const Spacer(),
                    Text(
                      '$_filledLineItemCount item'
                      '${_filledLineItemCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _budgetTotalRow(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _lineItemTable() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FixedColumnWidth(42),
          2: FlexColumnWidth(5),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(2),
          6: FixedColumnWidth(54),
          7: FixedColumnWidth(40),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: const TableBorder(
          horizontalInside: BorderSide(color: AppColors.border),
          verticalInside: BorderSide(color: AppColors.border),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
            ),
            children: [
              const _LineItemHeaderCell('LEVEL', horizontalPadding: 4),
              const _LineItemHeaderCell('NO.', horizontalPadding: 4),
              const _LineItemHeaderCell('DESCRIPTION OF WORK'),
              const _LineItemHeaderCell('QTY', alignment: TextAlign.center),
              const _LineItemHeaderCell('UNIT', alignment: TextAlign.center),
              const _LineItemHeaderCell('TOTAL', alignment: TextAlign.right),
              const _LineItemHeaderCell(
                'EXCLUDE',
                alignment: TextAlign.center,
                horizontalPadding: 4,
              ),
              const SizedBox.shrink(),
            ],
          ),
          for (var index = 0; index < _lineItems.length; index++)
            _lineItemTableRow(index),
        ],
      ),
    );
  }

  TableRow _lineItemTableRow(int index) {
    final item = _lineItems[index];
    return TableRow(
      decoration: item.excludeFromTotal
          ? BoxDecoration(color: AppColors.inProgress.withValues(alpha: 0.10))
          : null,
      children: [
        Center(child: _nestingButton(index)),
        _numberField(index),
        RichTextShortcuts(
          controller: item.description,
          child: _tableField(
            item.description,
            hintText: 'Enter work description',
            maxLines: 2,
            focusNode: item.descriptionFocus,
            textInputAction: TextInputAction.next,
            validator: (_) => _validateLineItemDescription(item),
          ),
        ),
        _tableField(
          item.qty,
          hintText: item.excludeFromTotal ? '' : '1',
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          enabled: !item.excludeFromTotal,
        ),
        _tableField(
          item.uom,
          hintText: item.excludeFromTotal ? '' : 'Lot',
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.next,
          enabled: !item.excludeFromTotal,
        ),
        _tableField(
          item.amount,
          hintText: '0',
          prefixText: 'Rp ',
          textAlign: TextAlign.right,
          style: _rowTextStyle(item),
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          textInputAction: TextInputAction.done,
          onChanged: (_) => _setState(() {}),
          onFieldSubmitted: (_) => _addLineItemAfter(index),
          validator: (_) => _validateLineItemAmount(index),
        ),
        Center(child: _excludeCheckbox(index)),
        Center(child: _removeLineItemButton(index)),
      ],
    );
  }

  Widget _numberField(int index, {bool compact = false}) {
    final item = _lineItems[index];
    return TextField(
      controller: item.number,
      focusNode: item.numberFocus,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: TextStyle(
        fontSize: compact ? 13 : 10.5,
        fontWeight: item.rowBold ? FontWeight.w900 : FontWeight.w700,
        fontStyle: item.rowItalic ? FontStyle.italic : FontStyle.normal,
        color: AppColors.textSecondary,
      ),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
      ],
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 4,
          vertical: compact ? 4 : 13,
        ),
      ),
      onTap: () {
        item.number.selection = TextSelection(
          baseOffset: 0,
          extentOffset: item.number.text.length,
        );
      },
      onChanged: (_) => _autoFillNumbers(index),
    );
  }

  TextStyle _rowTextStyle(_LineItemDraft item) {
    return TextStyle(
      fontWeight: item.rowBold ? FontWeight.w900 : null,
      fontStyle: item.rowItalic ? FontStyle.italic : null,
    );
  }

  void _setLineItemIndent(int index, int value) {
    final item = _lineItems[index];
    final oldIndent = item.indent;
    final maxIndent = index == 0 ? 0 : _lineItems[index - 1].indent + 1;
    final next = value.clamp(0, maxIndent.clamp(0, 2)).toInt();
    final delta = next - oldIndent;
    if (delta == 0) return;

    _setState(() {
      item.indent = next;
      for (var i = index + 1; i < _lineItems.length; i++) {
        final row = _lineItems[i];
        if (row.indent <= oldIndent) break;
        row.indent = (row.indent + delta).clamp(0, 2).toInt();
      }
    });
  }

  Widget _nestingButton(int index) {
    final item = _lineItems[index];
    return PopupMenuButton<int>(
      tooltip: 'Nesting level',
      initialValue: item.indent,
      onSelected: (value) => _setLineItemIndent(index, value),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 0, child: Text('Top level')),
        PopupMenuItem(value: 1, child: Text('Sub-item')),
        PopupMenuItem(value: 2, child: Text('Sub-sub-item')),
      ],
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          item.indent == 0
              ? Icons.vertical_align_top
              : Icons.subdirectory_arrow_right,
          size: 18,
          color: item.indent == 0 ? AppColors.textSecondary : AppColors.primary,
        ),
      ),
    );
  }

  Widget _excludeCheckbox(int index) {
    final item = _lineItems[index];
    return Tooltip(
      message: item.excludeFromTotal
          ? 'Count this row in the total'
          : "Don't count to total",
      child: Checkbox(
        value: item.excludeFromTotal,
        onChanged: (value) => _setLineItemExcluded(index, value ?? false),
        activeColor: AppColors.primary,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _removeLineItemButton(int index) {
    return IconButton(
      onPressed: () => _removeLineItem(index),
      icon: const Icon(Icons.delete_outline, size: 20),
      color: AppColors.onHold,
      tooltip: 'Remove item',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
    );
  }

  Widget _budgetTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calculate_outlined,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Total Budget',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            formatRupiah(_lineItemTotal),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
