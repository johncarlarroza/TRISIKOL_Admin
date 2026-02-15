import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_data_table.dart';

class DeliveriesManagementPage extends StatefulWidget {
  const DeliveriesManagementPage({super.key});

  @override
  State<DeliveriesManagementPage> createState() =>
      _DeliveriesManagementPageState();
}

class _DeliveriesManagementPageState extends State<DeliveriesManagementPage> {
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String? _statusFilter;
  bool _showMapView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deliveries Management',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Track all delivery orders',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showMapView = !_showMapView;
                  });
                },
                icon: Icon(_showMapView ? Icons.list : Icons.map),
                label: Text(_showMapView ? 'List View' : 'Map View'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by delivery ID or recipient...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String?>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Status')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'accepted', child: Text('Assigned')),
                  DropdownMenuItem(
                    value: 'inTransit',
                    child: Text('In Transit'),
                  ),
                  DropdownMenuItem(
                    value: 'delivered',
                    child: Text('Delivered'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_showMapView)
            Container(
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Map view - Google Maps integration'),
              ),
            )
          else
            // Data Table
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildQuery(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No deliveries found'),
                    );
                  }

                  final filteredDocs = _filterData(snapshot.data!.docs);

                  return AdminDataTable(
                    columns: const [
                      DataColumn(label: Text('Delivery ID')),
                      DataColumn(label: Text('Recipient')),
                      DataColumn(label: Text('Driver')),
                      DataColumn(label: Text('From')),
                      DataColumn(label: Text('To')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Fare')),
                      DataColumn(label: Text('Date')),
                    ],
                    rows: filteredDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return DataRow(
                        cells: [
                          DataCell(Text(doc.id.substring(0, 8))),
                          DataCell(
                            Text(data['recipientInfo']?['name'] ?? 'N/A'),
                          ),
                          DataCell(Text(data['driverId'] ?? 'Unassigned')),
                          DataCell(Text(data['pickupAddress'] ?? 'N/A')),
                          DataCell(Text(data['dropoffAddress'] ?? 'N/A')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  data['status'] ?? 'pending',
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                data['status'] ?? 'pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '₱${data['fare']?.toStringAsFixed(2) ?? '0.00'}',
                            ),
                          ),
                          DataCell(
                            Text(
                              data['createdAt'] != null
                                  ? DateFormat('MMM d, yyyy').format(
                                      (data['createdAt'] as Timestamp).toDate(),
                                    )
                                  : 'N/A',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('deliveries')
        .orderBy('createdAt', descending: true);

    if (_statusFilter != null) {
      query = query.where('status', isEqualTo: _statusFilter);
    }

    return query.snapshots();
  }

  List<QueryDocumentSnapshot<Object?>> _filterData(
    List<QueryDocumentSnapshot<Object?>> docs,
  ) {
    if (_searchController.text.isEmpty) {
      return docs;
    }

    final query = _searchController.text.toLowerCase();
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final id = doc.id.toLowerCase();
      final recipientName = (data['recipientInfo']?['name'] ?? '')
          .toString()
          .toLowerCase();

      return id.contains(query) || recipientName.contains(query);
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'pickedUp':
        return Colors.purple;
      case 'inTransit':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
