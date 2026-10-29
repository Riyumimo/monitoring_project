import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/offering.dart';
import '../models/project.dart';
import '../models/user.dart';
import '../services/mock_data.dart';
import '../utils/currency.dart';

/// Holds the in-memory offering and project data used across the app.
class ProjectProvider extends ChangeNotifier {
  List<Offering> _offerings = [];
  List<Project> _projects = [];
  final List<OfferingActivity> _activities = [];
  bool _hasLoaded = false;
  bool _isLoading = false;
  String? _error;

  List<Offering> get offerings => _offerings;
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Activity feed entries for [offeringId], oldest first.
  List<OfferingActivity> activitiesFor(String offeringId) {
    final items = [
      for (final activity in _activities)
        if (activity.offeringId == offeringId) activity,
    ];
    items.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return items;
  }

  Future<void> addActivity(OfferingActivity activity) async {
    _activities.add(activity);
    notifyListeners();
  }

  /// Seeds the activity entries that can be derived from [offering]'s current
  /// state. Entries whose type already exists are skipped, so this is safe to
  /// call every time the detail screen opens.
  Future<void> ensureActivities(
    Offering offering, {
    String? contactName,
  }) async {
    final existingTypes = <ActivityType>{
      for (final activity in _activities)
        if (activity.offeringId == offering.id) activity.type,
    };
    final missing = [
      for (final activity in _seedActivities(offering, contactName))
        if (!existingTypes.contains(activity.type)) activity,
    ];
    if (missing.isEmpty) return;
    _activities.addAll(missing);
    notifyListeners();
  }

  List<OfferingActivity> _seedActivities(
    Offering offering,
    String? contactName,
  ) {
    final now = DateTime.now();
    final owner = offering.owner.isEmpty ? 'the client' : offering.owner;
    final recipient = (contactName?.trim().isNotEmpty ?? false)
        ? contactName!.trim()
        : 'the client';
    final activities = <OfferingActivity>[
      OfferingActivity(
        id: 'seed-${offering.id}-created',
        offeringId: offering.id,
        type: ActivityType.created,
        title: 'Offering created',
        subtitle: offering.lineItems.isEmpty
            ? 'Draft prepared for $owner'
            : '${offering.lineItems.length} '
                  '${offering.lineItems.length == 1 ? 'work item' : 'work items'} '
                  'prepared for $owner',
        occurredAt: now.subtract(const Duration(days: 4)),
      ),
    ];

    if (offering.status != OfferingStatus.draft) {
      activities.add(
        OfferingActivity(
          id: 'seed-${offering.id}-sent',
          offeringId: offering.id,
          type: ActivityType.sent,
          title: 'Proposal sent',
          subtitle: 'Shared with $recipient',
          occurredAt: now.subtract(const Duration(days: 3)),
        ),
      );
    }

    switch (offering.status) {
      case OfferingStatus.accepted:
        activities.add(
          OfferingActivity(
            id: 'seed-${offering.id}-accepted',
            offeringId: offering.id,
            type: ActivityType.accepted,
            title: 'Proposal accepted',
            subtitle: 'Client approved the offering',
            occurredAt: now.subtract(const Duration(days: 2)),
          ),
        );
      case OfferingStatus.rejected:
        activities.add(
          OfferingActivity(
            id: 'seed-${offering.id}-rejected',
            offeringId: offering.id,
            type: ActivityType.rejected,
            title: 'Proposal declined',
            subtitle: 'Client rejected the offering',
            occurredAt: now.subtract(const Duration(days: 2)),
          ),
        );
      case OfferingStatus.expired:
        activities.add(
          OfferingActivity(
            id: 'seed-${offering.id}-expired',
            offeringId: offering.id,
            type: ActivityType.expired,
            title: 'Offering expired',
            subtitle: 'The validity period ended',
            occurredAt: now.subtract(const Duration(days: 2)),
          ),
        );
      case OfferingStatus.draft:
      case OfferingStatus.sent:
        break;
    }

    if (offering.paidStatus != PaidStatus.unpaid) {
      final fullyPaid = offering.paidStatus == PaidStatus.paid;
      activities.add(
        OfferingActivity(
          id: 'seed-${offering.id}-payment',
          offeringId: offering.id,
          type: fullyPaid
              ? ActivityType.paymentCompleted
              : ActivityType.payment,
          title: fullyPaid ? 'Payment completed' : 'Partial payment received',
          subtitle: fullyPaid
              ? '${formatRupiah(offering.amountPaid)} settled in full'
              : '${formatRupiah(offering.amountPaid)} paid so far',
          occurredAt: now.subtract(const Duration(hours: 20)),
        ),
      );
    }

    if (offering.hasProject) {
      activities.add(
        OfferingActivity(
          id: 'seed-${offering.id}-project',
          offeringId: offering.id,
          type: ActivityType.projectCreated,
          title: 'Project created',
          subtitle: 'Execution is ready to start',
          occurredAt: now.subtract(const Duration(days: 1)),
        ),
      );
    }

    return activities;
  }

  Offering? offeringById(String id) {
    for (final offering in _offerings) {
      if (offering.id == id) return offering;
    }
    return null;
  }

  Project? projectById(String id) {
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  Project? projectForOffering(String offeringId) {
    for (final project in _projects) {
      if (project.offeringId == offeringId) return project;
    }
    return null;
  }

  /// Loads the initial project data when a screen needs it without replacing
  /// data that has already been loaded or added.
  Future<void> ensureProjectsLoaded() async {
    if (_isLoading ||
        _hasLoaded ||
        _offerings.isNotEmpty ||
        _projects.isNotEmpty) {
      return;
    }
    await fetchProjects();
  }

  Future<void> fetchProjects() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // Keep in-memory additions and edits when reloading. Local records win
      // when the same id exists in the mock data.
      _offerings = _mergeOfferings(MockData.offerings(), _offerings);
      _projects = _mergeProjects(MockData.projects(), _projects);
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Offering> _mergeOfferings(List<Offering> loaded, List<Offering> local) {
    final byId = <String, Offering>{
      for (final offering in loaded) offering.id: offering,
    };
    for (final offering in local) {
      byId[offering.id] = offering;
    }
    return byId.values.toList();
  }

  List<Project> _mergeProjects(List<Project> loaded, List<Project> local) {
    final byId = <String, Project>{
      for (final project in loaded) project.id: project,
    };
    for (final project in local) {
      byId[project.id] = project;
    }
    return byId.values.toList();
  }

  Future<void> addOffering(Offering offering) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _offerings.add(offering);
    final owner = offering.owner.trim();
    final itemCount = offering.lineItems.length;
    final itemLabel = itemCount == 1 ? 'work item' : 'work items';
    _activities.add(
      OfferingActivity(
        id: 'ACT-${offering.id}-created',
        offeringId: offering.id,
        type: ActivityType.created,
        title: 'Offering created',
        subtitle: itemCount > 0
            ? '$itemCount $itemLabel prepared${owner.isEmpty ? '' : ' for $owner'}'
            : 'Draft prepared${owner.isEmpty ? '' : ' for $owner'}',
        occurredAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> updateOffering(Offering offering) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _offerings.indexWhere((o) => o.id == offering.id);
    if (index != -1) {
      _offerings[index] = offering;
      notifyListeners();
    }
  }

  Future<void> deleteOffering(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _offerings.removeWhere((o) => o.id == id);
    _activities.removeWhere((activity) => activity.offeringId == id);
    notifyListeners();
  }

  Future<void> addProject(Project project) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _projects.add(project);
    _activities.add(
      OfferingActivity(
        id: 'ACT-${project.id}-created',
        offeringId: project.offeringId,
        type: ActivityType.projectCreated,
        title: 'Project created',
        subtitle: 'Execution is ready to start',
        occurredAt: DateTime.now(),
      ),
    );
    final offering = offeringById(project.offeringId);
    if (offering != null) {
      _offerings = [
        for (final o in _offerings)
          if (o.id == offering.id)
            Offering(
              id: o.id,
              number: o.number,
              name: o.name,
              serviceType: o.serviceType,
              owner: o.owner,
              clientId: o.clientId,
              address: o.address,
              latitude: o.latitude,
              longitude: o.longitude,
              status: o.status,
              paidStatus: o.paidStatus,
              budgetAmount: o.budgetAmount,
              lineItems: o.lineItems,
              terms: o.terms,
              numberingStyle: o.numberingStyle,
              amountPaid: o.amountPaid,
              clientHasRecentOffer: o.clientHasRecentOffer,
              rentalUntil: o.rentalUntil,
              projectId: project.id,
            )
          else
            o,
      ];
    }
    notifyListeners();
  }

  Future<void> updateProject(Project project) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
      notifyListeners();
    }
  }

  Future<void> deleteProject(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _projects.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Keeps the field team names on projects in sync after [worker] is edited.
  void syncWorker(User worker) {
    var changed = false;
    final updated = <Project>[];
    for (final project in _projects) {
      if (!project.isAssignedTo(worker.id)) {
        updated.add(project);
        continue;
      }

      final index = project.assignedWorkerIds.indexOf(worker.id);
      final names = [...project.assignedWorkerNames];
      if (index < names.length) {
        if (names[index] == worker.name) {
          updated.add(project);
          continue;
        }
        names[index] = worker.name;
      } else {
        while (names.length < index) {
          names.add('');
        }
        names.add(worker.name);
      }

      updated.add(project.copyWith(assignedWorkerNames: names));
      changed = true;
    }

    _projects = updated;
    if (changed) notifyListeners();
  }

  /// Removes [workerId] from every project's field team.
  void removeWorkerFromProjects(String workerId) {
    var changed = false;
    final updated = <Project>[];
    for (final project in _projects) {
      if (!project.isAssignedTo(workerId)) {
        updated.add(project);
        continue;
      }

      final ids = <String>[];
      final names = <String>[];
      for (var i = 0; i < project.assignedWorkerIds.length; i++) {
        if (project.assignedWorkerIds[i] == workerId) continue;
        ids.add(project.assignedWorkerIds[i]);
        if (i < project.assignedWorkerNames.length) {
          names.add(project.assignedWorkerNames[i]);
        }
      }
      updated.add(
        project.copyWith(assignedWorkerIds: ids, assignedWorkerNames: names),
      );
      changed = true;
    }

    _projects = updated;
    if (changed) notifyListeners();
  }
}
