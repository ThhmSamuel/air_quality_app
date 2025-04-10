import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/mqtt_service.dart';

class SensorSettingsPage extends StatefulWidget {
  // Add the mqttService parameter
  final MqttService mqttService;
  
  const SensorSettingsPage({
    super.key, 
    required this.mqttService
  });

  @override
  _SensorSettingsPageState createState() => _SensorSettingsPageState();
}

class _SensorSettingsPageState extends State<SensorSettingsPage> {
  // Controllers for threshold text fields
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _pm25Controller = TextEditingController();
  final _co2Controller = TextEditingController();

  // Enable/disable notification toggles
  bool _temperatureNotificationsEnabled = true;
  bool _humidityNotificationsEnabled = true;
  bool _pm25NotificationsEnabled = true;
  bool _co2NotificationsEnabled = true;

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load saved settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Load threshold values with defaults if not set
      _temperatureController.text = (prefs.getDouble('temperature_threshold') ?? 35.0).toString();
      _humidityController.text = (prefs.getDouble('humidity_threshold') ?? 70.0).toString();
      _pm25Controller.text = (prefs.getDouble('pm25_threshold') ?? 50.0).toString();
      _co2Controller.text = (prefs.getDouble('co2_threshold') ?? 1000.0).toString();
      
      // Load notification settings with defaults if not set
      _temperatureNotificationsEnabled = prefs.getBool('temperature_notifications') ?? true;
      _humidityNotificationsEnabled = prefs.getBool('humidity_notifications') ?? true;
      _pm25NotificationsEnabled = prefs.getBool('pm25_notifications') ?? true;
      _co2NotificationsEnabled = prefs.getBool('co2_notifications') ?? true;
      
      _isLoading = false;
    });
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    
    // Parse values from text controllers, using defaults if parsing fails
    final temperatureThreshold = double.tryParse(_temperatureController.text) ?? 35.0;
    final humidityThreshold = double.tryParse(_humidityController.text) ?? 70.0;
    final pm25Threshold = double.tryParse(_pm25Controller.text) ?? 50.0;
    final co2Threshold = double.tryParse(_co2Controller.text) ?? 1000.0;
    
    // Save threshold values
    await prefs.setDouble('temperature_threshold', temperatureThreshold);
    await prefs.setDouble('humidity_threshold', humidityThreshold);
    await prefs.setDouble('pm25_threshold', pm25Threshold);
    await prefs.setDouble('co2_threshold', co2Threshold);
    
    // Save notification settings
    await prefs.setBool('temperature_notifications', _temperatureNotificationsEnabled);
    await prefs.setBool('humidity_notifications', _humidityNotificationsEnabled);
    await prefs.setBool('pm25_notifications', _pm25NotificationsEnabled);
    await prefs.setBool('co2_notifications', _co2NotificationsEnabled);
    
    // Refresh thresholds in the MQTT service
    await widget.mqttService.refreshThresholds();
    
    setState(() => _isLoading = false);
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    _temperatureController.dispose();
    _humidityController.dispose();
    _pm25Controller.dispose();
    _co2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sensor Threshold Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Configure sensor thresholds for notifications",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "You will receive alerts when sensor readings exceed these values",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  // Temperature settings
                  _buildSensorSetting(
                    title: "Temperature Threshold",
                    subtitle: "Notify when temperature exceeds this value (°C)",
                    icon: Icons.thermostat,
                    controller: _temperatureController,
                    enabled: _temperatureNotificationsEnabled,
                    onToggleChanged: (value) {
                      setState(() => _temperatureNotificationsEnabled = value);
                    },
                    suffix: "°C",
                  ),
                  
                  const Divider(height: 32),
                  
                  // Humidity settings
                  _buildSensorSetting(
                    title: "Humidity Threshold",
                    subtitle: "Notify when humidity exceeds this value (%)",
                    icon: Icons.water_drop,
                    controller: _humidityController,
                    enabled: _humidityNotificationsEnabled,
                    onToggleChanged: (value) {
                      setState(() => _humidityNotificationsEnabled = value);
                    },
                    suffix: "%",
                  ),
                  
                  const Divider(height: 32),
                  
                  // PM2.5 settings
                  _buildSensorSetting(
                    title: "PM2.5 Threshold",
                    subtitle: "Notify when PM2.5 exceeds this value (ppm)",
                    icon: Icons.air,
                    controller: _pm25Controller,
                    enabled: _pm25NotificationsEnabled,
                    onToggleChanged: (value) {
                      setState(() => _pm25NotificationsEnabled = value);
                    },
                    suffix: "ppm",
                  ),
                  
                  const Divider(height: 32),
                  
                  // CO2 settings
                  _buildSensorSetting(
                    title: "CO2 Threshold",
                    subtitle: "Notify when CO2 exceeds this value (ppm)",
                    icon: Icons.cloud,
                    controller: _co2Controller,
                    enabled: _co2NotificationsEnabled,
                    onToggleChanged: (value) {
                      setState(() => _co2NotificationsEnabled = value);
                    },
                    suffix: "ppm",
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.0),
                            )
                          : const Text('SAVE SETTINGS'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper method to build consistent sensor setting sections
  Widget _buildSensorSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required TextEditingController controller,
    required bool enabled,
    required Function(bool) onToggleChanged,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onToggleChanged,
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: "Threshold Value",
            suffixText: suffix,
            helperText: "Enter a numeric value",
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: enabled ? Colors.black : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}