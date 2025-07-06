import 'package:flutter/material.dart';

class CategoryOptions {
  static final List<Map<String, dynamic>> iconOptions = [
    {'name': 'Plumbing', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'Electrical', 'icon': Icons.electrical_services, 'color': Colors.amber},
    {'name': 'HVAC', 'icon': Icons.ac_unit, 'color': Colors.lightBlue},
    {'name': 'Appliance', 'icon': Icons.kitchen, 'color': Colors.green},
    {'name': 'Pest Control', 'icon': Icons.pest_control, 'color': Colors.brown},
    {'name': 'Carpentry', 'icon': Icons.handyman, 'color': Colors.orange},
    {'name': 'Painting', 'icon': Icons.brush, 'color': Colors.purple},
    {'name': 'Roofing', 'icon': Icons.roofing, 'color': Colors.red},
    {'name': 'Landscaping', 'icon': Icons.yard, 'color': Colors.green.shade800},
    {'name': 'Flooring', 'icon': Icons.grid_on, 'color': Colors.teal},
    {'name': 'General', 'icon': Icons.build, 'color': Colors.grey},
  ];
  
  // Find an icon and color for a category
  static Map<String, dynamic> getIconForCategory(String categoryName) {
    final match = iconOptions.firstWhere(
      (option) => categoryName.toLowerCase().contains(option['name'].toString().toLowerCase()),
      orElse: () => {'name': 'General', 'icon': Icons.build, 'color': Colors.grey},
    );
    
    return {
      'icon': match['icon'],
      'color': match['color'],
    };
  }
} 