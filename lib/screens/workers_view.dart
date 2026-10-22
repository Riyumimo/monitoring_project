import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/user.dart';
import '../providers/project_provider.dart';
import '../services/assignment_rules.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

enum _WCol { name, type, email, phone, load, inProgress, availability }

extension _WColX on _WCol {
  String get label => switch (this) {
        _WCol.name => 'Name',
        _WCol.type => 'Type',
        _WCol.email => 'Email',
        _WCol.phone => 'Phone',
        _WCol.load => 'Load',
        _WCol.inProgress => 'In Progress',
        _WCol.availability => 'Availability',
      };

  double get width => switch (this) {
        _WCol.name => 190,
        _WCol.type => 120,
        _WCol.email => 230,
        _WCol.phone => 165,
        _WCol.load => 100,
        _WCol.inProgress => 120,
        _WCol.availability => 130,
      };

  int get flex => width.round();
}

class WorkersView extends StatefulWidget {
  const WorkersView({super.key});

  @override
  State<WorkersView> createState() => _WorkersViewState();
}

class _WorkersViewState extends State<WorkersView> {
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workers = MockData.workers();
    final provider = context.watch<ProjectProvider>();
    final active = provider.projects
        .where((p) => p.status == ProjectStatus.inProgress);

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '${workers.length}',
                  label: 'Team Members',
                  icon: Icons.people_outline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: '${active.length}',
                  label: 'Active Projects',
                  icon: Icons.assignment_turned_in_outlined,
                  color: AppColors.inProgress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Field Team',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _table(workers, provider),
        ],
      ),
    );
  }

  Widget _table(List<User> workers, ProjectProvider provider) {
    const columns = _WCol.values;
    final fixed = columns.fold<double>(0, (sum, c) => sum + c.width);

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
                    for (var i = 0; i < workers.length; i++)
                      _tableRow(
                        workers[i],
                        i,
                        columns,
                        provider,
                        fill,
                        i == workers.length - 1,
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

  Widget _headerRow(List<_WCol> columns, bool fill) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < columns.length; i++)
            _gridCell(
              width: columns[i].width,
              flex: fill ? columns[i].flex : null,
              last: i == columns.length - 1,
              header: true,
              end: true,
              child: _headerText(columns[i].label),
            ),
        ],
      ),
    );
  }

  Widget _tableRow(
    User worker,
    int index,
    List<_WCol> columns,
    ProjectProvider provider,
    bool fill,
    bool isLast,
  ) {
    final workerProjects = provider.projects
        .where((p) => p.isAssignedTo(worker.id))
        .toList();
    final inProgress = workerProjects
        .where((p) => p.status == ProjectStatus.inProgress)
        .length;
    final load = AssignmentRules.activeLoad(
      worker.id,
      projects: provider.projects,
    );
    final stripe = index.isEven
        ? AppColors.surface
        : AppColors.background.withValues(alpha: 0.5);

    return Material(
      color: stripe,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < columns.length; i++)
              _gridCell(
                width: columns[i].width,
                flex: fill ? columns[i].flex : null,
                last: i == columns.length - 1,
                bottom: !isLast,
                end: true,
                child: _cellFor(
                  worker,
                  columns[i],
                  workerProjects.length,
                  inProgress,
                  load,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cellFor(
    User worker,
    _WCol c,
    int assignedProjects,
    int inProgress,
    int load,
  ) =>
      switch (c) {
        _WCol.name => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                worker.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$assignedProjects ${assignedProjects == 1 ? 'project' : 'projects'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        _WCol.type => _pill(
            worker.workerTypeLabel,
            worker.workerType == WorkerType.cad
                ? AppColors.accepted
                : AppColors.primary,
          ),
        _WCol.email => _plainText(worker.email),
        _WCol.phone => _plainText(
            (worker.phone == null || worker.phone!.isEmpty)
                ? '—'
                : worker.phone!,
          ),
        _WCol.load => Text(
            _loadLabel(worker, load),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        _WCol.inProgress => Text(
            '$inProgress',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: inProgress > 0
                  ? AppColors.inProgress
                  : AppColors.textSecondary,
            ),
          ),
        _WCol.availability => _pill(
            worker.availabilityLabel,
            worker.availability == WorkAvailability.inOffice
                ? AppColors.completed
                : AppColors.onHold,
          ),
      };

  String _loadLabel(User worker, int active) {
    final max = AssignmentRules.maxProjects(worker);
    return max == null ? '$active / ∞' : '$active / $max';
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
          bottom:
              bottom ? const BorderSide(color: AppColors.border) : BorderSide.none,
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
}
