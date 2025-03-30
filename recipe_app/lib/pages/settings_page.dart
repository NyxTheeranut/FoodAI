import 'package:flutter/cupertino.dart';
import 'package:recipe_app/services/api_service.dart';
import 'package:recipe_app/pages/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _apiService.getToken();
    if (token != null) {
      try {
        await _apiService.getUser();
        setState(() {
          _isLoggedIn = true;
        });
      } catch (e) {
        // Handle error silently for now
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Change Password'),
        content: Column(
          children: [
            CupertinoTextField(
              controller: currentPasswordController,
              placeholder: 'Current Password',
              obscureText: true,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: newPasswordController,
              placeholder: 'New Password',
              obscureText: true,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Change'),
            onPressed: () async {
              if (!mounted) return;
              try {
                await _apiService.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _showSuccessDialog('Password changed successfully');
              } catch (e) {
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _showErrorDialog('Error: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    final passwordController = TextEditingController();

    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          children: [
            const Text('Are you sure you want to delete your account? This action cannot be undone.'),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: passwordController,
              placeholder: 'Enter Password',
              obscureText: true,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () async {
              if (!mounted) return;
              try {
                await _apiService.deleteAccount(passwordController.text);
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                setState(() {
                  _isLoggedIn = false;
                });
                _showSuccessDialog('Account deleted successfully');
              } catch (e) {
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _showErrorDialog('Error: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please log in to access this feature.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Login'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => const LoginPage()),
              ).then((_) => _checkLoginStatus());
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            // General Section
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'General',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CupertinoListSection(
              children: [
                CupertinoListTile(
                  title: const Text('About App'),
                  onTap: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                        title: const Text('About Recipe App'),
                        message: const Text('Version 1.0.0\nA simple app to find and save your favorite recipes.'),
                        actions: [
                          CupertinoActionSheetAction(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            // Account Section (for logged-in users)
            if (_isLoggedIn) ...[
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text(
                  'Account',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoListSection(
                children: [
                  CupertinoListTile(
                    title: const Text('Change Password'),
                    onTap: _changePassword,
                  ),
                  CupertinoListTile(
                    title: const DefaultTextStyle(
                      style: TextStyle(color: CupertinoColors.destructiveRed),
                      child: Text('Delete Account'),
                    ),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}