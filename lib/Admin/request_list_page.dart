import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assign_technician_page.dart';

class RequestListPage extends StatefulWidget {
  const RequestListPage({super.key});

  @override
  State<RequestListPage> createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage> {
  String _selectedFilter = 'All';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Requests'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Filter by status: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('requests').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error:  ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No requests found.'));
                }

                // Filter requests by status
                final requests = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_selectedFilter == 'All') return true;
                  return data['status'] == _selectedFilter;
                }).toList();

                if (requests.isEmpty) {
                  return const Center(child: Text('No requests found for this filter.'));
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final doc = requests[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(data['description'] ?? 'No Title'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category: ${data['category'] ?? '-'}'),
                            Text('Submitted by: ${data['userName'] ?? '-'}'),
                            Text('Date: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0] : '-'}'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(data['status'] ?? '-'),
                          backgroundColor: _getStatusColor(data['status'] ?? ''),
                        ),
                        onTap: () {
                          _showRequestDetails({
                            ...data,
                            'id': doc.id,
                          });
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
    );
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['description'] ?? 'No Title',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('ID: ${request['id']}'),
                Text('Category: ${request['category'] ?? '-'}'),
                Text('Status: ${request['status'] ?? '-'}'),
                Text('Date: ${request['createdAt'] != null ? (request['createdAt'] as Timestamp).toDate().toString().split(' ')[0] : '-'}'),
                if (((request['status'] ?? '').toString().toLowerCase() == 'in progress' || (request['status'] ?? '').toString().toLowerCase() == 'completed'))
                  Text('Technician: '
                    '${(request['technician'] is Map && request['technician']['name'] != null) ? request['technician']['name'] : 'Not assigned'}'),
                Text('User: ${request['userName'] ?? '-'}'),
                const SizedBox(height: 16),
                Text(
                  'Description:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(request['description'] ?? '-'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if ((request['status'] ?? '').toString().toLowerCase() == 'pending')
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssignTechnicianPage(request: request),
                            ),
                          );
                        },
                        child: const Text('Assign Technician'),
                      ),
                    if ((request['status'] ?? '').toString().toLowerCase() == 'in progress')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cancel Assignment'),
                              content: const Text('Are you sure you want to cancel this technician assignment? The request will return to Pending status.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Yes, Cancel'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            // Set request status to Pending
                            await FirebaseFirestore.instance
                                .collection('requests')
                                .doc(request['id'])
                                .update({'status': 'Pending', 'technician': null});
                            // Set technician available if assigned
                            if (request['technician'] is Map && request['technician']['id'] != null) {
                              await FirebaseFirestore.instance
                                  .collection('technicians')
                                  .doc(request['technician']['id'])
                                  .update({'available': true});
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Technician assignment cancelled. Request is now pending.')),
                              );
                            }
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 