import 'package:flutter/material.dart';
import 'package:ioe_mobile_app/models/user_model.dart';
import 'package:ioe_mobile_app/services/api_service.dart';

class AuthService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _apiService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String department,
    required int? year,
    required UserRole role,
    // UPDATE: Added embeddings as a required parameter for signup.
    required List<List<double>> embeddings,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.signup(
        name: name,
        email: email,
        password: password,
        department: department,
        year: year,
        role: role,
        // UPDATE: Pass embeddings to the API service.
        embeddings: embeddings,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
}