import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class RepairHistoryPage extends StatefulWidget {
  const RepairHistoryPage({super.key});

  @override
  State<RepairHistoryPage> createState() => _RepairHistoryPageState();
}

class _RepairHistoryPageState extends State<RepairHistoryPage> {
  final AuthService _authService = AuthService();
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair History'),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildRequestList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            _buildFilterChip('Pending'),
            _buildFilterChip('In Progress'),
            _buildFilterChip('Completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        selected: _selectedFilter == label,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).colorScheme.primary.withAlpha(51),
      ),
    );
  }

  Widget _buildRequestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final requests = snapshot.data?.docs ?? [];
        
        if (requests.isEmpty) {
          return const Center(
            child: Text('No repair requests found'),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index].data() as Map<String, dynamic>;
            final requestId = requests[index].id;
            final status = request['status'] as String? ?? 'Pending';
            final category = request['category'] as String? ?? 'Unknown';
            final description = request['description'] as String? ?? 'No description';
            final createdAt = request['createdAt'] as Timestamp? ?? Timestamp.now();
            final date = DateTime.fromMillisecondsSinceEpoch(
                createdAt.millisecondsSinceEpoch);
            final formattedDate = '${date.day}/${date.month}/${date.year}';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(category),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('Date: $formattedDate'),
                  ],
                ),
                trailing: Chip(
                  label: Text(status),
                  backgroundColor: _getStatusColor(status),
                ),
                onTap: () => _showRequestDetails(requestId, request),
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getRequestsStream() {
    final user = _authService.currentUser;
    
    if (user == null) {
      // Return empty stream if no user
      return const Stream.empty();
    }

    Query query = FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    // Apply status filter if not 'All'
    if (_selectedFilter != 'All') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange[100]!;
      case 'In Progress':
        return Colors.blue[100]!;
      case 'Completed':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  void _showRequestDetails(String requestId, Map<String, dynamic> request) {
    final status = request['status'] as String? ?? 'Pending';
    final category = request['category'] as String? ?? 'Unknown';
    final description = request['description'] as String? ?? 'No description';
    final address = request['address'] as String? ?? 'No address provided';
    final createdAt = request['createdAt'] as Timestamp? ?? Timestamp.now();
    final date = DateTime.fromMillisecondsSinceEpoch(
        createdAt.millisecondsSinceEpoch);
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    final technician = request['technician'] as String? ?? 'Not assigned';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Status: $status'),
                Text('Date: $formattedDate'),
                const Divider(),
                Text(
                  'Description:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(description),
                const SizedBox(height: 16),
                Text(
                  'Address:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(address),
                const Divider(),
                Text('Request ID: $requestId'),
                Text('Technician: $technician'),
                const SizedBox(height: 16),
                if (status != 'Completed') ...[
                  OutlinedButton(
                    onPressed: () {
                      // Cancel request
                      _showCancelDialog(requestId);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancel Request'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCancelDialog(String requestId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text(
            'Are you sure you want to cancel this repair request?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              // Close the dialog immediately to avoid BuildContext issues
              Navigator.pop(dialogContext);
              
              // Store a reference to the scaffold messenger and navigator
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              // Now perform the async operation
              _cancelRequest(
                requestId,
                onSuccess: () {
                  if (!mounted) return;
                  
                  // Pop the details bottom sheet
                  navigator.pop();
                  
                  // Show success message
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Request cancelled successfully'),
                    ),
                  );
                },
                onError: (error) {
                  if (!mounted) return;
                  
                  // Show error message
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error cancelling request: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  // Extract the async operation to a separate method
  Future<void> _cancelRequest(
    String requestId, {
    required VoidCallback onSuccess,
    required Function(Object) onError,
  }) async {
    try {
      await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({'status': 'Cancelled'});
      
      onSuccess();
    } catch (error) {
      onError(error);
    }
  }
} 