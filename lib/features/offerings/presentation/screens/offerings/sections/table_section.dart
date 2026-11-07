part of '../../offerings_page.dart';

extension _TableSection on _OfferingsPageState {
  Widget _table(List<Offering> offerings) {
    final columns = _columns;
    final fixed =
        columns.fold<double>(0, (sum, c) => sum + c.width) +
        _OfferingsPageState._wActions;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fill = fixed <= constraints.maxWidth;
          return Scrollbar(
            controller: _horizontal,
            child: SingleChildScrollView(
              controller: _horizontal,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: fill ? constraints.maxWidth : fixed,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _headerRow(columns, fill),
                    for (var i = 0; i < offerings.length; i++)
                      _tableRow(
                        offerings[i],
                        i,
                        columns,
                        fill,
                        i == offerings.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _headerRow(List<_Col> columns, bool fill) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in columns)
            _gridCell(
              width: c.width,
              flex: fill ? c.flex : null,
              header: true,
              end: true,
              child: _headerText(c.label),
            ),
          _gridCell(
            width: _OfferingsPageState._wActions,
            header: true,
            last: true,
            center: true,
            child: _headerText(''),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(
    Offering offering,
    int index,
    List<_Col> columns,
    bool fill,
    bool isLast,
  ) {
    final stripe = index.isEven
        ? AppColors.surface
        : AppColors.background.withValues(alpha: 0.5);
    return Material(
      color: stripe,
      child: InkWell(
        onTap: () => _openOffering(offering),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final c in columns)
                _gridCell(
                  width: c.width,
                  flex: fill ? c.flex : null,
                  bottom: !isLast,
                  end: true,
                  child: _cellFor(offering, c),
                ),
              _gridCell(
                width: _OfferingsPageState._wActions,
                last: true,
                center: true,
                bottom: !isLast,
                child: _rowAction(offering),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cellFor(Offering offering, _Col c) => switch (c) {
    _Col.number => _plainText(offering.number.isEmpty ? '—' : offering.number),
    _Col.name => Text(
      offering.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
    _Col.serviceType => _plainText(offering.serviceType),
    _Col.owner => _plainText(offering.owner),
    _Col.address => _plainText(offering.address),
    _Col.status => _pill(offering.status.label, offering.status.color),
    _Col.payment => _pill(offering.paidStatus.label, offering.paidStatus.color),
  };

  String _valueOf(Offering offering, _Col c) => switch (c) {
    _Col.number => offering.number,
    _Col.name => offering.name,
    _Col.serviceType => offering.serviceType,
    _Col.owner => offering.owner,
    _Col.address => offering.address,
    _Col.status => offering.status.label,
    _Col.payment => offering.paidStatus.label,
  };

  Widget _rowAction(Offering offering) {
    if (_isManager) return _menu(offering);
    return const Icon(
      Icons.chevron_right,
      size: 20,
      color: AppColors.textSecondary,
    );
  }

  Widget _gridCell({
    double? width,
    int? flex,
    bool last = false,
    bool header = false,
    bool center = false,
    bool end = false,
    bool bottom = true,
    required Widget child,
  }) {
    final cell = Container(
      width: flex != null ? null : width,
      alignment: end
          ? Alignment.centerRight
          : center
          ? Alignment.center
          : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: header ? 12 : 10),
      decoration: BoxDecoration(
        color: header ? AppColors.background : null,
        border: Border(
          right: last
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
          bottom: bottom
              ? const BorderSide(color: AppColors.border)
              : BorderSide.none,
        ),
      ),
      child: child,
    );
    return flex != null ? Expanded(flex: flex, child: cell) : cell;
  }

  Widget _headerText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _plainText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _menu(Offering offering) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'details') {
          _openOffering(offering);
        } else if (value == 'edit') {
          _editOffering(offering);
        } else if (value == 'project') {
          _openProject(offering);
        } else if (value == 'rental') {
          context.push(AppRouter.offeringDetail(offering.id, tab: 3));
        } else if (value == 'delete') {
          _deleteOffering(offering);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.open_in_new, size: 18),
              SizedBox(width: 10),
              Text('Details'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 10),
              Text('Edit'),
            ],
          ),
        ),
        if (offering.isRentalService)
          const PopupMenuItem(
            value: 'rental',
            child: Row(
              children: [
                Icon(Icons.event_outlined, size: 18),
                SizedBox(width: 10),
                Text('Rental Details'),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'project',
            enabled: offering.projectId != null,
            child: const Row(
              children: [
                Icon(Icons.folder_open_outlined, size: 18),
                SizedBox(width: 10),
                Text('View Project'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.onHold),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: AppColors.onHold)),
            ],
          ),
        ),
      ],
    );
  }
}
