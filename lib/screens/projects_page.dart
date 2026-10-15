import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../utils/csv_download.dart';
import '../utils/status_extensions.dart';
import '../widgets/offering_sidebar.dart';

enum _Col { name, owner, address, status, payment }

extension _ColX on _Col {
  String get label => switch (this) {
        _Col.name => 'Name',
        _Col.owner => 'Owner',
        _Col.address => 'Address',
        _Col.status => 'Status',
        _Col.payment => 'Payment',
      };

  double get width => switch (this) {
        _Col.name => 240,
        _Col.owner => 170,
        _Col.address => 260,
        _Col.status => 130,
        _Col.payment => 120,
      };

  int get flex => width.round();
}

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  static const double _wActions = 56;

  static const List<SidebarMenuItem> _menuItems = [
    SidebarMenuItem(Icons.inventory_2_outlined, 'All Offerings'),
    SidebarMenuItem(Icons.hourglass_empty, 'Pending'),
    SidebarMenuItem(Icons.construction, 'In Progress'),
    SidebarMenuItem(Icons.history, 'History Offering'),
  ];

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

  List<_Col> get _columns =>
      [for (final c in _Col.values) if (_visible.contains(c)) c];

  List<Project> _filtered(List<Project> all) {
    var list = all;
    if (!_isManager) {
      final userId = context.read<AuthProvider>().user?.id;
      list = list.where((p) => p.assignedWorkerId == userId).toList();
    }
    list = list.where(_matchesMenu).toList();
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.owner.toLowerCase().contains(q) ||
              p.address.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  bool _matchesMenu(Project p) {
    switch (_menuIndex) {
      case 1:
        return p.status == ProjectStatus.pending;
      case 2:
        return p.status == ProjectStatus.inProgress;
      case 3:
        return p.paidStatus == PaidStatus.paid;
      default:
        return true;
    }
  }

  void _openProject(Project project) =>
      context.push(AppRouter.projectDetail(project.id));

  void _addProject() => context.push(AppRouter.newProject);

  void _editProject(Project project) =>
      context.push(AppRouter.projectEdit(project.id));

  void _importProjects() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import is coming soon')),
    );
  }

  Future<void> _exportProjects() async {
    final projects = _filtered(context.read<ProjectProvider>().projects);
    final columns = _columns;
    final buffer = StringBuffer();
    buffer.writeln([for (final c in columns) _csv(c.label)].join(','));
    for (final p in projects) {
      buffer.writeln([for (final c in columns) _csv(_valueOf(p, c))].join(','));
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
              ? 'Exported ${projects.length} rows to offerings.csv'
              : 'Exported ${projects.length} rows (copied to clipboard)',
        ),
      ),
    );
  }

  String _csv(String value) => '"${value.replaceAll('"', '""')}"';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offering deleted')),
      );
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
    final projects = _filtered(provider.projects);

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
                  child: projects.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<ProjectProvider>().fetchProjects(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _table(projects),
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

  Widget _table(List<Project> projects) {
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
                    for (var i = 0; i < projects.length; i++)
                      _tableRow(
                        projects[i],
                        i,
                        columns,
                        fill,
                        i == projects.length - 1,
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
    Project project,
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
        onTap: () => _openProject(project),
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
                  child: _cellFor(project, c),
                ),
              _gridCell(
                width: _wActions,
                last: true,
                center: true,
                bottom: !isLast,
                child: _rowAction(project),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cellFor(Project project, _Col c) => switch (c) {
        _Col.name => Text(
            project.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        _Col.owner => _plainText(project.owner),
        _Col.address => _plainText(project.address),
        _Col.status => _pill(project.status.label, project.status.color),
        _Col.payment => _pill(project.paidStatus.label, project.paidStatus.color),
      };

  String _valueOf(Project project, _Col c) => switch (c) {
        _Col.name => project.name,
        _Col.owner => project.owner,
        _Col.address => project.address,
        _Col.status => project.status.label,
        _Col.payment => project.paidStatus.label,
      };

  Widget _rowAction(Project project) {
    if (_isManager) return _menu(project);
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

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          _columnsDropdown(),
          const SizedBox(width: 8),
          if (_searching)
            _searchField()
          else
            _iconButton(
              Icons.search,
              'Search',
              () => setState(() => _searching = true),
            ),
          const Spacer(),
          if (_isManager) ...[
            FilledButton.icon(
              style:  FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  )
              ),
              onPressed: _addProject,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style:  FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  )
              ),
              onPressed: _importProjects,
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: const Text('Import'),
            ),
            const SizedBox(width: 8),
          ],
          OutlinedButton.icon(
            style:  FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  )
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
          hintText: 'Search offerings...',
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

  Widget _menu(Project project) {
    return PopupMenuButton<String>(
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
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.6)),
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
