import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../services/authentication_service.dart';
import 'login_screen.dart';
import 'forgot_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthenticationService _authService = AuthenticationService();
  bool _isLoading = false;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
  }

  Future<void> _loadCurrentUsername() async {
    final userId = await _getCurrentUserId();
    if (userId != null) {
      final user = await _dbHelper.getUserById(userId);
      setState(() {
        _currentUsername = user?['username'] ?? 'Unknown';
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await _showConfirmationDialog('Are you sure you want to log out?');
    if (confirmed) {
      await _authService.logoutUser();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showConfirmationDialog('Are you sure you want to delete your account?');
    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      final userId = await _getCurrentUserId();
      if (userId != null) {
        await _dbHelper.deleteUser(userId);
        await _authService.logoutUser();
      }

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _changeUsername() async {
    final newUsername = await _showChangeUsernameDialog();
    if (newUsername != null) {
      final userId = await _getCurrentUserId();
      if (userId != null) {
        final existingUser = await _dbHelper.getUserByUsername(newUsername);
        if (existingUser != null) {
          _showErrorMessage('Username already taken. Please choose another.');
          return;
        }
        await _dbHelper.updateUsername(userId, newUsername);
        _showErrorMessage('Username updated successfully.', isError: false);
        setState(() {
          _currentUsername = newUsername;
        });
      }
    }
  }

  Future<int?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<bool> _showConfirmationDialog(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<String?> _showChangeUsernameDialog() async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newUsername = controller.text.trim();
              if (newUsername.isEmpty) {
                _showErrorMessage('Username cannot be empty.');
              } else {
                Navigator.of(context).pop(newUsername);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ListTile(
                    leading: GestureDetector(
                      onTap: _changeUsername,
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                    title: GestureDetector(
                      onTap: _changeUsername,
                      child: Text(
                        _currentUsername ?? 'Username',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_open, color: Colors.white),
                    title: const Text('Forgot/Change Password', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: const Text('Log Out', style: TextStyle(color: Colors.white)),
                    onTap: _logout,
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
    );
  }
}
