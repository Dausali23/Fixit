import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:async';
import '../models/technician.dart';
import '../services/technician_service.dart';
import '../constants/specialty_options.dart';
import '../components/location_picker.dart';

class TechniciansPage extends StatefulWidget {
  const TechniciansPage({super.key});

  @override
  State<TechniciansPage> createState() => _TechniciansPageState();
}

class _TechniciansPageState extends State<TechniciansPage> {
  final TechnicianService _technicianService = TechnicianService();
  List<Technician> _technicians = [];
  bool _isLoading = true;
  String _errorMessage = '';
  List<String> _specialtyOptions = [];
  StreamSubscription<List<Technician>>? _techniciansSubscription;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
    _loadSpecialtyOptions();
  }

  @override
  void dispose() {
    _techniciansSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSpecialtyOptions() async {
    try {
      final options = await SpecialtyOptions.getOptions();
      if (mounted) {
        setState(() {
          _specialtyOptions = options;
        });
      }
    } catch (e) {
      developer.log('Error loading specialty options: $e');
      // Fall back to default options
      if (mounted) {
        setState(() {
          _specialtyOptions = SpecialtyOptions.options;
        });
      }
    }
  }

  void _loadTechnicians() {
    // Cancel previous subscription if exists
    _techniciansSubscription?.cancel();
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    // Create new subscription
    _techniciansSubscription = _technicianService.getTechnicians().listen(
      (technicians) {
        if (mounted) {
          setState(() {
            _technicians = technicians;
            _isLoading = false;
            
            // Debug log
            developer.log('Loaded ${technicians.length} technicians');
            for (var tech in technicians) {
              developer.log('Technician: ${tech.name}, ${tech.specialties.join(", ")}');
            }
          });
        }
      },
      onError: (error) {
        developer.log('Error loading technicians: $error');
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load technicians: ${error.toString()}';
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Technicians'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Technicians'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadTechnicians(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Technicians'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTechnicians,
            tooltip: 'Refresh technicians list',
          ),
        ],
      ),
      body: _technicians.isEmpty
          ? const Center(
              child: Text('No technicians found. Add a technician to get started.'),
            )
          : ListView.builder(
              itemCount: _technicians.length,
              itemBuilder: (context, index) {
                final technician = _technicians[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(technician.name[0]),
                    ),
                    title: Text(technician.name),
                    subtitle: Text('${technician.specialties.join(", ")} • ${technician.jobs} jobs completed'),
                    trailing: Switch(
                      value: technician.available,
                      onChanged: (value) async {
                        if (technician.id != null) {
                          final success = await _technicianService.updateTechnicianAvailability(
                            technician.id!,
                            value,
                          );
                          
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update availability'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    onTap: () => _showTechnicianDetails(technician),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTechnicianDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTechnicianDetails(Technician technician) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(technician.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specialties: ${technician.specialties.join(", ")}'),
            Text('Phone: ${technician.phone}'),
            Text('Email: ${technician.email}'),
            Text('Address: ${technician.address}'),
            Text('Jobs Completed: ${technician.jobs}'),
            Text('Rating: ${technician.rating}'),
            Text('Status: ${technician.available ? 'Available' : 'Unavailable'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditTechnicianDialog(technician);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () async {
              // Store context locally
              final currentContext = context;
              
              final confirmed = await showDialog<bool>(
                context: currentContext,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text('Are you sure you want to delete this technician?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true && technician.id != null && mounted) {
                Navigator.pop(currentContext); // Close details dialog
                await _technicianService.deleteTechnician(technician.id!);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddTechnicianDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTechnicianScreen(
          specialtyOptions: _specialtyOptions,
          onTechnicianAdded: () {
            // The stream will automatically update
          },
        ),
      ),
    );
  }
  
  void _showEditTechnicianDialog(Technician technician) {
    final TextEditingController nameController = TextEditingController(text: technician.name);
    final TextEditingController phoneController = TextEditingController(text: technician.phone);
    final TextEditingController emailController = TextEditingController(text: technician.email);
    final TextEditingController addressController = TextEditingController(text: technician.address);
    
    List<String> selectedSpecialties = List.from(technician.specialties);
    
    double? latitude = technician.latitude;
    double? longitude = technician.longitude;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Technician'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Specialties',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _specialtyOptions.length,
                      itemBuilder: (context, index) {
                        final specialty = _specialtyOptions[index];
                        return CheckboxListTile(
                          title: Text(specialty),
                          value: selectedSpecialties.contains(specialty),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedSpecialties.add(specialty);
                              } else {
                                selectedSpecialties.remove(specialty);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            hintText: 'Enter technician location',
                          ),
                          keyboardType: TextInputType.streetAddress,
                          maxLines: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map),
                        tooltip: 'Pick location on map',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationPicker(
                                initialAddress: addressController.text,
                                initialLatitude: latitude,
                                initialLongitude: longitude,
                                onLocationSelected: (address, lat, lng) {
                                  setState(() {
                                    addressController.text = address;
                                    latitude = lat;
                                    longitude = lng;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                                    if (technician.id != null &&
                      nameController.text.isNotEmpty && 
                      phoneController.text.isNotEmpty &&
                      emailController.text.isNotEmpty &&
                      addressController.text.isNotEmpty &&
                      selectedSpecialties.isNotEmpty) {
                    
                    final updatedTechnician = Technician(
                      id: technician.id,
                      name: nameController.text,
                      specialties: selectedSpecialties,
                      phone: phoneController.text,
                      email: emailController.text,
                      address: addressController.text,
                      latitude: latitude,
                      longitude: longitude,
                      jobs: technician.jobs,
                      rating: technician.rating,
                      available: technician.available,
                    );
                    
                    try {
                      final success = await _technicianService.updateTechnician(updatedTechnician);
                      
                      // Close dialog after operation
                      Navigator.pop(context);
                      
                      if (mounted) {
                        if (success) {
                          // Don't call _loadTechnicians() - the stream will automatically update
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Technician updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          // Failed but no exception
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update technician'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      // Close dialog even if there's an error
                      Navigator.pop(context);
                      
                      developer.log('Error updating technician: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    ).then((_) {
      // Dispose controllers
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      addressController.dispose();
    });
  }
}

class AddTechnicianScreen extends StatefulWidget {
  final List<String> specialtyOptions;
  final VoidCallback onTechnicianAdded;

  const AddTechnicianScreen({
    super.key,
    required this.specialtyOptions,
    required this.onTechnicianAdded,
  });

  @override
  State<AddTechnicianScreen> createState() => _AddTechnicianScreenState();
}

class _AddTechnicianScreenState extends State<AddTechnicianScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TechnicianService _technicianService = TechnicianService();
  
  List<String> _selectedSpecialties = [];
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Technician'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Specialties',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.specialtyOptions.length,
                itemBuilder: (context, index) {
                  final specialty = widget.specialtyOptions[index];
                  return CheckboxListTile(
                    title: Text(specialty),
                    value: _selectedSpecialties.contains(specialty),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedSpecialties.add(specialty);
                        } else {
                          _selectedSpecialties.remove(specialty);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter technician location',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.streetAddress,
                    maxLines: 2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.map),
                  tooltip: 'Pick location on map',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPicker(
                          initialAddress: _addressController.text,
                          initialLatitude: _latitude,
                          initialLongitude: _longitude,
                          onLocationSelected: (address, lat, lng) {
                            setState(() {
                              _addressController.text = address;
                              _latitude = lat;
                              _longitude = lng;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _addTechnician,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Add Technician'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTechnician() async {
    // Validate fields
    if (_nameController.text.isEmpty || 
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create technician object
      final newTechnician = Technician(
        name: _nameController.text,
        specialties: _selectedSpecialties,
        phone: _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        latitude: _latitude,
        longitude: _longitude,
      );

      // Add to Firebase
      final result = await _technicianService.addTechnician(newTechnician);

      if (mounted) {
        if (result != null) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Technician added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          // Failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add technician'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 