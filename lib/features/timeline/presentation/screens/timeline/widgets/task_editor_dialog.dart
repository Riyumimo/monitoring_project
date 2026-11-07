part of '../../timeline_page.dart';

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
