import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'User/login_page.dart';
import 'User/user_home_page.dart';
import 'Admin/admin_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('Firebase initialized successfully');
  } catch (e) {
    developer.log('Error initializing Firebase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixIt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isCheckingAdmin = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  bool _timeoutOccurred = false;
  
  @override
  void initState() {
    super.initState();
    _checkInitialAuthState();
    
    // Add a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isCheckingAdmin) {
        setState(() {
          _isCheckingAdmin = false;
          _timeoutOccurred = true;
          _errorMessage = 'Could not connect to the database. Please check your internet connection and try again.';
        });
      }
    });
  }
  
  // Check auth state on start and set up listener
  void _checkInitialAuthState() async {
    // Check current user (might already be logged in)
    final user = _authService.currentUser;
    if (user != null) {
      _handleAuthenticatedUser(user);
    }
    
    // Set up listener for future auth changes
    _authService.authStateNotifier.addListener(_handleAuthStateChange);
  }
  
  // Called whenever auth state changes
  void _handleAuthStateChange() {
    final user = _authService.authStateNotifier.value;
    if (user != null) {
      _handleAuthenticatedUser(user);
    } else {
      // Reset admin state when logged out
      setState(() {
        _isAdmin = false;
        _isCheckingAdmin = false;
      });
    }
  }
  
  // Handle the authenticated user state
  void _handleAuthenticatedUser(User user) async {
    try {
      setState(() {
        _isCheckingAdmin = true;
        _errorMessage = '';
      });
      
      developer.log('Checking admin status for: ${user.email}');
      
      // Special check for admin1@gmail.com - use this as the only admin check
      final isAdmin = user.email?.toLowerCase() == 'admin1@gmail.com';
      if (isAdmin) {
        developer.log('Admin email detected: ${user.email}');
        setState(() {
          _isAdmin = true;
          _isCheckingAdmin = false;
        });
        return;
      } else {
        // All other users are regular users
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _isCheckingAdmin = false;
          });
        }
      }
    } catch (e) {
      developer.log('Error determining admin status: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isCheckingAdmin = false;
          _errorMessage = 'Error checking permissions';
        });
      }
    }
  }
  
  @override
  void dispose() {
    // Remove listener when widget is disposed
    _authService.authStateNotifier.removeListener(_handleAuthStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    // Show loading indicator while checking admin status
    if (_isCheckingAdmin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Show error screen if we encountered a timeout or other error
    if (_timeoutOccurred || _errorMessage.isNotEmpty) {
      return _buildErrorScreen(
        _timeoutOccurred ? 'Connection Error' : 'Authentication Error', 
        _errorMessage
      );
    }
    
    // Show login page if not authenticated
    if (user == null) {
      return const LoginPage();
    }
    
    // Navigate to appropriate page based on admin status
    return _isAdmin ? const AdminHomePage() : const UserHomePage();
  }
  
  // Helper method to build error screens
  Widget _buildErrorScreen(String title, String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                message,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => const LoginPage())
              ),
              child: const Text('Go to Login'),
            )
          ],
        ),
      ),
    );
  }
}
