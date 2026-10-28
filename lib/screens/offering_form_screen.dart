import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/offering.dart';
import '../providers/project_provider.dart';
import '../router/app_router.dart';
import '../services/client_directory.dart';
import '../services/geocoding_service.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../utils/status_extensions.dart';

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
  final _budgetController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  OfferingStatus _status = OfferingStatus.draft;
  PaidStatus _paidStatus = PaidStatus.unpaid;
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
    _budgetController.text = formatRupiahInput(offering.budgetAmount);
    _useClientTable = ClientDirectory.findByName(offering.owner) != null;
    _clientHasRecentOffer = offering.clientHasRecentOffer;
    _clientOfferCount = _offerCountFor(offering.owner);
    _latitudeController.text = offering.latitude?.toString() ?? '';
    _longitudeController.text = offering.longitude?.toString() ?? '';
    _rentalUntil = offering.rentalUntil;
    _status = offering.status;
    _paidStatus = offering.paidStatus;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _serviceTypeController.dispose();
    _ownerController.dispose();
    _addressController.dispose();
    _budgetController.dispose();
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
      budgetAmount: parseRupiah(_budgetController.text),
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
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Offering' : 'New Offering')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _sectionCard(
              title: 'Offering Details',
              children: [
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Offering Number',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Offering Name',
                    prefixIcon: Icon(Icons.terrain_outlined),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter offering name'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
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
                      DropdownMenuItem(
                        value: type,
                        child: Text(type, overflow: TextOverflow.ellipsis),
                      ),
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
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: CheckboxListTile(
                    value: _useClientTable,
                    onChanged: (value) => _toggleClientTable(value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: const Text(
                      'Choose client from table',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Uncheck to type a new client manually.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_useClientTable) ...[
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
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Please select a client'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: CheckboxListTile(
                      value: _clientHasRecentOffer,
                      onChanged: (value) {
                        setState(() => _clientHasRecentOffer = value ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text(
                        'Client has an offer recently',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        _clientOfferCount == 0
                            ? 'No other offers found for this client.'
                            : '$_clientOfferCount other offer(s) found for '
                                  'this client. Checked automatically; you can '
                                  'change it.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ] else
                  TextFormField(
                    controller: _ownerController,
                    decoration: const InputDecoration(
                      labelText: 'New Client Name',
                      hintText: 'Type the client name',
                      prefixIcon: Icon(Icons.person_add_alt_1_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Please enter the new client name'
                        : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (_) {
                    if (_coordinateError != null) {
                      setState(() => _coordinateError = null);
                    }
                  },
                  onFieldSubmitted: (_) => _findCoordinates(),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter address'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Amount',
                    prefixIcon: Icon(Icons.payments_outlined),
                    prefixText: 'Rp ',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: const [RupiahInputFormatter()],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isCalibrationService)
              _sectionCard(
                title: 'Location',
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
            else
              _sectionCard(
                title: 'Location',
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
              ),
            if (_isRentalService) ...[
              const SizedBox(height: 16),
              _rentalCard(),
            ],
            const SizedBox(height: 16),
            _statusCard(),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveOffering,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Save Offering'),
              ),
            ),
          ],
        ),
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

  Widget _statusCard() {
    final accepted = _status == OfferingStatus.accepted;
    return _sectionCard(
      title: 'Status',
      children: [
        DropdownButtonFormField<OfferingStatus>(
          key: ValueKey('status:$_status'),
          initialValue: _status,
          decoration: const InputDecoration(
            labelText: 'Offering Status',
            prefixIcon: Icon(Icons.flag_outlined),
          ),
          items: OfferingStatus.values
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _status = value);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<PaidStatus>(
          key: ValueKey('paid:$_paidStatus'),
          initialValue: _paidStatus,
          decoration: const InputDecoration(
            labelText: 'Paid Status',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          items: PaidStatus.values
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _paidStatus = value);
          },
        ),
        const SizedBox(height: 16),
        _projectGate(accepted),
      ],
    );
  }

  Widget _projectGate(bool accepted) {
    if (_isRentalService) {
      return _infoNote(
        'Rent Tool offerings do not create a project. Set the rental until '
        'date instead.',
        AppColors.primary,
      );
    }

    final projectId = _editing == null
        ? null
        : context
              .watch<ProjectProvider>()
              .offeringById(_editing!.id)
              ?.projectId;
    if (projectId != null) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () => context.push(AppRouter.projectDetail(projectId)),
          icon: const Icon(Icons.folder_open_outlined, size: 18),
          label: const Text('Open Project'),
        ),
      );
    }

    if (!accepted) {
      return _infoNote(
        'A project can only be created after the offering is accepted.',
        AppColors.pending,
      );
    }

    if (!_isEditing) {
      return _infoNote(
        'Save the offering, then create its project from the offering page.',
        AppColors.accepted,
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _isSaving
            ? null
            : () => context.push(AppRouter.newProject(_editing!.id)),
        icon: const Icon(Icons.rocket_launch_outlined, size: 18),
        label: const Text('Create Project'),
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
