import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/timeline.dart';
import '../providers/project_provider.dart';
import '../providers/timeline_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Monthly Gantt chart for the field team, with create/edit/delete support.
class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  static const double _headerHeight = 58;
  static const double _baseRowHeight = 68;
  static const double _taskHeight = 30;
  static const double _taskGap = 6;
  static const double _rowPadding = 10;

  late DateTime _monthStart;
  late DateTime _monthEnd;
  late int _daysInMonth;
  final ScrollController _horizontal = ScrollController();

  @override
  void initState() {
    super.initState();
    _setMonth(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProjectProvider>().ensureProjectsLoaded();
    });
  }

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  void _setMonth(DateTime value) {
    _monthStart = DateTime(value.year, value.month, 1);
    _monthEnd = DateTime(value.year, value.month + 1, 0);
    _daysInMonth = _monthEnd.day;
  }

  void _changeMonth(int delta) {
    setState(
      () => _setMonth(DateTime(_monthStart.year, _monthStart.month + delta, 1)),
    );
    _scrollToStart();
  }

  void _goToToday() {
    if (_isCurrentMonth) return;
    setState(() => _setMonth(DateTime.now()));
    _scrollToStart();
  }

  void _scrollToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontal.hasClients) _horizontal.jumpTo(0);
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return now.year == _monthStart.year && now.month == _monthStart.month;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimelineProvider>();
    final projects = context.watch<ProjectProvider>();
    final projectTasks = _projectScheduleTasks(projects, provider);
    final allTasks = <TimelineTask>[...provider.tasks, ...projectTasks];

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          _header(provider, allTasks),
          Expanded(child: _chart(provider, allTasks)),
        ],
      ),
    );
  }

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
          height: _headerHeight,
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
      height: _headerHeight,
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
      height: _headerHeight,
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
    final top = _rowPadding + placement.lane * (_taskHeight + _taskGap);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: _taskHeight,
      child: Tooltip(
        message:
            '${isProject ? 'Project schedule: ' : ''}${task.title}\n'
            '${_dateLabel(task.startDate)} – ${_dateLabel(task.endDate)}',
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

  Future<void> _openTaskDialog(
    TimelineProvider provider, {
    TimelineTask? existing,
  }) async {
    final result = await showDialog<_TaskDialogResult>(
      context: context,
      builder: (context) => _TaskEditorDialog(
        people: provider.people,
        colorFor: provider.colorFor,
        monthStart: _monthStart,
        monthEnd: _monthEnd,
        existing: existing,
      ),
    );
    if (!mounted || result == null) return;

    if (result.delete) {
      if (existing != null) {
        provider.removeTask(existing.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted from the timeline.')),
        );
      }
      return;
    }

    final task = result.task;
    if (task == null) return;

    // A task may be scheduled outside the currently visible month. Switch the
    // timeline to the task's month so the saved task is visible immediately.
    _focusTaskMonth(task);

    if (existing == null) {
      provider.addTask(task);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task added.')));
    } else {
      provider.updateTask(task);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task updated.')));
    }
  }

  void _focusTaskMonth(TimelineTask task) {
    final startsInVisibleMonth =
        task.startDate.year == _monthStart.year &&
        task.startDate.month == _monthStart.month;
    final overlapsVisibleMonth =
        !task.endDate.isBefore(_monthStart) &&
        !task.startDate.isAfter(_monthEnd);

    if (startsInVisibleMonth || overlapsVisibleMonth) return;

    setState(() => _setMonth(task.startDate));
    _scrollToStart();
  }

  List<TimelineTask> _projectScheduleTasks(
    ProjectProvider projects,
    TimelineProvider timeline,
  ) {
    final workerIds = {for (final person in timeline.people) person.id};
    final tasks = <TimelineTask>[];

    for (final project in projects.projects) {
      final start = project.startDate;
      final end = project.endDate;
      if (start == null || end == null || end.isBefore(start)) continue;

      for (final workerId in project.assignedWorkerIds.toSet()) {
        if (!workerIds.contains(workerId)) continue;
        tasks.add(
          TimelineTask(
            id: 'project:${project.id}:$workerId',
            personId: workerId,
            title: project.name,
            startDate: DateUtils.dateOnly(start),
            endDate: DateUtils.dateOnly(end),
            color: _projectColor(project.status),
            projectId: project.id,
          ),
        );
      }
    }

    return tasks;
  }

  Color _projectColor(ProjectStatus status) {
    return switch (status) {
      ProjectStatus.planning => AppColors.pending,
      ProjectStatus.inProgress => AppColors.inProgress,
      ProjectStatus.onHold => AppColors.onHold,
      ProjectStatus.completed => AppColors.completed,
      ProjectStatus.cancelled => AppColors.textSecondary,
    };
  }

  List<TimelineTask> _tasksInMonth(List<TimelineTask> tasks) {
    return tasks
        .where(
          (task) =>
              !task.endDate.isBefore(_monthStart) &&
              !task.startDate.isAfter(_monthEnd),
        )
        .toList();
  }

  Map<String, List<_TaskPlacement>> _layoutTasks(
    TimelineProvider provider,
    List<TimelineTask> allTasks,
  ) {
    final result = <String, List<_TaskPlacement>>{};

    for (final person in provider.people) {
      final tasks =
          allTasks
              .where(
                (task) =>
                    task.personId == person.id &&
                    !task.endDate.isBefore(_monthStart) &&
                    !task.startDate.isAfter(_monthEnd),
              )
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));

      final laneEnds = <DateTime>[];
      final placements = <_TaskPlacement>[];

      for (final task in tasks) {
        var lane = laneEnds.indexWhere((end) => end.isBefore(task.startDate));
        if (lane == -1) {
          lane = laneEnds.length;
          laneEnds.add(task.endDate);
        } else {
          laneEnds[lane] = task.endDate;
        }
        placements.add(_TaskPlacement(task: task, lane: lane));
      }

      result[person.id] = placements;
    }

    return result;
  }

  double _rowHeightFor(List<_TaskPlacement> placements) {
    var lanes = 1;
    for (final placement in placements) {
      if (placement.lane + 1 > lanes) lanes = placement.lane + 1;
    }
    final needed =
        _rowPadding * 2 + lanes * _taskHeight + (lanes - 1) * _taskGap;
    return needed < _baseRowHeight ? _baseRowHeight : needed;
  }

  double? _todayOffset(double dayWidth) {
    final now = DateTime.now();
    if (now.year != _monthStart.year || now.month != _monthStart.month) {
      return null;
    }
    return (now.day - 1) * dayWidth + dayWidth / 2;
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

  String get _monthLabel {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[_monthStart.month - 1]} ${_monthStart.year}';
  }
}

class _TaskPlacement {
  final TimelineTask task;
  final int lane;

  const _TaskPlacement({required this.task, required this.lane});
}

class _TaskDialogResult {
  final TimelineTask? task;
  final bool delete;

  const _TaskDialogResult.save(this.task) : delete = false;

  const _TaskDialogResult.delete() : task = null, delete = true;
}

class _TaskEditorDialog extends StatefulWidget {
  final List<TimelinePerson> people;
  final Color Function(String personId) colorFor;
  final DateTime monthStart;
  final DateTime monthEnd;
  final TimelineTask? existing;

  const _TaskEditorDialog({
    required this.people,
    required this.colorFor,
    required this.monthStart,
    required this.monthEnd,
    this.existing,
  });

  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late String _personId;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _dateError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    final defaultStart =
        today.isBefore(widget.monthStart) || today.isAfter(widget.monthEnd)
        ? widget.monthStart
        : today;
    final defaultEnd = defaultStart.add(const Duration(days: 2));

    _personId =
        widget.existing?.personId ??
        (widget.people.isEmpty ? '' : widget.people.first.id);
    _titleController = TextEditingController(
      text: widget.existing?.title ?? '',
    );
    _startDate = widget.existing?.startDate ?? defaultStart;
    _endDate = widget.existing?.endDate ?? defaultEnd;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final firstDate = DateTime(2000, 1, 1);
    final lastDate = DateTime(2100, 12, 31);
    final initialDate = initial.isBefore(firstDate)
        ? firstDate
        : initial.isAfter(lastDate)
        ? lastDate
        : initial;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: isStart ? 'Select start date' : 'Select end date',
    );
    if (picked == null) return;

    final date = DateUtils.dateOnly(picked);
    setState(() {
      if (isStart) {
        _startDate = date;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = date;
      }
      _dateError = null;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      setState(() => _dateError = 'End date cannot be before start date.');
      return;
    }

    final task = TimelineTask(
      id:
          widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      personId: _personId,
      title: _titleController.text.trim(),
      startDate: DateUtils.dateOnly(_startDate),
      endDate: DateUtils.dateOnly(_endDate),
      color: widget.colorFor(_personId),
    );
    Navigator.of(context).pop(_TaskDialogResult.save(task));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          'Delete "${widget.existing!.title}" from the timeline? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.onHold),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    Navigator.of(context).pop(const _TaskDialogResult.delete());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Task' : 'New Task'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('dialog-person:$_personId'),
                  initialValue: _personId.isEmpty ? null : _personId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Person',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    for (final person in widget.people)
                      DropdownMenuItem(
                        value: person.id,
                        child: Text(
                          person.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _personId = value);
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select a person'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  autofocus: !_isEditing,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    prefixIcon: Icon(Icons.task_alt_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a task title'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        label: 'Start date',
                        value: _startDate,
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateField(
                        label: 'End date',
                        value: _endDate,
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Dates can be in any month. Saving moves the timeline '
                        'to the task month.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_dateError != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppColors.onHold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dateError!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.onHold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: AppColors.onHold),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Save Changes' : 'Add Task'),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined, size: 20),
        ),
        child: Text(
          _dateLabel(value),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _weekdayShort(int weekday) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
