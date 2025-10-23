// lib/services/session_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:parking_app/services/api_service.dart'; // add this import

class SessionService extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<void> saveUser(User user) async {
    // FIXED: Guard against empty ID
    if (user.id.isEmpty) {
      print('Warning: Attempted to save user with empty ID. Skipping.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('role', user.role);
    if (user.token != null) {
      await prefs.setString('token', user.token!);
    } else {
      await prefs.remove('token');
    }
    _currentUser = user;
    ApiService.setAuthToken(user.token);
    notifyListeners();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    // FIXED: Also check for non-empty
    if (userId != null && userId.isNotEmpty) {
      _currentUser = User(
        id: userId,
        username: prefs.getString('username') ?? '',
        role: prefs.getString('role') ?? 'user',
        token: prefs.getString('token'),
      );
      ApiService.setAuthToken(_currentUser?.token);
      notifyListeners();
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentUser = null;
    ApiService.setAuthToken(null);
    notifyListeners();
  }
}
