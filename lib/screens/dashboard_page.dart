import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/offering.dart';
import '../models/project.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/offering_card.dart';
import '../widgets/offering_map_split.dart';
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

  List<Offering> _visibleOfferings(List<Offering> all) {
    if (!_isManager) {
      final userId = context.read<AuthProvider>().user?.id;
      final provider = context.read<ProjectProvider>();
      return all.where((o) {
        final projectId = o.projectId;
        if (projectId == null || userId == null) return false;
        return provider.projectById(projectId)?.isAssignedTo(userId) ?? false;
      }).toList();
    }
    return all;
  }

  void _openOffering(Offering offering) =>
      context.push(AppRouter.offeringDetail(offering.id));

  void _editOffering(Offering offering) =>
      context.push(AppRouter.offeringEdit(offering.id));

  void _openProject(Offering offering) {
    if (offering.isRentalService) {
      context.push(AppRouter.offeringDetail(offering.id, tab: 3));
      return;
    }
    final projectId = offering.projectId;
    if (projectId != null) {
      context.push(AppRouter.projectDetail(projectId));
      return;
    }
    if (offering.status == OfferingStatus.accepted) {
      context.push(AppRouter.newProject(offering.id));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Accept the offering to create its project'),
      ),
    );
  }

  Future<void> _deleteOffering(Offering offering) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete offering'),
        content: Text('Remove "${offering.name}"? This cannot be undone.'),
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

    await context.read<ProjectProvider>().deleteOffering(offering.id);
    if (mounted) {
      if (_selectedId == offering.id) setState(() => _selectedId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offering deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final offerings = _visibleOfferings(provider.offerings);

    return OfferingMapSplit(
      offerings: offerings,
      selectedId: _selectedId,
      onSelect: (offering) => setState(() => _selectedId = offering.id),
      leftPanel: _isManager
          ? _managerPanel(offerings)
          : _workerPanel(offerings),
    );
  }

  Widget _managerPanel(List<Offering> offerings) {
    final provider = context.read<ProjectProvider>();
    final all = provider.offerings;
    final accepted = all
        .where((o) => o.status == OfferingStatus.accepted)
        .length;
    final pending = all
        .where(
          (o) =>
              o.status == OfferingStatus.draft ||
              o.status == OfferingStatus.sent,
        )
        .length;
    final activeProjects = provider.projects
        .where(
          (p) =>
              p.status == ProjectStatus.planning ||
              p.status == ProjectStatus.inProgress,
        )
        .length;

    return _panel(
      stats: [
        _stat(
          '${all.length}',
          'Total Offerings',
          Icons.folder_outlined,
          AppColors.primary,
        ),
        _stat(
          '$accepted',
          'Accepted',
          Icons.thumb_up_alt_outlined,
          AppColors.accepted,
        ),
        _stat('$pending', 'Pending', Icons.hourglass_empty, AppColors.pending),
        _stat(
          '$activeProjects',
          'Active Projects',
          Icons.construction,
          AppColors.inProgress,
        ),
      ],
      title: 'Offerings',
      offerings: offerings,
      emptyTitle: 'No offerings found',
      emptySubtitle: 'Add a new offering to get started.',
      emptyIcon: Icons.folder_off_outlined,
      itemBuilder: (offering) => OfferingCard(
        offering: offering,
        selected: offering.id == _selectedId,
        onTap: () => setState(() => _selectedId = offering.id),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                child: Row(
                  children: [
                    Icon(
                      offering.projectId != null
                          ? Icons.folder_open_outlined
                          : Icons.rocket_launch_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      offering.projectId != null
                          ? 'Open Project'
                          : 'Create Project',
                    ),
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
        ),
      ),
    );
  }

  Widget _workerPanel(List<Offering> assigned) {
    final provider = context.read<ProjectProvider>();
    final myProjects = provider.projects
        .where((p) => assigned.any((o) => o.projectId == p.id))
        .toList();
    final accepted = assigned
        .where((o) => o.status == OfferingStatus.accepted)
        .length;
    final active = myProjects
        .where(
          (p) =>
              p.status == ProjectStatus.planning ||
              p.status == ProjectStatus.inProgress,
        )
        .length;
    final paid = assigned.where((o) => o.paidStatus == PaidStatus.paid).length;

    return _panel(
      stats: [
        _stat(
          '${assigned.length}',
          'Assigned to me',
          Icons.assignment_outlined,
          AppColors.primary,
        ),
        _stat(
          '$accepted',
          'Accepted',
          Icons.thumb_up_alt_outlined,
          AppColors.accepted,
        ),
        _stat(
          '$active',
          'Active Projects',
          Icons.construction,
          AppColors.inProgress,
        ),
        _stat('$paid', 'Paid', Icons.verified_outlined, AppColors.paid),
      ],
      title: 'My Tasks',
      offerings: assigned,
      emptyTitle: 'No offerings assigned',
      emptySubtitle: 'New assignments will appear here.',
      emptyIcon: Icons.assignment_outlined,
      itemBuilder: (offering) => OfferingCard(
        offering: offering,
        selected: offering.id == _selectedId,
        onTap: () => setState(() => _selectedId = offering.id),
        trailing: IconButton(
          icon: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
          onPressed: () => _openOffering(offering),
        ),
      ),
    );
  }

  Widget _panel({
    required List<Widget> stats,
    required String title,
    required List<Offering> offerings,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
    required Widget Function(Offering) itemBuilder,
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
            if (offerings.isEmpty)
              _emptyState(emptyIcon, emptyTitle, emptySubtitle)
            else
              ...offerings.map(
                (offering) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: itemBuilder(offering),
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
          Icon(
            icon,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
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
