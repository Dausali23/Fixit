import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../User/login_page.dart';
import 'request_list_page.dart';
import 'technicians_page.dart';
import 'technicians_map_page.dart';
import 'categories_page.dart';
import 'settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final AuthService _authService = AuthService();

  void _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FixIt Admin'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildScrollableContent(),
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            _HeaderText(text: 'Admin Dashboard'),
            SizedBox(height: 20),
            _DashboardSummary(),
            SizedBox(height: 30),
            _HeaderText(text: 'Quick Actions', fontSize: 18),
            SizedBox(height: 10),
            _ActionButtonsGrid(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final double fontSize;

  const _HeaderText({
    required this.text,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _DashboardSummary extends StatelessWidget {
  const _DashboardSummary();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Pending Requests
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .where('status', isEqualTo: 'Pending')
              .snapshots(),
          builder: (context, snapshot) {
            int count = 0;
            if (snapshot.hasData) {
              count = snapshot.data!.docs.length;
            }
            return _SummaryCard(
              title: 'Pending Requests',
              value: count.toString(),
              color: Colors.orange,
              icon: Icons.pending_actions,
            );
          },
        ),
        // In Progress
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .where('status', isEqualTo: 'In Progress')
              .snapshots(),
          builder: (context, snapshot) {
            int count = 0;
            if (snapshot.hasData) {
              count = snapshot.data!.docs.length;
            }
            return _SummaryCard(
              title: 'In Progress',
              value: count.toString(),
              color: Colors.blue,
              icon: Icons.engineering,
            );
          },
        ),
        // Completed
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .where('status', isEqualTo: 'Completed')
              .snapshots(),
          builder: (context, snapshot) {
            int count = 0;
            if (snapshot.hasData) {
              count = snapshot.data!.docs.length;
            }
            return _SummaryCard(
              title: 'Completed',
              value: count.toString(),
              color: Colors.green,
              icon: Icons.check_circle,
            );
          },
        ),
        // Total Requests
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('requests').snapshots(),
          builder: (context, snapshot) {
            int count = 0;
            if (snapshot.hasData) {
              count = snapshot.data!.docs.length;
            }
            return _SummaryCard(
              title: 'Total Requests',
              value: count.toString(),
              color: Colors.purple,
              icon: Icons.analytics,
            );
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtonsGrid extends StatelessWidget {
  const _ActionButtonsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return _ActionButton(
              title: 'View All Requests',
              icon: Icons.list_alt,
              color: Colors.indigo,
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const RequestListPage())
                );
              },
            );
          case 1:
            return _ActionButton(
              title: 'Manage Technicians',
              icon: Icons.people,
              color: Colors.teal,
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const TechniciansPage())
                );
              },
            );
          case 2:
            return _ActionButton(
              title: 'Technician Map',
              icon: Icons.map,
              color: Colors.green,
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const TechniciansMapPage())
                );
              },
            );
          case 3:
            return _ActionButton(
              title: 'Categories',
              icon: Icons.category,
              color: Colors.amber,
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const CategoriesPage())
                );
              },
            );
          case 4:
            return _ActionButton(
              title: 'Settings',
              icon: Icons.settings,
              color: Colors.grey,
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const SettingsPage())
                );
              },
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 3),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 