import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../providers/project_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../utils/status_extensions.dart';
import '../widgets/status_chip.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String id;

  const ProjectDetailScreen({super.key, required this.id});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;

  Project? _lookup() => context.watch<ProjectProvider>().projectById(widget.id);

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboard);
    }
  }

  Future<void> _updateStatus(ProjectStatus status) async {
    final updated = _copyWith(_project, status: status);
    try {
      await context.read<ProjectProvider>().updateProject(updated);
      if (mounted) {
        setState(() => _project = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${status.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Project _copyWith(Project project, {ProjectStatus? status}) {
    return Project(
      id: project.id,
      number: project.number,
      name: project.name,
      offeringId: project.offeringId,
      owner: project.owner,
      address: project.address,
      latitude: project.latitude,
      longitude: project.longitude,
      status: status ?? project.status,
      startDate: project.startDate,
      endDate: project.endDate,
      budgetAmount: project.budgetAmount,
      progressPercentage: project.progressPercentage,
      tools: project.tools,
      assignedWorkerIds: project.assignedWorkerIds,
      assignedWorkerNames: project.assignedWorkerNames,
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _lookup();
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Project not found.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    _project = project;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _hero()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _ProjectTabBarDelegate(
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Location'),
                    Tab(text: 'Progress'),
                    Tab(text: 'Actions'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _detailsTab(),
              _locationTab(),
              _progressTab(),
              _actionsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.folder_open_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _project.number.isEmpty
                              ? 'PROJECT'
                              : 'PROJECT ${_project.number}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _project.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    StatusChip(
                      label: _project.status.label,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _date(DateTime? value) => value == null
      ? '—'
      : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String get _budget => formatRupiah(_project.budgetAmount);

  Widget _detailsTab() {
    final provider = context.read<ProjectProvider>();
    final offering = provider.offeringById(_project.offeringId);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Project Information',
          children: [
            _infoRow(Icons.tag, 'Project No', _project.number),
            _infoRow(Icons.apartment, 'Client', _project.owner),
            _infoRow(Icons.place_outlined, 'Address', _project.address),
            if (_project.assignedWorkerNames.isNotEmpty)
              _infoRow(
                Icons.groups_outlined,
                'Field team (${_project.assignedWorkerNames.length})',
                _project.assignedWorkerNames.join(', '),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Source Offering',
          children: offering == null
              ? [
                  Text(
                    _project.offeringId,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ]
              : [
                  _infoRow(
                    Icons.description_outlined,
                    'Offering',
                    '${offering.number} · ${offering.name}',
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push(AppRouter.offeringDetail(offering.id)),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open Offering'),
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Schedule & Budget',
          children: [
            _infoRow(
              Icons.event_outlined,
              'Start Date',
              _date(_project.startDate),
            ),
            _infoRow(
              Icons.event_available_outlined,
              'End Date',
              _date(_project.endDate),
            ),
            _infoRow(Icons.payments_outlined, 'Budget', _budget),
          ],
        ),
      ],
    );
  }

  Widget _locationTab() {
    final hasLocation = _project.latitude != null && _project.longitude != null;
    if (!hasLocation) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No coordinates recorded for this project.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final point = LatLng(_project.latitude!, _project.longitude!);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Coordinates',
          children: [
            _infoRow(
              Icons.my_location,
              'Latitude',
              _project.latitude!.toStringAsFixed(5),
            ),
            _infoRow(
              Icons.explore_outlined,
              'Longitude',
              _project.longitude!.toStringAsFixed(5),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(initialCenter: point, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.geoterra_monitoring',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 44,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '${_project.progressPercentage}%',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Overall progress',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _project.progressPercentage / 100,
                    minHeight: 10,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_project.tools.isNotEmpty)
          _sectionCard(
            title: 'Tools',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tool in _project.tools)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        tool,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _actionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Update Status',
          children: [
            _statusOption(
              ProjectStatus.planning,
              Icons.event_note_outlined,
              'Planning',
            ),
            _statusOption(
              ProjectStatus.inProgress,
              Icons.autorenew,
              'Mark as In Progress',
            ),
            _statusOption(
              ProjectStatus.onHold,
              Icons.pause_circle_outline,
              'Put On Hold',
            ),
            _statusOption(
              ProjectStatus.completed,
              Icons.check_circle_outline,
              'Mark as Completed',
            ),
            _statusOption(
              ProjectStatus.cancelled,
              Icons.cancel_outlined,
              'Cancel Project',
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusOption(ProjectStatus status, IconData icon, String label) {
    final isCurrent = _project.status == status;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isCurrent ? null : () => _updateStatus(status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent ? status.color : AppColors.border,
              width: isCurrent ? 1.5 : 1,
            ),
            color: isCurrent
                ? status.color.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: status.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isCurrent)
                Text(
                  'Current',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status.color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _ProjectTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 0.5;

  @override
  double get maxExtent => tabBar.preferredSize.height + 0.5;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.surface,
      child: Column(children: [tabBar, const Divider(height: 1)]),
    );
  }

  @override
  bool shouldRebuild(_ProjectTabBarDelegate oldDelegate) => false;
}
