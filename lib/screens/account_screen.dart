import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/constants.dart';

class AccountScreen extends StatelessWidget {
  final AuthService authService;
  const AccountScreen({super.key, required this.authService});

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              authService.logout();
            },
            style: FilledButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_rounded, size: 40, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authService.userName ?? 'User Not Set',
                              style: theme.textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Status: Logged In',
                              style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 30),            
                    ListTile(
                      leading: Icon(Icons.switch_account_rounded, color: theme.colorScheme.primary),
                      title: const Text('Change Account'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        authService.logout();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: kErrorColor),
              title: const Text('Logout'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showLogoutConfirmation(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              tileColor: Colors.white,
            ),

            const Spacer(),
            Center(
              child: Text(
                'Areax - By isg32 ❤️',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
