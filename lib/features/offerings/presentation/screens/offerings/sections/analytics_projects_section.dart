part of '../../offerings_page.dart';

extension _AnalyticsProjectsSection on _OfferingsPageState {
  Widget _topClientsCard(List<Offering> offerings) {
    final aggregates = <String, _ClientAggregate>{};
    for (final offering in offerings) {
      final name = offering.owner.trim().isEmpty
          ? 'Unassigned'
          : offering.owner.trim();
      final aggregate = aggregates.putIfAbsent(name, () => _ClientAggregate());
      aggregate.count += 1;
      aggregate.budget += offering.budgetAmount ?? 0;
      aggregate.paid += offering.amountPaid;
    }
    final top = aggregates.entries.toList()
      ..sort((a, b) => b.value.budget.compareTo(a.value.budget));

    return _analyticsCard(
      title: 'Top clients',
      subtitle: 'Ranked by offering value',
      trailing: _pill('${aggregates.length} clients', AppColors.primary),
      child: top.isEmpty
          ? _analyticsEmpty('No client data yet')
          : Column(
              children: [
                for (var i = 0; i < top.length && i < 5; i++) ...[
                  _clientAggregateRow(i + 1, top[i].key, top[i].value),
                  if (i < top.length - 1 && i < 4) const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }

  Widget _clientAggregateRow(
    int rank,
    String name,
    _ClientAggregate aggregate,
  ) {
    final ratio = aggregate.budget > 0
        ? (aggregate.paid / aggregate.budget).clamp(0.0, 1.0)
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 22,
              width: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: rank <= 3
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
                    '${aggregate.count} offering${aggregate.count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatRupiah(aggregate.budget),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation(AppColors.paid),
          ),
        ),
      ],
    );
  }

  Widget _serviceMixCard(List<Offering> offerings) {
    final counts = <String, int>{};
    final values = <String, double>{};
    for (final offering in offerings) {
      final key = offering.serviceType.trim().isEmpty
          ? 'Unspecified'
          : offering.serviceType.trim();
      counts[key] = (counts[key] ?? 0) + 1;
      values[key] = (values[key] ?? 0) + (offering.budgetAmount ?? 0);
    }
    final types = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    return _analyticsCard(
      title: 'Service mix',
      subtitle: 'Offerings grouped by service type',
      child: types.isEmpty
          ? _analyticsEmpty('No offerings yet')
          : Column(
              children: [
                for (var i = 0; i < types.length; i++)
                  _distributionRow(
                    label: types[i],
                    value:
                        '${counts[types[i]]} · ${formatRupiah(values[types[i]])}',
                    ratio: offerings.isEmpty
                        ? 0
                        : (counts[types[i]] ?? 0) / offerings.length,
                    color: _analyticsColor(i),
                  ),
              ],
            ),
    );
  }

  Widget _projectHealthCard(List<Project> projects, double averageProgress) {
    final slices = <_AnalyticsSlice>[
      for (final status in ProjectStatus.values)
        _AnalyticsSlice(
          status.label,
          projects.where((p) => p.status == status).length.toDouble(),
          status.color,
        ),
    ];
    return _analyticsCard(
      title: 'Project health',
      subtitle: 'Execution status across projects',
      trailing: _pill(
        '${(averageProgress * 100).round()}% avg',
        AppColors.inProgress,
      ),
      child: projects.isEmpty
          ? _analyticsEmpty('No projects yet')
          : Column(
              children: [
                _segmentedBar(slices, height: 10),
                const SizedBox(height: 14),
                for (final status in ProjectStatus.values) ...[
                  _legendRow(
                    label: status.label,
                    count: projects.where((p) => p.status == status).length,
                    color: status.color,
                    total: projects.length,
                  ),
                  if (status != ProjectStatus.values.last)
                    const SizedBox(height: 9),
                ],
              ],
            ),
    );
  }

  List<_UnpaidProject> _unpaidProjects(
    List<Offering> offerings,
    List<Project> projects,
  ) {
    final byId = {for (final offering in offerings) offering.id: offering};
    final items = <_UnpaidProject>[];
    for (final project in projects) {
      final offering = byId[project.offeringId];
      if (offering == null || offering.paidStatus == PaidStatus.paid) continue;
      items.add(_UnpaidProject(project, offering, offering.remainingAmount));
    }
    items.sort((a, b) => (b.remaining ?? 0).compareTo(a.remaining ?? 0));
    return items;
  }

  Widget _unpaidProjectsCard(List<_UnpaidProject> unpaidProjects) {
    final total = unpaidProjects.fold<double>(
      0,
      (sum, item) => sum + (item.remaining ?? 0),
    );
    final visible = unpaidProjects.take(6).toList();
    final totalLabel = unpaidProjects.length == 1 ? 'project' : 'projects';
    return _analyticsCard(
      title: 'Unpaid projects',
      subtitle: total > 0
          ? '${formatRupiah(total)} outstanding across '
                '${unpaidProjects.length} $totalLabel'
          : 'Projects whose offering invoice is not settled',
      trailing: _pill(
        '${unpaidProjects.length} unpaid',
        unpaidProjects.isEmpty ? AppColors.completed : AppColors.pending,
      ),
      child: unpaidProjects.isEmpty
          ? _analyticsEmpty('All project invoices are settled')
          : Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _unpaidProjectRow(visible[i]),
                  if (i < visible.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                ],
                if (unpaidProjects.length > visible.length) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '+${unpaidProjects.length - visible.length} more '
                      'unpaid $totalLabel',
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

  Widget _unpaidProjectRow(_UnpaidProject item) {
    final offering = item.offering;
    final budget = offering.budgetAmount ?? 0;
    final paidRatio = budget > 0
        ? (offering.amountPaid / budget).clamp(0.0, 1.0)
        : 0.0;
    final color = offering.paidStatus.color;
    final client = item.project.owner.isEmpty
        ? 'No client'
        : item.project.owner;
    final number = offering.number.isEmpty
        ? 'No offering number'
        : offering.number;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.folder_outlined, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.project.name,
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
                    '$client · $number · ${item.project.status.label}',
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
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.remaining == null
                      ? 'No budget'
                      : formatRupiah(item.remaining),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                _pill(offering.paidStatus.label, color),
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: paidRatio,
            minHeight: 5,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation(AppColors.paid),
          ),
        ),
      ],
    );
  }

  List<Offering> _rentalWatchlist(List<Offering> offerings) {
    final rentals =
        offerings
            .where((o) => o.isRentalService && o.rentalUntil != null)
            .toList()
          ..sort((a, b) => a.rentalUntil!.compareTo(b.rentalUntil!));
    return rentals.take(5).toList();
  }

  Widget _rentalWatchlistCard(List<Offering> rentals) {
    return _analyticsCard(
      title: 'Rental watchlist',
      subtitle: 'Rented tools due for return',
      trailing: _pill('${rentals.length} active', AppColors.primary),
      child: Column(
        children: [
          for (var i = 0; i < rentals.length; i++) ...[
            _rentalRow(rentals[i]),
            if (i < rentals.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _rentalRow(Offering offering) {
    final until = offering.rentalUntil!;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final target = DateTime(until.year, until.month, until.day);
    final days = target.difference(start).inDays;
    final (label, color) = days < 0
        ? ('${days.abs()}d overdue', AppColors.onHold)
        : days == 0
        ? ('Due today', AppColors.onHold)
        : days <= 3
        ? ('${days}d left', AppColors.pending)
        : ('${days}d left', AppColors.primary);

    return Row(
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
                offering.name,
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
                '${offering.owner.isEmpty ? 'No client' : offering.owner} · '
                '${_analyticsDate(until)}',
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
        _pill(label, color),
      ],
    );
  }
}
