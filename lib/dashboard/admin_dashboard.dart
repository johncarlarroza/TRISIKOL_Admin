import 'package:flutter/material.dart';
import 'package:trisikol_admin/pages/admin_dashboard_home.dart';
import 'package:trisikol_admin/pages/bookings_management.dart';
import 'package:trisikol_admin/pages/complaints_page.dart';
import 'package:trisikol_admin/pages/deliveries_management.dart';
import 'package:trisikol_admin/pages/drivers_management.dart';
import 'package:trisikol_admin/pages/passenger_management.dart';
import 'package:trisikol_admin/pages/payments_page.dart';
import 'package:trisikol_admin/pages/reports_page.dart';
import 'package:trisikol_admin/pages/settings_page.dart';
import 'package:trisikol_admin/widgets/admin_sidebar.dart';
import 'package:trisikol_admin/widgets/admin_top_bar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const AdminDashboardHome(),
      const DriversManagementPage(),
      const PassengersManagementPage(), // Passengers Management Page
      const BookingsManagementPage(),
      const DeliveriesManagementPage(),
      const PaymentsPage(),
      const ReportsPage(),
      const ComplaintsPage(),
      const SettingsPage(),
    ];
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            isCollapsed: _isSidebarCollapsed,
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                AdminTopBar(
                  // onMenuToggle: _toggleSidebar,
                  // isSidebarCollapsed: _isSidebarCollapsed,
                ),

                // Content Area
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
