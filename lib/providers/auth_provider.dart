import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/error_logger.dart';
import '../services/mock_data.dart';

class AuthProvider extends ChangeNotifier {
  static const String _sessionKey = 'auth_user';

  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  String get userRole => _user?.role ?? '';

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw != null && raw.isNotEmpty) {
        _user = User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e, st) {
      ErrorLogger.log(e, st, 'AuthProvider.restoreSession');
      _user = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final user = MockData.authenticate(email, password);
      if (user == null) {
        throw Exception('Invalid email or password');
      }
      _user = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    notifyListeners();
  }
}
