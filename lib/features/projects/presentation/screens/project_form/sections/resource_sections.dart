part of '../../project_form_screen.dart';

extension _ProjectFormResourceSections on _ProjectFormScreenState {
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
                onSelected: (selected) => _rebuild(() {
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
          ? (value) => _rebuild(() {
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
        '${worker.name} â€” ${worker.workerTypesLabel}',
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
}
