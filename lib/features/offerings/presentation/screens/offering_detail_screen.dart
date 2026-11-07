import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/activity.dart';
import '../../../../domain/models/offering.dart';
import '../../../../domain/models/offering_line_item.dart';
import '../../../../domain/models/offering_term.dart';
import '../../../../domain/models/payment.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../../../data/clients/client_directory.dart';
import '../../../invoices/services/invoice_download.dart';
import '../../../invoices/services/invoice_numbering.dart';
import '../../../invoices/services/invoice_pdf.dart';
import '../../../invoices/services/invoice_rental_pdf.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../../domain/rules/offering_line_items.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/utils/status_extensions.dart';
import '../../../../core/widgets/status_chip.dart';

part 'offering_detail/sections/layout_sections.dart';
part 'offering_detail/sections/overview_sections.dart';
part 'offering_detail/sections/description_sections.dart';
part 'offering_detail/sections/client_payment_sections.dart';
part 'offering_detail/sections/actions_sections.dart';
part 'offering_detail/sections/formatting_helpers.dart';
part 'offering_detail/widgets/po_details_dialog.dart';
part 'offering_detail/widgets/payment_dialog.dart';
part 'offering_detail/widgets/eyebrow.dart';
part 'offering_detail/widgets/description_header.dart';
part 'offering_detail/widgets/map_placeholder.dart';
part 'offering_detail/widgets/map_grid_painter.dart';

const Object _fullInvoiceChoice = Object();

/// Offering detail page styled as a responsive management dashboard.
///
/// The offering, client, payment, and project data are real. Contact details
/// fall back to demo values and the activity feed is demo content until
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
    final issuedAt = DateTime.now();
    final rentalInvoiceNumber = offering.isRentalService
        ? _buildRentalInvoiceNumber(
            context.read<ProjectProvider>().offerings,
            offering,
            issuedAt,
          )
        : null;
    OfferingTerm? selectedTerm;
    if (offering.terms.isNotEmpty) {
      final choice = await showDialog<Object?>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Choose invoice'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose the full offering or a payment milestone.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _invoiceChoiceTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Full offering invoice',
                  subtitle: 'Entire contract amount',
                  amount: offering.budgetAmount,
                  onTap: () => Navigator.pop(dialogContext, _fullInvoiceChoice),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final term in offering.terms) ...[
                          _invoiceChoiceTile(
                            icon: Icons.payments_outlined,
                            title: term.name,
                            subtitle:
                                '${term.percentage.toStringAsFixed(term.percentage % 1 == 0 ? 0 : 1)}% of offering',
                            amount: term.amount,
                            onTap: () => Navigator.pop(dialogContext, term),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      if (choice is OfferingTerm) selectedTerm = choice;
      if (!mounted) return;
    }

    _PoDetails? poDetails;
    if (selectedTerm != null) {
      poDetails = await showDialog<_PoDetails>(
        context: context,
        builder: (_) => const _PoDetailsDialog(),
      );
      if (poDetails == null || !mounted) return;
    }

    setState(() => _downloadingInvoice = true);
    try {
      final client = offering.clientId == null
          ? ClientDirectory.findByName(offering.owner)
          : ClientDirectory.findById(offering.clientId!);
      final payments = _payments
          .where((payment) => payment.offeringId == offering.id)
          .toList();
      final bytes = offering.isRentalService
          ? await buildRentalInvoicePdf(
              offering: offering,
              clientName: _rentalRecipient(offering, client),
              invoiceNumber: rentalInvoiceNumber!,
              issuedAt: issuedAt,
              bankName: client?.bankName ?? '',
              bankAccountNumber: client?.bankAccountNumber ?? '',
              bankAccountName: client?.bankAccountName ?? '',
            )
          : await buildOfferingInvoicePdf(
              offering: offering,
              client: client,
              payments: payments,
              invoiceSequence: selectedTerm == null
                  ? 1
                  : offering.terms.indexOf(selectedTerm) + 2,
              poNumber: poDetails?.number ?? '',
              poDate: poDetails?.date,
              invoiceTitle: selectedTerm == null ? 'INVOICE' : 'INVOICE TERMIN',
              invoiceSubtitle: selectedTerm == null
                  ? 'TAGIHAN'
                  : 'TAGIHAN ${selectedTerm.name}',
              invoiceAmount: selectedTerm?.amount,
            );
      final saved = await saveInvoiceFile(
        fileName: selectedTerm == null
            ? invoicePdfFileName(offering)
            : '${invoicePdfFileName(offering).replaceAll('.pdf', '')}-${selectedTerm.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').toLowerCase()}.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      if (!mounted) return;
      if (saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invoice PDF downloaded')));
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
      clientId: offering.clientId,
      address: offering.address,
      latitude: offering.latitude,
      longitude: offering.longitude,
      status: status ?? offering.status,
      paidStatus: paidStatus ?? offering.paidStatus,
      budgetAmount: offering.budgetAmount,
      lineItems: offering.lineItems,
      terms: offering.terms,
      rentalItems: offering.rentalItems,
      numberingStyle: offering.numberingStyle,
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

  static const List<OfferingStatus> _statusActions = [
    OfferingStatus.sent,
    OfferingStatus.accepted,
    OfferingStatus.rejected,
    OfferingStatus.expired,
  ];
}
