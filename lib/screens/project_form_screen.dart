import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class ProjectFormScreen extends StatefulWidget {
  final String? projectId;

  const ProjectFormScreen({super.key, this.projectId});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  ProjectStatus _status = ProjectStatus.pending;
  PaidStatus _paidStatus = PaidStatus.unpaid;
  Project? _editing;
  bool _isSaving = false;

  bool get _isEditing => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.projectId;
    if (id == null) return;

    final provider = context.read<ProjectProvider>();
    final index = provider.projects.indexWhere((p) => p.id == id);
    if (index != -1) {
      _populate(provider.projects[index]);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<ProjectProvider>().fetchProjects();
        if (!mounted) return;
        final projects = context.read<ProjectProvider>().projects;
        final i = projects.indexWhere((p) => p.id == id);
        if (i != -1) {
          setState(() => _populate(projects[i]));
        }
      });
    }
  }

  void _populate(Project project) {
    _editing = project;
    _nameController.text = project.name;
    _ownerController.text = project.owner;
    _addressController.text = project.address;
    _latitudeController.text = project.latitude?.toString() ?? '';
    _longitudeController.text = project.longitude?.toString() ?? '';
    _status = project.status;
    _paidStatus = project.paidStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final project = Project(
      id: _editing?.id ??
          widget.projectId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      owner: _ownerController.text.trim(),
      address: _addressController.text.trim(),
      latitude: double.tryParse(_latitudeController.text),
      longitude: double.tryParse(_longitudeController.text),
      status: _status,
      paidStatus: _paidStatus,
      tools: _editing?.tools ?? const [],
      assignedWorkerId: _editing?.assignedWorkerId,
      assignedWorkerName: _editing?.assignedWorkerName,
    );

    try {
      final provider = context.read<ProjectProvider>();
      if (_isEditing) {
        await provider.updateProject(project);
      } else {
        await provider.addProject(project);
      }
      if (mounted) _close();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
    final isEditing = _isEditing;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Offering' : 'Add Offering'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _sectionCard(
              title: 'Offering Details',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Offering Name',
                    prefixIcon: Icon(Icons.terrain_outlined),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Please enter offering name'
                          : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerController,
                  decoration: const InputDecoration(
                    labelText: 'Offering Owner',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Please enter owner name'
                          : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Please enter address'
                          : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Location',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration:
                            const InputDecoration(labelText: 'Longitude'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Status',
              children: [
                DropdownButtonFormField<ProjectStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Offering Status',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: ProjectStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaidStatus>(
                  initialValue: _paidStatus,
                  decoration: const InputDecoration(
                    labelText: 'Paid Status',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  items: PaidStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _paidStatus = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProject,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Save Offering'),
              ),
            ),
          ],
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
