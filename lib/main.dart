import 'package:airquality_monitor/services/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'pages/dashboard_page.dart';
import 'pages/data_page.dart';
import 'pages/account_page.dart';
//import 'pages/sensor_settings_page.dart'; // Import the new settings page
import 'widgets/bottom_nav.dart';

void main() async {
  // This is needed to ensure Flutter is initialized before we use platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notification system
final mqttService = MqttService();
await mqttService.initializeNotifications();

  initNotifications();
  
  runApp(const MyApp());
}

// Initialize notification permissions
Future<void> initNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // For iOS, request permissions
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      
  // For Android 13+, request permissions
  // await flutterLocalNotificationsPlugin
  //     .resolvePlatformSpecificImplementation<
  //         AndroidFlutterLocalNotificationsPlugin>()
  //     ?.requestNotificationsPermission();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // We'll replace AccountPage with SensorSettingsPage or keep both
  // depending on your preference
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize pages
    _pages = [
      const DashboardPage(), 
      const DataPage(), 
      const AccountPage()
    ];
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: onTabTapped,
      ),
    );
  }
}