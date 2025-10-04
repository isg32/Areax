import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

// --- AUTHENTICATION SERVICE ---
class AuthService extends ChangeNotifier {
  String? _authToken;
  String? _userName;
  bool _isLoading = true;

  String? get authToken => _authToken;
  String? get userName => _userName;
  bool get isAuthenticated => _authToken != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(kAuthTokenKey);
    _userName = prefs.getString(kAuthUserNameKey);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String user, String key) async {
    try {
      final response = await http.post(
        Uri.parse('$kApiUrl/authenticate'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user': user, 'key': key}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['authenticated'] == true) {
          final token = data['token'] ?? 'mock_token_${user}'; 
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(kAuthTokenKey, token);
          await prefs.setString(kAuthUserNameKey, user);
          _authToken = token;
          _userName = user;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      // Handle network/parsing error
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kAuthTokenKey);
    await prefs.remove(kAuthUserNameKey);
    _authToken = null;
    _userName = null;
    notifyListeners();
  }
}
