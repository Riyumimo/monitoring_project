part of '../../offerings_page.dart';

extension _AnalyticsCardsSection on _OfferingsPageState {
  Widget _kpiCard(_AnalyticsKpi kpi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: kpi.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(kpi.icon, size: 20, color: kpi.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kpi.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kpi.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kpi.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsCard({
    required String title,
    String? subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _collectionHealthCard({
    required double budget,
    required double collected,
    required double outstanding,
  }) {
    final rate = budget > 0 ? (collected / budget).clamp(0.0, 1.0) : 0.0;
    return _analyticsCard(
      title: 'Collection health',
      subtitle: 'Collected against the offering pipeline',
      trailing: _pill('${(rate * 100).round()}%', AppColors.paid),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 104,
                width: 104,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: rate,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.paid,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(rate * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'collected',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _analyticsAmountRow(
                      'Pipeline',
                      formatRupiah(budget),
                      AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    _analyticsAmountRow(
                      'Collected',
                      formatRupiah(collected),
                      AppColors.paid,
                    ),
                    const SizedBox(height: 8),
                    _analyticsAmountRow(
                      'Outstanding',
                      formatRupiah(outstanding),
                      AppColors.pending,
                    ),
                    const SizedBox(height: 12),
                    _segmentedBar([
                      _AnalyticsSlice('Collected', collected, AppColors.paid),
                      _AnalyticsSlice(
                        'Outstanding',
                        outstanding,
                        AppColors.pending,
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _analyticsAmountRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _offeringStatusCard(List<Offering> offerings) {
    final total = offerings.length;
    return _analyticsCard(
      title: 'Offering status',
      subtitle: 'Where the pipeline currently sits',
      child: Column(
        children: [
          for (final status in OfferingStatus.values)
            _distributionRow(
              label: status.label,
              value: _countShare(
                offerings.where((o) => o.status == status).length,
                total,
              ),
              ratio: total == 0
                  ? 0
                  : offerings.where((o) => o.status == status).length / total,
              color: status.color,
            ),
        ],
      ),
    );
  }

  Widget _projectDeadlinesCard(List<Project> projects) {
    final deadlines =
        projects
            .where(
              (project) =>
                  project.endDate != null &&
                  project.status != ProjectStatus.completed &&
                  project.status != ProjectStatus.cancelled,
            )
            .toList()
          ..sort((a, b) => a.endDate!.compareTo(b.endDate!));
    final overdue = deadlines
        .where((project) => _daysUntil(project.endDate!) < 0)
        .length;
    final top = deadlines.take(5).toList();

    return _analyticsCard(
      title: 'Project deadlines',
      subtitle: 'Active projects by due date',
      trailing: _pill(
        overdue > 0 ? '$overdue overdue' : '${deadlines.length} active',
        overdue > 0 ? AppColors.onHold : AppColors.primary,
      ),
      child: deadlines.isEmpty
          ? _analyticsEmpty('No active project deadlines')
          : Column(
              children: [
                for (var i = 0; i < top.length; i++) ...[
                  _projectDeadlineRow(top[i]),
                  if (i < top.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                ],
                if (deadlines.length > top.length) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '+${deadlines.length - top.length} more '
                      'deadline${deadlines.length - top.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _projectDeadlineRow(Project project) {
    final due = project.endDate!;
    final days = _daysUntil(due);
    final (label, color) = days < 0
        ? ('${days.abs()}d overdue', AppColors.onHold)
        : days == 0
        ? ('Due today', AppColors.onHold)
        : days <= 7
        ? ('${days}d left', AppColors.pending)
        : ('${days}d left', AppColors.primary);
    final client = project.owner.trim().isEmpty
        ? 'No client'
        : project.owner.trim();
    final progress = (project.progressPercentage / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.event_outlined, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$client · ${project.status.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _analyticsDate(due),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                _pill(label, color),
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
