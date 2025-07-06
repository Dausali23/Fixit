import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/technician.dart';

class TechnicianService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'technicians';

  // Get technician collection reference
  CollectionReference get _techniciansCollection => 
      _firestore.collection(_collection);

  // Get all technicians
  Stream<List<Technician>> getTechnicians() {
    return _techniciansCollection
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Technician.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            );
          }).toList();
        });
  }

  // Add a new technician
  Future<String?> addTechnician(Technician technician) async {
    try {
      final docRef = await _techniciansCollection.add(technician.toMap());
      developer.log('Added technician: ${technician.name} with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      developer.log('Error adding technician: $e');
      return null;
    }
  }

  // Update a technician
  Future<bool> updateTechnician(Technician technician) async {
    try {
      if (technician.id == null) {
        throw Exception('Cannot update technician without an ID');
      }
      
      await _techniciansCollection
          .doc(technician.id)
          .update(technician.toMap());
      
      developer.log('Updated technician: ${technician.name}');
      return true;
    } catch (e) {
      developer.log('Error updating technician: $e');
      return false;
    }
  }

  // Delete a technician
  Future<bool> deleteTechnician(String id) async {
    try {
      await _techniciansCollection.doc(id).delete();
      developer.log('Deleted technician with ID: $id');
      return true;
    } catch (e) {
      developer.log('Error deleting technician: $e');
      return false;
    }
  }

  // Update technician availability
  Future<bool> updateTechnicianAvailability(String id, bool available) async {
    try {
      await _techniciansCollection.doc(id).update({'available': available});
      developer.log('Updated technician availability: $id to $available');
      return true;
    } catch (e) {
      developer.log('Error updating technician availability: $e');
      return false;
    }
  }
} 