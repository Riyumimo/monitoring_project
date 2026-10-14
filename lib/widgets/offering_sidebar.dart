import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SidebarMenuItem {
  final IconData icon;
  final String label;

  const SidebarMenuItem(this.icon, this.label);
}

class OfferingSidebar extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onToggle;
  final List<SidebarMenuItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const OfferingSidebar({
    super.key,
    required this.collapsed,
    required this.onToggle,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      width: collapsed ? 72 : 236,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _brand(),
            const SizedBox(height: 6),
            for (var i = 0; i < items.length; i++) _navTile(i),
          ],
        ),
      ),
    );
  }

  Widget _brand() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          collapsed ? 12 : 16, 16, collapsed ? 12 : 8, 8),
      child: collapsed
          ? Column(
              children: [
                _logo(),
                const SizedBox(height: 6),
                _toggle(),
              ],
            )
          : Row(
              children: [
                _logo(),
                const SizedBox(width: 10),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.centerLeft,
                  child: collapsed
                      ? const SizedBox.shrink()
                      : const Expanded(
                          child: Text(
                            'Offering',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 4),
                _toggle(),
              ],
            ),
    );
  }

  Widget _logo() {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.inventory_2_outlined,
          color: Colors.white, size: 20),
    );
  }

  Widget _toggle() {
    return IconButton(
      onPressed: onToggle,
      tooltip: collapsed ? 'Expand menu' : 'Collapse menu',
      icon: Icon(
        collapsed ? Icons.chevron_right : Icons.chevron_left,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _navTile(int index) {
    final item = items[index];
    final selected = index == selectedIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Tooltip(
        message: collapsed ? item.label : '',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(index),
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary,
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  opacity: collapsed ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: collapsed,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: collapsed ? 0 : null,
                      padding: EdgeInsets.only(left: collapsed ? 0 : 12),
                      child: Flexible(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
