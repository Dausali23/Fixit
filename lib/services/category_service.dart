import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';

  // Get category collection reference
  CollectionReference get _categoriesCollection => 
      _firestore.collection(_collection);

  // Get all categories
  Stream<List<Category>> getCategories() {
    return _categoriesCollection
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Category.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            );
          }).toList();
        });
  }

  // Add a new category
  Future<String?> addCategory(Category category) async {
    try {
      final docRef = await _categoriesCollection.add(category.toMap());
      developer.log('Added category: ${category.name} with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      developer.log('Error adding category: $e');
      return null;
    }
  }

  // Update a category
  Future<bool> updateCategory(Category category) async {
    try {
      if (category.id == null) {
        throw Exception('Cannot update category without an ID');
      }
      
      await _categoriesCollection
          .doc(category.id)
          .update(category.toMap());
      
      developer.log('Updated category: ${category.name}');
      return true;
    } catch (e) {
      developer.log('Error updating category: $e');
      return false;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(String id) async {
    try {
      await _categoriesCollection.doc(id).delete();
      developer.log('Deleted category with ID: $id');
      return true;
    } catch (e) {
      developer.log('Error deleting category: $e');
      return false;
    }
  }

  // Update category active status
  Future<bool> updateCategoryStatus(String id, bool active) async {
    try {
      await _categoriesCollection.doc(id).update({'active': active});
      developer.log('Updated category status: $id to $active');
      return true;
    } catch (e) {
      developer.log('Error updating category status: $e');
      return false;
    }
  }
  
  // Initialize default categories if none exist
  Future<void> initializeDefaultCategories() async {
    try {
      // Check if categories exist
      final snapshot = await _categoriesCollection.limit(1).get();
      
      // If no categories exist, add default ones
      if (snapshot.docs.isEmpty) {
        developer.log('No categories found. Adding default categories...');
        
        final List<Category> defaultCategories = [
          Category(
            name: 'Plumbing',
            description: 'Water leaks, clogged drains, toilet issues',
            icon: Icons.water_drop,
            color: Colors.blue,
          ),
          Category(
            name: 'Electrical',
            description: 'Power outages, wiring issues, lighting installation',
            icon: Icons.electrical_services,
            color: Colors.amber,
          ),
          Category(
            name: 'Air Conditioning',
            description: 'AC not cooling, heating issues, thermostat problems',
            icon: Icons.ac_unit,
            color: Colors.lightBlue,
          ),
          Category(
            name: 'Appliance Repair',
            description: 'Refrigerator, dishwasher, oven, washer/dryer issues',
            icon: Icons.kitchen,
            color: Colors.green,
          ),
          Category(
            name: 'Pest Control',
            description: 'Insect infestations, rodent removal',
            icon: Icons.pest_control,
            color: Colors.brown,
          ),
        ];
        
        // Add each default category
        for (final category in defaultCategories) {
          await addCategory(category);
        }
        
        developer.log('Added ${defaultCategories.length} default categories.');
      }
    } catch (e) {
      developer.log('Error initializing default categories: $e');
    }
  }
} 