import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _firestore = FirebaseFirestore.instance;

  // Ride pricing
  late TextEditingController _rideBaseFareController;
  late TextEditingController _ridePerKmController;
  late TextEditingController _ridePerMinuteController;

  // Delivery pricing
  late TextEditingController _deliveryBaseFareController;
  late TextEditingController _deliveryPerKmController;

  bool _isSaving = false;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  @override
  void initState() {
    super.initState();
    _rideBaseFareController = TextEditingController();
    _ridePerKmController = TextEditingController();
    _ridePerMinuteController = TextEditingController();
    _deliveryBaseFareController = TextEditingController();
    _deliveryPerKmController = TextEditingController();

    _loadSettings();
  }

  @override
  void dispose() {
    _rideBaseFareController.dispose();
    _ridePerKmController.dispose();
    _ridePerMinuteController.dispose();
    _deliveryBaseFareController.dispose();
    _deliveryPerKmController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('pricing').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _rideBaseFareController.text =
              data['rideBaseFare']?.toString() ?? '50';
          _ridePerKmController.text = data['ridePerKm']?.toString() ?? '10';
          _ridePerMinuteController.text =
              data['ridePerMinute']?.toString() ?? '1';
          _deliveryBaseFareController.text =
              data['deliveryBaseFare']?.toString() ?? '50';
          _deliveryPerKmController.text =
              data['deliveryPerKm']?.toString() ?? '10';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore.collection('settings').doc('pricing').set({
        'rideBaseFare': double.parse(_rideBaseFareController.text),
        'ridePerKm': double.parse(_ridePerKmController.text),
        'ridePerMinute': double.parse(_ridePerMinuteController.text),
        'deliveryBaseFare': double.parse(_deliveryBaseFareController.text),
        'deliveryPerKm': double.parse(_deliveryPerKmController.text),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    } finally {
      setState(() {
        _isSaving = false;
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
            'Settings',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Pricing Settings Section
          Text(
            'Pricing Settings',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ride Pricing
                Text(
                  'Ride Pricing',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rideBaseFareController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Base Fare (₱)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _ridePerKmController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Per KM (₱)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _ridePerMinuteController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Per Minute (₱)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Delivery Pricing
                Text(
                  'Delivery Pricing',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _deliveryBaseFareController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Base Fare (₱)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _deliveryPerKmController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Per KM (₱)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Notification Settings
          Text(
            'Notification Settings',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Email Notifications'),
                    Switch(
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SMS Notifications'),
                    Switch(
                      value: _smsNotifications,
                      onChanged: (value) {
                        setState(() {
                          _smsNotifications = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // System Maintenance
          Text(
            'System Maintenance',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Backup Database'),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Backup started')),
                        );
                      },
                      icon: const Icon(Icons.backup),
                      label: const Text('Backup Now'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Restore Database'),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Restore feature coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
