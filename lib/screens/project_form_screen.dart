import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/offering.dart';
import '../models/project.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../providers/worker_provider.dart';
import '../router/app_router.dart';
import '../services/assignment_rules.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import '../utils/status_extensions.dart';

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

  Widget _sourceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accepted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accepted.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 18,
            color: AppColors.accepted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'From offering: $_offeringLabel',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.accepted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
  }) {
    final text = value == null
        ? ''
        : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(
          text.isEmpty ? 'Select date' : text,
          style: TextStyle(
            fontSize: 14,
            color: text.isEmpty
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _toolsCard() {
    final catalog = {for (final tool in MockData.tools()) tool.name: tool};
    final names = <String>{...catalog.keys, ..._tools}.toList();

    return _sectionCard(
      title: 'Tools',
      children: [
        Row(
          children: [
            const Icon(
              Icons.handyman_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              _tools.isEmpty
                  ? 'No tools selected'
                  : '${_tools.length} tool${_tools.length == 1 ? '' : 's'} selected',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in names)
              FilterChip(
                label: Text(
                  catalog[name] == null
                      ? name
                      : '$name (${catalog[name]!.available}/${catalog[name]!.total})',
                  style: const TextStyle(fontSize: 12.5),
                ),
                selected: _tools.contains(name),
                onSelected: (selected) => setState(() {
                  _tools = selected
                      ? (_tools.contains(name) ? _tools : [..._tools, name])
                      : _tools.where((t) => t != name).toList();
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _assignmentCard() {
    final provider = context.watch<ProjectProvider>();
    final workers = context.watch<WorkerProvider>().workers;
    final count = _assignedWorkerIds.length;

    return _sectionCard(
      title: 'Field Team Assignment',
      children: [
        Row(
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              count == 0
                  ? 'No workers selected'
                  : '$count worker${count == 1 ? '' : 's'} selected',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final worker in workers) _workerTile(worker, provider),
        if (_assignmentError != null) ...[
          const SizedBox(height: 10),
          _errorNote(_assignmentError!),
        ],
        const SizedBox(height: 10),
        const Text(
          'Choose how many workers this project needs. Rules: field workers in '
          'office can hold 2 active projects, out-of-town field workers only 1. '
          'CAD workers have no limit.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _workerTile(User worker, ProjectProvider provider) {
    final isSelected = _assignedWorkerIds.contains(worker.id);
    final canAssign =
        isSelected ||
        AssignmentRules.canAssign(
          worker,
          projects: provider.projects,
          ignoreProjectId: _editing?.id,
        );
    final blockedReason = AssignmentRules.blockedReason(
      worker,
      projects: provider.projects,
      ignoreProjectId: _editing?.id,
    );

    return CheckboxListTile(
      value: isSelected,
      onChanged: canAssign
          ? (value) => setState(() {
              if (value == true) {
                _assignedWorkerIds.add(worker.id);
              } else {
                _assignedWorkerIds.remove(worker.id);
              }
              _assignmentError = null;
            })
          : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        '${worker.name} — ${worker.workerTypesLabel}',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        canAssign
            ? AssignmentRules.capacityLabel(
                worker,
                projects: provider.projects,
                ignoreProjectId: _editing?.id,
              )
            : blockedReason ?? 'Unavailable',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: canAssign ? AppColors.textSecondary : AppColors.onHold,
        ),
      ),
    );
  }

  Widget _statusCard() {
    return _sectionCard(
      title: 'Status',
      children: [
        DropdownButtonFormField<ProjectStatus>(
          key: ValueKey('status:$_status'),
          initialValue: _status,
          decoration: const InputDecoration(
            labelText: 'Project Status',
            prefixIcon: Icon(Icons.flag_outlined),
          ),
          items: ProjectStatus.values
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _status = value);
          },
        ),
      ],
    );
  }

  Widget _errorNote(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.onHold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.onHold.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.onHold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.onHold,
              ),
            ),
          ),
        ],
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
