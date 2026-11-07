part of '../../offering_detail_screen.dart';

extension _ClientPaymentSections on _OfferingDetailScreenState {
  Payment? get _latestPaymentWithProof {
    for (final payment in _payments.reversed) {
      if (payment.invoiceNumber.isNotEmpty || payment.proofName.isNotEmpty) {
        return payment;
      }
    }
    return null;
  }

  Widget _paymentProofPill(Payment payment) {
    final hasInvoice = payment.invoiceNumber.isNotEmpty;
    final label = hasInvoice ? payment.invoiceNumber : 'Proof attached';
    final tooltip = [
      if (hasInvoice) 'Invoice ${payment.invoiceNumber}',
      if (payment.proofName.isNotEmpty) 'Proof: ${payment.proofName}',
    ].join('\n');
    return Tooltip(
      message: tooltip,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 168),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              payment.proofName.isNotEmpty
                  ? Icons.attach_file
                  : Icons.receipt_long_outlined,
              size: 12,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceChoiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double? amount,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount == null ? 'N/A' : formatRupiah(amount),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _clientCard(Offering offering, ClientRecord? client) {
    final contactName = (client?.contactPerson.isNotEmpty ?? false)
        ? client!.contactPerson
        : 'Michael Petersen';
    final contactEmail = (client?.email.isNotEmpty ?? false)
        ? client!.email
        : 'contact@geoterra.co.id';
    final contactPhone = (client?.phone.isNotEmpty ?? false)
        ? client!.phone
        : '+62 812-3456-7890';
    final detail = client == null
        ? 'Primary Contact'
        : '${client.contactPerson.isEmpty ? 'Primary Contact' : client.contactPerson} · ${client.typeLabel}';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Client')),
              if (offering.clientHasRecentOffer)
                _miniPill('Recent offer', AppColors.pending),
            ],
          ),
          Row(
            children: [
              _initialsAvatar(contactName, AppColors.inProgress, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offering.owner.isEmpty ? 'No client' : offering.owner,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contactEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  onTap: () => _showPlaceholder('Calling $contactPhone…'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactButton(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  onTap: () => _showPlaceholder('Emailing $contactEmail…'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(Offering offering) {
    final color = offering.paidStatus.color;
    final budget = offering.budgetAmount ?? 0;
    final progress = budget > 0
        ? (offering.amountPaid / budget).clamp(0.0, 1.0)
        : switch (offering.paidStatus) {
            PaidStatus.unpaid => 0.0,
            PaidStatus.partiallyPaid => 0.5,
            PaidStatus.paid => 1.0,
          };
    final remaining = offering.remainingAmount;
    final hint = switch (offering.paidStatus) {
      PaidStatus.unpaid => 'No payment recorded yet',
      PaidStatus.partiallyPaid =>
        remaining == null
            ? 'Part of the invoice has been recorded'
            : '${formatRupiah(remaining)} outstanding',
      PaidStatus.paid => 'Invoice fully settled',
    };
    final icon = switch (offering.paidStatus) {
      PaidStatus.unpaid => Icons.error_outline,
      PaidStatus.partiallyPaid => Icons.timelapse,
      PaidStatus.paid => Icons.check_circle_outline,
    };
    final buttonLabel = offering.isFullyPaid
        ? 'Payment Complete'
        : budget <= 0
        ? 'Set Budget First'
        : 'Add Payment';

    return _card(
      key: _paymentKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Payment')),
              if (_latestPaymentWithProof case final payment?)
                _paymentProofPill(payment),
            ],
          ),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  offering.paidStatus.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Text(
                    'Payment progress',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _amountRow(
                label: 'Paid',
                value: formatRupiah(offering.amountPaid),
                valueColor: color,
              ),
              const SizedBox(height: 3),
              _amountRow(
                label: 'Remaining',
                value: remaining == null ? '—' : formatRupiah(remaining),
                valueColor: AppColors.textPrimary,
              ),
              if (_isManager) ...[
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: budget > 0 && !offering.isFullyPaid
                        ? _recordPayment
                        : null,
                    icon: Icon(
                      offering.isFullyPaid
                          ? Icons.check_circle_outline
                          : Icons.add_card,
                      size: 16,
                    ),
                    label: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountRow({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _initialsAvatar(String name, Color color, {required double size}) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.inProgress.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.inProgress),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inProgress,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
