import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/mock_data.dart';

/// Holds the field team members shown on the Workers page.
class WorkerProvider extends ChangeNotifier {
  List<User> _workers = [];
  bool _hasLoaded = false;
  bool _isLoading = false;
  String? _error;

  List<User> get workers => _workers;
  bool get isLoading => _isLoading;
  bool get isLoaded => _hasLoaded;
  String? get error => _error;

  User? workerById(String id) {
    for (final worker in _workers) {
      if (worker.id == id) return worker;
    }
    return null;
  }

  bool emailTaken(String email, {String? ignoreId}) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return _workers.any(
      (worker) =>
          worker.id != ignoreId &&
          worker.email.trim().toLowerCase() == normalized,
    );
  }

  /// Loads the initial worker data when a screen needs it without replacing
  /// data that has already been loaded or added.
  Future<void> ensureWorkersLoaded() async {
    if (_isLoading || _hasLoaded || _workers.isNotEmpty) return;
    await fetchWorkers();
  }

  Future<void> fetchWorkers() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // Keep in-memory additions and edits when reloading. Local records win
      // when the same id exists in the mock data.
      _workers = _mergeWorkers(MockData.workers(), _workers);
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<User> _mergeWorkers(List<User> loaded, List<User> local) {
    final byId = <String, User>{for (final worker in loaded) worker.id: worker};
    for (final worker in local) {
      byId[worker.id] = worker;
    }
    return byId.values.toList();
  }

  Future<void> addWorker(User worker) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _workers.add(worker);
    notifyListeners();
  }

  Future<void> updateWorker(User worker) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _workers.indexWhere((w) => w.id == worker.id);
    if (index != -1) {
      _workers[index] = worker;
      notifyListeners();
    }
  }

  Future<void> deleteWorker(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _workers.removeWhere((w) => w.id == id);
    notifyListeners();
  }
}
