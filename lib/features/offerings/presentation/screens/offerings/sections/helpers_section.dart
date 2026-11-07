part of '../../offerings_page.dart';

extension _HelpersSection on _OfferingsPageState {
  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  String _countShare(int count, int total) {
    if (total == 0) return '0';
    return '$count · ${((count / total) * 100).round()}%';
  }

  String _analyticsDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  Color _analyticsColor(int index) {
    const palette = [
      AppColors.primary,
      AppColors.accepted,
      AppColors.inProgress,
      AppColors.pending,
      AppColors.onHold,
      AppColors.completed,
    ];
    return palette[index % palette.length];
  }
}
