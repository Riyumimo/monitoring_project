part of '../../project_form_screen.dart';

extension _ProjectFormStatusSections on _ProjectFormScreenState {
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
            if (value != null) _rebuild(() => _status = value);
          },
        ),
      ],
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
