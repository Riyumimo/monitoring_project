part of '../../offering_form_screen.dart';

extension _FormGeneralSections on _OfferingFormScreenState {
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
          DropdownMenuItem(
            value: type,
            child: Text(type, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        _setState(() {
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
                  _setState(() {
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
        if (_coordinateError != null) _setState(() => _coordinateError = null);
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
                  children: [Expanded(child: addressField)],
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
}
