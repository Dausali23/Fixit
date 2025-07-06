import 'package:flutter/material.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final List<Map<String, dynamic>> _categories = [
    {
      'id': '1',
      'name': 'Plumbing',
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'description': 'Water leaks, clogged drains, toilet issues',
      'active': true,
    },
    {
      'id': '2',
      'name': 'Electrical',
      'icon': Icons.electrical_services,
      'color': Colors.amber,
      'description': 'Power outages, wiring issues, lighting installation',
      'active': true,
    },
    {
      'id': '3',
      'name': 'Air Conditioning',
      'icon': Icons.ac_unit,
      'color': Colors.lightBlue,
      'description': 'AC not cooling, heating issues, thermostat problems',
      'active': true,
    },
    {
      'id': '4',
      'name': 'Appliance Repair',
      'icon': Icons.kitchen,
      'color': Colors.green,
      'description': 'Refrigerator, dishwasher, oven, washer/dryer issues',
      'active': true,
    },
    {
      'id': '5',
      'name': 'Pest Control',
      'icon': Icons.pest_control,
      'color': Colors.brown,
      'description': 'Insect infestations, rodent removal',
      'active': true,
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCategories {
    return _categories
        .where((category) => category['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Categories'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Categories',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category['color'],
                      child: Icon(
                        category['icon'],
                        color: Colors.white,
                      ),
                    ),
                    title: Text(category['name']),
                    subtitle: Text(category['description']),
                    trailing: Switch(
                      value: category['active'],
                      onChanged: (value) {
                        setState(() {
                          // Find actual index in original list
                          final originalIndex = _categories.indexWhere(
                              (c) => c['id'] == category['id']);
                          if (originalIndex != -1) {
                            _categories[originalIndex]['active'] = value;
                          }
                        });
                      },
                    ),
                    onTap: () {
                      _showCategoryEditDialog(category);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryEditDialog(Map<String, dynamic> category) {
    final TextEditingController nameController =
        TextEditingController(text: category['name']);
    final TextEditingController descController =
        TextEditingController(text: category['description']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
              ),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  // Find actual index in original list
                  final index =
                      _categories.indexWhere((c) => c['id'] == category['id']);
                  if (index != -1) {
                    _categories[index]['name'] = nameController.text;
                    _categories[index]['description'] = descController.text;
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
      descController.dispose();
    });
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
              ),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _categories.add({
                    'id': (_categories.length + 1).toString(),
                    'name': nameController.text,
                    'description': descController.text,
                    'icon': Icons.build,
                    'color': Colors.grey,
                    'active': true,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
      descController.dispose();
    });
  }
} 