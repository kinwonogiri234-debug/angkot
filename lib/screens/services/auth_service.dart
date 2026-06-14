import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String get userRole => _currentUser?['role'] ?? '';
  String get userName => _currentUser?['name'] ?? '';
  String get userEmail => _currentUser?['email'] ?? '';
  int get userId => _currentUser?['id'] ?? 0;

  // Demo accounts untuk testing
  final List<Map<String, dynamic>> _demoUsers = [
    {
      'id': 1,
      'email': 'admin@angkot.com',
      'password': 'admin123',
      'name': 'Admin Angkot',
      'phone': '081234567890',
      'role': 'admin',
      'profile_image': null,
    },
    {
      'id': 2,
      'email': 'driver@angkot.com',
      'password': 'driver123',
      'name': 'Budi Driver',
      'phone': '081234567891',
      'role': 'driver',
      'profile_image': null,
    },
    {
      'id': 3,
      'email': 'user@angkot.com',
      'password': 'user123',
      'name': 'Andi User',
      'phone': '081234567892',
      'role': 'user',
      'profile_image': null,
    },
  ];

  Future<String> signIn(String email, String password) async {
    try {
      // Simulasi delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final user = _demoUsers.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => {},
      );
      
      if (user.isNotEmpty) {
        _currentUser = Map.from(user);
        notifyListeners();
        return 'Success';
      } else {
        return 'Email atau password salah';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Cek apakah email sudah ada
      final existingUser = _demoUsers.firstWhere(
        (u) => u['email'] == email,
        orElse: () => {},
      );
      
      if (existingUser.isNotEmpty) {
        return 'Email sudah terdaftar';
      }
      
      return 'Success';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_currentUser != null) {
      _currentUser!.addAll(updates);
      notifyListeners();
    }
  }

  Future<void> updateDriverStatus(bool isAvailable) async {
    notifyListeners();
  }
}