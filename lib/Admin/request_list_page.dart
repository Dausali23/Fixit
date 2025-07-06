import 'package:flutter/material.dart';

class RequestListPage extends StatefulWidget {
  const RequestListPage({super.key});

  @override
  State<RequestListPage> createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage> {
  final List<Map<String, dynamic>> _dummyRequests = [
    {
      'id': '1',
      'title': 'Leaking Faucet',
      'category': 'Plumbing',
      'status': 'Pending',
      'date': '2025-06-15',
      'description': 'Kitchen sink faucet is leaking.',
      'user': 'John Doe',
    },
    {
      'id': '2',
      'title': 'Power Outage',
      'category': 'Electrical',
      'status': 'In Progress',
      'date': '2025-06-14',
      'description': 'No power in living room outlets.',
      'user': 'Jane Smith',
    },
    {
      'id': '3',
      'title': 'AC Not Working',
      'category': 'Air Conditioning',
      'status': 'Completed',
      'date': '2025-06-12',
      'description': 'Air conditioner not cooling properly.',
      'user': 'Mike Johnson',
    },
  ];

  String _selectedFilter = 'All';

  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedFilter == 'All') {
      return _dummyRequests;
    } else {
      return _dummyRequests
          .where((request) => request['status'] == _selectedFilter)
          .toList();
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
                    DropdownMenuItem(
                        value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(
                        value: 'Completed', child: Text('Completed')),
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
            child: ListView.builder(
              itemCount: _filteredRequests.length,
              itemBuilder: (context, index) {
                final request = _filteredRequests[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(request['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category: ${request['category']}'),
                        Text('Submitted by: ${request['user']}'),
                        Text('Date: ${request['date']}'),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(request['status']),
                      backgroundColor: _getStatusColor(request['status']),
                    ),
                    onTap: () {
                      // View request details
                      _showRequestDetails(request);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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

  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request['title'],
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('ID: ${request['id']}'),
              Text('Category: ${request['category']}'),
              Text('Status: ${request['status']}'),
              Text('Date: ${request['date']}'),
              Text('User: ${request['user']}'),
              const SizedBox(height: 16),
              Text(
                'Description:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(request['description']),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Assign technician functionality would go here
                      Navigator.pop(context);
                    },
                    child: const Text('Assign Technician'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Update status functionality would go here
                      Navigator.pop(context);
                    },
                    child: const Text('Update Status'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
} 