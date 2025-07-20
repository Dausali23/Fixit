import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'repair_request_form.dart';
import 'repair_history_page.dart';
import 'profile_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final AuthService _authService = AuthService();
  String _userName = '';
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final userData = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userName = userData?['name'] ?? '';
          _isLoadingName = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = '';
          _isLoadingName = false;
        });
      }
    }
  }

  void _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FixIt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.handyman,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            // Personalized Greeting
            if (_isLoadingName)
              const CircularProgressIndicator()
            else if (_userName.isNotEmpty)
              Text(
                'Hi ${_userName.split(' ').first}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'Welcome to FixIt',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your Home Repair Solution',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RepairRequestForm()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text('Report an Issue'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RepairHistoryPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text('View Repair History'),
            ),
          ],
        ),
      ),
    );
  }
} 