part of '../../project_detail_screen.dart';

extension _ProjectOverviewSections on _ProjectDetailScreenState {
  Widget _overviewCard(Project project, Offering? offering) {
    return _card(
      stripe: AppColors.pending,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: _Eyebrow('Project Overview')),
                  Text(
                    project.number.isEmpty
                        ? 'PROJECT'
                        : 'PROJECT ${project.number}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  letterSpacing: -0.4,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              _infoBar(
                icon: Icons.calendar_today_outlined,
                child: Text(
                  _dateRange(project.startDate, project.endDate),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _infoBar(
                icon: Icons.place_outlined,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.address.isEmpty
                            ? 'No address recorded'
                            : project.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _navButton(),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(
                  label: project.status.label,
                  color: project.status.color,
                ),
                _miniPill(
                  '${project.progressPercentage}% complete',
                  AppColors.primary,
                ),
                if (offering != null && offering.serviceType.isNotEmpty)
                  _miniPill(offering.serviceType, AppColors.accepted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(Project project, Offering? offering) {
    final serviceType = offering != null && offering.serviceType.isNotEmpty
        ? offering.serviceType
        : 'Project Work';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Status & Metadata'),
          const SizedBox(height: 14),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _metricCell(
                          label: 'Status',
                          icon: _statusIcon(project.status),
                          value: project.status.label,
                          color: project.status.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricCell(
                          label: 'Progress',
                          icon: Icons.trending_up,
                          value: '${project.progressPercentage}%',
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _metricCell(
                          label: 'Budget',
                          icon: Icons.payments_outlined,
                          value: formatRupiah(project.budgetAmount),
                          color: AppColors.completed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricCell(
                          label: 'Service',
                          icon: Icons.layers_outlined,
                          value: serviceType,
                          color: AppColors.accepted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCell({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Schedule not set';
    if (start != null && end == null) return _formatDate(start);
    if (start == null && end != null) return 'Until ${_formatDate(end)}';

    if (start!.year == end!.year && start.month == end.month) {
      return '${_monthName(start.month)} ${_ordinal(start.day)} – '
          '${_ordinal(end.day)}, ${end.year}';
    }
    return '${_monthName(start.month)} ${_ordinal(start.day)} – '
        '${_monthName(end.month)} ${_ordinal(end.day)}, ${end.year}';
  }

  String _formatDate(DateTime value) =>
      '${_monthName(value.month)} ${_ordinal(value.day)}, ${value.year}';

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }
}
