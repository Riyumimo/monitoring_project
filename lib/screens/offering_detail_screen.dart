import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/offering.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../utils/status_extensions.dart';
import '../widgets/status_chip.dart';

class OfferingDetailScreen extends StatefulWidget {
  final String id;
  final int initialTab;

  const OfferingDetailScreen({
    super.key,
    required this.id,
    this.initialTab = 0,
  });

  @override
  State<OfferingDetailScreen> createState() => _OfferingDetailScreenState();
}

class _OfferingDetailScreenState extends State<OfferingDetailScreen> {
  late Offering _offering;

  Offering? _lookup() =>
      context.watch<ProjectProvider>().offeringById(widget.id);

  bool get _isManager => context.read<AuthProvider>().userRole == 'Manager';

  String get _budgetLabel => formatRupiah(_offering.budgetAmount);

  String get _coordinateLabel {
    if (_offering.isCalibrationService) return 'Office calibration';
    final latitude = _offering.latitude;
    final longitude = _offering.longitude;
    if (latitude == null || longitude == null) return '—';
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  String get _rentalUntilLabel {
    final value = _offering.rentalUntil;
    return value == null ? 'Not set' : _dateLabel(value);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboard);
    }
  }

  Future<DateTime?> _pickRentalUntil() async {
    var selected =
        _offering.rentalUntil ?? DateTime.now().add(const Duration(days: 7));
    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rental until date'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rent Tool offerings do not create a project. Choose the '
                      'date when the rented tools must be returned.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _rentalDateField(
                      value: selected,
                      onPick: (date) => setDialogState(() => selected = date),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, selected),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateStatus(OfferingStatus status) async {
    DateTime? rentalUntil;
    if (status == OfferingStatus.accepted &&
        _offering.isRentalService &&
        _offering.rentalUntil == null) {
      rentalUntil = await _pickRentalUntil();
      if (rentalUntil == null || !mounted) return;
    }

    final updated = _copyWith(
      _offering,
      status: status,
      rentalUntil: rentalUntil,
    );
    try {
      await context.read<ProjectProvider>().updateOffering(updated);
      if (mounted) {
        setState(() => _offering = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${status.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _setRentalUntil() async {
    final picked = await _pickRentalUntil();
    if (picked == null || !mounted) return;

    final updated = _copyWith(_offering, rentalUntil: picked);
    try {
      await context.read<ProjectProvider>().updateOffering(updated);
      if (!mounted) return;
      setState(() => _offering = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rental until date set to ${_dateLabel(picked)}'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Offering _copyWith(
    Offering offering, {
    OfferingStatus? status,
    String? projectId,
    DateTime? rentalUntil,
  }) {
    return Offering(
      id: offering.id,
      number: offering.number,
      name: offering.name,
      serviceType: offering.serviceType,
      owner: offering.owner,
      address: offering.address,
      latitude: offering.latitude,
      longitude: offering.longitude,
      status: status ?? offering.status,
      paidStatus: offering.paidStatus,
      budgetAmount: offering.budgetAmount,
      rentalUntil: rentalUntil ?? offering.rentalUntil,
      projectId: projectId ?? offering.projectId,
    );
  }

  String _dateLabel(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final offering = _lookup();
    if (offering == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offering')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Offering not found.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    _offering = offering;

    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _hero()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Location'),
                    Tab(text: 'Payment'),
                    Tab(text: 'Actions'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _detailsTab(),
              _locationTab(),
              _paymentTab(),
              _actionsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _goBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    if (_isManager)
                      IconButton(
                        tooltip: 'Edit offering',
                        onPressed: () =>
                            context.push(AppRouter.offeringEdit(_offering.id)),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _offering.number.isEmpty
                              ? 'OFFERING'
                              : 'OFFERING ${_offering.number}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _offering.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (_offering.serviceType.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _offering.serviceType,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          label: _offering.status.label,
                          color: Colors.white,
                        ),
                        StatusChip(
                          label: _offering.paidStatus.label,
                          color: Colors.white,
                          icon: Icons.payments_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryGrid(),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Offering Information',
          children: [
            _infoRow(
              Icons.tag,
              'Offering No',
              _offering.number.isEmpty ? '—' : _offering.number,
            ),
            _infoRow(
              Icons.work_outline,
              'Service Type',
              _offering.serviceType.isEmpty ? '—' : _offering.serviceType,
            ),
            if (_offering.isRentalService)
              _infoRow(Icons.event_outlined, 'Rental Until', _rentalUntilLabel),
            _infoRow(Icons.payments_outlined, 'Budget', _budgetLabel),
            _infoRow(Icons.my_location, 'Coordinates', _coordinateLabel),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Client Information',
          children: [
            _infoRow(Icons.apartment, 'Client', _offering.owner),
            _infoRow(Icons.place_outlined, 'Address', _offering.address),
            if (_offering.clientHasRecentOffer)
              _infoRow(
                Icons.history,
                'Recent Offer',
                'Client has another recent offer',
              ),
          ],
        ),
      ],
    );
  }

  Widget _summaryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _statTile(
              width: tileWidth,
              icon: Icons.flag_outlined,
              label: 'Status',
              value: _offering.status.label,
              color: _offering.status.color,
            ),
            _statTile(
              width: tileWidth,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payment',
              value: _offering.paidStatus.label,
              color: _offering.paidStatus.color,
            ),
            _statTile(
              width: tileWidth,
              icon: Icons.payments_outlined,
              label: 'Budget',
              value: _budgetLabel,
              color: AppColors.primary,
            ),
            if (_offering.isRentalService)
              _statTile(
                width: tileWidth,
                icon: Icons.event_outlined,
                label: 'Rental until',
                value: _rentalUntilLabel,
                color: _offering.rentalUntil == null
                    ? AppColors.pending
                    : AppColors.primary,
              )
            else
              _statTile(
                width: tileWidth,
                icon: Icons.folder_outlined,
                label: 'Project',
                value: _offering.hasProject ? 'Created' : 'Not created',
                color: _offering.hasProject
                    ? AppColors.completed
                    : AppColors.textSecondary,
              ),
          ],
        );
      },
    );
  }

  Widget _statTile({
    required double width,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationTab() {
    if (_offering.isCalibrationService) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business_outlined, size: 40, color: AppColors.primary),
              SizedBox(height: 12),
              Text(
                'Calibration service is performed at the office.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'No survey coordinates are required for this offering.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final hasLocation =
        _offering.latitude != null && _offering.longitude != null;
    if (!hasLocation) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No coordinates recorded for this offering.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final point = LatLng(_offering.latitude!, _offering.longitude!);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Coordinates',
          children: [
            _infoRow(
              Icons.my_location,
              'Latitude',
              _offering.latitude!.toStringAsFixed(5),
            ),
            _infoRow(
              Icons.explore_outlined,
              'Longitude',
              _offering.longitude!.toStringAsFixed(5),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(initialCenter: point, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.geoterra_monitoring',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 44,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _offering.paidStatus.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _offering.paidStatus.color,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _offering.paidStatus.label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _offering.paidStatus.color,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Current payment status',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Billing Summary',
          children: [
            _infoRow(
              Icons.tag,
              'Offering No',
              _offering.number.isEmpty ? '—' : _offering.number,
            ),
            _infoRow(Icons.receipt_long_outlined, 'Offering', _offering.name),
            _infoRow(Icons.person_outline, 'Billed to', _offering.owner),
            _infoRow(Icons.payments_outlined, 'Budget', _budgetLabel),
            _infoRow(Icons.circle, 'Payment', _offering.paidStatus.label),
          ],
        ),
      ],
    );
  }

  Widget _actionsTab() {
    final status = _offering.status;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (status == OfferingStatus.draft ||
            status == OfferingStatus.sent) ...[
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(OfferingStatus.accepted),
              icon: const Icon(Icons.thumb_up_alt_outlined),
              label: const Text('Accept Offering'),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (_offering.isRentalService)
          _rentalSection(status)
        else
          _projectSection(status),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Update Status',
          children: [
            _statusOption(
              OfferingStatus.sent,
              Icons.send_outlined,
              'Mark as Sent',
            ),
            _statusOption(
              OfferingStatus.accepted,
              Icons.thumb_up_alt_outlined,
              'Mark as Accepted',
            ),
            _statusOption(
              OfferingStatus.rejected,
              Icons.cancel_outlined,
              'Reject',
            ),
            _statusOption(
              OfferingStatus.expired,
              Icons.history,
              'Mark as Expired',
            ),
          ],
        ),
      ],
    );
  }

  Widget _rentalSection(OfferingStatus status) {
    final until = _offering.rentalUntil;
    final accepted = status == OfferingStatus.accepted;

    return _sectionCard(
      title: 'Rental Period',
      children: [
        _infoNote(
          'Rent Tool offerings do not create a project. Set the date when the '
          'rental ends instead.',
          AppColors.primary,
        ),
        const SizedBox(height: 14),
        _infoRow(
          Icons.event_outlined,
          'Until Date',
          until == null ? 'Not set yet' : _dateLabel(until),
        ),
        if (!accepted) ...[
          _infoNote(
            'Accept this offering to confirm the rental.',
            AppColors.pending,
          ),
          const SizedBox(height: 14),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: until == null
              ? FilledButton.icon(
                  onPressed: _setRentalUntil,
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: const Text('Set Until Date'),
                )
              : OutlinedButton.icon(
                  onPressed: _setRentalUntil,
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text('Update Until Date'),
                ),
        ),
      ],
    );
  }

  Widget _projectSection(OfferingStatus status) {
    if (_offering.projectId != null) {
      return _sectionCard(
        title: 'Project',
        children: [
          const Text(
            'A project has been created from this offering.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.push(AppRouter.projectDetail(_offering.projectId!)),
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: const Text('Open Project'),
            ),
          ),
        ],
      );
    }

    if (status != OfferingStatus.accepted) {
      return _sectionCard(
        title: 'Project',
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pending.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.pending.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.pending),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A project can only be created once this offering is accepted.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pending,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _sectionCard(
      title: 'Project',
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () => context.push(AppRouter.newProject(_offering.id)),
            icon: const Icon(Icons.rocket_launch_outlined, size: 18),
            label: const Text('Create Project'),
          ),
        ),
      ],
    );
  }

  Widget _statusOption(OfferingStatus status, IconData icon, String label) {
    final isCurrent = _offering.status == status;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isCurrent ? null : () => _updateStatus(status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent ? status.color : AppColors.border,
              width: isCurrent ? 1.5 : 1,
            ),
            color: isCurrent
                ? status.color.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: status.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isCurrent)
                Text(
                  'Current',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status.color,
                  ),
                ),
            ],
          ),
        ),
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
          _dateLabel(value),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _infoNote(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 0.5;

  @override
  double get maxExtent => tabBar.preferredSize.height + 0.5;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.surface,
      child: Column(children: [tabBar, const Divider(height: 1)]),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
