import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/offering.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';

extension OfferingStatusX on OfferingStatus {
  String get label {
    switch (this) {
      case OfferingStatus.draft:
        return 'Draft';
      case OfferingStatus.sent:
        return 'Sent';
      case OfferingStatus.accepted:
        return 'Accepted';
      case OfferingStatus.rejected:
        return 'Rejected';
      case OfferingStatus.expired:
        return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case OfferingStatus.draft:
        return AppColors.textSecondary;
      case OfferingStatus.sent:
        return AppColors.pending;
      case OfferingStatus.accepted:
        return AppColors.accepted;
      case OfferingStatus.rejected:
        return AppColors.onHold;
      case OfferingStatus.expired:
        return AppColors.textSecondary;
    }
  }
}

extension ProjectStatusX on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.planning:
        return AppColors.pending;
      case ProjectStatus.inProgress:
        return AppColors.inProgress;
      case ProjectStatus.onHold:
        return AppColors.onHold;
      case ProjectStatus.completed:
        return AppColors.completed;
      case ProjectStatus.cancelled:
        return AppColors.onHold;
    }
  }
}

extension PaidStatusX on PaidStatus {
  String get label {
    switch (this) {
      case PaidStatus.unpaid:
        return 'Unpaid';
      case PaidStatus.partiallyPaid:
        return 'Partially Paid';
      case PaidStatus.paid:
        return 'Paid';
    }
  }

  Color get color {
    switch (this) {
      case PaidStatus.unpaid:
        return AppColors.unpaid;
      case PaidStatus.partiallyPaid:
        return AppColors.partiallyPaid;
      case PaidStatus.paid:
        return AppColors.paid;
    }
  }
}

extension ActivityTypeX on ActivityType {
  IconData get icon {
    switch (this) {
      case ActivityType.created:
        return Icons.note_add_outlined;
      case ActivityType.sent:
        return Icons.send_outlined;
      case ActivityType.accepted:
        return Icons.check_circle_outline;
      case ActivityType.rejected:
        return Icons.cancel_outlined;
      case ActivityType.expired:
        return Icons.history;
      case ActivityType.projectCreated:
        return Icons.folder_open_outlined;
      case ActivityType.payment:
        return Icons.payments_outlined;
      case ActivityType.paymentCompleted:
        return Icons.verified_outlined;
      case ActivityType.note:
        return Icons.sticky_note_2_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.created:
        return AppColors.textSecondary;
      case ActivityType.sent:
        return AppColors.pending;
      case ActivityType.accepted:
        return AppColors.completed;
      case ActivityType.rejected:
        return AppColors.onHold;
      case ActivityType.expired:
        return AppColors.textSecondary;
      case ActivityType.projectCreated:
        return AppColors.primary;
      case ActivityType.payment:
        return AppColors.paid;
      case ActivityType.paymentCompleted:
        return AppColors.paid;
      case ActivityType.note:
        return AppColors.inProgress;
    }
  }
}
