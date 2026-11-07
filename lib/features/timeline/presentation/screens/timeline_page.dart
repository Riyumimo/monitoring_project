import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/project.dart';
import '../../../../domain/models/timeline.dart';
import '../../../offerings/providers/project_provider.dart';
import '../../providers/timeline_provider.dart';
import '../../../workers/providers/worker_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';

part 'timeline/sections/header_section.dart';
part 'timeline/sections/chart_section.dart';
part 'timeline/sections/helpers.dart';
part 'timeline/widgets/task_placement.dart';
part 'timeline/widgets/task_dialog_result.dart';
part 'timeline/widgets/task_editor_dialog.dart';
part 'timeline/widgets/task_editor_dialog_state.dart';

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
      context.read<WorkerProvider>().ensureWorkersLoaded();
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
