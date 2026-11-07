part of '../../offerings_page.dart';

enum _Col { number, name, serviceType, owner, address, status, payment }

extension _ColX on _Col {
  String get label => switch (this) {
    _Col.number => 'No',
    _Col.name => 'Name',
    _Col.serviceType => 'Service Type',
    _Col.owner => 'Client',
    _Col.address => 'Address',
    _Col.status => 'Status',
    _Col.payment => 'Payment',
  };

  double get width => switch (this) {
    _Col.number => 110,
    _Col.name => 220,
    _Col.serviceType => 200,
    _Col.owner => 170,
    _Col.address => 250,
    _Col.status => 120,
    _Col.payment => 120,
  };

  int get flex => width.round();
}
