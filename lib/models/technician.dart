class Technician {
  String? id;
  String name;
  String email;
  String phone;
  List<String> specialties;
  int jobs;
  double rating;
  bool available;
  String address;
  double? latitude;
  double? longitude;

  Technician({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialties,
    this.jobs = 0,
    this.rating = 0.0,
    this.available = true,
    this.address = '',
    this.latitude,
    this.longitude,
  });

  // Create a Technician from a Map (used when retrieving from Firestore)
  factory Technician.fromMap(Map<String, dynamic> map, String docId) {
    // Handle both new format (List) and old format (String) for backward compatibility
    List<String> getSpecialties() {
      if (map['specialties'] != null) {
        return List<String>.from(map['specialties']);
      } else if (map['specialty'] != null) {
        // Convert old format to new format
        return [map['specialty'] as String];
      }
      return [];
    }
    
    return Technician(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      specialties: getSpecialties(),
      jobs: map['jobs'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      available: map['available'] ?? true,
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  // Convert Technician to a Map (used when saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'specialties': specialties,
      'jobs': jobs,
      'rating': rating,
      'available': available,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
} 