import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

class LocationPicker extends StatefulWidget {
  final String initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(String address, double latitude, double longitude) onLocationSelected;

  const LocationPicker({
    super.key, 
    required this.onLocationSelected,
    this.initialAddress = '',
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late GoogleMapController _mapController;
  final TextEditingController _addressController = TextEditingController();
  bool _isSearching = false;
  String _errorMessage = '';
  
  // Default map center (will be replaced with selected location if available)
  LatLng _center = const LatLng(-6.2088, 106.8456); // Jakarta, Indonesia
  Marker? _marker;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress;
    
    // If we have initial coordinates, use them
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _center = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _marker = Marker(
        markerId: const MarkerId('selected_location'),
        position: _center,
      );
    } 
    // Otherwise if we have an address but no coordinates, try to geocode it
    else if (widget.initialAddress.isNotEmpty) {
      _geocodeAddress(widget.initialAddress);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Convert address to coordinates
  Future<void> _geocodeAddress(String address) async {
    if (address.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });
    
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final newPosition = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _center = newPosition;
          _marker = Marker(
            markerId: const MarkerId('selected_location'),
            position: newPosition,
          );
          _isSearching = false;
        });
        
        _mapController.animateCamera(CameraUpdate.newLatLng(newPosition));
      } else {
        setState(() {
          _isSearching = false;
          _errorMessage = 'No location found for that address';
        });
      }
    } catch (e) {
      developer.log('Error geocoding address: $e');
      setState(() {
        _isSearching = false;
        _errorMessage = 'Could not find location: $e';
      });
    }
  }
  
  // Convert coordinates to address (reverse geocoding)
  Future<void> _reverseGeocode(LatLng position) async {
    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = _formatAddress(placemark);
        
        setState(() {
          _addressController.text = address;
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Could not determine address for this location';
        });
      }
    } catch (e) {
      developer.log('Error reverse geocoding: $e');
      setState(() {
        _isSearching = false;
        _errorMessage = 'Could not determine address: $e';
      });
    }
  }
  
  // Format address from placemark
  String _formatAddress(Placemark placemark) {
    final components = [
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ];
    
    return components
        .where((component) => component != null && component.isNotEmpty)
        .join(', ');
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  
  void _onMapTapped(LatLng position) {
    setState(() {
      _marker = Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
      );
    });
    
    _reverseGeocode(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          TextButton(
            onPressed: () {
              if (_marker != null) {
                widget.onLocationSelected(
                  _addressController.text,
                  _marker!.position.latitude,
                  _marker!.position.longitude
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a location first'))
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          hintText: 'Enter an address to search',
                          suffixIcon: _isSearching 
                              ? const CircularProgressIndicator()
                              : IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () => _geocodeAddress(_addressController.text),
                                ),
                          errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                        ),
                        onSubmitted: (_) => _geocodeAddress(_addressController.text),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 14.0,
                  ),
                  onTap: _onMapTapped,
                  markers: _marker != null ? <Marker>{_marker!} : <Marker>{},
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              heroTag: 'current_location',
              onPressed: () async {
                try {
                  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location services are disabled.')),
                    );
                    return;
                  }
                  LocationPermission permission = await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.denied) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location permissions are denied.')),
                      );
                      return;
                    }
                  }
                  if (permission == LocationPermission.deniedForever) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location permissions are permanently denied.')),
                    );
                    return;
                  }
                  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                  LatLng currentLatLng = LatLng(position.latitude, position.longitude);
                  setState(() {
                    _center = currentLatLng;
                    _marker = Marker(
                      markerId: const MarkerId('selected_location'),
                      position: currentLatLng,
                    );
                  });
                  _mapController.animateCamera(CameraUpdate.newLatLng(currentLatLng));
                  await _reverseGeocode(currentLatLng);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error getting current location: $e')),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
} 