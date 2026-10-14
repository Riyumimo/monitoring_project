import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/project_card.dart';
import '../widgets/project_map_split.dart';
import '../widgets/stat_card.dart';
import '../router/app_router.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().fetchProjects();
    });
  }

  bool get _isManager => context.read<AuthProvider>().userRole == 'Manager';

  List<Project> _visibleProjects(List<Project> all) {
    if (!_isManager) {
      final userId = context.read<AuthProvider>().user?.id;
      return all.where((p) => p.assignedWorkerId == userId).toList();
    }
    return all;
  }

  void _openProject(Project project) =>
      context.push(AppRouter.projectDetail(project.id));

  void _editProject(Project project) =>
      context.push(AppRouter.projectEdit(project.id));

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete offering'),
        content: Text('Remove "${project.name}"? This cannot be undone.'),
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

    await context.read<ProjectProvider>().deleteProject(project.id);
    if (mounted) {
      if (_selectedId == project.id) setState(() => _selectedId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offering deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final projects = _visibleProjects(provider.projects);

    return ProjectMapSplit(
      projects: projects,
      selectedId: _selectedId,
      onSelect: (project) => setState(() => _selectedId = project.id),
      leftPanel: _isManager ? _managerPanel(projects) : _workerPanel(projects),
    );
  }

  Widget _managerPanel(List<Project> projects) {
    final all = context.read<ProjectProvider>().projects;
    final inProgress =
        all.where((p) => p.status == ProjectStatus.inProgress).length;
    final completed =
        all.where((p) => p.status == ProjectStatus.completed).length;
    final unpaid = all.where((p) => p.paidStatus != PaidStatus.paid).length;

    return _panel(
      stats: [
        _stat('${all.length}', 'Total Offerings', Icons.folder_outlined,
            AppColors.primary),
        _stat('$inProgress', 'In Progress', Icons.autorenew,
            AppColors.inProgress),
        _stat('$completed', 'Completed', Icons.check_circle_outline,
            AppColors.completed),
        _stat('$unpaid', 'Unpaid / Partial', Icons.payments_outlined,
            AppColors.pending),
      ],
      title: 'Offerings',
      projects: projects,
      emptyTitle: 'No offerings found',
      emptySubtitle: 'Add a new offering to get started.',
      emptyIcon: Icons.folder_off_outlined,
      itemBuilder: (project) => ProjectCard(
        project: project,
        selected: project.id == _selectedId,
        onTap: () => setState(() => _selectedId = project.id),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'details') {
              _openProject(project);
            } else if (value == 'edit') {
              _editProject(project);
            } else if (value == 'delete') {
              _deleteProject(project);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 18),
                  SizedBox(width: 10),
                  Text('Details'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
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
        ),
      ),
    );
  }

  Widget _workerPanel(List<Project> assigned) {
    final inProgress = assigned
        .where((p) => p.status == ProjectStatus.inProgress)
        .length;
    final completed =
        assigned.where((p) => p.status == ProjectStatus.completed).length;
    final paid =
        assigned.where((p) => p.paidStatus == PaidStatus.paid).length;

    return _panel(
      stats: [
        _stat('${assigned.length}', 'Assigned to me', Icons.assignment_outlined,
            AppColors.primary),
        _stat('$inProgress', 'In Progress', Icons.autorenew,
            AppColors.inProgress),
        _stat('$completed', 'Completed', Icons.check_circle_outline,
            AppColors.completed),
        _stat('$paid', 'Paid', Icons.verified_outlined, AppColors.paid),
      ],
      title: 'My Tasks',
      projects: assigned,
      emptyTitle: 'No offerings assigned',
      emptySubtitle: 'New assignments will appear here.',
      emptyIcon: Icons.assignment_outlined,
      itemBuilder: (project) => ProjectCard(
        project: project,
        selected: project.id == _selectedId,
        onTap: () => setState(() => _selectedId = project.id),
        trailing: IconButton(
          icon: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
          onPressed: () => _openProject(project),
        ),
      ),
    );
  }

  Widget _panel({
    required List<Widget> stats,
    required String title,
    required List<Project> projects,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
    required Widget Function(Project) itemBuilder,
  }) {
    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: () => context.read<ProjectProvider>().fetchProjects(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                Expanded(child: stats[0]),
                const SizedBox(width: 12),
                Expanded(child: stats[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: stats[2]),
                const SizedBox(width: 12),
                Expanded(child: stats[3]),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (projects.isEmpty)
              _emptyState(emptyIcon, emptyTitle, emptySubtitle)
            else
              ...projects.map(
                (project) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: itemBuilder(project),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon, Color color) {
    return StatCard(value: value, label: label, icon: icon, color: color);
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon,
              size: 48, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
