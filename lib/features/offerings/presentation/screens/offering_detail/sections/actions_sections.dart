part of '../../offering_detail_screen.dart';

extension _ActionsSections on _OfferingDetailScreenState {
  Widget _actionsCard(Offering offering) {
    return _card(
      key: _actionsKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Quick Actions'),
          const SizedBox(height: 14),
          _primaryAction(offering),
          const SizedBox(height: 10),
          Row(
            children: [
              if (_isManager) ...[
                Expanded(
                  child: _secondaryButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: () =>
                        context.push(AppRouter.offeringEdit(offering.id)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _secondaryButton(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  onTap: _showOnMap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _downloadingInvoice
                  ? null
                  : () => _downloadInvoice(offering),
              icon: _downloadingInvoice
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 17),
              label: Text(
                _downloadingInvoice
                    ? 'Preparing invoice...'
                    : 'Download Invoice',
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'UPDATE STATUS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in _OfferingDetailScreenState._statusActions)
                _statusActionChip(offering, status),
            ],
          ),
          if (offering.isRentalService) ...[
            const SizedBox(height: 16),
            _infoNote(
              offering.rentalUntil == null
                  ? 'Rent Tool offerings do not create a project. Set the '
                        'return date instead.'
                  : 'Rental ends on ${_formatDate(offering.rentalUntil!)} '
                        '(${_rentalDaysLabel(offering.rentalUntil!)}).',
              AppColors.primary,
            ),
          ],
          if (offering.clientHasRecentOffer) ...[
            const SizedBox(height: 12),
            _infoNote(
              'This client received another offer recently. Review for '
              'duplicate proposals before sending.',
              AppColors.pending,
            ),
          ],
        ],
      ),
    );
  }

  Widget _primaryAction(Offering offering) {
    if (offering.isRentalService) {
      if (offering.status != OfferingStatus.accepted) {
        return _primaryButton(
          icon: Icons.thumb_up_alt_outlined,
          label: 'Accept Offering',
          onTap: () => _updateStatus(OfferingStatus.accepted),
        );
      }
      return _primaryButton(
        icon: offering.rentalUntil == null
            ? Icons.event_available_outlined
            : Icons.edit_calendar_outlined,
        label: offering.rentalUntil == null
            ? 'Set Rental Until'
            : 'Update Rental Until',
        onTap: _setRentalUntil,
      );
    }

    if (offering.status == OfferingStatus.draft ||
        offering.status == OfferingStatus.sent) {
      return _primaryButton(
        icon: Icons.thumb_up_alt_outlined,
        label: 'Accept Offering',
        onTap: () => _updateStatus(OfferingStatus.accepted),
      );
    }

    if (offering.status == OfferingStatus.accepted) {
      if (offering.projectId != null) {
        return _primaryButton(
          icon: Icons.folder_open_outlined,
          label: 'Open Project',
          onTap: () =>
              context.push(AppRouter.projectDetail(offering.projectId!)),
        );
      }
      return _primaryButton(
        icon: Icons.rocket_launch_outlined,
        label: 'Create Project',
        onTap: () => context.push(AppRouter.newProject(offering.id)),
      );
    }

    return _primaryButton(
      icon: Icons.send_outlined,
      label: 'Mark as Sent',
      onTap: () => _updateStatus(OfferingStatus.sent),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _secondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label),
      ),
    );
  }

  Widget _statusActionChip(Offering offering, OfferingStatus status) {
    final current = offering.status == status;
    final color = status.color;
    return Material(
      color: current
          ? color.withValues(alpha: 0.1)
          : AppColors.background.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: current ? null : () => _updateStatus(status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: current ? color.withValues(alpha: 0.45) : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (current)
                Icon(Icons.check, size: 13, color: color)
              else
                Icon(_statusIcon(status), size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                status.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: current ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentActivityCard(Offering offering) {
    final activities = context.watch<ProjectProvider>().activitiesFor(
      offering.id,
    );
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Recent Activity')),
              if (activities.isNotEmpty)
                Text(
                  '${activities.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No activity recorded yet.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else
            for (var i = 0; i < activities.length; i++)
              _activityItem(activities[i], isLast: i == activities.length - 1),
        ],
      ),
    );
  }

  Widget _activityItem(OfferingActivity item, {required bool isLast}) {
    return Container(
      padding: EdgeInsets.only(top: 12, bottom: isLast ? 2 : 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: item.type.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.type.icon, size: 16, color: item.type.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _activityTimestamp(item.occurredAt),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (item.actor?.isNotEmpty ?? false)
                Text(
                  'by ${item.actor}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
