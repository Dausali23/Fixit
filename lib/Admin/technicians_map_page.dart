import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:developer' as developer;
import '../models/technician.dart';
import '../services/technician_service.dart';

class TechniciansMapPage extends StatefulWidget {
  const TechniciansMapPage({super.key});

  @override
  State<TechniciansMapPage> createState() => _TechniciansMapPageState();
}

class _TechniciansMapPageState extends State<TechniciansMapPage> {
  final TechnicianService _technicianService = TechnicianService();
  List<Technician> _technicians = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Default to Jakarta, Indonesia as initial map location
  final LatLng _defaultLocation = const LatLng(-6.2088, 106.8456);
  Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }
  
  void _loadTechnicians() {
    _isLoading = true;
    _errorMessage = '';
    
    // Cancel previous subscription if exists
    _technicianService.getTechnicians().listen(
      (technicians) {
        if (mounted) {
          setState(() {
            _technicians = technicians;
            _isLoading = false;
            _updateMarkers();
          });
        }
      },
      onError: (error) {
        developer.log('Error loading technicians for map: $error');
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load technicians: ${error.toString()}';
            _isLoading = false;
          });
        }
      },
    );
  }
  
  void _updateMarkers() {
    final markers = <Marker>{};
    
    for (final technician in _technicians) {
      // Only add marker if latitude and longitude are available
      if (technician.latitude != null && technician.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId(technician.id ?? ''),
            position: LatLng(technician.latitude!, technician.longitude!),
            infoWindow: InfoWindow(
              title: technician.name,
              snippet: '${technician.specialty} - ${technician.available ? 'Available' : 'Unavailable'}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              technician.available ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  void _onMapCreated(GoogleMapController controller) {
    // No need to store the controller if we're not using it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technicians Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTechnicians,
            tooltip: 'Refresh map data',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _errorMessage.isNotEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      const Text(
                        'Error',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        onPressed: _loadTechnicians,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _getMapCenter(),
                        zoom: 11.0,
                      ),
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapType: MapType.normal,
                    ),
                    if (_markers.isEmpty)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          color: Colors.white.withAlpha(230),
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No technician locations available. Add technician locations to see them on the map.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
  
  // Find the best center point for the map based on technician locations
  LatLng _getMapCenter() {
    // Filter technicians with valid coordinates
    final techniciansWithCoords = _technicians.where(
      (tech) => tech.latitude != null && tech.longitude != null
    ).toList();
    
    if (techniciansWithCoords.isEmpty) {
      return _defaultLocation;
    }
    
    // If only one technician, center on them
    if (techniciansWithCoords.length == 1) {
      return LatLng(
        techniciansWithCoords[0].latitude!,
        techniciansWithCoords[0].longitude!,
      );
    }
    
    // Otherwise, find the center of all technicians
    double totalLat = 0;
    double totalLng = 0;
    
    for (final tech in techniciansWithCoords) {
      totalLat += tech.latitude!;
      totalLng += tech.longitude!;
    }
    
    return LatLng(
      totalLat / techniciansWithCoords.length,
      totalLng / techniciansWithCoords.length,
    );
  }
} 