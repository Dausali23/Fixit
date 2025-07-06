import 'package:flutter/material.dart';

class Category {
  String? id;
  String name;
  String description;
  IconData icon;
  Color color;
  bool active;

  Category({
    this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.active = true,
  });

  // Create a Category from a Map (used when retrieving from Firestore)
  factory Category.fromMap(Map<String, dynamic> map, String docId) {
    return Category(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: _getIconFromString(map['icon'] ?? 'build'),
      color: _getColorFromString(map['color'] ?? 'grey'),
      active: map['active'] ?? true,
    );
  }

  // Convert Category to a Map (used when saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': _getStringFromIcon(icon),
      'color': _getStringFromColor(color),
      'active': active,
    };
  }

  // Helper methods to convert between IconData and String
  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'kitchen':
        return Icons.kitchen;
      case 'pest_control':
        return Icons.pest_control;
      case 'handyman':
        return Icons.handyman;
      case 'brush':
        return Icons.brush;
      case 'roofing':
        return Icons.roofing;
      case 'yard':
        return Icons.yard;
      case 'floor':
        return Icons.grid_on;
      default:
        return Icons.build;
    }
  }

  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.water_drop) return 'water_drop';
    if (icon == Icons.electrical_services) return 'electrical_services';
    if (icon == Icons.ac_unit) return 'ac_unit';
    if (icon == Icons.kitchen) return 'kitchen';
    if (icon == Icons.pest_control) return 'pest_control';
    if (icon == Icons.handyman) return 'handyman';
    if (icon == Icons.brush) return 'brush';
    if (icon == Icons.roofing) return 'roofing';
    if (icon == Icons.yard) return 'yard';
    if (icon == Icons.grid_on) return 'floor';
    return 'build';
  }

  // Helper methods to convert between Color and String
  static Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'amber':
        return Colors.amber;
      case 'lightBlue':
        return Colors.lightBlue;
      case 'green':
        return Colors.green;
      case 'brown':
        return Colors.brown;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  static String _getStringFromColor(Color color) {
    if (color == Colors.blue) return 'blue';
    if (color == Colors.amber) return 'amber';
    if (color == Colors.lightBlue) return 'lightBlue';
    if (color == Colors.green) return 'green';
    if (color == Colors.brown) return 'brown';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.red) return 'red';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.teal) return 'teal';
    return 'grey';
  }
} 