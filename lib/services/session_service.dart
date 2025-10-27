// ============================================
// File: lib/services/session_service.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class SessionService extends ChangeNotifier {
  User? _currentUser;

  // Getters
  User? get currentUser => _currentUser;
  bool get hasSession => _currentUser != null && _currentUser!.id.isNotEmpty;
  String? get userId => _currentUser?.id;
  String? get username => _currentUser?.username;
  String? get userRole => _currentUser?.role;
  String? get token => _currentUser?.token;

  // Save user session to SharedPreferences
  Future<void> saveUser(User user) async {
    if (user.id.isEmpty) {
      print('SessionService: Cannot save user with empty ID');
      return;
    }

    try {
      print('SessionService: Saving user session for ${user.username}');
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('userId', user.id);
      await prefs.setString('username', user.username);
      await prefs.setString('role', user.role);

      if (user.token != null && user.token!.isNotEmpty) {
        await prefs.setString('token', user.token!);
        print('SessionService: Token saved');
      } else {
        await prefs.remove('token');
        print('SessionService: Token removed (was null/empty)');
      }

      _currentUser = user;
      ApiService.setAuthToken(user.token);
      notifyListeners();

      print('SessionService: User session saved successfully');
    } catch (e) {
      print('SessionService: Error saving user session - $e');
    }
  }

  // Load user session from SharedPreferences
  Future<void> loadUser() async {
    try {
      print('SessionService: Loading user session...');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null && userId.isNotEmpty) {
        final username = prefs.getString('username') ?? '';
        final role = prefs.getString('role') ?? 'user';
        final token = prefs.getString('token');

        _currentUser = User(
          id: userId,
          username: username,
          role: role,
          token: token,
        );

        ApiService.setAuthToken(token);
        notifyListeners();

        print('SessionService: Session loaded for $username ($role)');
      } else {
        print('SessionService: No saved session found');
      }
    } catch (e) {
      print('SessionService: Error loading user session - $e');
    }
  }

  // Clear user session
  Future<void> clearSession() async {
    try {
      print('SessionService: Clearing user session...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _currentUser = null;
      ApiService.setAuthToken(null);
      notifyListeners();

      print('SessionService: Session cleared successfully');
    } catch (e) {
      print('SessionService: Error clearing session - $e');
    }
  }

  // Update user data in session
  Future<void> updateUser(User user) async {
    if (user.id.isEmpty) {
      print('SessionService: Cannot update user with empty ID');
      return;
    }

    try {
      print('SessionService: Updating user session for ${user.username}');
      await saveUser(user);
    } catch (e) {
      print('SessionService: Error updating user - $e');
    }
  }

  // Check if session is valid
  bool isSessionValid() {
    if (_currentUser == null) {
      return false;
    }

    if (_currentUser!.id.isEmpty) {
      return false;
    }

    return true;
  }

  // Refresh session (reload from storage)
  Future<void> refreshSession() async {
    await loadUser();
  }
}
