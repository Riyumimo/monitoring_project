import 'package:flutter/material.dart';

import '../../../../data/clients/client_directory.dart';
import '../../../../app/theme/app_theme.dart';

part 'client_form/sections/layout_sections.dart';
part 'client_form/sections/navigation_sections.dart';
part 'client_form/sections/field_sections.dart';

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

  /// `setState` for the builder methods that live in `part` files.
  void _rebuild(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

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
}
