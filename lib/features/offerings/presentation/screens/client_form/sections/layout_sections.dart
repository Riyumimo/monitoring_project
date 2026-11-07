part of '../../client_form_dialog.dart';

extension _ClientFormLayoutSections on _ClientFormDialogState {
  Widget _titleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      color: AppColors.primary,
      child: Row(
        children: [
          const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Add New Client',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Client'),
          ),
        ],
      ),
    );
  }
}
