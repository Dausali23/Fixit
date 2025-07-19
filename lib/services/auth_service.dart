import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Simple auth state notifier
  final ValueNotifier<User?> authStateNotifier = ValueNotifier<User?>(null);
  
  // Constructor - initialize state
  AuthService() {
    // Initialize the notifier with current user
    authStateNotifier.value = _auth.currentUser;
    
    // Set up auth state listener
    _auth.authStateChanges().listen((User? user) {
      developer.log('Auth state changed: ${user?.email ?? 'No user'}');
      authStateNotifier.value = user;
    });
  }
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Sign in with email and password - with workaround for type casting issues
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      developer.log('Attempting sign in: $email');
      
      // Try to sign in - this might throw the type casting error
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // Check if this is the specific type casting error we're seeing
        if (e.toString().contains("type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?'")) {
          // The login likely succeeded despite the error
          developer.log('Caught type casting error but auth may have succeeded');
          
          // Check if we have a user now
          if (_auth.currentUser != null) {
            developer.log('User is signed in despite error: ${_auth.currentUser?.email}');
            return true;
          }
        }
        
        // Rethrow if it's not our specific error or if we couldn't recover
        rethrow;
      }
      
      // If no exception, check for current user
      final user = _auth.currentUser;
      
      if (user == null) {
        developer.log('Sign in completed but user is null');
        return false;
      }
      
      developer.log('Sign in successful: ${user.email}');
      return true;
    } catch (e) {
      developer.log('Sign in error: $e');
      return false;
    }
  }
  
  // Register with email and password - with workaround for type casting issues
  Future<bool> registerWithEmailPassword(String email, String password, String name, String phone) async {
    try {
      developer.log('Attempting registration: $email');
      
      // Try to register - this might throw the type casting error
      try {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // Check if this is the specific type casting error we're seeing
        if (e.toString().contains("type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?'") ) {
          // The registration likely succeeded despite the error
          developer.log('Caught type casting error but registration may have succeeded');
          
          // Check if we have a user now
          if (_auth.currentUser != null) {
            developer.log('User is registered despite error: ${_auth.currentUser?.email}');
            // Create user profile in Firestore
            await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
              'name': name,
              'email': email,
              'phone': phone,
            });
            return true;
          }
        }
        
        // Rethrow if it's not our specific error or if we couldn't recover
        rethrow;
      }
      
      // If no exception, check for current user
      final user = _auth.currentUser;
      
      // Check if user is null
      if (user == null) {
        developer.log('Registration completed but user is null');
        return false;
      }
      
      developer.log('Registration successful: ${user.email}');
      // Create user profile in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
      });
      return true;
    } catch (e) {
      developer.log('Registration error: $e');
      return false;
    }
  }
  
  // Sign out - simplified
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      developer.log('User signed out');
      return true;
    } catch (e) {
      developer.log('Sign out error: $e');
      return false;
    }
  }
  
  // Get user display name or email
  String getUserDisplayName() {
    final user = _auth.currentUser;
    if (user == null) return '';
    return user.displayName ?? user.email ?? '';
  }
  
  // Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      developer.log('Error getting user profile: $e');
      return null;
    }
  }
  
  // Update user profile data in Firestore
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      await _firestore.collection('users').doc(user.uid).update(profileData);
      developer.log('User profile updated successfully');
      return true;
    } catch (e) {
      developer.log('Error updating user profile: $e');
      return false;
    }
  }
  
  // Direct check if current user is admin - avoids the problematic type casting
  Future<bool> isUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        developer.log('No current user, cannot check admin status');
        return false;
      }
      
      // Force admin for specific email
      if (user.email?.toLowerCase() == 'admin1@gmail.com') {
        developer.log('Admin account detected via direct email check: ${user.email}');
        return true;
      }
      
      // Check Firestore directly 
      try {
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get()
            .timeout(const Duration(seconds: 5), onTimeout: () {
              throw FirebaseException(
                plugin: 'firestore', 
                message: 'Connection timeout when accessing Firestore'
              );
            });
            
        if (!docSnapshot.exists) {
          return false;
        }
        
        // Safe way to check without casting to a specific type
        final data = docSnapshot.data();
        if (data == null) return false;
        
        final roleValue = data['role'];
        final isAdmin = (roleValue != null && roleValue == 'admin');
        developer.log('Admin check via Firestore: ${user.email} is ${isAdmin ? 'admin' : 'regular user'}');
        return isAdmin;
      } catch (e) {
        developer.log('Firestore admin check error: $e');
        // If Firestore is unavailable, default to non-admin for safety
        // except for the known admin email
        return user.email?.toLowerCase() == 'admin1@gmail.com';
      }
    } catch (e) {
      developer.log('Admin check error: $e');
      return false;
    }
  }
}