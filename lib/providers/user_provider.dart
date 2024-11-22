import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class UserProvider extends ChangeNotifier {
  int? _userId; // เก็บ userId ของผู้ใช้ที่ล็อกอินอยู่
  String? _username; // เก็บชื่อผู้ใช้
  bool _isLoggedIn = false; // ตรวจสอบสถานะล็อกอิน

  final DatabaseHelper _dbHelper = DatabaseHelper();

  int? get userId => _userId;
  String? get username => _username;
  bool get isLoggedIn => _isLoggedIn;

  Future<bool> loginUser(String email, String password) async {
    final user = await _dbHelper.getUserByEmail(email);

    if (user != null && user['password'] == password) {
      _userId = user['id'];
      _username = user['username'];
      _isLoggedIn = true;

      notifyListeners();
      return true;
    }
    return false;
  }

  void logoutUser() {
    _userId = null;
    _username = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> updateUsername(String newUsername) async {
    if (_userId != null) {
      await _dbHelper.updateUsername(_userId!, newUsername);
      _username = newUsername;
      notifyListeners();
    }
  }

  Future<void> deleteUser() async {
    if (_userId != null) {
      await _dbHelper.deleteUser(_userId!);
      logoutUser();
    }
  }

  Future<void> checkLoginStatus() async {
    notifyListeners();
  }
}
