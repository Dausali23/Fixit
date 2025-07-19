import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/category_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    // Initialize default categories if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _categoryService.initializeDefaultCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _refreshPage() {
    setState(() {
      // Just trigger a rebuild
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPage,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search box
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
          
          // Categories list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').snapshots(),
              builder: (context, snapshot) {
                // Show loading spinner
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Handle error state
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                
                // If no data
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No categories found. Add a category to get started.'),
                  );
                }
                
                // Get the categories and filter by search query
                final categories = snapshot.data!.docs
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'name': data['name'] as String? ?? '',
                      'description': data['description'] as String? ?? '',
                      'icon': data['icon'] as String? ?? 'build',
                      'color': data['color'] as String? ?? 'grey',
                      'active': data['active'] as bool? ?? true,
                    };
                  })
                  .where((category) => 
                    _searchQuery.isEmpty || 
                    category['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
                  )
                  .toList();
                
                if (categories.isEmpty) {
                  return const Center(
                    child: Text('No matching categories found.'),
                  );
                }
                
                // Build the list
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorFromString(category['color'].toString()),
                          child: Icon(
                            _getIconFromString(category['icon'].toString()),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(category['name'].toString()),
                        subtitle: Text(category['description'].toString()),
                        trailing: Switch(
                          value: category['active'] as bool,
                          onChanged: (value) {
                            _updateCategoryStatus(category['id'].toString(), value);
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => CategoryEditScreen(
                                categoryId: category['id'].toString(),
                                name: category['name'].toString(),
                                description: category['description'].toString(),
                                onSave: _refreshPage,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryAddScreen(
                onSave: _refreshPage,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Helper methods to convert string to IconData and Color
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'water_drop': return Icons.water_drop;
      case 'electrical_services': return Icons.electrical_services;
      case 'ac_unit': return Icons.ac_unit;
      case 'kitchen': return Icons.kitchen;
      case 'pest_control': return Icons.pest_control;
      case 'handyman': return Icons.handyman;
      case 'brush': return Icons.brush;
      case 'roofing': return Icons.roofing;
      case 'yard': return Icons.yard;
      case 'grid_on': return Icons.grid_on;
      default: return Icons.build;
    }
  }
  
  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'blue': return Colors.blue;
      case 'amber': return Colors.amber;
      case 'lightBlue': return Colors.lightBlue;
      case 'green': return Colors.green;
      case 'brown': return Colors.brown;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      case 'purple': return Colors.purple;
      case 'teal': return Colors.teal;
      default: return Colors.grey;
    }
  }
  
  // Update category status
  Future<void> _updateCategoryStatus(String id, bool active) async {
    try {
      await FirebaseFirestore.instance
        .collection('categories')
        .doc(id)
        .update({'active': active});
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Separate screen for adding a new category
class CategoryAddScreen extends StatefulWidget {
  final Function onSave;
  
  const CategoryAddScreen({
    super.key,
    required this.onSave,
  });

  @override
  State<CategoryAddScreen> createState() => _CategoryAddScreenState();
}

class _CategoryAddScreenState extends State<CategoryAddScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isSaving = false;
  String _selectedIcon = 'build';
  String _selectedColor = 'grey';
  
  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'Plumbing', 'icon': 'water_drop', 'color': 'blue'},
    {'name': 'Electrical', 'icon': 'electrical_services', 'color': 'amber'},
    {'name': 'HVAC', 'icon': 'ac_unit', 'color': 'lightBlue'},
    {'name': 'Appliance', 'icon': 'kitchen', 'color': 'green'},
    {'name': 'Pest Control', 'icon': 'pest_control', 'color': 'brown'},
    {'name': 'Carpentry', 'icon': 'handyman', 'color': 'orange'},
    {'name': 'Painting', 'icon': 'brush', 'color': 'purple'},
    {'name': 'Roofing', 'icon': 'roofing', 'color': 'red'},
    {'name': 'Landscaping', 'icon': 'yard', 'color': 'green'},
    {'name': 'Flooring', 'icon': 'grid_on', 'color': 'teal'},
    {'name': 'General', 'icon': 'build', 'color': 'grey'},
  ];
  
  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Suggest icon based on name
                if (value.isNotEmpty) {
                  for (var option in _iconOptions) {
                    if (value.toLowerCase().contains(option['name'].toString().toLowerCase())) {
                      setState(() {
                        _selectedIcon = option['icon'];
                        _selectedColor = option['color'];
                      });
                      break;
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Icon & Color',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _iconOptions.length,
                itemBuilder: (context, index) {
                  final option = _iconOptions[index];
                  final iconName = option['icon'];
                  final colorName = option['color'];
                  final isSelected = _selectedIcon == iconName && _selectedColor == colorName;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconName;
                        _selectedColor = colorName;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey.shade200 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: _getColorFromString(colorName),
                          child: Icon(
                            _getIconFromString(iconName),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveCategory,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isSaving 
                ? const CircularProgressIndicator()
                : const Text('Save Category'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods to convert string to IconData and Color
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'water_drop': return Icons.water_drop;
      case 'electrical_services': return Icons.electrical_services;
      case 'ac_unit': return Icons.ac_unit;
      case 'kitchen': return Icons.kitchen;
      case 'pest_control': return Icons.pest_control;
      case 'handyman': return Icons.handyman;
      case 'brush': return Icons.brush;
      case 'roofing': return Icons.roofing;
      case 'yard': return Icons.yard;
      case 'grid_on': return Icons.grid_on;
      default: return Icons.build;
    }
  }
  
  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'blue': return Colors.blue;
      case 'amber': return Colors.amber;
      case 'lightBlue': return Colors.lightBlue;
      case 'green': return Colors.green;
      case 'brown': return Colors.brown;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      case 'purple': return Colors.purple;
      case 'teal': return Colors.teal;
      default: return Colors.grey;
    }
  }
  
  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      // Add to Firestore with selected icon and color
      await FirebaseFirestore.instance.collection('categories').add({
        'name': name,
        'description': description,
        'icon': _selectedIcon,
        'color': _selectedColor,
        'active': true,
      });
      
      if (!mounted) return;
      
      widget.onSave();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Separate screen for editing a category
class CategoryEditScreen extends StatefulWidget {
  final String categoryId;
  final String name;
  final String description;
  final Function onSave;
  
  const CategoryEditScreen({
    super.key,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.onSave,
  });

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isSaving = false;
  String _selectedIcon = 'build';
  String _selectedColor = 'grey';
  
  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'Plumbing', 'icon': 'water_drop', 'color': 'blue'},
    {'name': 'Electrical', 'icon': 'electrical_services', 'color': 'amber'},
    {'name': 'HVAC', 'icon': 'ac_unit', 'color': 'lightBlue'},
    {'name': 'Appliance', 'icon': 'kitchen', 'color': 'green'},
    {'name': 'Pest Control', 'icon': 'pest_control', 'color': 'brown'},
    {'name': 'Carpentry', 'icon': 'handyman', 'color': 'orange'},
    {'name': 'Painting', 'icon': 'brush', 'color': 'purple'},
    {'name': 'Roofing', 'icon': 'roofing', 'color': 'red'},
    {'name': 'Landscaping', 'icon': 'yard', 'color': 'green'},
    {'name': 'Flooring', 'icon': 'grid_on', 'color': 'teal'},
    {'name': 'General', 'icon': 'build', 'color': 'grey'},
  ];
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _descController = TextEditingController(text: widget.description);
    
    // Load current icon and color
    _loadCurrentIconAndColor();
  }
  
  Future<void> _loadCurrentIconAndColor() async {
    try {
      final doc = await FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.categoryId)
        .get();
      
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _selectedIcon = data['icon'] as String? ?? 'build';
          _selectedColor = data['color'] as String? ?? 'grey';
        });
      }
    } catch (e) {
      // Default values will be used
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Icon & Color',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _iconOptions.length,
                itemBuilder: (context, index) {
                  final option = _iconOptions[index];
                  final iconName = option['icon'];
                  final colorName = option['color'];
                  final isSelected = _selectedIcon == iconName && _selectedColor == colorName;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconName;
                        _selectedColor = colorName;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey.shade200 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: _getColorFromString(colorName),
                          child: Icon(
                            _getIconFromString(iconName),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveCategory,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isSaving 
                ? const CircularProgressIndicator()
                : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods to convert string to IconData and Color
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'water_drop': return Icons.water_drop;
      case 'electrical_services': return Icons.electrical_services;
      case 'ac_unit': return Icons.ac_unit;
      case 'kitchen': return Icons.kitchen;
      case 'pest_control': return Icons.pest_control;
      case 'handyman': return Icons.handyman;
      case 'brush': return Icons.brush;
      case 'roofing': return Icons.roofing;
      case 'yard': return Icons.yard;
      case 'grid_on': return Icons.grid_on;
      default: return Icons.build;
    }
  }
  
  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'blue': return Colors.blue;
      case 'amber': return Colors.amber;
      case 'lightBlue': return Colors.lightBlue;
      case 'green': return Colors.green;
      case 'brown': return Colors.brown;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      case 'purple': return Colors.purple;
      case 'teal': return Colors.teal;
      default: return Colors.grey;
    }
  }
  
  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      // Update in Firestore with selected icon and color
      await FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.categoryId)
        .update({
          'name': name,
          'description': description,
          'icon': _selectedIcon,
          'color': _selectedColor,
        });
      
      if (!mounted) return;
      
      widget.onSave();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 