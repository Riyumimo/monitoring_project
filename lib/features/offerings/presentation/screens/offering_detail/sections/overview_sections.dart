part of '../../offering_detail_screen.dart';

extension _OverviewSections on _OfferingDetailScreenState {
  Widget _overviewCard(Offering offering) {
    return _card(
      stripe: offering.status.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: _Eyebrow('Offering Overview')),
                  Text(
                    offering.number.isEmpty
                        ? 'OFFERING'
                        : 'OFFERING ${offering.number}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                offering.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  letterSpacing: -0.4,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                offering.owner.isEmpty
                    ? 'No client recorded'
                    : 'Prepared for ${offering.owner}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _infoBar(
                icon: Icons.payments_outlined,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatRupiah(offering.budgetAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _infoBar(
                icon: Icons.place_outlined,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        offering.address.isEmpty
                            ? 'No address recorded'
                            : offering.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _navButton(),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(
                  label: offering.status.label,
                  color: offering.status.color,
                ),
                _miniPill(offering.paidStatus.label, offering.paidStatus.color),
                if (offering.serviceType.isNotEmpty)
                  _miniPill(offering.serviceType, AppColors.accepted),
                if (offering.clientHasRecentOffer)
                  _miniPill('Recent offer on file', AppColors.pending),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(Offering offering) {
    final projectValue = offering.isRentalService
        ? _rentalUntilLabel(offering)
        : offering.hasProject
        ? 'Created'
        : offering.status == OfferingStatus.accepted
        ? 'Ready to create'
        : 'Not created';
    final projectIcon = offering.isRentalService
        ? Icons.event_outlined
        : Icons.folder_outlined;
    final projectColor = offering.isRentalService
        ? (offering.rentalUntil == null ? AppColors.pending : AppColors.primary)
        : offering.hasProject
        ? AppColors.completed
        : offering.status == OfferingStatus.accepted
        ? AppColors.pending
        : AppColors.textSecondary;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Status & Metadata'),
          const SizedBox(height: 14),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _metricCell(
                          label: 'Status',
                          icon: _statusIcon(offering.status),
                          value: offering.status.label,
                          color: offering.status.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricCell(
                          label: 'Service',
                          icon: Icons.layers_outlined,
                          value: offering.serviceType.isEmpty
                              ? '—'
                              : offering.serviceType,
                          color: AppColors.accepted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _metricCell(
                          label: 'Budget',
                          icon: Icons.payments_outlined,
                          value: formatRupiah(offering.budgetAmount),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricCell(
                          label: offering.isRentalService
                              ? 'Rental Until'
                              : 'Project',
                          icon: projectIcon,
                          value: projectValue,
                          color: projectColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCell({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapCard(Offering offering) {
    final hasLocation = offering.latitude != null && offering.longitude != null;
    final point = hasLocation
        ? LatLng(offering.latitude!, offering.longitude!)
        : null;

    return _card(
      key: _mapKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Site Location')),
              _locationBadge(offering, hasLocation),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: offering.isCalibrationService
                  ? const _MapPlaceholder(
                      icon: Icons.business_outlined,
                      title: 'Office Calibration',
                      subtitle:
                          'This service is performed at the office, so no '
                          'survey coordinates are required.',
                    )
                  : point == null
                  ? _MapPlaceholder(
                      icon: offering.isRentalService
                          ? Icons.build_circle_outlined
                          : Icons.location_off_outlined,
                      title: offering.isRentalService
                          ? 'Rental Service'
                          : 'No coordinates recorded',
                      subtitle: offering.isRentalService
                          ? 'No survey site is required for this rental '
                                'offering.'
                          : 'Add a location to this offering to see it here.',
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: point,
                              initialZoom: 14,
                              minZoom: 3,
                              maxZoom: 18,
                              interactionOptions: const InteractionOptions(
                                flags:
                                    InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.geoterra_monitoring',
                                maxZoom: 19,
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: point,
                                    width: 54,
                                    height: 54,
                                    child: Icon(
                                      Icons.location_on,
                                      size: 46,
                                      color: AppColors.onHold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.22,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Column(
                            children: [
                              _mapControlButton(
                                icon: Icons.add,
                                tooltip: 'Zoom in',
                                onTap: () => _zoomMap(1),
                              ),
                              const SizedBox(height: 6),
                              _mapControlButton(
                                icon: Icons.remove,
                                tooltip: 'Zoom out',
                                onTap: () => _zoomMap(-1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _zoomMap(double delta) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + delta).clamp(3.0, 18.0));
  }

  Widget _mapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 16, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _locationBadge(Offering offering, bool hasLocation) {
    final color = offering.isCalibrationService
        ? AppColors.primary
        : hasLocation
        ? AppColors.completed
        : offering.isRentalService
        ? AppColors.primary
        : AppColors.textSecondary;
    final label = offering.isCalibrationService
        ? 'Office Based'
        : hasLocation
        ? 'Verified Location'
        : offering.isRentalService
        ? 'Rental Service'
        : 'No Coordinates';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rentalDateField({
    required DateTime value,
    required ValueChanged<DateTime> onPick,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Until Date',
          prefixIcon: Icon(Icons.event_outlined),
        ),
        child: Text(
          _formatDate(value),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  String _rentalUntilLabel(Offering offering) {
    final value = offering.rentalUntil;
    return value == null ? 'Not set' : _formatDate(value);
  }

  String _rentalDaysLabel(DateTime value) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final target = DateTime(value.year, value.month, value.day);
    final days = target.difference(startOfToday).inDays;
    if (days == 0) return 'due today';
    if (days > 0) return '$days day${days == 1 ? '' : 's'} left';
    final overdue = days.abs();
    return '$overdue day${overdue == 1 ? '' : 's'} overdue';
  }
}
