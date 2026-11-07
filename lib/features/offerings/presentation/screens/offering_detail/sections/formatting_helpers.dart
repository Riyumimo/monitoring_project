part of '../../offering_detail_screen.dart';

extension _FormattingHelpers on _OfferingDetailScreenState {
  String _rentalRecipient(Offering offering, ClientRecord? client) {
    final name = client?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return offering.owner.trim();
  }

  String _buildRentalInvoiceNumber(
    List<Offering> offerings,
    Offering offering,
    DateTime issuedAt,
  ) {
    return InvoiceNumbering.rental(
      sequence: InvoiceNumbering.rentalSequence(offerings, offering),
      issuedAt: issuedAt,
    );
  }

  OfferingActivity _statusActivity(Offering offering, OfferingStatus status) {
    final now = DateTime.now();
    final client = ClientDirectory.findByName(offering.owner);
    final recipient = (client?.contactPerson.isNotEmpty ?? false)
        ? client!.contactPerson
        : 'the client';
    final (type, title, subtitle) = switch (status) {
      OfferingStatus.draft => (
        ActivityType.created,
        'Offering moved to draft',
        'Status reset to draft',
      ),
      OfferingStatus.sent => (
        ActivityType.sent,
        'Proposal sent',
        'Shared with $recipient',
      ),
      OfferingStatus.accepted => (
        ActivityType.accepted,
        'Proposal accepted',
        'Client approved the offering',
      ),
      OfferingStatus.rejected => (
        ActivityType.rejected,
        'Proposal declined',
        'Client rejected the offering',
      ),
      OfferingStatus.expired => (
        ActivityType.expired,
        'Offering expired',
        'The validity period ended',
      ),
    };
    return OfferingActivity(
      id: 'ACT-${now.microsecondsSinceEpoch}',
      offeringId: offering.id,
      type: type,
      title: title,
      subtitle: subtitle,
      occurredAt: now,
      actor: _actorName,
    );
  }

  OfferingActivity _paymentActivityEntry(Offering offering, Payment payment) {
    final note = payment.note.trim();
    final hasProof = payment.proofName.isNotEmpty;
    final subtitleParts = <String>[
      '${formatRupiah(payment.amount)} via ${payment.method.label}',
      if (payment.invoiceNumber.isNotEmpty) 'Invoice ${payment.invoiceNumber}',
      if (hasProof) 'Proof: ${payment.proofName}',
      if (note.isNotEmpty) note,
    ];
    return OfferingActivity(
      id: 'ACT-${payment.id}',
      offeringId: offering.id,
      type: ActivityType.payment,
      title: 'Payment received',
      subtitle: subtitleParts.join(' · '),
      occurredAt: payment.paidAt,
      actor: _actorName,
    );
  }

  OfferingActivity _paymentCompletedActivity(
    Offering offering,
    DateTime occurredAt,
  ) {
    return OfferingActivity(
      id: 'ACT-${offering.id}-paid-${occurredAt.microsecondsSinceEpoch}',
      offeringId: offering.id,
      type: ActivityType.paymentCompleted,
      title: 'Offering fully paid',
      subtitle: '${formatRupiah(offering.amountPaid)} settled in full',
      occurredAt: occurredAt,
      actor: _actorName,
    );
  }

  String? get _actorName => context.read<AuthProvider>().user?.name;

  String _activityTimestamp(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour24 = value.hour;
    final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    return '${weekdays[value.weekday - 1]} ${value.month}/${value.day} '
        '· $hour:$minute $suffix';
  }

  String _formatDate(DateTime value) =>
      '${_monthName(value.month)} ${value.day}, ${value.year}';

  String _monthName(int month) => const [
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
  ][month - 1];

  IconData _statusIcon(OfferingStatus status) => switch (status) {
    OfferingStatus.draft => Icons.edit_note,
    OfferingStatus.sent => Icons.send_outlined,
    OfferingStatus.accepted => Icons.thumb_up_alt_outlined,
    OfferingStatus.rejected => Icons.cancel_outlined,
    OfferingStatus.expired => Icons.history,
  };
}
