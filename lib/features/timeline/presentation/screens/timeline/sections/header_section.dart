part of '../../timeline_page.dart';

extension _TimelineHeaderSections on _TimelinePageState {
  Widget _header(TimelineProvider provider, List<TimelineTask> allTasks) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final monthTasks = _tasksInMonth(allTasks);
          final itemLabel = monthTasks.length == 1 ? 'item' : 'items';
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${provider.people.length} people • '
                '${monthTasks.length} scheduled $itemLabel this month',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (monthTasks.isEmpty) ...[
                const SizedBox(height: 3),
                const Text(
                  'No schedules for this month. Add a task or create a project '
                  'schedule to start planning.',
                  style: TextStyle(fontSize: 12, color: AppColors.pending),
                ),
              ],
            ],
          );

          final monthSelector = Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _monthButton(
                  Icons.chevron_left,
                  'Previous month',
                  () => _changeMonth(-1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    _monthLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _monthButton(
                  Icons.chevron_right,
                  'Next month',
                  () => _changeMonth(1),
                ),
              ],
            ),
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              monthSelector,
              if (!_isCurrentMonth)
                TextButton.icon(
                  onPressed: _goToToday,
                  icon: const Icon(Icons.today_outlined, size: 17),
                  label: const Text('Today'),
                ),
              OutlinedButton.icon(
                onPressed: () => _openTaskDialog(provider),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Task'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 38),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 12), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _monthButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      visualDensity: VisualDensity.compact,
      color: AppColors.textSecondary,
    );
  }
}
