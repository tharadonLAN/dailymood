import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class AuthenticationService {
  Future<bool> loginUser(String email, String password) async {
    final user = await DatabaseHelper().getUserByEmail(email);

    if (user != null && user['password'] == password) {
      final userId = user['id'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', userId);

      return true; 
    }
    return false; 
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); 
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId'); 
  }
}
