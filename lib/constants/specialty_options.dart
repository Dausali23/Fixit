import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialtyOptions {
  // Deprecated static options - keep as fallback
  static const List<String> _fallbackOptions = [
    'Plumbing',
    'Electrical',
    'HVAC',
    'Carpentry',
    'Painting',
    'Appliance Repair',
    'Roofing',
    'Landscaping',
    'Flooring',
    'General Maintenance',
  ];
  
  // Method to get options from Firestore categories
  static Future<List<String>> getOptions() async {
    try {
      final QuerySnapshot snapshot = 
          await FirebaseFirestore.instance.collection('categories').get();
      
      if (snapshot.docs.isEmpty) {
        return _fallbackOptions;
      }
      
      // Extract active category names
      final List<String> options = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((data) => data['active'] == true) // Only include active categories
          .map((data) => data['name'] as String)
          .toList();
      
      return options.isNotEmpty ? options : _fallbackOptions;
    } catch (e) {
      // Return fallback options in case of error
      return _fallbackOptions;
    }
  }
  
  // Temporary property to maintain backward compatibility
  static List<String> get options => _fallbackOptions;
} 