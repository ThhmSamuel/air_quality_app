// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/services.dart'; // Required for rootBundle
// import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';

// class MqttService {
//   late MqttServerClient client;
//   Function(Map<String, dynamic>)? onDataReceived;

//   MqttService({this.onDataReceived}) {
//     client = MqttServerClient.withPort(
//       'a232e1qhm7j0vy-ats.iot.ap-southeast-1.amazonaws.com', // AWS IoT Endpoint
//       'flutter_client',
//       8883,
//     );

//     client.secure = true;
//     client.logging(on: true);
//   }

//   Future<void> connect() async {
//     try {
//       // Load certificates from assets
//       final rootCa = await rootBundle.loadString('assets/root-CA.crt');
//       final deviceCert = await rootBundle.loadString('assets/RaspberryPi4_Sensor.cert.pem');
//       final privateKey = await rootBundle.loadString('assets/RaspberryPi4_Sensor.private.key');

//       // 🔐 Create Security Context
//       final context = SecurityContext.defaultContext;
//       context.setTrustedCertificatesBytes(utf8.encode(rootCa));
//       context.useCertificateChainBytes(utf8.encode(deviceCert));
//       context.usePrivateKeyBytes(utf8.encode(privateKey));

//       client.securityContext = context;
//       client.keepAlivePeriod = 30;
//       client.autoReconnect = true;

//       // Attempt Connection
//       await client.connect();

//       // Subscribe to MQTT topic
//       client.subscribe("sensor/data", MqttQos.atMostOnce);

//       // Listen for incoming messages
//       client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
//         final MqttPublishMessage recMessage = messages[0].payload as MqttPublishMessage;
//         final String payload = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
//         print('Received Data: $payload');

//         Map<String, dynamic> sensorData = jsonDecode(payload);
//         if (onDataReceived != null) {
//           onDataReceived!(sensorData);
//         }
//       });

//       print('Connected to AWS IoT!');
//     } catch (e) {
//       print('MQTT Connection Failed: $e');
//     }
//   }

//   void disconnect() {
//     client.disconnect();
//     print('MQTT Disconnected');
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart'; // Required for rootBundle
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MqttService {
  late MqttServerClient client;
  Function(Map<String, dynamic>)? onDataReceived;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Cache for threshold values
  double _temperatureThreshold = 35.0;
  double _humidityThreshold = 70.0;
  double _pm25Threshold = 50.0;
  double _co2Threshold = 1000.0;
  
  // Cache for notification settings
  bool _temperatureNotificationsEnabled = true;
  bool _humidityNotificationsEnabled = true;
  bool _pm25NotificationsEnabled = true;
  bool _co2NotificationsEnabled = true;
  
  // Track when last notification was sent to prevent spam
  DateTime? _lastTemperatureNotification;
  DateTime? _lastHumidityNotification;
  DateTime? _lastPm25Notification;
  DateTime? _lastCo2Notification;
  
  // Cooldown period between notifications (in minutes)
  final int _notificationCooldown = 15;

  MqttService({this.onDataReceived}) {
    client = MqttServerClient.withPort(
      'a232e1qhm7j0vy-ats.iot.ap-southeast-1.amazonaws.com', // AWS IoT Endpoint
      'flutter_client',
      8883,
    );

    client.secure = true;
    client.logging(on: true);
    
    // Initialize notifications and load threshold values
    _initializeNotifications();
    _loadThresholds();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification taps here if needed
      },
    );
  }

  Future<void> _loadThresholds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load threshold values with defaults if not set
      _temperatureThreshold = prefs.getDouble('temperature_threshold') ?? 35.0;
      _humidityThreshold = prefs.getDouble('humidity_threshold') ?? 70.0;
      _pm25Threshold = prefs.getDouble('pm25_threshold') ?? 50.0;
      _co2Threshold = prefs.getDouble('co2_threshold') ?? 1000.0;
      
      // Load notification settings with defaults if not set
      _temperatureNotificationsEnabled = prefs.getBool('temperature_notifications') ?? true;
      _humidityNotificationsEnabled = prefs.getBool('humidity_notifications') ?? true;
      _pm25NotificationsEnabled = prefs.getBool('pm25_notifications') ?? true;
      _co2NotificationsEnabled = prefs.getBool('co2_notifications') ?? true;
    } catch (e) {
      print('Error loading thresholds: $e');
    }
  }

  // Method to reload thresholds when settings change
  Future<void> refreshThresholds() async {
    await _loadThresholds();
  }

  Future<void> connect() async {
    try {
      // Load certificates from assets
      final rootCa = await rootBundle.loadString('assets/root-CA.crt');
      final deviceCert = await rootBundle.loadString('assets/RaspberryPi4_Sensor.cert.pem');
      final privateKey = await rootBundle.loadString('assets/RaspberryPi4_Sensor.private.key');

      // 🔐 Create Security Context
      final context = SecurityContext.defaultContext;
      context.setTrustedCertificatesBytes(utf8.encode(rootCa));
      context.useCertificateChainBytes(utf8.encode(deviceCert));
      context.usePrivateKeyBytes(utf8.encode(privateKey));

      client.securityContext = context;
      client.keepAlivePeriod = 30;
      client.autoReconnect = true;

      // Attempt Connection
      await client.connect();

      // Subscribe to MQTT topic
      client.subscribe("sensor/data", MqttQos.atMostOnce);

      // Listen for incoming messages
      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final MqttPublishMessage recMessage = messages[0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
        print('Received Data: $payload');

        try {
          Map<String, dynamic> sensorData = jsonDecode(payload);
          
          // Process data to check thresholds and send notifications if needed
          _processData(sensorData);
          
          // Forward data to UI as before
          if (onDataReceived != null) {
            onDataReceived!(sensorData);
          }
        } catch (e) {
          print('Error processing MQTT message: $e');
        }
      });

      print('Connected to AWS IoT!');
    } catch (e) {
      print('MQTT Connection Failed: $e');
    }
  }

  void _processData(Map<String, dynamic> data) async {
    // Parse incoming data
    final temperature = double.tryParse(data["temperature"]?.toString() ?? '') ?? 0.0;
    final humidity = double.tryParse(data["humidity"]?.toString() ?? '') ?? 0.0;
    final pm25 = double.tryParse(data["pm25"]?.toString() ?? '') ?? 0.0;
    final co2 = double.tryParse(data["co2"]?.toString() ?? '') ?? 0.0;
    
    final now = DateTime.now();
    
    // Check temperature threshold and send notification if exceeded
    if (_temperatureNotificationsEnabled && 
        temperature > _temperatureThreshold &&
        (_lastTemperatureNotification == null || 
         now.difference(_lastTemperatureNotification!).inMinutes > _notificationCooldown)) {
      _sendNotification(
        'High Temperature Alert',
        'Temperature has reached ${temperature.toStringAsFixed(1)}°C, exceeding the threshold of ${_temperatureThreshold.toStringAsFixed(1)}°C',
        1
      );
      _lastTemperatureNotification = now;
    }
    
    // Check humidity threshold
    if (_humidityNotificationsEnabled && 
        humidity > _humidityThreshold &&
        (_lastHumidityNotification == null || 
         now.difference(_lastHumidityNotification!).inMinutes > _notificationCooldown)) {
      _sendNotification(
        'High Humidity Alert',
        'Humidity has reached ${humidity.toStringAsFixed(1)}%, exceeding the threshold of ${_humidityThreshold.toStringAsFixed(1)}%',
        2
      );
      _lastHumidityNotification = now;
    }
    
    // Check PM2.5 threshold
    if (_pm25NotificationsEnabled && 
        pm25 > _pm25Threshold &&
        (_lastPm25Notification == null || 
         now.difference(_lastPm25Notification!).inMinutes > _notificationCooldown)) {
      _sendNotification(
        'High PM2.5 Alert',
        'PM2.5 has reached ${pm25.toStringAsFixed(1)} ppm, exceeding the threshold of ${_pm25Threshold.toStringAsFixed(1)} ppm',
        3
      );
      _lastPm25Notification = now;
    }
    
    // Check CO2 threshold
    if (_co2NotificationsEnabled && 
        co2 > _co2Threshold &&
        (_lastCo2Notification == null || 
         now.difference(_lastCo2Notification!).inMinutes > _notificationCooldown)) {
      _sendNotification(
        'High CO2 Alert',
        'CO2 has reached ${co2.toStringAsFixed(1)} ppm, exceeding the threshold of ${_co2Threshold.toStringAsFixed(1)} ppm',
        4
      );
      _lastCo2Notification = now;
    }
  }

  Future<void> _sendNotification(String title, String body, int id) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sensor_alerts_channel',
      'Sensor Alerts',
      channelDescription: 'Notifications for sensor threshold alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
    );
  }

  void disconnect() {
    client.disconnect();
    print('MQTT Disconnected');
  }
}