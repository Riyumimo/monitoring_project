import 'line_item_number_style.dart';
import 'offering_line_item.dart';

enum OfferingStatus { draft, sent, accepted, rejected, expired }

enum PaidStatus { unpaid, partiallyPaid, paid }

/// A sales offering / proposal sent to a client. Once a client accepts it,
/// a [Project] is created from it (see `Project.offeringId`). Rent Tool
/// offerings are the exception: they have a rental until date instead of a
/// project.
class Offering {
  final String id;
  final String number;
  final String name;
  final String serviceType;
  final String owner;
  final String? clientId;
  final String address;
  final double? latitude;
  final double? longitude;
  final OfferingStatus status;
  final PaidStatus paidStatus;
  final double? budgetAmount;

  /// Itemised description of work. The effective sum of these rows is the
  /// offering budget; rows marked [OfferingLineItem.excludeFromTotal] are
  /// omitted. Older records may have a budget with no rows yet.
  final List<OfferingLineItem> lineItems;

  /// Fallback numbering style for rows that do not have a manually typed
  /// number label. Used by older records; the offering form stores per-row
  /// labels when the user types into the No. column.
  final LineItemNumberStyle numberingStyle;

  /// Amount already collected from the client. For older records this is
  /// derived from [paidStatus] and [budgetAmount] so existing paid/partial
  /// offerings still show a meaningful balance.
  final double amountPaid;

  /// Whether this client already received another offer recently. Set from
  /// the offering form so the team can avoid duplicate proposals.
  final bool clientHasRecentOffer;

  /// Date the rented tools must be returned for [isRentalService] offerings.
  final DateTime? rentalUntil;

  /// Id of the project created from this offering, if any.
  final String? projectId;

  Offering({
    required this.id,
    this.number = '',
    required this.name,
    this.serviceType = '',
    required this.owner,
    this.clientId,
    required this.address,
    this.latitude,
    this.longitude,
    this.status = OfferingStatus.draft,
    this.paidStatus = PaidStatus.unpaid,
    this.budgetAmount,
    this.lineItems = const [],
    this.numberingStyle = LineItemNumberStyle.numeric,
    double? amountPaid,
    this.clientHasRecentOffer = false,
    this.rentalUntil,
    this.projectId,
  }) : amountPaid = amountPaid ?? _defaultAmountPaid(paidStatus, budgetAmount);

  /// Remaining balance for this offering, or `null` when no budget is set.
  double? get remainingAmount {
    final budget = budgetAmount;
    if (budget == null) return null;
    final remaining = budget - amountPaid;
    return remaining > 0 ? remaining : 0;
  }

  /// Whether the offering has been fully paid.
  bool get isFullyPaid =>
      budgetAmount != null && budgetAmount! > 0 && amountPaid >= budgetAmount!;

  static double _defaultAmountPaid(PaidStatus status, double? budget) {
    final total = budget ?? 0;
    return switch (status) {
      PaidStatus.unpaid => 0,
      PaidStatus.partiallyPaid => total * 0.5,
      PaidStatus.paid => total,
    };
  }

  bool get hasProject => projectId != null;

  /// Calibration work is performed at the office/calibration lab, so it does
  /// not need survey coordinates.
  bool get isCalibrationService =>
      serviceType.toLowerCase().contains('calibrat');

  /// Rent Tool offerings are fulfilled as rentals and do not create projects.
  bool get isRentalService =>
      serviceType.toLowerCase().trim().startsWith('rent');

  factory Offering.fromJson(Map<String, dynamic> json) {
    final rawItems = json['lineItems'];
    final lineItems = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) =>
                    OfferingLineItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : const <OfferingLineItem>[];
    final storedBudget = (json['budgetAmount'] as num?)?.toDouble();

    return Offering(
      id: json['id'] ?? '',
      number: json['number'] ?? '',
      name: json['name'] ?? '',
      serviceType: json['serviceType'] ?? '',
      owner: json['owner'] ?? '',
      clientId: json['clientId']?.toString(),
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: _statusFromString(json['status'] ?? 'draft'),
      paidStatus: _paidStatusFromString(json['paidStatus'] ?? 'unpaid'),
      budgetAmount: storedBudget ?? _lineItemsTotal(lineItems),
      lineItems: lineItems,
      numberingStyle: LineItemNumberStyle.fromStorage(
        json['numberingStyle']?.toString(),
      ),
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      clientHasRecentOffer: json['clientHasRecentOffer'] == true,
      rentalUntil: DateTime.tryParse(json['rentalUntil']?.toString() ?? ''),
      projectId: json['projectId'],
    );
  }

  static double? _lineItemsTotal(List<OfferingLineItem> items) {
    if (items.isEmpty) return null;
    final rootIndent = items
        .map((item) => item.indent)
        .reduce((a, b) => a < b ? a : b);

    var total = 0.0;
    for (var index = 0; index < items.length; index++) {
      if (items[index].indent == rootIndent) {
        total += _effectiveItemAmount(items, index);
      }
    }
    return total;
  }

  static double _effectiveItemAmount(List<OfferingLineItem> items, int index) {
    final item = items[index];
    final own = item.excludeFromTotal ? 0.0 : item.amount;
    if (own > 0) return own;

    int? childIndent;
    var total = 0.0;
    for (var i = index + 1; i < items.length; i++) {
      final row = items[i];
      if (row.indent <= item.indent) break;
      childIndent ??= row.indent;
      if (row.indent == childIndent) {
        total += _effectiveItemAmount(items, i);
      }
    }
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'name': name,
      'serviceType': serviceType,
      'owner': owner,
      'clientId': clientId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': _statusToString(status),
      'paidStatus': _paidStatusToString(paidStatus),
      'budgetAmount': budgetAmount,
      'lineItems': [for (final item in lineItems) item.toJson()],
      'numberingStyle': numberingStyle.name,
      'amountPaid': amountPaid,
      'clientHasRecentOffer': clientHasRecentOffer,
      'rentalUntil': rentalUntil?.toIso8601String(),
      'projectId': projectId,
    };
  }

  static OfferingStatus _statusFromString(String status) {
    switch (status) {
      case 'sent':
        return OfferingStatus.sent;
      case 'accepted':
        return OfferingStatus.accepted;
      case 'rejected':
        return OfferingStatus.rejected;
      case 'expired':
        return OfferingStatus.expired;
      case 'draft':
      default:
        return OfferingStatus.draft;
    }
  }

  static String _statusToString(OfferingStatus status) {
    switch (status) {
      case OfferingStatus.sent:
        return 'sent';
      case OfferingStatus.accepted:
        return 'accepted';
      case OfferingStatus.rejected:
        return 'rejected';
      case OfferingStatus.expired:
        return 'expired';
      case OfferingStatus.draft:
        return 'draft';
    }
  }

  static PaidStatus _paidStatusFromString(String status) {
    switch (status) {
      case 'partiallyPaid':
        return PaidStatus.partiallyPaid;
      case 'paid':
        return PaidStatus.paid;
      case 'unpaid':
      default:
        return PaidStatus.unpaid;
    }
  }

  static String _paidStatusToString(PaidStatus status) {
    switch (status) {
      case PaidStatus.partiallyPaid:
        return 'partiallyPaid';
      case PaidStatus.paid:
        return 'paid';
      case PaidStatus.unpaid:
        return 'unpaid';
    }
  }
}
