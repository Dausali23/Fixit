import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  final Map<String, dynamic> _settings = {
    'notifications': true,
    'darkMode': false,
    'autoAssign': false,
    'requestTimeout': 3, // days
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Application Settings'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: _settings['darkMode'],
            onChanged: (value) {
              setState(() {
                _settings['darkMode'] = value;
              });
            },
          ),
          const Divider(),
          
          _buildSectionHeader('Notification Settings'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Enable notifications for new requests'),
            value: _settings['notifications'],
            onChanged: (value) {
              setState(() {
                _settings['notifications'] = value;
              });
            },
          ),
          const Divider(),
          
          _buildSectionHeader('Request Settings'),
          SwitchListTile(
            title: const Text('Auto-assign Technicians'),
            subtitle: const Text('Automatically assign technicians based on specialty'),
            value: _settings['autoAssign'],
            onChanged: (value) {
              setState(() {
                _settings['autoAssign'] = value;
              });
            },
          ),
          ListTile(
            title: const Text('Request Timeout (Days)'),
            subtitle: Text('Requests marked as pending for more than ${_settings['requestTimeout']} days will be flagged'),
            trailing: DropdownButton<int>(
              value: _settings['requestTimeout'],
              items: [1, 2, 3, 5, 7, 14].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _settings['requestTimeout'] = newValue;
                });
              },
            ),
          ),
          const Divider(),
          
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            subtitle: Text('Logged in as ${_authService.currentUser?.email ?? 'Unknown'}'),
            onTap: () {
              // Navigate to profile page
            },
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Change Password'),
            onTap: () {
              _showChangePasswordDialog();
            },
          ),
          const Divider(),
          
          _buildSectionHeader('Database'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Data'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup started...'),
                ),
              );
              // Implement backup functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Data'),
            onTap: () {
              // Implement restore functionality
            },
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _showClearDataConfirmationDialog();
              },
              child: const Text('Reset Application Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
  
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
              ),
              obscureText: true,
            ),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
              obscureText: true,
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement password change
              if (newPasswordController.text == confirmPasswordController.text) {
                // Save password
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    ).then((_) {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }
  
  void _showClearDataConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Application Data'),
        content: const Text('This will delete all data including repair requests, user data, and settings. This action cannot be undone. Are you sure you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              // Implement data reset
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application data has been reset'),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
} 