part of '../../client_form_dialog.dart';

extension _ClientFormNavigationSections on _ClientFormDialogState {
  Widget _sectionNavigation({required bool vertical}) {
    final children = [
      for (
        var index = 0;
        index < _ClientFormDialogState._sections.length;
        index++
      )
        _sectionNavItem(index),
    ];
    if (!vertical) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Wrap(spacing: 4, runSpacing: 2, children: children),
      );
    }
    return Container(
      color: AppColors.background.withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: children),
    );
  }

  Widget _sectionNavItem(int index) {
    final selected = _activeSection == index;
    return Semantics(
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: TextButton.icon(
          onPressed: () => _goToSection(index),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            foregroundColor: selected
                ? AppColors.primary
                : AppColors.textSecondary,
            backgroundColor: selected
                ? AppColors.primary.withValues(alpha: 0.09)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          icon: Icon(switch (index) {
            0 => Icons.business_outlined,
            1 => Icons.contact_page_outlined,
            2 => Icons.account_balance_outlined,
            3 => Icons.payments_outlined,
            _ => Icons.settings_outlined,
          }, size: 18),
          label: Text(_ClientFormDialogState._sections[index]),
        ),
      ),
    );
  }

  void _goToSection(int index) {
    _rebuild(() {
      _activeSection = index;
      _expandedSections
        ..clear()
        ..add(0)
        ..add(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sectionContext = _sectionKeys[index].currentContext;
      if (sectionContext == null) return;
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: 0,
      );
    });
  }

  void _toggleSection(int index) {
    if (index == 0) return;
    _rebuild(() {
      _activeSection = index;
      if (_expandedSections.contains(index)) {
        _expandedSections.remove(index);
      } else {
        _expandedSections
          ..clear()
          ..add(0)
          ..add(index);
      }
    });
  }
}
