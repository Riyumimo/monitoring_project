part of '../../timeline_page.dart';

class _TaskDialogResult {
  final TimelineTask? task;
  final bool delete;

  const _TaskDialogResult.save(this.task) : delete = false;

  const _TaskDialogResult.delete() : task = null, delete = true;
}
