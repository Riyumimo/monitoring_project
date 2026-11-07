import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/offering.dart';
import '../../../../domain/models/project.dart';
import '../../../offerings/providers/project_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/status_extensions.dart';
import '../../../../core/widgets/status_chip.dart';

part 'project_detail/sections/layout_sections.dart';
part 'project_detail/sections/overview_sections.dart';
part 'project_detail/sections/map_sections.dart';
part 'project_detail/sections/contact_sections.dart';
part 'project_detail/sections/team_sections.dart';
part 'project_detail/sections/notes_sections.dart';
part 'project_detail/sections/helpers.dart';
part 'project_detail/widgets/eyebrow.dart';
part 'project_detail/widgets/map_placeholder.dart';
part 'project_detail/widgets/project_note.dart';

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
                      Icon(_statusIcon(status), size: 18, color: status.color),
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
}
