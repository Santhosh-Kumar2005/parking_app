// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  bool get isLoggedIn => _user != null;
  String? get userRole => _user?.role;
  String? get userId => _user?.id;
  String? get token => _user?.token; // Added token getter

  Future<bool> login(String username, String password) async {
    final user = await ApiService.login(username, password);
    if (user != null && user.id.isNotEmpty) {
      // FIXED: Check for non-empty ID
      _user = user;
      ApiService.setAuthToken(user.token);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String password, String role) async {
    final user = await ApiService.register(username, password, role);
    if (user != null && user.id.isNotEmpty) {
      // FIXED: Check for non-empty ID
      _user = user;
      ApiService.setAuthToken(user.token);
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
