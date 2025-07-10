import 'package:flutter/material.dart';
import 'package:ioe_mobile_app/models/user_model.dart';
import 'package:ioe_mobile_app/services/api_service.dart';

// This class manages the user's authentication state
class AuthService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;

  User? get currentUser => _currentUser;

  // Simulates logging in a user based on their role
  Future<void> login(UserRole role) async {
    _currentUser = await _apiService.loginAs(role);
    // Notify listeners (like the UI) that the user has changed
    notifyListeners();
  }

  // Simulates logging out
  Future<void> logout() async {
    _currentUser = null;
    // Notify listeners that the user has logged out
    notifyListeners();
  }
}