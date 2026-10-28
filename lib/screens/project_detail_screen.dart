import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/offering.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../utils/status_extensions.dart';
import '../widgets/status_chip.dart';

/// Project detail page styled as a compact, responsive management dashboard.
///
/// The project data is real; the contact people and notes are demo content
/// until those modules are backed by the API.
class ProjectDetailScreen extends StatefulWidget {
  final String id;

  const ProjectDetailScreen({super.key, required this.id});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  static const double _contentMaxWidth = 1240;

  final GlobalKey _mapKey = GlobalKey();
  final MapController _mapController = MapController();

  late List<_ProjectNote> _notes;

  Project? _lookup() => context.watch<ProjectProvider>().projectById(widget.id);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectProvider>().ensureProjectsLoaded();
    });
    _notes = [
      _ProjectNote(
        title: 'Site access confirmed',
        category: 'General',
        program: 'Survey',
        updated: DateTime(2026, 6, 24, 18, 48),
        body:
            'Access to the site has been confirmed with the client. The field '
            'team can start on schedule.',
      ),
      _ProjectNote(
        title: 'Boundary check pending',
        category: 'Client',
        program: 'Mapping',
        updated: DateTime(2026, 6, 24, 16, 20),
        body:
            'Waiting for the client to approve the additional boundary points '
            'before the map is finalised.',
      ),
      _ProjectNote(
        title: 'Equipment checklist verified',
        category: 'Equipment',
        program: 'Operations',
        updated: DateTime(2026, 6, 23, 9, 5),
        body:
            'GPS receivers, total station, and safety equipment have been '
            'checked and are ready for deployment.',
      ),
    ];
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboard);
    }
  }

  Future<void> _updateStatus(ProjectStatus status) async {
    final project = _lookup();
    if (project == null || project.status == status) return;

    try {
      await context.read<ProjectProvider>().updateProject(
        project.copyWith(status: status),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${status.label}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showOnMap() async {
    final target = _mapKey.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.15,
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

    final offering = context.watch<ProjectProvider>().offeringById(
      project.offeringId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Project Details'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (offering != null)
            IconButton(
              tooltip: 'Open source offering',
              onPressed: () =>
                  context.push(AppRouter.offeringDetail(offering.id)),
              icon: const Icon(Icons.description_outlined),
            ),
          IconButton(
            tooltip: 'Edit project',
            onPressed: () => context.push(AppRouter.projectEdit(project.id)),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<ProjectStatus>(
            tooltip: 'Update status',
            icon: const Icon(Icons.flag_outlined),
            onSelected: _updateStatus,
            itemBuilder: (context) => [
              for (final status in ProjectStatus.values)
                PopupMenuItem<ProjectStatus>(
                  value: status,
                  child: Row(
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: 18,
                        color: status.color,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(status.label)),
                      if (project.status == status)
                        const Icon(Icons.check, size: 17),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1024;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                  child: wide
                      ? _wideLayout(project, offering)
                      : _narrowLayout(project, offering),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _wideLayout(Project project, Offering? offering) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: SizedBox(
                height: 340,
                child: _overviewCard(project, offering),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 340,
                child: _mapCard(project),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 260,
                child: _organizationContactCard(project),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 260,
                child: _accountExecutiveCard(),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 260,
                child: _statusCard(project, offering),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _teamCard(project)),
            const SizedBox(width: 24),
            Expanded(flex: 7, child: _notesCard()),
          ],
        ),
      ],
    );
  }

  Widget _narrowLayout(Project project, Offering? offering) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overviewCard(project, offering),
        const SizedBox(height: 20),
        SizedBox(height: 260, child: _mapCard(project)),
        const SizedBox(height: 20),
        _organizationContactCard(project),
        const SizedBox(height: 20),
        _accountExecutiveCard(),
        const SizedBox(height: 20),
        SizedBox(height: 260, child: _statusCard(project, offering)),
        const SizedBox(height: 20),
        _teamCard(project),
        const SizedBox(height: 20),
        _notesCard(),
      ],
    );
  }

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

  Widget _mapCard(Project project) {
    final hasLocation =
        project.latitude != null && project.longitude != null;
    final point = hasLocation
        ? LatLng(project.latitude!, project.longitude!)
        : null;

    return _card(
      key: _mapKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Main Site')),
              _locationBadge(hasLocation),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: point == null
                  ? const _MapPlaceholder()
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: point,
                              initialZoom: 14,
                              minZoom: 3,
                              maxZoom: 18,
                              interactionOptions: const InteractionOptions(
                                flags:
                                    InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.geoterra_monitoring',
                                maxZoom: 19,
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: point,
                                    width: 54,
                                    height: 54,
                                    child: Icon(
                                      Icons.location_on,
                                      size: 46,
                                      color: AppColors.onHold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.22,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Column(
                            children: [
                              _mapControlButton(
                                icon: Icons.add,
                                tooltip: 'Zoom in',
                                onTap: () => _zoomMap(1),
                              ),
                              const SizedBox(height: 6),
                              _mapControlButton(
                                icon: Icons.remove,
                                tooltip: 'Zoom out',
                                onTap: () => _zoomMap(-1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _zoomMap(double delta) {
    final camera = _mapController.camera;
    _mapController.move(
      camera.center,
      (camera.zoom + delta).clamp(3.0, 18.0),
    );
  }

  Widget _mapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 16, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _locationBadge(bool hasLocation) {
    final color = hasLocation ? AppColors.completed : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            hasLocation ? 'Verified Location' : 'No Coordinates',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _organizationContactCard(Project project) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _Eyebrow('Organization Contact'),
          Row(
            children: [
              _initialsAvatar(
                'Michael Petersen',
                AppColors.inProgress,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Michael Petersen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Primary Contact',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (project.owner.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        project.owner,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  onTap: () => _showPlaceholder('Calling Michael Petersen…'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactButton(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  onTap: () =>
                      _showPlaceholder('Emailing Michael Petersen…'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountExecutiveCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _Eyebrow('Account Executive'),
          Row(
            children: [
              _initialsAvatar('Cynthia Lopez', AppColors.primary, size: 56),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cynthia Lopez',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Account Lead',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'GeoTerra Monitoring',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  onTap: () => _showPlaceholder('Calling Cynthia Lopez…'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactButton(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  onTap: () => _showPlaceholder('Emailing Cynthia Lopez…'),
                ),
              ),
            ],
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

  Widget _teamCard(Project project) {
    final names = project.assignedWorkerNames;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Project Team')),
              Text(
                names.isEmpty
                    ? 'No team assigned'
                    : '${names.length} Active ${names.length == 1 ? 'Member' : 'Members'}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          if (names.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Assign workers to this project to see them here.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            for (var i = 0; i < names.length; i++)
              _teamRow(names[i], i, isLast: i == names.length - 1),
        ],
      ),
    );
  }

  Widget _teamRow(String name, int index, {required bool isLast}) {
    const roles = [
      'Field Surveyor',
      'GIS Specialist',
      'CAD Specialist',
      'Survey Technician',
    ];
    const colors = [
      AppColors.primary,
      AppColors.inProgress,
      AppColors.accepted,
      AppColors.pending,
    ];
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _initialsAvatar(name, color, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roles[index % roles.length],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _iconAction(
            icon: Icons.mail_outline,
            tooltip: 'Message $name',
            onTap: () => _showPlaceholder('Messaging $name…'),
          ),
        ],
      ),
    );
  }

  Widget _notesCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Notes')),
              TextButton.icon(
                onPressed: _addNote,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.inProgress,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Add Note',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          for (var i = 0; i < _notes.length; i++)
            _noteItem(_notes[i], isLast: i == _notes.length - 1),
        ],
      ),
    );
  }

  Widget _noteItem(_ProjectNote note, {required bool isLast}) {
    return Container(
      padding: EdgeInsets.only(top: 14, bottom: isLast ? 2 : 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
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
                      note.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Program: ${note.program}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _noteTimestamp(note.updated),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            note.body,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNote() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    titleController.dispose();
    bodyController.dispose();

    if (added != true || !mounted) return;
    if (title.isEmpty && body.isEmpty) return;

    setState(() {
      _notes.insert(
        0,
        _ProjectNote(
          title: title.isEmpty ? 'Untitled note' : title,
          category: 'General',
          program: 'Project',
          updated: DateTime.now(),
          body: body,
        ),
      );
    });
  }

  Widget _initialsAvatar(String name, Color color, {required double size}) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.inProgress.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.inProgress),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inProgress,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.inProgress.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 17, color: AppColors.inProgress),
          ),
        ),
      ),
    );
  }

  Widget _navButton() {
    return Tooltip(
      message: 'Show on map',
      child: Material(
        color: AppColors.inProgress.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: _showOnMap,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.navigation_outlined,
              size: 17,
              color: AppColors.inProgress,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBar({required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 11),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _miniPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _card({
    Key? key,
    required Widget child,
    Color? stripe,
  }) {
    final content = stripe == null
        ? Padding(
            padding: const EdgeInsets.all(22),
            child: child,
          )
        : Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: ColoredBox(color: stripe),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 22, 22),
                child: child,
              ),
            ],
          );

    return Container(
      key: key,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.018),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: content,
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

  String _noteTimestamp(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour24 = value.hour;
    final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    return 'Updated ${weekdays[value.weekday - 1]} ${value.month}/${value.day} '
        '$hour:$minute $suffix';
  }

  IconData _statusIcon(ProjectStatus status) => switch (status) {
    ProjectStatus.planning => Icons.event_note_outlined,
    ProjectStatus.inProgress => Icons.autorenew,
    ProjectStatus.onHold => Icons.pause_circle_outline,
    ProjectStatus.completed => Icons.check_circle_outline,
    ProjectStatus.cancelled => Icons.cancel_outlined,
  };
}

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _MapGridPainter()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off_outlined,
                  size: 34,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No coordinates recorded',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Add a location to this project to see it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
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
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.55)
      ..strokeWidth = 1;

    const step = 38.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) => false;
}

class _ProjectNote {
  final String title;
  final String category;
  final String program;
  final DateTime updated;
  final String body;

  const _ProjectNote({
    required this.title,
    required this.category,
    required this.program,
    required this.updated,
    required this.body,
  });
}
