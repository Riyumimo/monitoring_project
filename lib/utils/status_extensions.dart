import 'package:flutter/material.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';

extension ProjectStatusX on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.pending:
        return 'Pending';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.onHold:
        return 'On Hold';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.pending:
        return AppColors.pending;
      case ProjectStatus.inProgress:
        return AppColors.inProgress;
      case ProjectStatus.completed:
        return AppColors.completed;
      case ProjectStatus.onHold:
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
