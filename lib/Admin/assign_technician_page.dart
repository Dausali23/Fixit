import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class AssignTechnicianPage extends StatefulWidget {
  final Map<String, dynamic> request;
  const AssignTechnicianPage({Key? key, required this.request}) : super(key: key);

  @override
  State<AssignTechnicianPage> createState() => _AssignTechnicianPageState();
}

class _AssignTechnicianPageState extends State<AssignTechnicianPage> {
  late LatLng userLocation;
  late String category;
  List<Map<String, dynamic>> technicians = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    userLocation = LatLng(
      widget.request['latitude'] ?? 0.0,
      widget.request['longitude'] ?? 0.0,
    );
    category = widget.request['category'] ?? '';
    fetchTechnicians();
  }

  Future<void> fetchTechnicians() async {
    setState(() { isLoading = true; });
    
    // Get all technicians and filter by specialties
    final query = await FirebaseFirestore.instance
        .collection('technicians')
        .get();
    
    final techs = <Map<String, dynamic>>[];
    for (var doc in query.docs) {
      final data = doc.data();
      
      // Check if technician has the required specialty
      List<String> specialties = [];
      if (data['specialties'] != null) {
        // New format: specialties array
        specialties = List<String>.from(data['specialties']);
      } else if (data['specialty'] != null) {
        // Old format: single specialty string
        specialties = [data['specialty'] as String];
      }
      
      // Only include technicians who have the required category/specialty
      if (specialties.contains(category) && 
          data['latitude'] != null && 
          data['longitude'] != null) {
        
        double distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          data['latitude'],
          data['longitude'],
        ) / 1000.0; // in km
        
        techs.add({
          ...data,
          'id': doc.id,
          'distance': distance,
          'specialties': specialties, // Use the processed specialties list
        });
      }
    }
    
    techs.sort((a, b) => a['distance'].compareTo(b['distance']));
    setState(() {
      technicians = techs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Technician'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 300,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: userLocation,
                      zoom: 13,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('user'),
                        position: userLocation,
                        infoWindow: const InfoWindow(title: 'User Location'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      ),
                      ...technicians.map((tech) => Marker(
                        markerId: MarkerId(tech['id']),
                        position: LatLng(tech['latitude'], tech['longitude']),
                        infoWindow: InfoWindow(title: tech['name'], snippet: tech['available'] == true ? 'Available' : 'Unavailable'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          tech['available'] == true ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
                        ),
                      ))
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: technicians.length,
                    itemBuilder: (context, index) {
                      final tech = technicians[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.engineering,
                            color: tech['available'] == true ? Colors.green : Colors.red,
                          ),
                          title: Text(tech['name'] ?? '-'),
                          subtitle: Text('${(tech['specialties'] as List<String>).join(", ")}\n${tech['distance'].toStringAsFixed(2)} km away'),
                          trailing: ElevatedButton(
                            onPressed: tech['available'] == true ? () async {
                              print('Assigning technician: ${tech['id']} to request: ${widget.request['id']}');
                              
                              // Assign this technician to the request
                              await FirebaseFirestore.instance
                                  .collection('requests')
                                  .doc(widget.request['id'])
                                  .update({
                                'technician': {
                                  'id': tech['id'],
                                  'name': tech['name'],
                                  'specialties': tech['specialties'],
                                  'phone': tech['phone'],
                                  'latitude': tech['latitude'],
                                  'longitude': tech['longitude'],
                                },
                                'status': 'In Progress',
                              });
                              
                              print('Request updated, now setting technician unavailable');
                              await FirebaseFirestore.instance
                                  .collection('technicians')
                                  .doc(tech['id'])
                                  .update({'available': false});
                              print('Technician availability set to false');
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Technician assigned successfully!')),
                                );
                                Navigator.pop(context);
                              }
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tech['available'] == true ? Colors.green : Colors.grey,
                            ),
                            child: Text(tech['available'] == true ? 'Assign' : 'Unavailable'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
} 