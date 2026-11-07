import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/offering.dart';
import '../../../../domain/models/project.dart';
import '../../../../domain/models/user.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../offerings/providers/project_provider.dart';
import '../../../workers/providers/worker_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../../../domain/rules/assignment_rules.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/status_extensions.dart';

part 'project_form/sections/source_sections.dart';
part 'project_form/sections/resource_sections.dart';
part 'project_form/sections/status_sections.dart';

/// Create/edit a **project**. Projects are separate from offerings: new
/// projects are always created from an accepted offering, which is why this
/// form needs an [offeringId] when creating.
class ProjectFormScreen extends StatefulWidget {
  final String? projectId;
  final String? offeringId;

  const ProjectFormScreen({super.key, this.projectId, this.offeringId});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _addressController = TextEditingController();

  ProjectStatus _status = ProjectStatus.planning;
  double? _latitude;
  double? _longitude;
  double? _budgetAmount;
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _tools = const [];
  String _offeringLabel = '';
  String? _sourceOfferingId;
  final Set<String> _assignedWorkerIds = {};
  Project? _editing;
  bool _isSaving = false;
  bool _rentalBlocked = false;
  String? _assignmentError;
  String? _error;

  bool get _isEditing => widget.projectId != null;
  bool get _isManager => context.read<AuthProvider>().userRole == 'Manager';

  /// `setState` for the builder methods that live in `part` files.
  void _rebuild(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerProvider>().ensureWorkersLoaded();
    });
    final projectId = widget.projectId;
    if (projectId != null) {
      final project = context.read<ProjectProvider>().projectById(projectId);
      if (project != null) {
        _populate(project);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await context.read<ProjectProvider>().ensureProjectsLoaded();
          if (!mounted) return;
          final loaded = context.read<ProjectProvider>().projectById(projectId);
          if (loaded != null) setState(() => _populate(loaded));
        });
      }
      return;
    }

    final offeringId = widget.offeringId;
    if (offeringId != null) {
      final offering = context.read<ProjectProvider>().offeringById(offeringId);
      if (offering != null) {
        _populateFromOffering(offering);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await context.read<ProjectProvider>().ensureProjectsLoaded();
          if (!mounted) return;
          final loaded = context.read<ProjectProvider>().offeringById(
            offeringId,
          );
          if (loaded != null) setState(() => _populateFromOffering(loaded));
        });
      }
    } else {
      _numberController.text = _nextNumber();
    }
  }

  String _nextNumber() {
    final count = context.read<ProjectProvider>().projects.length;
    return 'PRJ-${(count + 1).toString().padLeft(3, '0')}';
  }

  void _populate(Project project) {
    _editing = project;
    _numberController.text = project.number;
    _nameController.text = project.name;
    _ownerController.text = project.owner;
    _addressController.text = project.address;
    _latitude = project.latitude;
    _longitude = project.longitude;
    _budgetAmount = project.budgetAmount;
    _status = project.status;
    _startDate = project.startDate;
    _endDate = project.endDate;
    _tools = project.tools;
    _sourceOfferingId = project.offeringId;
    _assignedWorkerIds
      ..clear()
      ..addAll(project.assignedWorkerIds);
    final offering = context.read<ProjectProvider>().offeringById(
      project.offeringId,
    );
    _offeringLabel = offering == null
        ? project.offeringId
        : '${offering.number} · ${offering.name}';
  }

  void _populateFromOffering(Offering offering) {
    _sourceOfferingId = offering.id;
    _rentalBlocked = offering.isRentalService;
    if (_rentalBlocked) {
      _error =
          'Rent Tool offerings do not create projects. Set the rental '
          'until date on the offering instead.';
    }
    _offeringLabel = '${offering.number} · ${offering.name}';
    _numberController.text = _nextNumber();
    _nameController.text = offering.name;
    _ownerController.text = offering.owner;
    _addressController.text = offering.address;
    _latitude = offering.latitude;
    _longitude = offering.longitude;
    _budgetAmount = offering.budgetAmount;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _ownerController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  List<User> get _selectedWorkers {
    final provider = context.read<WorkerProvider>();
    return [
      for (final id in _assignedWorkerIds)
        if (provider.workerById(id) != null) provider.workerById(id)!,
    ];
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProjectProvider>();

    // A project can only be created from an accepted offering.
    if (!_isEditing) {
      final offering = _sourceOfferingId == null
          ? null
          : provider.offeringById(_sourceOfferingId!);
      if (offering == null) {
        setState(() => _error = 'This project has no source offering.');
        return;
      }
      if (offering.isRentalService) {
        setState(() {
          _rentalBlocked = true;
          _error =
              'Rent Tool offerings do not create projects. Set the rental '
              'until date on the offering instead.';
        });
        return;
      }
      if (offering.status != OfferingStatus.accepted) {
        setState(
          () => _error =
              'The offering must be accepted before its project is created.',
        );
        return;
      }
    }

    final workers = _selectedWorkers;
    for (final worker in workers) {
      if (!AssignmentRules.canAssign(
        worker,
        projects: provider.projects,
        ignoreProjectId: _editing?.id,
      )) {
        setState(() {
          _assignmentError = AssignmentRules.blockedReason(
            worker,
            projects: provider.projects,
            ignoreProjectId: _editing?.id,
          );
        });
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _assignmentError = null;
      _error = null;
    });

    final project = Project(
      id: _editing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      number: _numberController.text.trim(),
      name: _nameController.text.trim(),
      offeringId: _editing?.offeringId ?? _sourceOfferingId ?? '',
      owner: _ownerController.text.trim(),
      address: _addressController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
      budgetAmount: _budgetAmount,
      progressPercentage: _editing?.progressPercentage ?? 0,
      tools: _tools,
      assignedWorkerIds: [for (final worker in workers) worker.id],
      assignedWorkerNames: [for (final worker in workers) worker.name],
    );

    try {
      if (_isEditing) {
        await provider.updateProject(project);
      } else {
        await provider.addProject(project);
      }
      if (mounted) _close();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Project' : 'New Project')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (_offeringLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _sourceBanner(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _errorNote(_error!),
              ),
            _sectionCard(
              title: 'Project Details',
              children: [
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Project Number',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    prefixIcon: Icon(Icons.terrain_outlined),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter project name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Client / Owner',
                    prefixIcon: Icon(Icons.apartment_outlined),
                    helperText: 'Inherited from the source offering',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.place_outlined),
                    helperText: 'Inherited from the source offering',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Schedule',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        label: 'Start Date',
                        value: _startDate,
                        onPick: (date) => setState(() => _startDate = date),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _dateField(
                        label: 'End Date',
                        value: _endDate,
                        onPick: (date) => setState(() => _endDate = date),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _toolsCard(),
            if (_isManager) ...[const SizedBox(height: 16), _assignmentCard()],
            const SizedBox(height: 16),
            _statusCard(),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving || _rentalBlocked ? null : _saveProject,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Create Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
