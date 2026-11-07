import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/offering.dart';
import '../../../../domain/models/project.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../../../app/router/app_router.dart';
import './client_form_dialog.dart';
import '../../../../data/clients/client_directory.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/csv_download.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/status_extensions.dart';
import '../widgets/offering_sidebar.dart';

part 'offerings/sections/filters_section.dart';
part 'offerings/sections/table_section.dart';
part 'offerings/sections/projects_section.dart';
part 'offerings/sections/analytics_section.dart';
part 'offerings/sections/analytics_cards_section.dart';
part 'offerings/sections/analytics_projects_section.dart';
part 'offerings/sections/analytics_charts_section.dart';
part 'offerings/sections/clients_section.dart';
part 'offerings/sections/cards_section.dart';
part 'offerings/sections/dialogs_section.dart';
part 'offerings/sections/helpers_section.dart';
part 'offerings/widgets/col.dart';
part 'offerings/widgets/analytics_kpi.dart';
part 'offerings/widgets/analytics_slice.dart';
part 'offerings/widgets/client_aggregate.dart';
part 'offerings/widgets/unpaid_project.dart';
part 'offerings/widgets/client_record.dart';

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
    SidebarMenuItem(Icons.insights_outlined, 'Analytics', dividerBefore: true),
  ];

  bool get _isOfferingsView => _menuIndex == 0;
  bool get _isAnalyticsView => _menuIndex == 3;

  String get _searchHint => switch (_menuIndex) {
    1 => 'Search projects...',
    2 => 'Search clients...',
    3 => 'Search analytics...',
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
      context.read<ProjectProvider>().ensureProjectsLoaded();
    });
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isManager => context.read<AuthProvider>().userRole == 'Manager';

  /// `setState` reachable from the `part` files that hold this screen's
  /// builders (an extension cannot call the protected member directly).
  void _rebuild(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  List<_Col> get _columns => [
    for (final c in _Col.values)
      if (_visible.contains(c)) c,
  ];

  void _openOffering(Offering offering) =>
      context.push(AppRouter.offeringDetail(offering.id));

  void _addOffering() => context.push(AppRouter.newOffering);

  Future<void> _addClient() async {
    final client = await showDialog<ClientRecord>(
      context: context,
      builder: (_) => const ClientFormDialog(),
    );
    if (client == null || !mounted) return;
    setState(() {
      _query = '';
      _searchController.clear();
      _searching = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${client.name} added to clients')));
  }

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final offerings = _filtered(provider.offerings);
    final projects = _visibleProjects(provider.projects);
    final analyticsOfferings = _visibleOfferings(provider.offerings);
    final analyticsProjects = _assignedProjects(provider.projects);

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
            onSelect: (i) => setState(() {
              _menuIndex = i;
              _searching = false;
              _query = '';
              _searchController.clear();
            }),
          ),
          Expanded(
            child: Column(
              children: [
                if (!_isAnalyticsView) _toolbar(),
                Expanded(
                  child: _menuIndex == 1
                      ? _projectsView(projects)
                      : _menuIndex == 2
                      ? _clientsView()
                      : _menuIndex == 3
                      ? _analyticsView(analyticsOfferings, analyticsProjects)
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
}
