import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/stat_card.dart';

class AdminDashboardHome extends StatefulWidget {
  const AdminDashboardHome({super.key});

  @override
  State<AdminDashboardHome> createState() => _AdminDashboardHomeState();
}

class _AdminDashboardHomeState extends State<AdminDashboardHome> {
  final _firestore = FirebaseFirestore.instance;

  late Stream<int> _totalBookingsStream;
  late Stream<int> _completedBookingsStream;
  late Stream<int> _totalPassengersStream;
  late Stream<int> _totalDriversStream;
  late Stream<double> _totalRevenueStream;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _setupStreams() {
    _totalBookingsStream = _firestore
        .collection('bookings')
        .snapshots()
        .map((s) => s.docs.length);

    _completedBookingsStream = _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((s) => s.docs.length);

    _totalPassengersStream = _firestore
        .collection('users')
        .where('role', isEqualTo: 'passenger')
        .snapshots()
        .map((s) => s.docs.length);

    _totalDriversStream = _firestore
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .snapshots()
        .map((s) => s.docs.length);

    _totalRevenueStream = _firestore
        .collection('bookings')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<double>(
            0,
            (prev, doc) => prev + ((doc['fare'] as num?)?.toDouble() ?? 0),
          ),
        );
  }

  Stream<List<FlSpot>> _usersPerDayStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      Map<int, int> usersPerDay = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          DateTime date = (data['createdAt'] as Timestamp).toDate();
          usersPerDay[date.day] = (usersPerDay[date.day] ?? 0) + 1;
        }
      }
      return usersPerDay.entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
          .toList()
        ..sort((a, b) => a.x.compareTo(b.x));
    });
  }

  Stream<List<BarChartGroupData>> _bookingsPerDayBarStream() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      Map<int, int> bookingsPerDay = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          DateTime date = (data['createdAt'] as Timestamp).toDate();
          bookingsPerDay[date.day] = (bookingsPerDay[date.day] ?? 0) + 1;
        }
      }
      return bookingsPerDay.entries.map((e) {
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value.toDouble(),
              width: 20,
              color: const Color.fromARGB(
                255,
                26,
                203,
                6,
              ), // aligned to "Total Bookings"
            ),
          ],
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Card theme colors
    final cardColors = [
      Colors.blue,
      Colors.green,
      Colors.cyan,
      Colors.purple,
      Colors.orange,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Text(
            'TRISIKOL Dashboard',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome back! Here\'s your business performance.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),

          /// KPI CARDS
          GridView.count(
            crossAxisCount: 6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StreamBuilder<int>(
                stream: _totalBookingsStream,
                builder: (_, snapshot) => StatCard(
                  title: 'Total Bookings',
                  value: snapshot.data?.toString() ?? '0',
                  icon: Icons.local_taxi,
                  color: cardColors[0],
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                ),
              ),
              StreamBuilder<int>(
                stream: _completedBookingsStream,
                builder: (_, snapshot) => StatCard(
                  title: 'Completed',
                  value: snapshot.data?.toString() ?? '0',
                  icon: Icons.check_circle,
                  color: cardColors[1],
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                ),
              ),
              StreamBuilder<int>(
                stream: _totalPassengersStream,
                builder: (_, snapshot) => StatCard(
                  title: 'Passengers',
                  value: snapshot.data?.toString() ?? '0',
                  icon: Icons.person,
                  color: cardColors[2],
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                ),
              ),
              StreamBuilder<int>(
                stream: _totalDriversStream,
                builder: (_, snapshot) => StatCard(
                  title: 'Drivers',
                  value: snapshot.data?.toString() ?? '0',
                  icon: Icons.drive_eta,
                  color: cardColors[3],
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                ),
              ),
              StreamBuilder<double>(
                stream: _totalRevenueStream,
                builder: (_, snapshot) => StatCard(
                  title: 'Revenue',
                  value: '₱${snapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                  icon: Icons.attach_money,
                  color: cardColors[4],
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // // ANALYTICS SECTION
          // Text(
          //   'Analytics Overview',
          //   style: Theme.of(
          //     context,
          //   ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          // ),
          // const SizedBox(height: 10),

          // CHARTS VERTICAL STACK
          Column(
            children: [
              // USERS PER DAY - LineChart
              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColors[0].withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<FlSpot>>(
                        stream: _usersPerDayStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: true),
                              titlesData: FlTitlesData(
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    interval: 1,
                                    getTitlesWidget: (val, meta) => Text(
                                      val.toInt().toString(),
                                      style: const TextStyle(
                                        color: Color.fromARGB(179, 2, 17, 58),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (val, meta) => Text(
                                      'Day ${val.toInt()}',
                                      style: const TextStyle(
                                        color: Color.fromARGB(179, 2, 17, 58),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: snapshot.data!,
                                  isCurved: true,
                                  color: cardColors[0],
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: cardColors[0].withOpacity(0.3),
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                handleBuiltInTouches: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (spots) => spots
                                      .map(
                                        (e) => LineTooltipItem(
                                          'Day ${e.x.toInt()}: ${e.y.toInt()} users',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Figure 4: Number of Users per Day',
                        style: const TextStyle(
                          color: Color.fromARGB(179, 2, 17, 58),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // BOOKINGS PER DAY - BarChart
              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColors[1].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<BarChartGroupData>>(
                        stream: _bookingsPerDayBarStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return BarChart(
                            BarChartData(
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: true),
                              titlesData: FlTitlesData(
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 3,
                                    getTitlesWidget: (val, meta) => Text(
                                      val.toInt().toString(),
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 10, 69, 9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (val, meta) => Text(
                                      'Day ${val.toInt()}',
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 10, 69, 9),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              barGroups: snapshot.data!,
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          'Day ${group.x}: ${rod.toY.toInt()} bookings',
                                          const TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              10,
                                              204,
                                              7,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Figure 5: Number of Bookings per Day',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 10, 69, 9),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // ===============================
          // RECENT BOOKINGS SECTION
          // ===============================
          Text(
            'Recent Bookings',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('bookings')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      Colors.grey.shade200,
                    ),
                    columnSpacing: 40,
                    columns: const [
                      DataColumn(label: Text('Booking ID')),
                      DataColumn(label: Text('Passenger')),
                      DataColumn(label: Text('Driver')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Fare')),
                      DataColumn(label: Text('Date')),
                    ],
                    rows: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final shortId = doc.id.length > 8
                          ? doc.id.substring(0, 8)
                          : doc.id;

                      final status = data['status'] ?? 'pending';

                      Color statusColor;
                      switch (status) {
                        case 'accepted':
                          statusColor = Colors.blue;
                          break;
                        case 'declined':
                          statusColor = Colors.grey;
                          break;
                        case 'completed':
                          statusColor = Colors.green;
                          break;
                        default:
                          statusColor = Colors.orange;
                      }

                      final createdAt = data['createdAt'] != null
                          ? (data['createdAt'] as Timestamp)
                                .toDate()
                                .toString()
                                .split(' ')[0]
                          : 'N/A';

                      return DataRow(
                        cells: [
                          DataCell(Text(shortId)),
                          DataCell(Text(data['passengerName'] ?? 'N/A')),
                          DataCell(Text(data['driverName'] ?? 'N/A')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text('₱${data['fare'] ?? 0.00}')),
                          DataCell(Text(createdAt)),
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
}
