/// Kinds of events that can appear in an offering's activity feed.
enum ActivityType {
  created,
  sent,
  accepted,
  rejected,
  expired,
  projectCreated,
  payment,
  paymentCompleted,
  note,
}

/// A single event in an offering's activity feed.
///
/// Unlike the payment and status fields on [Offering], which describe the
/// current state, an activity records that something happened at a point in
/// time. The provider keeps these records so the feed survives navigation and
/// additions such as notes and payments are not lost when the screen rebuilds.
class OfferingActivity {
  final String id;
  final String offeringId;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime occurredAt;

  /// Name of the user who performed the action, when known.
  final String? actor;

  const OfferingActivity({
    required this.id,
    required this.offeringId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.occurredAt,
    this.actor,
  });

  factory OfferingActivity.fromJson(Map<String, dynamic> json) {
    return OfferingActivity(
      id: json['id']?.toString() ?? '',
      offeringId: json['offeringId']?.toString() ?? '',
      type: _typeFromString(json['type']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      occurredAt:
          DateTime.tryParse(json['occurredAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      actor: json['actor']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offeringId': offeringId,
      'type': _typeToString(type),
      'title': title,
      'subtitle': subtitle,
      'occurredAt': occurredAt.toIso8601String(),
      'actor': actor,
    };
  }

  static ActivityType _typeFromString(String type) {
    switch (type) {
      case 'created':
        return ActivityType.created;
      case 'sent':
        return ActivityType.sent;
      case 'accepted':
        return ActivityType.accepted;
      case 'rejected':
        return ActivityType.rejected;
      case 'expired':
        return ActivityType.expired;
      case 'projectCreated':
        return ActivityType.projectCreated;
      case 'payment':
        return ActivityType.payment;
      case 'paymentCompleted':
        return ActivityType.paymentCompleted;
      case 'note':
        return ActivityType.note;
      default:
        return ActivityType.created;
    }
  }

  static String _typeToString(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return 'created';
      case ActivityType.sent:
        return 'sent';
      case ActivityType.accepted:
        return 'accepted';
      case ActivityType.rejected:
        return 'rejected';
      case ActivityType.expired:
        return 'expired';
      case ActivityType.projectCreated:
        return 'projectCreated';
      case ActivityType.payment:
        return 'payment';
      case ActivityType.paymentCompleted:
        return 'paymentCompleted';
      case ActivityType.note:
        return 'note';
    }
  }
}
