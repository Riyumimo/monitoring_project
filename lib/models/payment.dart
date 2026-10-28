/// How a client settled a payment for an offering.
enum PaymentMethod { cash, transfer, other }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.transfer:
        return 'Bank Transfer';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}

/// A single payment collected from a client for an [Offering].
///
/// An offering can receive more than one payment, so the offering's
/// `amountPaid` is the sum of its [Payment] records. Each record keeps its own
/// amount, date, method, and note so the payment history and activity feed can
/// be rebuilt accurately.
class Payment {
  final String id;
  final String offeringId;
  final double amount;
  final DateTime paidAt;
  final PaymentMethod method;
  final String note;

  /// Invoice or receipt number that proves this payment, if provided.
  final String invoiceNumber;

  /// Display name of the uploaded proof of payment (transfer receipt, etc.).
  final String proofName;

  /// Local path of the uploaded proof, when the platform exposes one.
  final String? proofPath;

  const Payment({
    required this.id,
    required this.offeringId,
    required this.amount,
    required this.paidAt,
    this.method = PaymentMethod.cash,
    this.note = '',
    this.invoiceNumber = '',
    this.proofName = '',
    this.proofPath,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? '',
      offeringId: json['offeringId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paidAt:
          DateTime.tryParse(json['paidAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      method: _methodFromString(json['method']?.toString() ?? 'cash'),
      note: json['note']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      proofName: json['proofName']?.toString() ?? '',
      proofPath: json['proofPath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offeringId': offeringId,
      'amount': amount,
      'paidAt': paidAt.toIso8601String(),
      'method': _methodToString(method),
      'note': note,
      'invoiceNumber': invoiceNumber,
      'proofName': proofName,
      'proofPath': proofPath,
    };
  }

  static PaymentMethod _methodFromString(String method) {
    switch (method) {
      case 'transfer':
        return PaymentMethod.transfer;
      case 'other':
        return PaymentMethod.other;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }

  static String _methodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.transfer:
        return 'transfer';
      case PaymentMethod.other:
        return 'other';
      case PaymentMethod.cash:
        return 'cash';
    }
  }
}
