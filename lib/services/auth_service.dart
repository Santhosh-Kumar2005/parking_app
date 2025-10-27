// ============================================
// File: lib/services/auth_service.dart
// COMPLETE STANDALONE VERSION - COPY THIS ENTIRE FILE
// ============================================

import 'package:flutter/material.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _user;

  // Getters
  bool get isLoggedIn => _user != null && _user!.id.isNotEmpty;
  String? get userRole => _user?.role;
  String? get userId => _user?.id;
  String? get token => _user?.token;
  String? get username => _user?.username;
  User? get user => _user;

  // Set user (for session restoration)
  void setUser(User user) {
    if (user.id.isEmpty) {
      print('Warning: Attempted to set user with empty ID');
      return;
    }
    _user = user;
    ApiService.setAuthToken(user.token);
    notifyListeners();
  }

  // Login method
  Future<bool> login(String username, String password) async {
    try {
      print('AuthService: Attempting login for $username');
      final user = await ApiService.login(username, password);

      if (user != null && user.id.isNotEmpty) {
        print('AuthService: Login successful for ${user.username}');
        _user = user;
        ApiService.setAuthToken(user.token);
        notifyListeners();
        return true;
      }

      print('AuthService: Login failed - invalid credentials');
      return false;
    } catch (e) {
      print('AuthService: Login error - $e');
      return false;
    }
  }

  // Register method
  Future<bool> register(String username, String password, String role) async {
    try {
      print('AuthService: Attempting registration for $username as $role');
      final user = await ApiService.register(username, password, role);

      if (user != null && user.id.isNotEmpty) {
        print('AuthService: Registration successful for ${user.username}');
        _user = user;
        ApiService.setAuthToken(user.token);
        notifyListeners();
        return true;
      }

      print('AuthService: Registration failed');
      return false;
    } catch (e) {
      print('AuthService: Registration error - $e');
      return false;
    }
  }

  // Logout method
  void logout() {
    print('AuthService: Logging out user ${_user?.username}');
    _user = null;
    ApiService.logout();
    notifyListeners();
  }

  // Check if user is admin
  bool isAdmin() {
    return _user?.role == 'admin';
  }

  // Check if user is regular user
  bool isUser() {
    return _user?.role == 'user';
  }
}
