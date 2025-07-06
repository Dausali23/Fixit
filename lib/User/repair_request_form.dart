import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/auth_service.dart';

class RepairRequestForm extends StatefulWidget {
  const RepairRequestForm({super.key});

  @override
  State<RepairRequestForm> createState() => _RepairRequestFormState();
}

class _RepairRequestFormState extends State<RepairRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _selectedCategory = 'Plumbing';
  bool _isSubmitting = false;
  File? _imageFile;
  bool _isUploadingImage = false;
  
  final List<String> _categories = [
    'Plumbing',
    'Electrical',
    'Air Conditioning',
    'Appliance Repair',
    'Pest Control',
    'Maintenance',
    'Other'
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080, // Limit image size to reduce upload time and storage
        maxHeight: 1080,
        imageQuality: 85, // Slightly compressed for faster upload
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImageToStorage(String userId) async {
    if (_imageFile == null) return null;
    
    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Create a reference to the location you want to upload to in Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('request_images')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the file
      await storageRef.putFile(_imageFile!);
      
      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Get current user
        User? user = _authService.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to submit a request')),
          );
          return;
        }

        // Upload image if one is selected
        String? imageUrl;
        if (_imageFile != null) {
          imageUrl = await _uploadImageToStorage(user.uid);
        }

        // Get user data from Firestore
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        // Create the repair request
        await FirebaseFirestore.instance.collection('requests').add({
          'userId': user.uid,
          'userName': userData['name'] ?? 'Unknown',
          'userEmail': user.email,
          'category': _selectedCategory,
          'description': _descriptionController.text,
          'address': _addressController.text,
          'status': 'Pending',
          'hasImage': _imageFile != null,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'technician': null,
        });

        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repair request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return to previous page
        Navigator.pop(context);
      } catch (e) {
        // Show error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Description text field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Please describe the issue in detail',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please describe the issue';
                    }
                    if (value.length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Address text field
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    hintText: 'Where should the technician go?',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Image upload button
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera),
                  label: Text(_imageFile != null 
                      ? 'Change Photo' 
                      : 'Add Photo (Optional)'),
                  onPressed: _isSubmitting ? null : _showImagePicker,
                ),
                if (_imageFile != null) ...[
                  const SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (_isUploadingImage)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                  // Remove image button
                  TextButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove Photo'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _imageFile = null;
                            });
                          },
                  ),
                ],
                const SizedBox(height: 30),
                
                // Submit button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Submitting...'),
                          ],
                        )
                      : const Text('Submit Request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 