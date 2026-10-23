import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/project_provider.dart';
import '../providers/worker_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Create/edit a **worker** shown on the Workers page.
class WorkerFormScreen extends StatefulWidget {
  final String? workerId;

  const WorkerFormScreen({super.key, this.workerId});

  @override
  State<WorkerFormScreen> createState() => _WorkerFormScreenState();
}

class _WorkerFormScreenState extends State<WorkerFormScreen> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final Set<WorkerType> _workerTypes = {WorkerType.field};
  bool _showTypeError = false;
  User? _editing;
  bool _isSaving = false;

  bool get _isEditing => widget.workerId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.workerId;
    if (id == null) return;

    final provider = context.read<WorkerProvider>();
    final worker = provider.workerById(id);
    if (worker != null) {
      _populate(worker);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<WorkerProvider>().ensureWorkersLoaded();
        if (!mounted) return;
        final loaded = context.read<WorkerProvider>().workerById(id);
        if (loaded != null) setState(() => _populate(loaded));
      });
    }
  }

  void _populate(User worker) {
    _editing = worker;
    _nameController.text = worker.name;
    _emailController.text = worker.email;
    _phoneController.text = worker.phone ?? '';
    _workerTypes
      ..clear()
      ..addAll(
        worker.workerTypes.isEmpty
            ? const [WorkerType.field]
            : worker.workerTypes,
      );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveWorker() async {
    if (!_formKey.currentState!.validate()) return;
    if (_workerTypes.isEmpty) {
      setState(() => _showTypeError = true);
      return;
    }

    final provider = context.read<WorkerProvider>();
    final projectProvider = context.read<ProjectProvider>();
    final phone = _phoneController.text.trim();

    setState(() => _isSaving = true);

    final worker = User(
      id: _editing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _editing?.role ?? 'FieldWorker',
      phone: phone.isEmpty ? null : phone,
      workerTypes: _workerTypes.toList(),
    );

    try {
      if (_isEditing) {
        await provider.updateWorker(worker);
        // Keep project team names in sync if the worker was renamed.
        if (!mounted) return;
        projectProvider.syncWorker(worker);
      } else {
        await provider.addWorker(worker);
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
    final isEditing = _isEditing;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Worker' : 'New Worker')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _sectionCard(
              title: 'Worker Details',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter the worker name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: 'Optional',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Worker Types',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in WorkerType.values)
                      FilterChip(
                        label: Text(type.label),
                        selected: _workerTypes.contains(type),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _workerTypes.add(type);
                            } else {
                              _workerTypes.remove(type);
                            }
                            _showTypeError = false;
                          });
                        },
                      ),
                  ],
                ),
                if (_showTypeError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Select at least one worker type.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onHold,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Select every type this person can perform. A worker with the '
                  'CAD type has no project limit.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWorker,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Add Worker'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter an email address';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
    if (context.read<WorkerProvider>().emailTaken(
      email,
      ignoreId: _editing?.id,
    )) {
      return 'This email is already used by another worker';
    }
    return null;
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
