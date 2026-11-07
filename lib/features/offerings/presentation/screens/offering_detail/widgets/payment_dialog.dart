part of '../../offering_detail_screen.dart';

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
