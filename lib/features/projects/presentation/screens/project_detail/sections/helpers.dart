part of '../../project_detail_screen.dart';

extension _ProjectDetailHelpers on _ProjectDetailScreenState {
  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.inProgress.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 17, color: AppColors.inProgress),
          ),
        ),
      ),
    );
  }

  Widget _navButton() {
    return Tooltip(
      message: 'Show on map',
      child: Material(
        color: AppColors.inProgress.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: _showOnMap,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.navigation_outlined,
              size: 17,
              color: AppColors.inProgress,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBar({required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 11),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _miniPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _card({Key? key, required Widget child, Color? stripe}) {
    final content = stripe == null
        ? Padding(padding: const EdgeInsets.all(22), child: child)
        : Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: ColoredBox(color: stripe),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 22, 22),
                child: child,
              ),
            ],
          );

    return Container(
      key: key,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.018),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: content,
    );
  }

  String _noteTimestamp(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour24 = value.hour;
    final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    return 'Updated ${weekdays[value.weekday - 1]} ${value.month}/${value.day} '
        '$hour:$minute $suffix';
  }

  IconData _statusIcon(ProjectStatus status) => switch (status) {
    ProjectStatus.planning => Icons.event_note_outlined,
    ProjectStatus.inProgress => Icons.autorenew,
    ProjectStatus.onHold => Icons.pause_circle_outline,
    ProjectStatus.completed => Icons.check_circle_outline,
    ProjectStatus.cancelled => Icons.cancel_outlined,
  };
}
