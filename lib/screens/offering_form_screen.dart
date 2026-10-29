import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/line_item_number_style.dart';
import '../models/line_item_text_run.dart';
import '../models/offering.dart';
import '../models/offering_line_item.dart';
import '../providers/project_provider.dart';
import '../router/app_router.dart';
import '../services/client_directory.dart';
import '../services/geocoding_service.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../utils/offering_line_items.dart';
import '../utils/rich_text_controller.dart';
import '../utils/status_extensions.dart';
import '../widgets/rich_text_shortcuts.dart';

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
    _numberController.text = offering.number;
    _nameController.text = offering.name;
    _serviceTypeController.text = offering.serviceType;
    _ownerController.text = offering.owner;
    _addressController.text = offering.address;
    _setLineItems(offering);
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

    if (_lineItems.isEmpty) _lineItems.add(_createLineItemDraft(numberText: '1'));
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

  void _addLineItem() {
    setState(() {
      final draft = _createLineItemDraft(
        numberText: _nextNumberForNewRow(_lineItems.length, 0),
      );
      _lineItems.add(draft);
    });
  }

  /// Finds the next serial number for a new row in the sibling group that
  /// starts at [insertAt] with [indent].
  String _nextNumberForNewRow(int insertAt, int indent) {
    for (var i = insertAt - 1; i >= 0; i--) {
      final row = _lineItems[i];
      if (row.indent < indent) break;
      if (row.indent == indent) {
        final previous = row.number.text.trim();
        if (isLineItemNumberSeed(previous)) {
          return lineItemLabelAfter(previous, 1);
        }
      }
    }
    return switch (indent) {
      1 => 'a',
      2 => 'A',
      _ => '1',
    };
  }

  /// Auto-fills following siblings when the user types a starting number such
  /// as 1, a or A into a No. cell. Deeper nested rows are left untouched.
  void _autoFillNumbers(int index) {
    final item = _lineItems[index];
    final seed = item.number.text.trim();
    if (!isLineItemNumberSeed(seed)) return;

    var offset = 1;
    for (var i = index + 1; i < _lineItems.length; i++) {
      final row = _lineItems[i];
      if (row.indent < item.indent) break;
      if (row.indent != item.indent) continue;
      row.number.text = lineItemLabelAfter(seed, offset);
      offset++;
    }
  }

  /// Adds a new row below the current row (after any nested children) and
  /// focuses its description. This backs the Enter shortcut on the Total
  /// field.
  void _addLineItemAfter(int index) {
    final current = _lineItems[index];
    var insertAt = index + 1;
    while (insertAt < _lineItems.length &&
        _lineItems[insertAt].indent > current.indent) {
      insertAt++;
    }

    final draft = _createLineItemDraft(
      indent: current.indent,
      numberText: _nextNumberForNewRow(insertAt, current.indent),
    );
    setState(() {
      _lineItems.insert(insertAt, draft);
      _autoFillNumbers(insertAt);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_lineItems.contains(draft)) return;
      draft.descriptionFocus.requestFocus();
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      final removeIndent = _lineItems[index].indent;
      var end = index + 1;
      while (end < _lineItems.length && _lineItems[end].indent > removeIndent) {
        end++;
      }
      for (var i = end - 1; i >= index; i--) {
        _lineItems.removeAt(i).dispose();
      }
      if (_lineItems.isEmpty) {
        _lineItems.add(_createLineItemDraft(numberText: '1'));
        return;
      }

      int? remainingSibling;
      if (index < _lineItems.length &&
          _lineItems[index].indent == removeIndent) {
        remainingSibling = index;
      } else {
        for (var i = index - 1; i >= 0; i--) {
          final row = _lineItems[i];
          if (row.indent < removeIndent) break;
          if (row.indent == removeIndent) {
            remainingSibling = i;
            break;
          }
        }
      }
      if (remainingSibling != null) {
        final start = _firstSiblingIndex(remainingSibling, removeIndent);
        _autoFillNumbers(start);
      }
    });
  }

  /// Finds the first row of the sibling group that contains [index].
  int _firstSiblingIndex(int index, int indent) {
    var start = index;
    for (var i = index - 1; i >= 0; i--) {
      final row = _lineItems[i];
      if (row.indent < indent) break;
      if (row.indent == indent) start = i;
    }
    return start;
  }

  double get _lineItemTotal {
    if (_lineItems.isEmpty) return 0;
    final rootIndent = _lineItems
        .map((item) => item.indent)
        .reduce((a, b) => a < b ? a : b);

    var total = 0.0;
    for (var index = 0; index < _lineItems.length; index++) {
      if (_lineItems[index].indent == rootIndent) {
        total += _effectiveAmount(index);
      }
    }
    return total;
  }

  double _draftAmount(_LineItemDraft item) =>
      parseRupiah(item.amount.text) ?? 0;

  double _effectiveAmount(int index) {
    final item = _lineItems[index];
    final own = item.excludeFromTotal ? 0.0 : _draftAmount(item);
    if (own > 0) return own;

    final baseIndent = item.indent;
    int? childIndent;
    var total = 0.0;
    for (var i = index + 1; i < _lineItems.length; i++) {
      final row = _lineItems[i];
      if (row.indent <= baseIndent) break;
      childIndent ??= row.indent;
      if (row.indent == childIndent) total += _effectiveAmount(i);
    }
    return total;
  }

  bool _hasNestedChildren(int index) =>
      index + 1 < _lineItems.length &&
      _lineItems[index + 1].indent > _lineItems[index].indent;

  int get _filledLineItemCount =>
      _lineItems.where((item) => !item.isBlank).length;

  List<OfferingLineItem> get _lineItemsForSave => [
    for (final item in _lineItems)
      if (!item.isBlank)
        OfferingLineItem(
          description: item.description.text,
          descriptionRuns: item.description.formatRuns,
          rowBold: item.rowBold,
          rowItalic: item.rowItalic,
          qty: item.excludeFromTotal ? '' : item.qty.text.trim(),
          uom: item.excludeFromTotal ? '' : item.uom.text.trim(),
          amount: parseRupiah(item.amount.text) ?? 0,
          numberLabel: item.number.text.trim(),
          indent: item.indent,
          excludeFromTotal: item.excludeFromTotal,
        ),
  ];

  String? _validateLineItemDescription(_LineItemDraft item) {
    if (item.isBlank) return null;
    return item.description.text.trim().isEmpty ? 'Enter a description' : null;
  }

  String? _validateLineItemAmount(int index) {
    final item = _lineItems[index];
    if (item.isBlank || item.excludeFromTotal) return null;
    final amount = parseRupiah(item.amount.text);
    if (amount != null && amount > 0) return null;
    if (_hasNestedChildren(index)) return null;
    return amount == null ? 'Enter total' : 'Enter a valid total';
  }

  void _setLineItemExcluded(int index, bool excluded) {
    setState(() {
      final item = _lineItems[index];
      item.excludeFromTotal = excluded;
      if (excluded) {
        item.qty.clear();
        item.uom.clear();
      }
    });
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
    final lineItems = _lineItemsForSave;
    final budgetAmount = lineItems.isEmpty ? null : _lineItemTotal;

    setState(() => _isSaving = true);

    final offering = Offering(
      id:
          _editing?.id ??
          widget.offeringId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      number: _numberController.text.trim(),
      name: _nameController.text.trim(),
      serviceType: _serviceTypeController.text.trim(),
      owner: _ownerController.text.trim(),
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
                      onPressed: _isFindingCoordinates
                          ? null
                          : _findCoordinates,
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
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                          ),
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
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                          ),
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
            _budgetCard(),
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
  Widget _offeringDetailsCard({required Widget locationCard}) {
    final numberField = TextFormField(
      controller: _numberController,
      decoration: const InputDecoration(
        labelText: 'Offering Number',
        prefixIcon: Icon(Icons.tag),
      ),
    );
    final nameField = TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Offering Name',
        prefixIcon: Icon(Icons.terrain_outlined),
      ),
      validator: (value) => (value == null || value.trim().isEmpty)
          ? 'Please enter offering name'
          : null,
    );
    final serviceTypeField = DropdownButtonFormField<String>(
      key: ValueKey('serviceType:${_serviceTypeController.text}'),
      initialValue: _serviceTypeController.text.trim().isEmpty
          ? null
          : _serviceTypeController.text.trim(),
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Service Type',
        hintText: 'Select service type',
        prefixIcon: Icon(Icons.work_outline),
      ),
      items: [
        for (final type in _serviceTypeOptions)
          DropdownMenuItem(value: type, child: Text(type, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _serviceTypeController.text = value;
          if (_isCalibrationService) {
            _latitudeController.clear();
            _longitudeController.clear();
          }
        });
      },
      validator: (value) => (value == null || value.trim().isEmpty)
          ? 'Please select service type'
          : null,
    );
    final clientSourceSuffix = Tooltip(
      message: 'Choose client from table',
      child: SizedBox(
        height: 56,
        width: 48,
        child: Center(
          child: Checkbox(
            value: _useClientTable,
            onChanged: (value) => _toggleClientTable(value ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          ),
        ),
      ),
    );
    final clientField = _useClientTable
        ? Column(
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('client:${_ownerController.text}'),
                initialValue: _ownerController.text.trim().isEmpty
                    ? null
                    : _ownerController.text.trim(),
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Client / Owner',
                  hintText: 'Select client',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                items: [
                  for (final name in _clientOptions)
                    DropdownMenuItem(
                      value: name,
                      child: Text(name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _ownerController.text = value;
                    _clientOfferCount = _offerCountFor(value);
                    _clientHasRecentOffer = _clientOfferCount > 0;
                  });
                },
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please select a client'
                    : null,
              ),
            ],
          )
        : TextFormField(
            controller: _ownerController,
            decoration: const InputDecoration(
              labelText: 'New Client Name',
              hintText: 'Type the client name',
              prefixIcon: Icon(Icons.person_add_alt_1_outlined),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter the new client name'
                : null,
          );
    final clientInputWithToggle = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: clientField),
        const SizedBox(width: 8),
        clientSourceSuffix,
      ],
    );
    final addressField = TextFormField(
      controller: _addressController,
      decoration: const InputDecoration(
        labelText: 'Address',
        prefixIcon: Icon(Icons.place_outlined),
      ),
      textInputAction: TextInputAction.search,
      onChanged: (_) {
        if (_coordinateError != null) setState(() => _coordinateError = null);
      },
      onFieldSubmitted: (_) => _findCoordinates(),
      validator: (value) => (value == null || value.trim().isEmpty)
          ? 'Please enter address'
          : null,
    );

    final leftColumn = <Widget>[
      numberField,
      const SizedBox(height: 16),
      nameField,
      const SizedBox(height: 16),
      serviceTypeField,
    ];
    final rightColumn = <Widget>[
      clientInputWithToggle,
      const SizedBox(height: 16),
      addressField,
    ];

    return _sectionCard(
      title: 'Offering Details',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  ...leftColumn,
                  const SizedBox(height: 16),
                  ...rightColumn,
                  const SizedBox(height: 16),
                  locationCard,
                ],
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: numberField),
                    const SizedBox(width: 20),
                    Expanded(child: clientInputWithToggle),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: nameField),
                    const SizedBox(width: 20),
                    Expanded(child: serviceTypeField),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: addressField),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: (constraints.maxWidth - 20) / 2,
                    child: locationCard,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _budgetCard() {
    return _sectionCard(
      title: 'Description of Work',
      children: [
        const Text(
          'Add each work item with its quantity, unit, and total. Use the '
          'level control to nest an item under the row above; nesting is '
          'optional. Tick Exclude for a section row that should not add its '
          'own total to the budget. The total below becomes the offering '
          'budget. Press Enter in the Total field to add the next row. Select '
          'description text and press Ctrl+B for bold or Ctrl+I for italic. '
          'Type a starting number in any No. cell, such as 1, a or A, and the '
          'rows below it at the same level are numbered automatically.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 680;
            return Column(
              children: [
                wide
                    ? _lineItemTable()
                    : Column(
                        children: [
                          for (
                            var index = 0;
                            index < _lineItems.length;
                            index++
                          ) ...[
                            _narrowLineItem(index),
                            if (index != _lineItems.length - 1)
                              const SizedBox(height: 8),
                          ],
                        ],
                      ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _addLineItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Item'),
                    ),
                    const Spacer(),
                    Text(
                      '$_filledLineItemCount item'
                      '${_filledLineItemCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _budgetTotalRow(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _lineItemTable() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FixedColumnWidth(42),
          2: FlexColumnWidth(5),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(2),
          6: FixedColumnWidth(54),
          7: FixedColumnWidth(40),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: const TableBorder(
          horizontalInside: BorderSide(color: AppColors.border),
          verticalInside: BorderSide(color: AppColors.border),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
            ),
            children: [
              const _LineItemHeaderCell('LEVEL', horizontalPadding: 4),
              const _LineItemHeaderCell('NO.', horizontalPadding: 4),
              const _LineItemHeaderCell('DESCRIPTION OF WORK'),
              const _LineItemHeaderCell('QTY', alignment: TextAlign.center),
              const _LineItemHeaderCell('UNIT', alignment: TextAlign.center),
              const _LineItemHeaderCell('TOTAL', alignment: TextAlign.right),
              const _LineItemHeaderCell(
                'EXCLUDE',
                alignment: TextAlign.center,
                horizontalPadding: 4,
              ),
              const SizedBox.shrink(),
            ],
          ),
          for (var index = 0; index < _lineItems.length; index++)
            _lineItemTableRow(index),
        ],
      ),
    );
  }

  TableRow _lineItemTableRow(int index) {
    final item = _lineItems[index];
    return TableRow(
      decoration: item.excludeFromTotal
          ? BoxDecoration(color: AppColors.inProgress.withValues(alpha: 0.10))
          : null,
      children: [
        Center(child: _nestingButton(index)),
        _numberField(index),
        RichTextShortcuts(
          controller: item.description,
          child: _tableField(
            item.description,
            hintText: 'Enter work description',
            maxLines: 2,
            focusNode: item.descriptionFocus,
            textInputAction: TextInputAction.next,
            validator: (_) => _validateLineItemDescription(item),
          ),
        ),
        _tableField(
          item.qty,
          hintText: item.excludeFromTotal ? '' : '1',
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          enabled: !item.excludeFromTotal,
        ),
        _tableField(
          item.uom,
          hintText: item.excludeFromTotal ? '' : 'Lot',
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.next,
          enabled: !item.excludeFromTotal,
        ),
        _tableField(
          item.amount,
          hintText: '0',
          prefixText: 'Rp ',
          textAlign: TextAlign.right,
          style: _rowTextStyle(item),
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onFieldSubmitted: (_) => _addLineItemAfter(index),
          validator: (_) => _validateLineItemAmount(index),
        ),
        Center(child: _excludeCheckbox(index)),
        Center(child: _removeLineItemButton(index)),
      ],
    );
  }

  Widget _numberField(int index, {bool compact = false}) {
    final item = _lineItems[index];
    return TextField(
      controller: item.number,
      focusNode: item.numberFocus,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: TextStyle(
        fontSize: compact ? 13 : 10.5,
        fontWeight: item.rowBold ? FontWeight.w900 : FontWeight.w700,
        fontStyle: item.rowItalic ? FontStyle.italic : FontStyle.normal,
        color: AppColors.textSecondary,
      ),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
      ],
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 4,
          vertical: compact ? 4 : 13,
        ),
      ),
      onTap: () {
        item.number.selection = TextSelection(
          baseOffset: 0,
          extentOffset: item.number.text.length,
        );
      },
      onChanged: (_) => _autoFillNumbers(index),
    );
  }

  TextStyle _rowTextStyle(_LineItemDraft item) {
    return TextStyle(
      fontWeight: item.rowBold ? FontWeight.w900 : null,
      fontStyle: item.rowItalic ? FontStyle.italic : null,
    );
  }

  void _setLineItemIndent(int index, int value) {
    final item = _lineItems[index];
    final oldIndent = item.indent;
    final maxIndent = index == 0 ? 0 : _lineItems[index - 1].indent + 1;
    final next = value.clamp(0, maxIndent.clamp(0, 2)).toInt();
    final delta = next - oldIndent;
    if (delta == 0) return;

    setState(() {
      item.indent = next;
      for (var i = index + 1; i < _lineItems.length; i++) {
        final row = _lineItems[i];
        if (row.indent <= oldIndent) break;
        row.indent = (row.indent + delta).clamp(0, 2).toInt();
      }
    });
  }

  Widget _nestingButton(int index) {
    final item = _lineItems[index];
    return PopupMenuButton<int>(
      tooltip: 'Nesting level',
      initialValue: item.indent,
      onSelected: (value) => _setLineItemIndent(index, value),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 0, child: Text('Top level')),
        PopupMenuItem(value: 1, child: Text('Sub-item')),
        PopupMenuItem(value: 2, child: Text('Sub-sub-item')),
      ],
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          item.indent == 0
              ? Icons.vertical_align_top
              : Icons.subdirectory_arrow_right,
          size: 18,
          color: item.indent == 0 ? AppColors.textSecondary : AppColors.primary,
        ),
      ),
    );
  }

  Widget _excludeCheckbox(int index) {
    final item = _lineItems[index];
    return Tooltip(
      message: item.excludeFromTotal
          ? 'Count this row in the total'
          : "Don't count to total",
      child: Checkbox(
        value: item.excludeFromTotal,
        onChanged: (value) => _setLineItemExcluded(index, value ?? false),
        activeColor: AppColors.primary,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _tableField(
    TextEditingController controller, {
    String? hintText,
    String? prefixText,
    int maxLines = 1,
    TextAlign textAlign = TextAlign.start,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextStyle? style,
    FocusNode? focusNode,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: _tableFieldDecoration(
        hintText: hintText,
        prefixText: prefixText,
      ),
      enabled: enabled,
      maxLines: maxLines,
      minLines: 1,
      textAlign: textAlign,
      textAlignVertical: TextAlignVertical.center,
      style: style,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
    );
  }

  InputDecoration _tableFieldDecoration({
    String? hintText,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      errorStyle: const TextStyle(fontSize: 10.5),
    );
  }

  Widget _narrowLineItem(int index) {
    final item = _lineItems[index];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: item.excludeFromTotal
            ? AppColors.inProgress.withValues(alpha: 0.10)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'No.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 42, child: _numberField(index, compact: true)),
              _nestingButton(index),
              Text(
                'Level ${item.indent}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              _removeLineItemButton(index),
            ],
          ),
          const SizedBox(height: 4),
          RichTextShortcuts(
            controller: item.description,
            child: TextFormField(
              controller: item.description,
              focusNode: item.descriptionFocus,
              decoration: const InputDecoration(
                labelText: 'Description of work',
                hintText: 'Enter work description',
              ),
              maxLines: 2,
              minLines: 1,
              textInputAction: TextInputAction.next,
              validator: (_) => _validateLineItemDescription(item),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.qty,
                  enabled: !item.excludeFromTotal,
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    hintText: item.excludeFromTotal ? '' : '1',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.uom,
                  enabled: !item.excludeFromTotal,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    hintText: item.excludeFromTotal ? '' : 'Lot',
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CheckboxListTile(
            value: item.excludeFromTotal,
            onChanged: (value) => _setLineItemExcluded(index, value ?? false),
            title: const Text(
              "Don't count to total",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Qty and Unit are cleared and this row total is skipped.',
              style: TextStyle(fontSize: 11.5, height: 1.3),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: item.amount,
            decoration: const InputDecoration(
              labelText: 'Total',
              prefixText: 'Rp ',
              hintText: '0',
            ),
            style: _rowTextStyle(item),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: const [RupiahInputFormatter()],
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) => _addLineItemAfter(index),
            validator: (_) => _validateLineItemAmount(index),
          ),
        ],
      ),
    );
  }

  Widget _removeLineItemButton(int index) {
    return IconButton(
      onPressed: () => _removeLineItem(index),
      icon: const Icon(Icons.delete_outline, size: 20),
      color: AppColors.onHold,
      tooltip: 'Remove item',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
    );
  }

  Widget _budgetTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calculate_outlined,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Total Budget',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            formatRupiah(_lineItemTotal),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rentalCard() {
    return _sectionCard(
      title: 'Rental Period',
      children: [
        _dateField(
          label: 'Until Date',
          value: _rentalUntil,
          onPick: (date) => setState(() => _rentalUntil = date),
        ),
        const SizedBox(height: 12),
        const Text(
          'Rent Tool offerings do not create a project. Set the date when the '
          'rental ends.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
  }) {
    final text = value == null
        ? ''
        : '${value.year}-${value.month.toString().padLeft(2, '0')}-'
              '${value.day.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now.add(const Duration(days: 7)),
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(
          text.isEmpty ? 'Select date' : text,
          style: TextStyle(
            fontSize: 14,
            color: text.isEmpty
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LineItemHeaderCell extends StatelessWidget {
  final String label;
  final TextAlign alignment;
  final double horizontalPadding;

  const _LineItemHeaderCell(
    this.label, {
    this.alignment = TextAlign.start,
    this.horizontalPadding = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 9),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _LineItemDraft {
  _LineItemDraft({
    String numberText = '',
    String descriptionText = '',
    List<LineItemTextRun> descriptionRuns = const [],
    this.rowBold = false,
    this.rowItalic = false,
    String qtyText = '',
    String uomText = '',
    String amountText = '',
    this.indent = 0,
    this.excludeFromTotal = false,
    required VoidCallback onFormatChanged,
  }) : number = TextEditingController(text: numberText),
       description = RichTextEditingController(
         text: descriptionText,
         runs: descriptionRuns,
       ),
       qty = TextEditingController(text: qtyText),
       uom = TextEditingController(text: uomText),
       amount = TextEditingController(text: amountText) {
    description.onFormatChanged = ({bold, italic}) {
      if (bold != null) rowBold = bold;
      if (italic != null) rowItalic = italic;
      onFormatChanged();
    };
    numberFocus.addListener(_selectNumberOnFocus);
  }

  final TextEditingController number;
  final RichTextEditingController description;
  final TextEditingController qty;
  final TextEditingController uom;
  final TextEditingController amount;
  final FocusNode numberFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();
  int indent;
  bool excludeFromTotal;
  bool rowBold;
  bool rowItalic;

  bool get isBlank =>
      description.text.trim().isEmpty &&
      qty.text.trim().isEmpty &&
      uom.text.trim().isEmpty &&
      (parseRupiah(amount.text) ?? 0) <= 0;

  void _selectNumberOnFocus() {
    if (!numberFocus.hasFocus) return;
    number.selection = TextSelection(
      baseOffset: 0,
      extentOffset: number.text.length,
    );
  }

  void dispose() {
    numberFocus.removeListener(_selectNumberOnFocus);
    numberFocus.dispose();
    number.dispose();
    description.dispose();
    qty.dispose();
    uom.dispose();
    amount.dispose();
    descriptionFocus.dispose();
  }
}
