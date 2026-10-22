import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/offering.dart';
import '../models/project.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../router/app_router.dart';
import '../services/schema_mock_data.dart';
import '../theme/app_theme.dart';
import '../utils/csv_download.dart';
import '../utils/status_extensions.dart';
import '../widgets/offering_sidebar.dart';

enum _Col { number, name, serviceType, owner, address, status, payment }

extension _ColX on _Col {
  String get label => switch (this) {
    _Col.number => 'No',
    _Col.name => 'Name',
    _Col.serviceType => 'Service Type',
    _Col.owner => 'Client',
    _Col.address => 'Address',
    _Col.status => 'Status',
    _Col.payment => 'Payment',
  };

  double get width => switch (this) {
    _Col.number => 110,
    _Col.name => 220,
    _Col.serviceType => 200,
    _Col.owner => 170,
    _Col.address => 250,
    _Col.status => 120,
    _Col.payment => 120,
  };

  int get flex => width.round();
}

class OfferingsPage extends StatefulWidget {
  const OfferingsPage({super.key});

  @override
  State<OfferingsPage> createState() => _OfferingsPageState();
}

class _OfferingsPageState extends State<OfferingsPage> {
  static const double _wActions = 56;

  static const List<SidebarMenuItem> _menuItems = [
    SidebarMenuItem(Icons.inventory_2_outlined, 'All Offerings'),
    SidebarMenuItem(Icons.folder_outlined, 'Projects'),
    SidebarMenuItem(Icons.people_outline, 'Clients'),
  ];

  bool get _isOfferingsView => _menuIndex == 0;

  String get _searchHint => switch (_menuIndex) {
    1 => 'Search projects...',
    2 => 'Search clients...',
    _ => 'Search offerings...',
  };

  final ScrollController _horizontal = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Set<_Col> _visible = {..._Col.values};

  bool _sidebarCollapsed = false;
  bool _searching = false;
  String _query = '';
  int _menuIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().fetchProjects();
    });
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isManager => context.read<AuthProvider>().userRole == 'Manager';

  List<_Col> get _columns => [
    for (final c in _Col.values)
      if (_visible.contains(c)) c,
  ];

  List<Offering> _filtered(List<Offering> all) {
    var list = all;
    if (!_isManager) {
      final userId = context.read<AuthProvider>().user?.id;
      final provider = context.read<ProjectProvider>();
      list = list.where((o) {
        final projectId = o.projectId;
        if (projectId == null || userId == null) return false;
        return provider.projectById(projectId)?.isAssignedTo(userId) ?? false;
      }).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (o) =>
                o.name.toLowerCase().contains(q) ||
                o.number.toLowerCase().contains(q) ||
                o.serviceType.toLowerCase().contains(q) ||
                o.owner.toLowerCase().contains(q) ||
                o.address.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  List<Project> _visibleProjects(List<Project> all) {
    var list = all;
    if (!_isManager) {
      final userId = context.read<AuthProvider>().user?.id;
      list = userId == null
          ? const <Project>[]
          : all.where((p) => p.isAssignedTo(userId)).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.number.toLowerCase().contains(q) ||
                p.owner.toLowerCase().contains(q) ||
                p.address.toLowerCase().contains(q) ||
                p.assignedWorkerNames.any(
                  (name) => name.toLowerCase().contains(q),
                ),
          )
          .toList();
    }
    return list;
  }

  void _openOffering(Offering offering) =>
      context.push(AppRouter.offeringDetail(offering.id));

  void _addOffering() => context.push(AppRouter.newOffering);

  void _editOffering(Offering offering) =>
      context.push(AppRouter.offeringEdit(offering.id));

  void _openProject(Offering offering) {
    if (offering.isRentalService) {
      context.push(AppRouter.offeringDetail(offering.id, tab: 3));
      return;
    }
    final projectId = offering.projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accept the offering to create its project'),
        ),
      );
      return;
    }
    context.push(AppRouter.projectDetail(projectId));
  }

  void _importProjects() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Import is coming soon')));
  }

  Future<void> _exportProjects() async {
    final offerings = _filtered(context.read<ProjectProvider>().offerings);
    final columns = _columns;
    final buffer = StringBuffer();
    buffer.writeln([for (final c in columns) _csv(c.label)].join(','));
    for (final o in offerings) {
      buffer.writeln([for (final c in columns) _csv(_valueOf(o, c))].join(','));
    }
    final csv = buffer.toString();

    final downloaded = await downloadCsv('offerings.csv', csv);
    if (!downloaded) {
      await Clipboard.setData(ClipboardData(text: csv));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          downloaded
              ? 'Exported ${offerings.length} rows to offerings.csv'
              : 'Exported ${offerings.length} rows (copied to clipboard)',
        ),
      ),
    );
  }

  String _csv(String value) => '"${value.replaceAll('"', '""')}"';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offering deleted')));
    }
  }

  Widget _columnsDropdown() {
    return PopupMenuButton<void>(
      tooltip: 'Show / hide columns',
      offset: const Offset(0, 46),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, setMenuState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Show columns',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                for (final c in _Col.values)
                  CheckboxListTile(
                    dense: true,
                    value: _visible.contains(c),
                    title: Text(c.label),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) {
                      setMenuState(() {});
                      setState(() {
                        if (v == true) {
                          _visible.add(c);
                        } else if (_visible.length > 1) {
                          _visible.remove(c);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.view_column_outlined,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final offerings = _filtered(provider.offerings);
    final projects = _visibleProjects(provider.projects);

    return Container(
      color: AppColors.background,
      child: Row(
        children: [
          OfferingSidebar(
            collapsed: _sidebarCollapsed,
            onToggle: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            items: _menuItems,
            selectedIndex: _menuIndex,
            onSelect: (i) => setState(() => _menuIndex = i),
          ),
          Expanded(
            child: Column(
              children: [
                _toolbar(),
                Expanded(
                  child: _menuIndex == 1
                      ? _projectsView(projects)
                      : _menuIndex == 2
                      ? _clientsView()
                      : offerings.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<ProjectProvider>().fetchProjects(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _table(offerings),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _table(List<Offering> offerings) {
    final columns = _columns;
    final fixed =
        columns.fold<double>(0, (sum, c) => sum + c.width) + _wActions;

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
                    for (var i = 0; i < offerings.length; i++)
                      _tableRow(
                        offerings[i],
                        i,
                        columns,
                        fill,
                        i == offerings.length - 1,
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

  Widget _headerRow(List<_Col> columns, bool fill) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in columns)
            _gridCell(
              width: c.width,
              flex: fill ? c.flex : null,
              header: true,
              end: true,
              child: _headerText(c.label),
            ),
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
    Offering offering,
    int index,
    List<_Col> columns,
    bool fill,
    bool isLast,
  ) {
    final stripe = index.isEven
        ? AppColors.surface
        : AppColors.background.withValues(alpha: 0.5);
    return Material(
      color: stripe,
      child: InkWell(
        onTap: () => _openOffering(offering),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final c in columns)
                _gridCell(
                  width: c.width,
                  flex: fill ? c.flex : null,
                  bottom: !isLast,
                  end: true,
                  child: _cellFor(offering, c),
                ),
              _gridCell(
                width: _wActions,
                last: true,
                center: true,
                bottom: !isLast,
                child: _rowAction(offering),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cellFor(Offering offering, _Col c) => switch (c) {
    _Col.number => _plainText(offering.number.isEmpty ? '—' : offering.number),
    _Col.name => Text(
      offering.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
    _Col.serviceType => _plainText(offering.serviceType),
    _Col.owner => _plainText(offering.owner),
    _Col.address => _plainText(offering.address),
    _Col.status => _pill(offering.status.label, offering.status.color),
    _Col.payment => _pill(offering.paidStatus.label, offering.paidStatus.color),
  };

  String _valueOf(Offering offering, _Col c) => switch (c) {
    _Col.number => offering.number,
    _Col.name => offering.name,
    _Col.serviceType => offering.serviceType,
    _Col.owner => offering.owner,
    _Col.address => offering.address,
    _Col.status => offering.status.label,
    _Col.payment => offering.paidStatus.label,
  };

  Widget _rowAction(Offering offering) {
    if (_isManager) return _menu(offering);
    return const Icon(
      Icons.chevron_right,
      size: 20,
      color: AppColors.textSecondary,
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

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          if (_isOfferingsView) ...[
            _columnsDropdown(),
            const SizedBox(width: 8),
          ],
          if (_searching)
            _searchField()
          else
            _iconButton(
              Icons.search,
              'Search',
              () => setState(() => _searching = true),
            ),
          const Spacer(),
          if (_isOfferingsView && _isManager) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _addOffering,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _importProjects,
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: const Text('Import'),
            ),
            const SizedBox(width: 8),
          ],
          if (_isOfferingsView)
            OutlinedButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _exportProjects,
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export'),
            ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _searchField() {
    return SizedBox(
      width: 220,
      height: 40,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: _searchHint,
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Close',
            onPressed: () => setState(() {
              _searching = false;
              _query = '';
              _searchController.clear();
            }),
          ),
        ),
      ),
    );
  }

  Widget _menu(Offering offering) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            enabled: offering.projectId != null,
            child: const Row(
              children: [
                Icon(Icons.folder_open_outlined, size: 18),
                SizedBox(width: 10),
                Text('View Project'),
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

  Widget _projectsView(List<Project> projects) {
    if (projects.isEmpty) return _projectsEmptyState();
    final provider = context.read<ProjectProvider>();

    return RefreshIndicator(
      onRefresh: () => context.read<ProjectProvider>().fetchProjects(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: projects.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final project = projects[index];
          final offering = provider.offeringById(project.offeringId);
          final team = project.assignedWorkerNames;

          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push(AppRouter.projectDetail(project.id)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _pill(project.status.label, project.status.color),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _projectMeta(
                      Icons.tag,
                      project.number.isEmpty ? '—' : project.number,
                    ),
                    const SizedBox(height: 4),
                    _projectMeta(Icons.apartment_outlined, project.owner),
                    const SizedBox(height: 4),
                    _projectMeta(
                      Icons.description_outlined,
                      offering == null
                          ? 'No linked offering'
                          : '${offering.number} · ${offering.name}',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${team.length} worker${team.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (team.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              team.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
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

  Widget _projectMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _projectsEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'No projects yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Accept an offering and create its project to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientsView() {
    final clients = [
      for (final row in SchemaMockData.rows('clients'))
        _ClientRecord.fromRow(row),
    ];
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? clients
        : clients.where((client) => client.matches(q)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _clientsHeader(clients, filtered),
          const SizedBox(height: 16),
          _clientSummary(clients),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _clientsEmptyState()
          else
            _clientResults(filtered),
        ],
      ),
    );
  }

  Widget _clientResults(List<_ClientRecord> clients) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          return _clientTable(clients);
        }

        const gap = 12.0;
        final columns = constraints.maxWidth >= 600 ? 2 : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final client in clients) _clientCard(client, width)],
        );
      },
    );
  }

  Widget _clientTable(List<_ClientRecord> clients) {
    const widths = <double>[220, 110, 150, 210, 140, 190, 95];
    const headers = [
      'Client',
      'Type',
      'Contact',
      'Email',
      'Phone',
      'Location',
      'Updated',
    ];
    final total = widths.fold<double>(0, (sum, width) => sum + width);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fill = total <= constraints.maxWidth;
          final scale = fill ? constraints.maxWidth / total : 1.0;
          final scaled = [for (final width in widths) width * scale];

          return Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: fill ? constraints.maxWidth : total,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < headers.length; i++)
                            _gridCell(
                              width: scaled[i],
                              header: true,
                              last: i == headers.length - 1,
                              child: _headerText(headers[i]),
                            ),
                        ],
                      ),
                    ),
                    for (var i = 0; i < clients.length; i++)
                      _clientTableRow(
                        clients[i],
                        scaled,
                        i,
                        i == clients.length - 1,
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

  Widget _clientTableRow(
    _ClientRecord client,
    List<double> widths,
    int index,
    bool isLast,
  ) {
    final stripe = index.isEven
        ? AppColors.surface
        : AppColors.background.withValues(alpha: 0.5);

    return Material(
      color: stripe,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _gridCell(
              width: widths[0],
              bottom: !isLast,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: client.typeColor.withValues(alpha: 0.12),
                    child: Text(
                      client.initials,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: client.typeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          client.name,
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
                          client.number,
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
                ],
              ),
            ),
            _gridCell(
              width: widths[1],
              bottom: !isLast,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _pill(client.typeLabel, client.typeColor),
              ),
            ),
            _gridCell(
              width: widths[2],
              bottom: !isLast,
              child: _plainText(client.contact.isEmpty ? '—' : client.contact),
            ),
            _gridCell(
              width: widths[3],
              bottom: !isLast,
              child: _plainText(client.email.isEmpty ? '—' : client.email),
            ),
            _gridCell(
              width: widths[4],
              bottom: !isLast,
              child: _plainText(client.phone.isEmpty ? '—' : client.phone),
            ),
            _gridCell(
              width: widths[5],
              bottom: !isLast,
              child: _plainText(client.fullAddress),
            ),
            _gridCell(
              width: widths[6],
              last: true,
              bottom: !isLast,
              child: _plainText(client.updatedLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientsHeader(
    List<_ClientRecord> clients,
    List<_ClientRecord> filtered,
  ) {
    final q = _query.trim();
    final cities = {
      for (final client in clients)
        if (client.city.isNotEmpty) client.city,
    }.length;

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
          child: const Icon(Icons.people_outline, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Clients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                q.isEmpty
                    ? '${clients.length} clients across $cities ${cities == 1 ? 'city' : 'cities'}'
                    : '${filtered.length} of ${clients.length} clients match "$q"',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (q.isNotEmpty) _pill('${filtered.length} found', AppColors.primary),
      ],
    );
  }

  Widget _clientSummary(List<_ClientRecord> clients) {
    final business = clients.where((client) => client.isBusiness).length;
    final government = clients.where((client) => client.isGovernment).length;
    final cities = {
      for (final client in clients)
        if (client.city.isNotEmpty) client.city,
    }.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _clientStat(
              width: width,
              label: 'Total clients',
              value: '${clients.length}',
              icon: Icons.groups_outlined,
              color: AppColors.primary,
            ),
            _clientStat(
              width: width,
              label: 'Business',
              value: '$business',
              icon: Icons.business_outlined,
              color: AppColors.inProgress,
            ),
            _clientStat(
              width: width,
              label: 'Government',
              value: '$government',
              icon: Icons.account_balance_outlined,
              color: AppColors.pending,
            ),
            _clientStat(
              width: width,
              label: 'Cities',
              value: '$cities',
              icon: Icons.location_city_outlined,
              color: AppColors.accepted,
            ),
          ],
        );
      },
    );
  }

  Widget _clientStat({
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientCard(_ClientRecord client, double width) {
    final color = client.typeColor;
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Text(
                      client.initials,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${client.number} · ${client.city.isEmpty ? '—' : client.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _pill(client.typeLabel, color),
                ],
              ),
              const SizedBox(height: 14),
              _clientLine(
                Icons.person_outline,
                client.contact.isEmpty ? 'No contact person' : client.contact,
              ),
              _clientLine(
                Icons.email_outlined,
                client.email.isEmpty ? 'No email' : client.email,
              ),
              _clientLine(
                Icons.phone_outlined,
                client.phone.isEmpty ? 'No phone' : client.phone,
              ),
              _clientLine(Icons.place_outlined, client.fullAddress),
              if (client.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    client.notes,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.update,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Updated ${client.updatedLabel}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _clientLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientsEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 44,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'No clients match',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try a different search.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'No offerings match',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try a different filter.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientRecord {
  final String number;
  final String type;
  final String name;
  final String contact;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String notes;
  final String updatedAt;

  const _ClientRecord({
    required this.number,
    required this.type,
    required this.name,
    required this.contact,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.notes,
    required this.updatedAt,
  });

  factory _ClientRecord.fromRow(List<String> row) {
    String at(int index) => index < row.length ? row[index] : '';
    return _ClientRecord(
      number: at(1),
      type: at(2),
      name: at(3),
      contact: at(4),
      email: at(5),
      phone: at(6),
      address: at(7),
      city: at(8),
      notes: at(10),
      updatedAt: at(12),
    );
  }

  bool get isBusiness => type == 'company' || type == 'organization';

  bool get isGovernment => type == 'government';

  String get typeLabel => switch (type.toLowerCase()) {
    'company' => 'Company',
    'government' => 'Government',
    'organization' => 'Organization',
    'individual' => 'Individual',
    _ => type.isEmpty ? 'Other' : type[0].toUpperCase() + type.substring(1),
  };

  Color get typeColor => switch (type.toLowerCase()) {
    'company' => AppColors.primary,
    'government' => AppColors.inProgress,
    'organization' => AppColors.pending,
    'individual' => AppColors.accepted,
    _ => AppColors.textSecondary,
  };

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get fullAddress {
    final parts = [address, city].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'No address' : parts.join(', ');
  }

  String get updatedLabel {
    if (updatedAt.length >= 10) return updatedAt.substring(0, 10);
    return updatedAt.isEmpty ? '—' : updatedAt;
  }

  bool matches(String query) {
    return [
      number,
      typeLabel,
      name,
      contact,
      email,
      phone,
      address,
      city,
      notes,
    ].any((value) => value.toLowerCase().contains(query));
  }
}
