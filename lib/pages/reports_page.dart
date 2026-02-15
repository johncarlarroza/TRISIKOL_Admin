import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _firestore = FirebaseFirestore.instance;
  int _selectedTabIndex = 0;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reports',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Analyze business metrics and trends',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export feature coming soon')),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Export as PDF'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date Range Filter
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDateRange != null
                      ? '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}'
                      : 'Select Date Range',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Report Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                _buildTabButton('Earnings Report', 0),
                _buildTabButton('User Activity', 1),
                _buildTabButton('Delivery Metrics', 2),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tab Content
          if (_selectedTabIndex == 0)
            _buildEarningsReport()
          else if (_selectedTabIndex == 1)
            _buildUserActivityReport()
          else
            _buildDeliveryMetricsReport(),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                ),
              ),
              if (isSelected)
                Container(
                  height: 2,
                  margin: const EdgeInsets.only(top: 8),
                  color: Colors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue by Date/Week/Month',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('Chart placeholder - Recharts integration'),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Breakdown by Ride/Delivery',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ride Revenue:'),
                  StreamBuilder<double>(
                    stream: _getRideRevenue(),
                    builder: (context, snapshot) {
                      return Text(
                        '₱${snapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery Revenue:'),
                  StreamBuilder<double>(
                    stream: _getDeliveryRevenue(),
                    builder: (context, snapshot) {
                      return Text(
                        '₱${snapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserActivityReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Users Trend',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('Chart placeholder - Recharts integration'),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'User Breakdown',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: StreamBuilder<int>(
                stream: _getTotalPassengers(),
                builder: (context, snapshot) {
                  return _buildStatItem(
                    'Total Passengers',
                    snapshot.data?.toString() ?? '0',
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<int>(
                stream: _getTotalDrivers(),
                builder: (context, snapshot) {
                  return _buildStatItem(
                    'Total Drivers',
                    snapshot.data?.toString() ?? '0',
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<int>(
                stream: _getTotalUsers(),
                builder: (context, snapshot) {
                  return _buildStatItem(
                    'Total Users',
                    snapshot.data?.toString() ?? '0',
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryMetricsReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Metrics',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Deliveries:'),
                  StreamBuilder<int>(
                    stream: _getTotalDeliveries(),
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Completed:'),
                  StreamBuilder<int>(
                    stream: _getCompletedDeliveries(),
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cancellation Rate:'),
                  StreamBuilder<double>(
                    stream: _getCancellationRate(),
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data?.toStringAsFixed(1) ?? '0'}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Stream<double> _getRideRevenue() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        final fare = doc['fare'] as num?;
        if (fare != null) total += fare.toDouble();
      }
      return total;
    });
  }

  Stream<double> _getDeliveryRevenue() {
    return _firestore.collection('deliveries').snapshots().map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        final fare = doc['fare'] as num?;
        if (fare != null) total += fare.toDouble();
      }
      return total;
    });
  }

  Stream<int> _getTotalDeliveries() {
    return _firestore.collection('deliveries').snapshots().map((snapshot) {
      return snapshot.docs.length;
    });
  }

  Stream<int> _getCompletedDeliveries() {
    return _firestore
        .collection('deliveries')
        .where('status', isEqualTo: 'delivered')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.length;
        });
  }

  Stream<double> _getCancellationRate() {
    return _firestore.collection('deliveries').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return 0;
      final cancelled = snapshot.docs.where((doc) {
        return doc['status'] == 'cancelled';
      }).length;
      return (cancelled / snapshot.docs.length) * 100;
    });
  }

  Stream<int> _getTotalPassengers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'passenger')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getTotalDrivers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getTotalUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
