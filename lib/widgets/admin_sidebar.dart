import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200, // fixed width
      color: const Color.fromARGB(255, 79, 204, 220), // light blue background
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Admin Profile Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.blue, size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Navigation Items
          _buildNavItem(icon: Icons.home, label: 'Dashboard', index: 0),
          _buildNavItem(icon: Icons.people, label: 'Drivers', index: 1),
          _buildNavItem(icon: Icons.person, label: 'Passengers', index: 2),
          _buildNavItem(
            icon: Icons.calendar_today,
            label: 'Bookings',
            index: 3,
          ),
          _buildNavItem(
            icon: Icons.local_shipping,
            label: 'Deliveries',
            index: 4,
          ),
          _buildNavItem(icon: Icons.payment, label: 'Payments', index: 5),
          _buildNavItem(
            icon: Icons.insert_drive_file,
            label: 'Reports',
            index: 6,
          ),
          _buildNavItem(icon: Icons.feedback, label: 'Complaints', index: 7),
          _buildNavItem(icon: Icons.settings, label: 'Settings', index: 8),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Container(
        color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
