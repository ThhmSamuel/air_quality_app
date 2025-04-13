import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/mqtt_service.dart';
import 'sensor_settings_page.dart';
//import 'dashboard_page.dart'; // Import dashboard page explicitly

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info section
            const Center( 
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      size: 60,
                      color: Colors.white,
                    ),
                    // You can replace with NetworkImage if loading from URL
                  ),
                  SizedBox(height: 16),
                  Text(
                    "User Name",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "user@example.com",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text(
              "Settings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Settings list
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Sensor Notifications"),
              subtitle: const Text("Configure threshold alerts"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Create a new instance of MqttService for settings
                // This is a simpler approach that avoids complex state management
                final mqttService = MqttService();
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SensorSettingsPage(
                      mqttService: mqttService,
                    ),
                  ),
                );
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile Settings"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to profile settings
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("App Settings"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to app settings
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text("Help & Support"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to help page
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                // Handle logout
              },
            ),
          ],
        ),
      ),
    );
  }
}