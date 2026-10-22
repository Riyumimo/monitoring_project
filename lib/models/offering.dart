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
  final String address;
  final double? latitude;
  final double? longitude;
  final OfferingStatus status;
  final PaidStatus paidStatus;
  final double? budgetAmount;

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
    required this.address,
    this.latitude,
    this.longitude,
    this.status = OfferingStatus.draft,
    this.paidStatus = PaidStatus.unpaid,
    this.budgetAmount,
    this.clientHasRecentOffer = false,
    this.rentalUntil,
    this.projectId,
  });

  bool get hasProject => projectId != null;

  /// Calibration work is performed at the office/calibration lab, so it does
  /// not need survey coordinates.
  bool get isCalibrationService =>
      serviceType.toLowerCase().contains('calibrat');

  /// Rent Tool offerings are fulfilled as rentals and do not create projects.
  bool get isRentalService =>
      serviceType.toLowerCase().trim().startsWith('rent');

  factory Offering.fromJson(Map<String, dynamic> json) {
    return Offering(
      id: json['id'] ?? '',
      number: json['number'] ?? '',
      name: json['name'] ?? '',
      serviceType: json['serviceType'] ?? '',
      owner: json['owner'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: _statusFromString(json['status'] ?? 'draft'),
      paidStatus: _paidStatusFromString(json['paidStatus'] ?? 'unpaid'),
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble(),
      clientHasRecentOffer: json['clientHasRecentOffer'] == true,
      rentalUntil: DateTime.tryParse(json['rentalUntil']?.toString() ?? ''),
      projectId: json['projectId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'name': name,
      'serviceType': serviceType,
      'owner': owner,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': _statusToString(status),
      'paidStatus': _paidStatusToString(paidStatus),
      'budgetAmount': budgetAmount,
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
