import 'package:flutter/material.dart';

import '../models/offering.dart';
import '../models/project.dart';
import '../services/mock_data.dart';

/// Holds the in-memory offering and project data used across the app.
class ProjectProvider extends ChangeNotifier {
  List<Offering> _offerings = [];
  List<Project> _projects = [];
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

  Future<void> fetchProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _offerings = MockData.offerings();
      _projects = MockData.projects();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
