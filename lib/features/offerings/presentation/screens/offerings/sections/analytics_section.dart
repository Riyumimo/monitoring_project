part of '../../offerings_page.dart';

extension _AnalyticsSection on _OfferingsPageState {
  Widget _analyticsView(List<Offering> offerings, List<Project> projects) {
    final budget = offerings.fold<double>(
      0,
      (sum, offering) => sum + (offering.budgetAmount ?? 0),
    );
    final collected = offerings.fold<double>(
      0,
      (sum, offering) => sum + offering.amountPaid,
    );
    final outstanding = offerings.fold<double>(
      0,
      (sum, offering) => sum + (offering.remainingAmount ?? 0),
    );
    final accepted = offerings
        .where((offering) => offering.status == OfferingStatus.accepted)
        .length;
    final rejected = offerings
        .where((offering) => offering.status == OfferingStatus.rejected)
        .length;
    final decided = accepted + rejected;
    final activeProjects = projects
        .where(
          (project) =>
              project.status != ProjectStatus.completed &&
              project.status != ProjectStatus.cancelled,
        )
        .length;
    final completedProjects = projects
        .where((project) => project.status == ProjectStatus.completed)
        .length;
    final averageProgress = projects.isEmpty
        ? 0.0
        : projects.fold<int>(
                0,
                (sum, project) => sum + project.progressPercentage,
              ) /
              projects.length /
              100;

    final kpis = <_AnalyticsKpi>[
      _AnalyticsKpi(
        label: 'Pipeline value',
        value: formatRupiah(budget),
        caption:
            '${offerings.length} offering${offerings.length == 1 ? '' : 's'}',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
      ),
      _AnalyticsKpi(
        label: 'Collected',
        value: formatRupiah(collected),
        caption: budget > 0
            ? '${((collected / budget) * 100).round()}% of pipeline'
            : 'No budget recorded',
        icon: Icons.payments_outlined,
        color: AppColors.paid,
      ),
      _AnalyticsKpi(
        label: 'Outstanding',
        value: formatRupiah(outstanding),
        caption:
            '${offerings.where((o) => (o.remainingAmount ?? 0) > 0).length} with a balance',
        icon: Icons.request_quote_outlined,
        color: AppColors.pending,
      ),
      _AnalyticsKpi(
        label: 'Acceptance rate',
        value: decided == 0 ? '—' : '${((accepted / decided) * 100).round()}%',
        caption: decided == 0
            ? 'No decided offers'
            : '$accepted of $decided decided',
        icon: Icons.thumb_up_alt_outlined,
        color: AppColors.accepted,
      ),
      _AnalyticsKpi(
        label: 'Active projects',
        value: '$activeProjects',
        caption: '${projects.length} total · $completedProjects completed',
        icon: Icons.folder_open_outlined,
        color: AppColors.inProgress,
      ),
      _AnalyticsKpi(
        label: 'Average progress',
        value: '${(averageProgress * 100).round()}%',
        caption: projects.isEmpty
            ? 'No projects yet'
            : 'Across visible projects',
        icon: Icons.stacked_line_chart_outlined,
        color: AppColors.completed,
      ),
    ];

    final rentals = _rentalWatchlist(offerings);
    final unpaidProjects = _unpaidProjects(offerings, projects);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _analyticsHeader(offerings.length, projects.length),
          const SizedBox(height: 18),
          _kpiGrid(kpis),
          const SizedBox(height: 16),
          _unpaidProjectsCard(unpaidProjects),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 16.0;
              final twoColumns = constraints.maxWidth >= 980;
              if (!twoColumns) {
                return Column(
                  children: [
                    _collectionHealthCard(
                      budget: budget,
                      collected: collected,
                      outstanding: outstanding,
                    ),
                    const SizedBox(height: gap),
                    _offeringStatusCard(offerings),
                    const SizedBox(height: gap),
                    _projectDeadlinesCard(projects),
                    const SizedBox(height: gap),
                    _topClientsCard(offerings),
                    const SizedBox(height: gap),
                    _serviceMixCard(offerings),
                    const SizedBox(height: gap),
                    _projectHealthCard(projects, averageProgress),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _collectionHealthCard(
                          budget: budget,
                          collected: collected,
                          outstanding: outstanding,
                        ),
                        const SizedBox(height: gap),
                        _projectDeadlinesCard(projects),
                        const SizedBox(height: gap),
                        _serviceMixCard(offerings),
                      ],
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      children: [
                        _offeringStatusCard(offerings),
                        const SizedBox(height: gap),
                        _topClientsCard(offerings),
                        const SizedBox(height: gap),
                        _projectHealthCard(projects, averageProgress),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (rentals.isNotEmpty) ...[
            const SizedBox(height: 16),
            _rentalWatchlistCard(rentals),
          ],
        ],
      ),
    );
  }

  Widget _analyticsHeader(int offeringCount, int projectCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.insights_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$offeringCount offerings · $projectCount projects',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _pill('Live view', AppColors.accepted),
      ],
    );
  }

  Widget _kpiGrid(List<_AnalyticsKpi> kpis) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 1040
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final kpi in kpis)
              SizedBox(width: width, child: _kpiCard(kpi)),
          ],
        );
      },
    );
  }
}
