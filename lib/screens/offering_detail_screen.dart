import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../models/offering.dart';
import '../models/payment.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../router/app_router.dart';
import '../services/client_directory.dart';
import '../services/invoice_pdf.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../utils/status_extensions.dart';
import '../widgets/status_chip.dart';

/// Offering detail page styled as a responsive management dashboard.
///
/// The offering, client, payment, and project data are real. Contact details
/// fall back to demo values and the notes/activity feed is demo content until
/// those modules are backed by the API.
class OfferingDetailScreen extends StatefulWidget {
  final String id;

  /// Legacy deep-link section: 0 details, 1 map, 2 payment, 3 actions.
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
  static const double _contentMaxWidth = 1240;

  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey _paymentKey = GlobalKey();
  final GlobalKey _actionsKey = GlobalKey();
  final MapController _mapController = MapController();

  late Offering _offering;
  late List<_OfferingNote> _notes;
  bool _didInitialScroll = false;
  bool _didEnsureActivities = false;
  bool _downloadingInvoice = false;

  /// Payments recorded from this screen during the current session, newest
  /// last. They back the payment history in the activity feed.
  final List<Payment> _payments = [];

  Offering? _lookup() =>
      context.watch<ProjectProvider>().offeringById(widget.id);

  bool get _isManager => context.read<AuthProvider>().userRole == 'Manager';

  @override
  void initState() {
    super.initState();
    _notes = [
      _OfferingNote(
        title: 'Scope walkthrough completed',
        category: 'General',
        program: 'Survey',
        updated: DateTime(2026, 6, 24, 18, 48),
        body:
            'The proposed scope and deliverables were reviewed with the '
            'client. Field access and reporting expectations are confirmed.',
      ),
      _OfferingNote(
        title: 'Awaiting revised budget',
        category: 'Client',
        program: 'Commercial',
        updated: DateTime(2026, 6, 24, 15, 20),
        body:
            'The client requested a small revision to the survey area. An '
            'updated budget is being prepared before the proposal is re-sent.',
      ),
      _OfferingNote(
        title: 'Equipment availability checked',
        category: 'Equipment',
        program: 'Operations',
        updated: DateTime(2026, 6, 23, 9, 5),
        body:
            'GPS receivers and the total station are available for the '
            'proposed schedule. No equipment conflicts were found.',
      ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectProvider>().ensureProjectsLoaded();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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
    if (_offering.status == status) return;

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
      final provider = context.read<ProjectProvider>();
      await provider.updateOffering(updated);
      if (!mounted) return;
      await provider.addActivity(_statusActivity(updated, status));
      if (!mounted) return;
      setState(() => _offering = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${status.label}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          content: Text('Rental until date set to ${_formatDate(picked)}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _recordPayment() async {
    final remaining = _offering.remainingAmount;
    if (remaining == null || remaining <= 0) return;

    final input = await showDialog<_PaymentResult>(
      context: context,
      builder: (_) => _PaymentDialog(remaining: remaining),
    );

    if (input == null || !mounted) return;

    final now = DateTime.now();
    final payment = Payment(
      id: 'PAY-${now.millisecondsSinceEpoch}',
      offeringId: _offering.id,
      amount: input.amount,
      paidAt: now,
      method: input.method,
      note: input.note,
      invoiceNumber: input.invoiceNumber,
      proofName: input.proofName,
      proofPath: input.proofPath,
    );

    final total = _offering.amountPaid + payment.amount;
    final budget = _offering.budgetAmount ?? 0;
    final paidStatus = total <= 0
        ? PaidStatus.unpaid
        : budget > 0 && total >= budget
        ? PaidStatus.paid
        : PaidStatus.partiallyPaid;
    final updated = _copyWith(
      _offering,
      amountPaid: total,
      paidStatus: paidStatus,
    );

    final becameFullyPaid =
        paidStatus == PaidStatus.paid &&
        _offering.paidStatus != PaidStatus.paid;

    try {
      final provider = context.read<ProjectProvider>();
      await provider.updateOffering(updated);
      if (!mounted) return;
      await provider.addActivity(_paymentActivityEntry(updated, payment));
      if (becameFullyPaid) {
        await provider.addActivity(
          _paymentCompletedActivity(
            updated,
            payment.paidAt.add(const Duration(milliseconds: 1)),
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _offering = updated;
        _payments.add(payment);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of ${formatRupiah(payment.amount)} recorded'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _downloadInvoice(Offering offering) async {
    if (_downloadingInvoice) return;
    setState(() => _downloadingInvoice = true);
    try {
      final client = ClientDirectory.findByName(offering.owner);
      final payments = _payments
          .where((payment) => payment.offeringId == offering.id)
          .toList();
      final bytes = await buildOfferingInvoicePdf(
        offering: offering,
        client: client,
        payments: payments,
      );
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save invoice',
        fileName: invoicePdfFileName(offering),
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      if (!mounted) return;
      if (kIsWeb || saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice PDF downloaded')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create invoice: $error')),
      );
    } finally {
      if (mounted) setState(() => _downloadingInvoice = false);
    }
  }

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

  Offering _copyWith(
    Offering offering, {
    OfferingStatus? status,
    PaidStatus? paidStatus,
    double? amountPaid,
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
      paidStatus: paidStatus ?? offering.paidStatus,
      budgetAmount: offering.budgetAmount,
      amountPaid: amountPaid ?? offering.amountPaid,
      clientHasRecentOffer: offering.clientHasRecentOffer,
      rentalUntil: rentalUntil ?? offering.rentalUntil,
      projectId: projectId ?? offering.projectId,
    );
  }

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showOnMap() async {
    final target = _mapKey.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.15,
    );
  }

  void _ensureActivities(Offering offering) {
    if (_didEnsureActivities) return;
    _didEnsureActivities = true;
    final client = ClientDirectory.findByName(offering.owner);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProjectProvider>().ensureActivities(
        offering,
        contactName: client?.contactPerson,
      );
    });
  }

  void _scheduleInitialScroll() {
    if (_didInitialScroll || widget.initialTab == 0) return;
    _didInitialScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = switch (widget.initialTab) {
        1 => _mapKey,
        2 => _paymentKey,
        3 => _actionsKey,
        _ => null,
      };
      final target = key?.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      );
    });
  }

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
    _ensureActivities(offering);
    _scheduleInitialScroll();

    final client = ClientDirectory.findByName(offering.owner);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offering Details'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (_isManager)
            IconButton(
              tooltip: 'Edit offering',
              onPressed: () =>
                  context.push(AppRouter.offeringEdit(offering.id)),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (offering.projectId != null)
            IconButton(
              tooltip: 'Open project',
              onPressed: () =>
                  context.push(AppRouter.projectDetail(offering.projectId!)),
              icon: const Icon(Icons.folder_open_outlined),
            ),
          IconButton(
            tooltip: 'Download invoice',
            onPressed: _downloadingInvoice
                ? null
                : () => _downloadInvoice(offering),
            icon: _downloadingInvoice
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
          ),
          PopupMenuButton<OfferingStatus>(
            tooltip: 'Update status',
            icon: const Icon(Icons.flag_outlined),
            onSelected: _updateStatus,
            itemBuilder: (context) => [
              for (final status in _statusActions)
                PopupMenuItem<OfferingStatus>(
                  value: status,
                  child: Row(
                    children: [
                      Icon(_statusIcon(status), size: 18, color: status.color),
                      const SizedBox(width: 10),
                      Expanded(child: Text(status.label)),
                      if (offering.status == status)
                        const Icon(Icons.check, size: 17),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1024;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                  child: wide
                      ? _wideLayout(offering, client)
                      : _narrowLayout(offering, client),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _wideLayout(Offering offering, ClientRecord? client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: SizedBox(height: 340, child: _overviewCard(offering)),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: SizedBox(height: 340, child: _mapCard(offering)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 300,
                child: _clientCard(offering, client),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: SizedBox(height: 300, child: _paymentCard(offering)),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: SizedBox(height: 300, child: _statusCard(offering)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _actionsCard(offering)),
            const SizedBox(width: 24),
            Expanded(flex: 7, child: _notesCard(offering)),
          ],
        ),
      ],
    );
  }

  Widget _narrowLayout(Offering offering, ClientRecord? client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overviewCard(offering),
        const SizedBox(height: 20),
        SizedBox(height: 260, child: _mapCard(offering)),
        const SizedBox(height: 20),
        _clientCard(offering, client),
        const SizedBox(height: 20),
        _paymentCard(offering),
        const SizedBox(height: 20),
        SizedBox(height: 270, child: _statusCard(offering)),
        const SizedBox(height: 20),
        _actionsCard(offering),
        const SizedBox(height: 20),
        _notesCard(offering),
      ],
    );
  }

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
                _downloadingInvoice ? 'Preparing invoice...' : 'Download Invoice',
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
              for (final status in _statusActions)
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

  Widget _notesCard(Offering offering) {
    final activities = context
        .watch<ProjectProvider>()
        .activitiesFor(offering.id);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Notes & Activity')),
              TextButton.icon(
                onPressed: _addNote,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.inProgress,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Add Note',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          for (var i = 0; i < _notes.length; i++)
            _noteItem(_notes[i], isLast: i == _notes.length - 1),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          const _Eyebrow('Recent Activity'),
          const SizedBox(height: 4),
          for (var i = 0; i < activities.length; i++)
            _activityItem(activities[i], isLast: i == activities.length - 1),
        ],
      ),
    );
  }

  Widget _noteItem(_OfferingNote note, {required bool isLast}) {
    return Container(
      padding: EdgeInsets.only(top: 14, bottom: isLast ? 2 : 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Program: ${note.program}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _noteTimestamp(note.updated),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            note.body,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
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
            child: Icon(
              item.type.icon,
              size: 16,
              color: item.type.color,
            ),
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

  OfferingActivity _noteActivity(_OfferingNote note) {
    return OfferingActivity(
      id: 'ACT-${note.updated.microsecondsSinceEpoch}',
      offeringId: _offering.id,
      type: ActivityType.note,
      title: note.title,
      subtitle: note.body.isEmpty ? 'Note added to this offering' : note.body,
      occurredAt: note.updated,
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

  Future<void> _addNote() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    titleController.dispose();
    bodyController.dispose();

    if (added != true || !mounted) return;
    if (title.isEmpty && body.isEmpty) return;

    final note = _OfferingNote(
      title: title.isEmpty ? 'Untitled note' : title,
      category: 'General',
      program: 'Offering',
      updated: DateTime.now(),
      body: body,
    );
    setState(() => _notes.insert(0, note));
    await context.read<ProjectProvider>().addActivity(_noteActivity(note));
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

  Widget _navButton() {
    return Tooltip(
      message: 'Show on map',
      child: Material(
        color: AppColors.inProgress.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: _showOnMap,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.navigation_outlined,
              size: 17,
              color: AppColors.inProgress,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBar({required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 11),
          Expanded(child: child),
        ],
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _card({Key? key, required Widget child, Color? stripe}) {
    final content = stripe == null
        ? Padding(padding: const EdgeInsets.all(22), child: child)
        : Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: ColoredBox(color: stripe),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 22, 22),
                child: child,
              ),
            ],
          );

    return Container(
      key: key,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.018),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: content,
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

  String _noteTimestamp(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour24 = value.hour;
    final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    return 'Updated ${weekdays[value.weekday - 1]} ${value.month}/${value.day} '
        '$hour:$minute $suffix';
  }

  static const List<OfferingStatus> _statusActions = [
    OfferingStatus.sent,
    OfferingStatus.accepted,
    OfferingStatus.rejected,
    OfferingStatus.expired,
  ];

  IconData _statusIcon(OfferingStatus status) => switch (status) {
    OfferingStatus.draft => Icons.edit_note,
    OfferingStatus.sent => Icons.send_outlined,
    OfferingStatus.accepted => Icons.thumb_up_alt_outlined,
    OfferingStatus.rejected => Icons.cancel_outlined,
    OfferingStatus.expired => Icons.history,
  };
}

typedef _PaymentResult = ({
  double amount,
  PaymentMethod method,
  String note,
  String invoiceNumber,
  String proofName,
  String? proofPath,
});

class _PaymentDialog extends StatefulWidget {
  final double remaining;

  const _PaymentDialog({required this.remaining});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _noteController = TextEditingController();
  final _invoiceController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  PlatformFile? _proofFile;

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop<_PaymentResult>(context, (
        amount: parseRupiah(_controller.text)!,
        method: _method,
        note: _noteController.text.trim(),
        invoiceNumber: _invoiceController.text.trim(),
        proofName: _proofFile?.name ?? '',
        proofPath: _proofFile?.path,
      ));
    }
  }

  Future<void> _pickProof() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Select proof of payment',
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (file == null || !mounted) return;
      setState(() => _proofFile = file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not attach file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 520,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.paid.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      size: 20,
                      color: AppColors.paid,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Record payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _balanceChip(),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [RupiahInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Payment amount',
                        prefixText: 'Rp ',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (value) {
                        final parsed = parseRupiah(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid payment amount';
                        }
                        if (parsed > widget.remaining) {
                          return 'Amount exceeds the remaining balance';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _invoiceController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Invoice number (optional)',
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'PAYMENT METHOD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final method in PaymentMethod.values)
                          _methodChip(method),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Reference / note (optional)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PROOF OF PAYMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _proofPicker(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Add Payment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceChip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 17,
            color: AppColors.paid,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Remaining balance',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            formatRupiah(widget.remaining),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodChip(PaymentMethod method) {
    final selected = _method == method;
    final color = selected ? AppColors.paid : AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _method = method),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.paid.withValues(alpha: 0.1)
                : AppColors.background.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.paid.withValues(alpha: 0.5)
                  : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_methodIcon(method), size: 16, color: color),
              const SizedBox(width: 7),
              Text(
                method.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check, size: 14, color: AppColors.paid),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _methodIcon(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.transfer => Icons.account_balance_outlined,
    PaymentMethod.other => Icons.more_horiz,
  };

  Widget _proofPicker() {
    final file = _proofFile;
    if (file == null) {
      return SizedBox(
        width: double.infinity,
        height: 40,
        child: OutlinedButton.icon(
          onPressed: _pickProof,
          icon: const Icon(Icons.attach_file, size: 16),
          label: const Text(
            'Attach invoice / transfer receipt',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.paid.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.paid.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_proofFileIcon(file), size: 18, color: AppColors.paid),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove proof',
            onPressed: () => setState(() => _proofFile = null),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  IconData _proofFileIcon(PlatformFile file) {
    final extension = (file.extension ?? '').toLowerCase();
    return switch (extension) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'png' || 'jpg' || 'jpeg' => Icons.image_outlined,
      _ => Icons.attach_file,
    };
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MapPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _MapGridPainter()),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 34,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.55)
      ..strokeWidth = 1;

    const step = 38.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) => false;
}

class _OfferingNote {
  final String title;
  final String category;
  final String program;
  final DateTime updated;
  final String body;

  const _OfferingNote({
    required this.title,
    required this.category,
    required this.program,
    required this.updated,
    required this.body,
  });
}
