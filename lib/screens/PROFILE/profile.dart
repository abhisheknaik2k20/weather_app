import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Picture and Name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'USERNAME',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mumbai, Maharashtra',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dark Mode Toggle
                    _buildSettingItem(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (value) => onThemeToggle(),
                        activeColor: Colors.blue,
                      ),
                    ),

                    const Divider(height: 32),

                    // Location
                    _buildSettingItem(
                      icon: Icons.location_on,
                      title: 'Location',
                      subtitle: 'Mumbai, Maharashtra',
                      trailing: const Icon(Icons.chevron_right),
                    ),

                    const Divider(height: 32),

                    // Temperature Unit
                    _buildSettingItem(
                      icon: Icons.thermostat,
                      title: 'Temperature Unit',
                      subtitle: 'Celsius (°C)',
                      trailing: const Icon(Icons.chevron_right),
                    ),

                    const Divider(height: 32),

                    // Notifications
                    _buildSettingItem(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Weather alerts enabled',
                      trailing: const Icon(Icons.chevron_right),
                    ),

                    const Divider(height: 32),

                    // About
                    _buildSettingItem(
                      icon: Icons.info,
                      title: 'About',
                      subtitle: 'Version 1.0.0',
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
