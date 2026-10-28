import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../providers/worker_provider.dart';
import '../router/app_router.dart';
import '../services/assignment_rules.dart';
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
    _WCol.type => 170,
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
  static const double _wActions = 56;

  final ScrollController _horizontal = ScrollController();

  bool get _isManager => context.read<AuthProvider>().userRole == 'Manager';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerProvider>().ensureWorkersLoaded();
      context.read<ProjectProvider>().ensureProjectsLoaded();
    });
  }

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final workerProvider = context.watch<WorkerProvider>();
    final workers = workerProvider.workers;
    final active = provider.projects.where(
      (p) => p.status == ProjectStatus.inProgress,
    );

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
          _toolbar(),
          const SizedBox(height: 12),
          if (workerProvider.isLoading && workers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (workers.isEmpty)
            _emptyState()
          else
            _table(workers, provider),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Members',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (_isManager)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _addWorker,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Worker'),
          ),
      ],
    );
  }

  Widget _table(List<User> workers, ProjectProvider provider) {
    const columns = _WCol.values;
    final showActions = _isManager;
    final fixed =
        columns.fold<double>(0, (sum, c) => sum + c.width) +
        (showActions ? _wActions : 0);

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
                    _headerRow(columns, fill, showActions),
                    for (var i = 0; i < workers.length; i++)
                      _tableRow(
                        workers[i],
                        i,
                        columns,
                        provider,
                        fill,
                        showActions,
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

  Widget _headerRow(List<_WCol> columns, bool fill, bool showActions) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < columns.length; i++)
            _gridCell(
              width: columns[i].width,
              flex: fill ? columns[i].flex : null,
              last: !showActions && i == columns.length - 1,
              header: true,
              end: true,
              child: _headerText(columns[i].label),
            ),
          if (showActions)
            _gridCell(
              width: _wActions,
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
    User worker,
    int index,
    List<_WCol> columns,
    ProjectProvider provider,
    bool fill,
    bool showActions,
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
                last: !showActions && i == columns.length - 1,
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
            if (showActions)
              _gridCell(
                width: _wActions,
                last: true,
                center: true,
                bottom: !isLast,
                child: _rowAction(worker),
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
  ) => switch (c) {
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
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
    _WCol.type =>
      worker.workerTypes.isEmpty
          ? _plainText('—')
          : Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: [
                for (final type in worker.workerTypes)
                  _pill(type.label, _typeColor(type)),
              ],
            ),
    _WCol.email => _plainText(worker.email),
    _WCol.phone => _plainText(
      (worker.phone == null || worker.phone!.isEmpty) ? '—' : worker.phone!,
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
        color: inProgress > 0 ? AppColors.inProgress : AppColors.textSecondary,
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

  void _addWorker() => context.push(AppRouter.newWorker);

  void _editWorker(User worker) =>
      context.push(AppRouter.workerEdit(worker.id));

  Widget _rowAction(User worker) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') {
          _editWorker(worker);
        } else if (value == 'delete') {
          _deleteWorker(worker);
        }
      },
      itemBuilder: (_) => [
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

  Future<void> _deleteWorker(User worker) async {
    final projectProvider = context.read<ProjectProvider>();
    final assignments = projectProvider.projects
        .where((p) => p.isAssignedTo(worker.id))
        .length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete worker'),
        content: Text(
          assignments == 0
              ? 'Remove "${worker.name}" from the field team? '
                    'This cannot be undone.'
              : 'Remove "${worker.name}" from the field team? They are assigned '
                    'to $assignments project${assignments == 1 ? '' : 's'} and '
                    'will be removed from '
                    '${assignments == 1 ? 'it' : 'them'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.onHold),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<WorkerProvider>().deleteWorker(worker.id);
    if (!mounted) return;

    projectProvider.removeWorkerFromProjects(worker.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Worker deleted')));
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'No workers yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isManager
                ? 'Add a worker to start building the field team.'
                : 'There are no team members to display.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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

  Color _typeColor(WorkerType type) => switch (type) {
    WorkerType.field => AppColors.primary,
    WorkerType.cad => AppColors.accepted,
    WorkerType.manager => AppColors.pending,
    WorkerType.owner => AppColors.primaryDark,
  };

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
