import 'package:flutter_test/flutter_test.dart';
import 'package:geoterra_monitoring/models/activity.dart';
import 'package:geoterra_monitoring/models/offering.dart';
import 'package:geoterra_monitoring/providers/project_provider.dart';

void main() {
  group('OfferingActivity', () {
    test('round-trips through JSON', () {
      final activity = OfferingActivity(
        id: 'ACT-1',
        offeringId: 'off-1',
        type: ActivityType.payment,
        title: 'Payment received',
        subtitle: 'Rp 2.500.000 via Bank Transfer',
        occurredAt: DateTime(2026, 6, 25, 9, 30),
        actor: 'Ryu',
      );

      final restored = OfferingActivity.fromJson(activity.toJson());

      expect(restored.id, activity.id);
      expect(restored.offeringId, activity.offeringId);
      expect(restored.type, ActivityType.payment);
      expect(restored.title, activity.title);
      expect(restored.subtitle, activity.subtitle);
      expect(restored.occurredAt, activity.occurredAt);
      expect(restored.actor, activity.actor);
    });

    test('defaults unknown fields safely', () {
      final activity = OfferingActivity.fromJson(const {});

      expect(activity.id, '');
      expect(activity.offeringId, '');
      expect(activity.type, ActivityType.created);
      expect(activity.title, '');
      expect(activity.subtitle, '');
      expect(activity.actor, isNull);
    });
  });

  group('ProjectProvider activity feed', () {
    Offering offering() => Offering(
      id: 'off-1',
      number: 'OFF-1',
      name: 'Topographic Survey',
      owner: 'Acme',
      address: 'Site',
      status: OfferingStatus.accepted,
      paidStatus: PaidStatus.partiallyPaid,
      budgetAmount: 10000000,
      amountPaid: 4000000,
    );

    test('seeds baseline activities once and keeps them ordered', () async {
      final provider = ProjectProvider();
      final record = offering();

      await provider.ensureActivities(record, contactName: 'Jane');
      final first = provider.activitiesFor(record.id);

      expect(
        first.map((activity) => activity.type),
        containsAll([
          ActivityType.created,
          ActivityType.sent,
          ActivityType.accepted,
          ActivityType.payment,
        ]),
      );
      for (var i = 1; i < first.length; i++) {
        expect(first[i].occurredAt.isBefore(first[i - 1].occurredAt), isFalse);
      }

      await provider.ensureActivities(record, contactName: 'Jane');
      expect(provider.activitiesFor(record.id).length, first.length);
    });

    test('keeps manually recorded activities', () async {
      final provider = ProjectProvider();
      final record = offering();
      await provider.ensureActivities(record);

      await provider.addActivity(
        OfferingActivity(
          id: 'ACT-note',
          offeringId: record.id,
          type: ActivityType.note,
          title: 'Scope confirmed',
          subtitle: 'Client approved the survey area',
          occurredAt: DateTime.now(),
        ),
      );

      final activities = provider.activitiesFor(record.id);
      expect(activities.last.type, ActivityType.note);
      expect(activities.last.title, 'Scope confirmed');
    });

    test('records a created activity when an offering is added', () async {
      final provider = ProjectProvider();
      final record = offering();

      await provider.addOffering(record);

      final activities = provider.activitiesFor(record.id);
      expect(activities, hasLength(1));
      expect(activities.single.type, ActivityType.created);
      expect(activities.single.title, 'Offering created');

      await provider.ensureActivities(record, contactName: 'Jane');
      expect(
        provider
            .activitiesFor(record.id)
            .where((activity) => activity.type == ActivityType.created),
        hasLength(1),
      );
    });
  });
}
