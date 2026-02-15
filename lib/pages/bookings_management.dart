import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_data_table.dart';

class BookingsManagementPage extends StatefulWidget {
  const BookingsManagementPage({super.key});

  @override
  State<BookingsManagementPage> createState() => _BookingsManagementPageState();
}

class _BookingsManagementPageState extends State<BookingsManagementPage> {
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String? _statusFilter;
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );

    if (range != null) {
      setState(() {
        _selectedDateRange = range;
      });
    }
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
                    'Bookings Management',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Track all ride bookings',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by booking ID or passenger name...',
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
              DropdownButton<String?>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Status')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
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
              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDateRange != null
                      ? '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}'
                      : 'Date Range',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
                    child: Text('No bookings found'),
                  );
                }

                final filteredDocs = _filterData(snapshot.data!.docs);

                return AdminDataTable(
                  columns: const [
                    DataColumn(label: Text('Booking ID')),
                    DataColumn(label: Text('Passenger')),
                    DataColumn(label: Text('Driver')),
                    DataColumn(label: Text('Pickup')),
                    DataColumn(label: Text('Dropoff')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Fare')),
                    DataColumn(label: Text('Date')),
                  ],
                  rows: filteredDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return DataRow(
                      cells: [
                        DataCell(Text(doc.id.substring(0, 8))),
                        DataCell(Text(data['passengerName'] ?? 'N/A')),
                        DataCell(Text(data['driverName'] ?? 'Unassigned')),
                        DataCell(Text(data['pickupLocation'] ?? 'N/A')),
                        DataCell(Text(data['dropoffLocation'] ?? 'N/A')),
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
        .collection('bookings')
        .orderBy('createdAt', descending: true);

    if (_statusFilter != null) {
      query = query.where('status', isEqualTo: _statusFilter);
    }

    return query.snapshots();
  }

  List<QueryDocumentSnapshot<Object?>> _filterData(
    List<QueryDocumentSnapshot<Object?>> docs,
  ) {
    var filtered = docs;

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id.toLowerCase();
        final passengerName = (data['passengerName'] ?? '')
            .toString()
            .toLowerCase();
        return id.contains(query) || passengerName.contains(query);
      }).toList();
    }

    // Filter by date range
    if (_selectedDateRange != null) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['createdAt'] == null) return false;
        final date = (data['createdAt'] as Timestamp).toDate();
        return date.isAfter(_selectedDateRange!.start) &&
            date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
