part of '../../timeline_page.dart';

extension _TimelineChartSections on _TimelinePageState {
  Widget _chart(TimelineProvider provider, List<TimelineTask> allTasks) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final leftWidth = compact ? 152.0 : 220.0;
          final dayWidth = compact ? 36.0 : 44.0;
          final chartWidth = dayWidth * _daysInMonth;
          final placements = _layoutTasks(provider, allTasks);

          return SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: leftWidth,
                  child: _leftColumn(provider, placements),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _horizontal,
                    thumbVisibility: true,
                    interactive: true,
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    child: SingleChildScrollView(
                      controller: _horizontal,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        child: Column(
                          children: [
                            _timelineHeader(dayWidth),
                            for (final person in provider.people)
                              _timelineRow(
                                person,
                                placements[person.id] ?? const [],
                                dayWidth,
                                chartWidth,
                              ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _leftColumn(
    TimelineProvider provider,
    Map<String, List<_TaskPlacement>> placements,
  ) {
    return Column(
      children: [
        Container(
          height: _TimelinePageState._headerHeight,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.55),
            border: const Border(
              right: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: const Text(
            'Team member',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        for (final person in provider.people)
          _personCell(
            person,
            provider.colorFor(person.id),
            _rowHeightFor(placements[person.id] ?? const []),
          ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _personCell(TimelinePerson person, Color color, double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Text(
              _initials(person.name),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (person.roleLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    person.roleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineHeader(double dayWidth) {
    return SizedBox(
      height: _TimelinePageState._headerHeight,
      child: Row(
        children: [
          for (var day = 1; day <= _daysInMonth; day++)
            _dayHeader(day, dayWidth),
        ],
      ),
    );
  }

  Widget _dayHeader(int day, double dayWidth) {
    final date = DateTime(_monthStart.year, _monthStart.month, day);
    final today = DateUtils.isSameDay(date, DateTime.now());
    final weekend = date.weekday >= DateTime.saturday;

    return Container(
      width: dayWidth,
      height: _TimelinePageState._headerHeight,
      decoration: BoxDecoration(
        color: today
            ? AppColors.primary.withValues(alpha: 0.12)
            : weekend
            ? AppColors.background.withValues(alpha: 0.6)
            : AppColors.surface,
        border: const Border(
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekdayShort(date.weekday),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: today ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: today ? FontWeight.w700 : FontWeight.w600,
              color: today ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineRow(
    TimelinePerson person,
    List<_TaskPlacement> placements,
    double dayWidth,
    double chartWidth,
  ) {
    final height = _rowHeightFor(placements);
    final todayOffset = _todayOffset(dayWidth);

    return SizedBox(
      width: chartWidth,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(child: _grid(dayWidth)),
          if (todayOffset != null)
            Positioned(
              left: todayOffset,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 1.5,
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
            ),
          for (final placement in placements) _taskBlock(placement, dayWidth),
        ],
      ),
    );
  }

  Widget _grid(double dayWidth) {
    return Row(
      children: [
        for (var day = 1; day <= _daysInMonth; day++)
          Container(
            width: dayWidth,
            decoration: BoxDecoration(
              color:
                  DateTime(_monthStart.year, _monthStart.month, day).weekday >=
                      DateTime.saturday
                  ? AppColors.background.withValues(alpha: 0.45)
                  : Colors.transparent,
              border: Border(
                right: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
                bottom: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
      ],
    );
  }

  Widget _taskBlock(_TaskPlacement placement, double dayWidth) {
    final task = placement.task;
    final isProject = task.isProjectSchedule;
    final startDay = task.startDate.isBefore(_monthStart)
        ? 1
        : task.startDate.day;
    final endDay = task.endDate.isAfter(_monthEnd)
        ? _daysInMonth
        : task.endDate.day;
    final left = (startDay - 1) * dayWidth + 4.0;
    final rawWidth = (endDay - startDay + 1) * dayWidth - 8.0;
    final width = rawWidth < 24 ? 24.0 : rawWidth;
    final top =
        _TimelinePageState._rowPadding +
        placement.lane *
            (_TimelinePageState._taskHeight + _TimelinePageState._taskGap);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: _TimelinePageState._taskHeight,
      child: Tooltip(
        message:
            '${isProject ? 'Project schedule: ' : ''}${task.title}\n'
            '${_dateLabel(task.startDate)} â€“ ${_dateLabel(task.endDate)}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: isProject
                ? () => context.push(AppRouter.projectDetail(task.projectId!))
                : () => _openTaskDialog(
                    context.read<TimelineProvider>(),
                    existing: task,
                  ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: task.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: task.color.withValues(alpha: 0.55)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: task.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isProject) ...[
                    const Icon(
                      Icons.work_outline,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
