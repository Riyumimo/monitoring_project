import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/payment.dart';

void main() {
  group('Payment', () {
    test('round-trips through JSON', () {
      final payment = Payment(
        id: 'PAY-1',
        offeringId: 'off-1',
        amount: 2500000,
        paidAt: DateTime(2026, 6, 25, 9, 30),
        method: PaymentMethod.transfer,
        note: 'First installment',
        invoiceNumber: 'INV-2026-001',
        proofName: 'transfer-receipt.pdf',
        proofPath: r'C:\docs\transfer-receipt.pdf',
      );

      final restored = Payment.fromJson(payment.toJson());

      expect(restored.id, payment.id);
      expect(restored.offeringId, payment.offeringId);
      expect(restored.amount, payment.amount);
      expect(restored.paidAt, payment.paidAt);
      expect(restored.method, PaymentMethod.transfer);
      expect(restored.note, payment.note);
      expect(restored.invoiceNumber, payment.invoiceNumber);
      expect(restored.proofName, payment.proofName);
      expect(restored.proofPath, payment.proofPath);
    });

    test('defaults unknown or missing fields safely', () {
      final payment = Payment.fromJson(const {});

      expect(payment.id, '');
      expect(payment.offeringId, '');
      expect(payment.amount, 0);
      expect(payment.method, PaymentMethod.cash);
      expect(payment.note, '');
      expect(payment.invoiceNumber, '');
      expect(payment.proofName, '');
      expect(payment.proofPath, isNull);
    });
  });
}
