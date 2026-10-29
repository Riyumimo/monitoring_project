import 'package:flutter/material.dart';

import '../services/client_directory.dart';
import '../theme/app_theme.dart';

/// Client creation dialog based on the new partner form reference.
class ClientFormDialog extends StatefulWidget {
  const ClientFormDialog({super.key});

  @override
  State<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _sectionKeys = List.generate(5, (_) => GlobalKey());
  final _expandedSections = <int>{0};
  final _clientNumber = TextEditingController(
    text: ClientDirectory.nextClientNumber(),
  );
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _additionalPhone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _website = TextEditingController();
  final _taxNumber = TextEditingController();
  final _notes = TextEditingController();
  final _bankName = TextEditingController();
  final _bankAccountName = TextEditingController();
  final _bankAccountNumber = TextEditingController();
  final _paymentTerms = TextEditingController();
  final _accountCode = TextEditingController();

  String _clientType = 'company';
  String _relationshipType = 'Client';
  String _paymentMethod = '';
  int _activeSection = 0;

  static const _sections = [
    'Company Information',
    'Contact Information',
    'Bank Information',
    'Payment Method',
    'Account Settings',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in [
      _clientNumber,
      _name,
      _contact,
      _phone,
      _additionalPhone,
      _email,
      _address,
      _city,
      _website,
      _taxNumber,
      _notes,
      _bankName,
      _bankAccountName,
      _bankAccountNumber,
      _paymentTerms,
      _accountCode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _goToSection(int index) {
    setState(() {
      _activeSection = index;
      _expandedSections
        ..clear()
        ..add(0)
        ..add(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sectionContext = _sectionKeys[index].currentContext;
      if (sectionContext == null) return;
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: 0,
      );
    });
  }

  void _toggleSection(int index) {
    if (index == 0) return;
    setState(() {
      _activeSection = index;
      if (_expandedSections.contains(index)) {
        _expandedSections.remove(index);
      } else {
        _expandedSections
          ..clear()
          ..add(0)
          ..add(index);
      }
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _goToSection(0);
      return;
    }

    final now = DateTime.now().toIso8601String();
    final clients = ClientDirectory.all();
    final client = ClientRecord(
      id: 'CL-${(clients.length + 1).toString().padLeft(3, '0')}',
      number: _clientNumber.text.trim(),
      type: _clientType,
      name: _name.text.trim(),
      contactPerson: _contact.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      relationshipType: _relationshipType,
      additionalPhone: _additionalPhone.text.trim(),
      website: _website.text.trim(),
      taxNumber: _taxNumber.text.trim(),
      notes: _notes.text.trim(),
      bankName: _bankName.text.trim(),
      bankAccountName: _bankAccountName.text.trim(),
      bankAccountNumber: _bankAccountNumber.text.trim(),
      paymentMethod: _paymentMethod,
      paymentTerms: _paymentTerms.text.trim(),
      accountCode: _accountCode.text.trim(),
      updatedAt: now,
    );
    ClientDirectory.add(client);
    Navigator.of(context).pop(client);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final dialogWidth = (size.width - 32).clamp(0.0, 1000.0).toDouble();
    final dialogHeight = (size.height - keyboardInset - 32)
        .clamp(0.0, 760.0)
        .toDouble();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _titleBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 700) {
                    return Column(
                      children: [
                        _sectionNavigation(vertical: false),
                        Expanded(child: _formContent()),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      SizedBox(
                        width: 210,
                        child: _sectionNavigation(vertical: true),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: _formContent()),
                    ],
                  );
                },
              ),
            ),
            _actions(),
          ],
        ),
      ),
    );
  }

  Widget _titleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      color: AppColors.primary,
      child: Row(
        children: [
          const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Add New Client',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _sectionNavigation({required bool vertical}) {
    final children = [
      for (var index = 0; index < _sections.length; index++)
        _sectionNavItem(index),
    ];
    if (!vertical) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Wrap(spacing: 4, runSpacing: 2, children: children),
      );
    }
    return Container(
      color: AppColors.background.withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: children),
    );
  }

  Widget _sectionNavItem(int index) {
    final selected = _activeSection == index;
    return Semantics(
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: TextButton.icon(
          onPressed: () => _goToSection(index),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            foregroundColor: selected
                ? AppColors.primary
                : AppColors.textSecondary,
            backgroundColor: selected
                ? AppColors.primary.withValues(alpha: 0.09)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          icon: Icon(switch (index) {
            0 => Icons.business_outlined,
            1 => Icons.contact_page_outlined,
            2 => Icons.account_balance_outlined,
            3 => Icons.payments_outlined,
            _ => Icons.settings_outlined,
          }, size: 18),
          label: Text(_sections[index]),
        ),
      ),
    );
  }

  Widget _formContent() {
    final inputDecorationTheme = Theme.of(context).inputDecorationTheme;
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: inputDecorationTheme.copyWith(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section(
                  index: 0,
                  title: _sections[0],
                  subtitle: 'Required client details and relationship type.',
                  children: [
                    _pair(
                      _field(
                        'Client Number',
                        _clientNumber,
                        icon: Icons.tag_outlined,
                        readOnly: true,
                      ),
                      _dropdown(
                        'Business Entity',
                        _clientType,
                        [
                          ('company', 'Company'),
                          ('government', 'Government'),
                          ('organization', 'Organization'),
                          ('individual', 'Individual'),
                        ],
                        (value) => setState(() => _clientType = value),
                      ),
                    ),
                    _field(
                      'Name',
                      _name,
                      icon: Icons.business_outlined,
                      required: true,
                      hint: 'Company or client name',
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.organizationName],
                    ),
                    _pair(
                      _field(
                        'Primary Phone',
                        _phone,
                        icon: Icons.phone_outlined,
                        required: true,
                        keyboardType: TextInputType.phone,
                        hint: '+62 812 3456 7890',
                        autofillHints: const [AutofillHints.telephoneNumber],
                      ),
                      _field(
                        'Email',
                        _email,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        hint: 'name@company.com',
                        validator: _validateEmail,
                        autofillHints: const [AutofillHints.email],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Relationship',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 18,
                      children: [
                        _relationshipOption('Client'),
                        _relationshipOption('Client & Supplier'),
                      ],
                    ),
                  ],
                ),
                _section(
                  index: 1,
                  title: _sections[1],
                  subtitle:
                      'Optional contact, address, and reference information.',
                  children: [
                    _pair(
                      _field(
                        'Contact Person',
                        _contact,
                        icon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                      ),
                      _field(
                        'Additional Phone',
                        _additionalPhone,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                      ),
                    ),
                    _pair(
                      _field(
                        'Address',
                        _address,
                        icon: Icons.location_on_outlined,
                        textCapitalization: TextCapitalization.sentences,
                        autofillHints: const [AutofillHints.fullStreetAddress],
                      ),
                      _field(
                        'City',
                        _city,
                        icon: Icons.location_city_outlined,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.addressCity],
                      ),
                    ),
                    _pair(
                      _field(
                        'Website',
                        _website,
                        icon: Icons.language_outlined,
                        hint: 'https://',
                      ),
                      _field(
                        'Tax Number',
                        _taxNumber,
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                    _field(
                      'Notes',
                      _notes,
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
                _section(
                  index: 2,
                  title: _sections[2],
                  subtitle: 'Optional bank details for client payments.',
                  children: [
                    _pair(
                      _field(
                        'Bank Name',
                        _bankName,
                        icon: Icons.account_balance_outlined,
                      ),
                      _field(
                        'Account Name',
                        _bankAccountName,
                        icon: Icons.person_outline,
                      ),
                    ),
                    _field(
                      'Account Number',
                      _bankAccountNumber,
                      icon: Icons.numbers_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                _section(
                  index: 3,
                  title: _sections[3],
                  subtitle:
                      'Optional defaults to help prepare future invoices.',
                  children: [
                    _pair(
                      _dropdown(
                        'Default Payment Method',
                        _paymentMethod,
                        const [
                          ('', 'Not set'),
                          ('transfer', 'Bank Transfer'),
                          ('cash', 'Cash'),
                          ('other', 'Other'),
                        ],
                        (value) => setState(() => _paymentMethod = value),
                      ),
                      _field(
                        'Payment Terms',
                        _paymentTerms,
                        icon: Icons.schedule_outlined,
                        hint: 'e.g. Net 30',
                      ),
                    ),
                  ],
                ),
                _section(
                  index: 4,
                  title: _sections[4],
                  subtitle: 'Optional internal account reference.',
                  children: [
                    _field(
                      'Account Code',
                      _accountCode,
                      icon: Icons.key_outlined,
                      submitOnDone: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({
    required int index,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final expanded = _expandedSections.contains(index);
    return Container(
      key: _sectionKeys[index],
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: index != 0,
            expanded: expanded,
            child: InkWell(
              onTap: index == 0 ? null : () => _toggleSection(index),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
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
                    if (index != 0)
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index < children.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(children: [first, const SizedBox(height: 8), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool required = false,
    bool readOnly = false,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<String>? autofillHints,
    bool submitOnDone = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : submitOnDone
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: maxLines > 1
          ? null
          : submitOnDone
          ? (_) => _save()
          : (_) => FocusScope.of(context).nextFocus(),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      validator:
          validator ??
          (required
              ? (value) => value == null || value.trim().isEmpty
                    ? 'Please enter $label'
                    : null
              : null),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<(String, String)> options,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option.$1, child: Text(option.$2)),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }

  Widget _relationshipOption(String value) {
    return InkWell(
      onTap: () => setState(() => _relationshipType = value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: value,
              groupValue: _relationshipType,
              onChanged: (next) {
                if (next != null) setState(() => _relationshipType = next);
              },
            ),
            Text(value),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email';
    }
    if (ClientDirectory.emailTaken(email)) return 'This email is already used';
    return null;
  }

  Widget _actions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Client'),
          ),
        ],
      ),
    );
  }
}
