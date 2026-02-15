import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/stat_card.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final _firestore = FirebaseFirestore.instance;
  String? _paymentMethodFilter;
  DateTimeRange? _selectedDateRange;

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
          Text(
            'Payments',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Revenue Summary Cards
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StreamBuilder<double>(
                stream: _getTotalRevenue(),
                builder: (context, snapshot) {
                  return StatCard(
                    title: 'Total Revenue',
                    value: '₱${snapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                  );
                },
              ),
              StreamBuilder<double>(
                stream: _getMonthlyRevenue(),
                builder: (context, snapshot) {
                  return StatCard(
                    title: 'This Month',
                    value: '₱${snapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                  );
                },
              ),
              StreamBuilder<double>(
                stream: _getWeeklyRevenue(),
                builder: (context, snapshot) {
                  return StatCard(
                    title: 'This Week',
                    value: '₱${snapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                    icon: Icons.trending_up,
                    color: Colors.orange,
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Filters
          Row(
            children: [
              DropdownButton<String?>(
                value: _paymentMethodFilter,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Methods')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentMethodFilter = value;
                  });
                },
              ),
              const SizedBox(width: 16),
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

          // Transactions Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('bookings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
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
                    child: Text('No transactions found'),
                  );
                }

                final transactions = snapshot.data!.docs;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Transaction ID')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Payment Method')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: transactions.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return DataRow(
                        cells: [
                          DataCell(Text(doc.id.substring(0, 8))),
                          DataCell(
                            Text(
                              '₱${data['fare']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text('Ride')),
                          DataCell(Text(data['paymentMethod'] ?? 'N/A')),
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
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<double> _getTotalRevenue() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        final fare = doc['fare'] as num?;
        if (fare != null) total += fare.toDouble();
      }
      return total;
    });
  }

  Stream<double> _getMonthlyRevenue() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      double total = 0;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (var doc in snapshot.docs) {
        final createdAt = doc['createdAt'] as Timestamp?;
        if (createdAt != null && createdAt.toDate().isAfter(startOfMonth)) {
          final fare = doc['fare'] as num?;
          if (fare != null) total += fare.toDouble();
        }
      }
      return total;
    });
  }

  Stream<double> _getWeeklyRevenue() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      double total = 0;
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      for (var doc in snapshot.docs) {
        final createdAt = doc['createdAt'] as Timestamp?;
        if (createdAt != null && createdAt.toDate().isAfter(startOfWeek)) {
          final fare = doc['fare'] as num?;
          if (fare != null) total += fare.toDouble();
        }
      }
      return total;
    });
  }
}
