import 'dart:io';

import 'package:flutter/material.dart';
import 'database_helper.dart';

class DatabaseService extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Future<void> updateUserProfile(int userId, Map<String, dynamic> updates) async {
    try {
      await _dbHelper.updateUser(userId, updates);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
  
  Future<Map<String, dynamic>> getUserStats(int userId) async {
    try {
      // Ini hanya contoh, sesuaikan dengan struktur database Anda
      return {
        'totalOrders': 0,
        'totalSpent': '0',
      };
    } catch (e) {
      return {
        'totalOrders': 0,
        'totalSpent': '0',
      };
    }
  }
  
  Future<String?> uploadImage(File imageFile) async {
    // Untuk SQLite, kita simpan path lokal
    // Implementasi penyimpanan gambar lokal
    return null;
  }
}