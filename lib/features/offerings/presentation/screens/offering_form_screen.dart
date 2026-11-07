import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/line_item_number_style.dart';
import '../../../../domain/models/line_item_text_run.dart';
import '../../../../domain/models/offering.dart';
import '../../../../domain/models/rental_tool.dart';
import '../../../../domain/models/offering_line_item.dart';
import '../../../../domain/models/offering_term.dart';
import '../../providers/project_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../../../data/clients/client_directory.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../../domain/rules/offering_line_items.dart';
import '../../../../core/utils/rich_text_controller.dart';
import '../../../../core/widgets/rich_text_shortcuts.dart';

part 'offering_form/sections/form_helpers.dart';
part 'offering_form/sections/general_sections.dart';
part 'offering_form/sections/line_item_narrow_sections.dart';
part 'offering_form/sections/line_item_sections.dart';
part 'offering_form/sections/rental_editor_sections.dart';
part 'offering_form/sections/rental_sections.dart';
part 'offering_form/sections/terms_sections.dart';
part 'offering_form/widgets/line_item_draft.dart';
part 'offering_form/widgets/line_item_header_cell.dart';
part 'offering_form/widgets/term_draft.dart';

/// Create/edit an **offering** (the proposal sent to a client). Offers are
/// separate from projects: a project is created later, from an accepted
/// offering, with its own form.
class OfferingFormScreen extends StatefulWidget {
  final String? offeringId;

  const OfferingFormScreen({super.key, this.offeringId});

  @override
  State<OfferingFormScreen> createState() => _OfferingFormScreenState();
}

class _OfferingFormScreenState extends State<OfferingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _ownerController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final List<_LineItemDraft> _lineItems = [];
  final List<_TermDraft> _terms = [];
  final List<RentalOfferingItem> _rentalItems = [];

  OfferingStatus _status = OfferingStatus.draft;
  PaidStatus _paidStatus = PaidStatus.unpaid;
  LineItemNumberStyle _numberStyle = LineItemNumberStyle.numeric;
  DateTime? _rentalUntil;
  Offering? _editing;
  bool _isSaving = false;
  bool _useClientTable = true;
  bool _clientHasRecentOffer = false;
  int _clientOfferCount = 0;
  bool _isFindingCoordinates = false;
  String? _coordinateError;

  bool get _isEditing => widget.offeringId != null;

  /// Lets section extensions trigger rebuilds (`setState` is `@protected`).
  void _setState(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    final id = widget.offeringId;
    if (id == null) {
      _numberController.text = _nextNumber();
      _lineItems.add(_createLineItemDraft(numberText: '1'));
      return;
    }

    final provider = context.read<ProjectProvider>();
    final offering = provider.offeringById(id);
    if (offering != null) {
      _populate(offering);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<ProjectProvider>().ensureProjectsLoaded();
        if (!mounted) return;
        final loaded = context.read<ProjectProvider>().offeringById(id);
        if (loaded != null) {
          setState(() => _populate(loaded));
        }
      });
    }
  }

  String _nextNumber() {
    final count = context.read<ProjectProvider>().offerings.length;
    return 'OFF-${(count + 1).toString().padLeft(3, '0')}';
  }

  List<String> get _serviceTypeOptions {
    final current = _serviceTypeController.text.trim();
    return [
      ...MockData.serviceTypes,
      if (current.isNotEmpty && !MockData.serviceTypes.contains(current))
        current,
    ];
  }

  List<String> get _clientOptions {
    final names = [for (final client in ClientDirectory.all()) client.name];
    final current = _ownerController.text.trim();
    if (current.isNotEmpty && !names.contains(current)) names.add(current);
    return names;
  }

  int _offerCountFor(String clientName) {
    final target = clientName.trim().toLowerCase();
    if (target.isEmpty) return 0;
    return context
        .read<ProjectProvider>()
        .offerings
        .where(
          (offering) =>
              offering.id != _editing?.id &&
              offering.owner.trim().toLowerCase() == target,
        )
        .length;
  }

  void _toggleClientTable(bool useTable) {
    setState(() {
      _useClientTable = useTable;
      if (useTable) {
        final current = _ownerController.text.trim();
        if (ClientDirectory.findByName(current) == null) {
          _ownerController.clear();
          _clientOfferCount = 0;
          _clientHasRecentOffer = false;
        } else {
          _clientOfferCount = _offerCountFor(current);
          _clientHasRecentOffer = _clientOfferCount > 0;
        }
      } else {
        _ownerController.clear();
        _clientOfferCount = 0;
        _clientHasRecentOffer = false;
      }
    });
  }

  bool get _isCalibrationService =>
      _serviceTypeController.text.toLowerCase().contains('calibrat');

  bool get _isRentalService =>
      _serviceTypeController.text.toLowerCase().trim().startsWith('rent');

  void _populate(Offering offering) {
    _editing = offering;
    _rentalItems
      ..clear()
      ..addAll(offering.rentalItems);
    _numberController.text = offering.number;
    _nameController.text = offering.name;
    _serviceTypeController.text = offering.serviceType;
    _ownerController.text = offering.owner;
    _addressController.text = offering.address;
    _setLineItems(offering);
    _terms.clear();
    for (final term in offering.terms) {
      _terms.add(_TermDraft(term.name, term.percentage.toStringAsFixed(0)));
    }
    _useClientTable = ClientDirectory.findByName(offering.owner) != null;
    _clientHasRecentOffer = offering.clientHasRecentOffer;
    _clientOfferCount = _offerCountFor(offering.owner);
    _latitudeController.text = offering.latitude?.toString() ?? '';
    _longitudeController.text = offering.longitude?.toString() ?? '';
    _rentalUntil = offering.rentalUntil;
    _numberStyle = offering.numberingStyle;
    _status = offering.status;
    _paidStatus = offering.paidStatus;
  }

  void _setLineItems(Offering offering) {
    for (final item in _lineItems) {
      item.dispose();
    }
    for (final term in _terms) {
      term.dispose();
    }
    _lineItems.clear();

    if (offering.lineItems.isNotEmpty) {
      final labels = lineItemLabels(
        offering.lineItems,
        style: offering.numberingStyle,
      );
      for (var index = 0; index < offering.lineItems.length; index++) {
        final item = offering.lineItems[index];
        _lineItems.add(
          _createLineItemDraft(
            numberText: labels[index],
            descriptionText: item.description,
            descriptionRuns: item.descriptionRuns,
            rowBold: item.rowBold,
            rowItalic: item.rowItalic,
            qtyText: item.excludeFromTotal ? '' : item.qty,
            uomText: item.excludeFromTotal ? '' : item.uom,
            amountText: formatRupiahInput(item.amount),
            indent: item.indent,
            excludeFromTotal: item.excludeFromTotal,
          ),
        );
      }
    } else if ((offering.budgetAmount ?? 0) > 0) {
      _lineItems.add(
        _createLineItemDraft(
          numberText: '1',
          descriptionText: offering.name.trim().isEmpty
              ? 'Offering value'
              : offering.name.trim(),
          qtyText: '1',
          uomText: 'Lot',
          amountText: formatRupiahInput(offering.budgetAmount),
        ),
      );
    }

    if (_lineItems.isEmpty) {
      _lineItems.add(_createLineItemDraft(numberText: '1'));
    }
  }

  _LineItemDraft _createLineItemDraft({
    String numberText = '',
    String descriptionText = '',
    List<LineItemTextRun> descriptionRuns = const [],
    bool rowBold = false,
    bool rowItalic = false,
    String qtyText = '',
    String uomText = '',
    String amountText = '',
    int indent = 0,
    bool excludeFromTotal = false,
  }) {
    return _LineItemDraft(
      numberText: numberText,
      descriptionText: descriptionText,
      descriptionRuns: descriptionRuns,
      rowBold: rowBold,
      rowItalic: rowItalic,
      qtyText: qtyText,
      uomText: uomText,
      amountText: amountText,
      indent: indent,
      excludeFromTotal: excludeFromTotal,
      onFormatChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    for (final item in _lineItems) {
      item.dispose();
    }
    _numberController.dispose();
    _nameController.dispose();
    _serviceTypeController.dispose();
    _ownerController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _findCoordinates() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an address before searching for coordinates.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isFindingCoordinates = true;
      _coordinateError = null;
    });

    try {
      final coordinates = await GeocodingService.coordinatesFromAddress(
        address,
      );
      if (!mounted) return;

      setState(() {
        _latitudeController.text = coordinates.latitude.toStringAsFixed(6);
        _longitudeController.text = coordinates.longitude.toStringAsFixed(6);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates found and filled in below.')),
      );
    } on GeocodingException catch (error) {
      if (!mounted) return;
      setState(() => _coordinateError = error.message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      const message =
          'Could not look up that address. Please check it and try again.';
      setState(() => _coordinateError = message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isFindingCoordinates = false);
    }
  }

  Future<void> _saveOffering() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRentalService &&
        _status == OfferingStatus.accepted &&
        _rentalUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choose the rental until date before accepting this offering.',
          ),
        ),
      );
      return;
    }

    final provider = context.read<ProjectProvider>();
    if (_isRentalService && _rentalItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one rental tool.')),
      );
      return;
    }
    final lineItems = _isRentalService
        ? <OfferingLineItem>[]
        : _lineItemsForSave;
    final budgetAmount = _isRentalService
        ? _rentalItems.fold<double>(0, (sum, item) => sum + item.total)
        : lineItems.isEmpty
        ? null
        : _lineItemTotal;
    final owner = _ownerController.text.trim();
    final selectedClient = ClientDirectory.findByName(owner);
    final clientId =
        selectedClient?.id ??
        (owner == _editing?.owner ? _editing?.clientId : null);

    setState(() => _isSaving = true);

    final offering = Offering(
      id:
          _editing?.id ??
          widget.offeringId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      number: _numberController.text.trim(),
      name: _nameController.text.trim(),
      serviceType: _serviceTypeController.text.trim(),
      owner: owner,
      clientId: clientId,
      address: _addressController.text.trim(),
      latitude: _isCalibrationService
          ? null
          : double.tryParse(_latitudeController.text),
      longitude: _isCalibrationService
          ? null
          : double.tryParse(_longitudeController.text),
      status: _status,
      paidStatus: _paidStatus,
      budgetAmount: budgetAmount,
      lineItems: lineItems,
      rentalItems: _isRentalService
          ? List.unmodifiable(_rentalItems)
          : const [],
      terms: [
        for (final term in _terms)
          if (term.name.text.trim().isNotEmpty)
            OfferingTerm(
              name: term.name.text.trim(),
              percentage: double.tryParse(term.percentage.text) ?? 0,
              amount: budgetAmount == null
                  ? 0
                  : budgetAmount *
                        (double.tryParse(term.percentage.text) ?? 0) /
                        100,
            ),
      ],
      numberingStyle: _numberStyle,
      amountPaid: _editing == null || _paidStatus != _editing!.paidStatus
          ? null
          : _editing!.amountPaid,
      clientHasRecentOffer: _clientHasRecentOffer,
      rentalUntil: _isRentalService ? _rentalUntil : null,
      projectId: _editing?.projectId,
    );

    try {
      if (_isEditing) {
        await provider.updateOffering(offering);
      } else {
        await provider.addOffering(offering);
      }
      if (mounted) _close();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _isEditing;
    final locationCard = _isCalibrationService
        ? _sectionCard(
            title: 'Address & Location',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.business_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Calibration is performed at the office. '
                      'Latitude and longitude are not required for this service.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        : _sectionCard(
            title: 'Address & Location',
            children: [
              const Text(
                'Find the coordinates from the address above, or enter '
                'them manually.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isFindingCoordinates ? null : _findCoordinates,
                  icon: _isFindingCoordinates
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : const Icon(Icons.travel_explore, size: 18),
                  label: Text(
                    _isFindingCoordinates
                        ? 'Finding coordinates…'
                        : 'Find Coordinates',
                  ),
                ),
              ),
              if (_coordinateError != null) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppColors.onHold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _coordinateError!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.onHold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
    final detailsCard = _offeringDetailsCard(locationCard: locationCard);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Offering' : 'New Offering')),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveOffering,
        icon: _isSaving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(isEditing ? 'Save Changes' : 'Save Offering'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            detailsCard,
            const SizedBox(height: 16),
            if (_isRentalService) _rentalItemsCard() else _budgetCard(),
            const SizedBox(height: 16),
            _termsCard(),
            const SizedBox(height: 16),
            if (_isRentalService) ...[
              const SizedBox(height: 16),
              _rentalCard(),
            ],
          ],
        ),
      ),
    );
  }
}
