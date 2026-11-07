part of '../../offerings_page.dart';

extension _FiltersSection on _OfferingsPageState {
  List<Offering> _visibleOfferings(List<Offering> all) {
    if (_isManager) return all;
    final userId = context.read<AuthProvider>().user?.id;
    final provider = context.read<ProjectProvider>();
    return all.where((o) {
      final projectId = o.projectId;
      if (projectId == null || userId == null) return false;
      return provider.projectById(projectId)?.isAssignedTo(userId) ?? false;
    }).toList();
  }

  List<Offering> _filtered(List<Offering> all) {
    var list = _visibleOfferings(all);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (o) =>
                o.name.toLowerCase().contains(q) ||
                o.number.toLowerCase().contains(q) ||
                o.serviceType.toLowerCase().contains(q) ||
                o.owner.toLowerCase().contains(q) ||
                o.address.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  List<Project> _assignedProjects(List<Project> all) {
    if (_isManager) return all;
    final userId = context.read<AuthProvider>().user?.id;
    return userId == null
        ? const <Project>[]
        : all.where((p) => p.isAssignedTo(userId)).toList();
  }

  List<Project> _visibleProjects(List<Project> all) {
    var list = _assignedProjects(all);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.number.toLowerCase().contains(q) ||
                p.owner.toLowerCase().contains(q) ||
                p.address.toLowerCase().contains(q) ||
                p.assignedWorkerNames.any(
                  (name) => name.toLowerCase().contains(q),
                ),
          )
          .toList();
    }
    return list;
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
                      _rebuild(() {
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

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          if (_isOfferingsView) ...[
            _columnsDropdown(),
            const SizedBox(width: 8),
          ],
          if (_searching)
            _searchField()
          else
            _iconButton(
              Icons.search,
              'Search',
              () => _rebuild(() => _searching = true),
            ),
          const Spacer(),
          if (_isOfferingsView && _isManager) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _addOffering,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _importProjects,
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: const Text('Import'),
            ),
            const SizedBox(width: 8),
          ],
          if (_isOfferingsView)
            OutlinedButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
        onChanged: (v) => _rebuild(() => _query = v),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: _searchHint,
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Close',
            onPressed: () => _rebuild(() {
              _searching = false;
              _query = '';
              _searchController.clear();
            }),
          ),
        ),
      ),
    );
  }
}
