import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userData = userData;
          if (userData != null) {
            _nameController.text = userData['name'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await _authService.updateUserProfile({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (mounted) {
        if (success) {
          setState(() {
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload profile data
          await _loadUserProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset to original values if canceling edit
        if (_userData != null) {
          _nameController.text = _userData!['name'] ?? '';
          _phoneController.text = _userData!['phone'] ?? '';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isLoading && _userData != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: _toggleEdit,
              tooltip: _isEditing ? 'Cancel Edit' : 'Edit Profile',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('Failed to load profile data'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  _userData!['name']?.substring(0, 1).toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _userData!['name'] ?? 'Unknown User',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _userData!['email'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Profile Information
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Email Field (Read-only)
                        TextFormField(
                          controller: _emailController,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone Field
                        TextFormField(
                          controller: _phoneController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        
                        // Save Button (only show when editing)
                        if (_isEditing) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator()
                                  : const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }



  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
} 