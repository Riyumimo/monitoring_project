part of '../../timeline_page.dart';

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
