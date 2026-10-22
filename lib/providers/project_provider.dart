import 'package:flutter/material.dart';

import '../models/offering.dart';
import '../models/project.dart';
import '../services/mock_data.dart';

/// Holds the in-memory offering and project data used across the app.
class ProjectProvider extends ChangeNotifier {
  List<Offering> _offerings = [];
  List<Project> _projects = [];
  bool _hasLoaded = false;
  bool _isLoading = false;
  String? _error;

  List<Offering> get offerings => _offerings;
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    notifyListeners();
  }

  Future<void> addProject(Project project) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _projects.add(project);
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
              address: o.address,
              latitude: o.latitude,
              longitude: o.longitude,
              status: o.status,
              paidStatus: o.paidStatus,
              budgetAmount: o.budgetAmount,
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
}
