// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import '../services/mqtt_service.dart';

// class DashboardPage extends StatefulWidget {
//   const DashboardPage({super.key});

//   @override
//   _DashboardPageState createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {
//   double temperature = 0.0;
//   double humidity = 0.0;
//   double pm25 = 0.0;
//   double co2 = 0.0;

//   late MqttService mqttService;

//   @override
//   void initState() {
//     super.initState();
//     mqttService = MqttService(onDataReceived: updateData);
//     mqttService.connect();
//   }

//   void updateData(Map<String, dynamic> sensorData) {
//     setState(() {
//       temperature = double.tryParse(sensorData["temperature"].toString()) ?? 0.0;
//       humidity = double.tryParse(sensorData["humidity"].toString()) ?? 0.0;
//       pm25 = double.tryParse(sensorData["pm25"].toString()) ?? 0.0;
//       co2 = double.tryParse(sensorData["co2"].toString()) ?? 0.0;
//     });
//   }

//   @override
//   void dispose() {
//     mqttService.disconnect();
//     super.dispose();
//   }

//   Color getBoxColor(double value, {double low = 0, double high = 100}) {
//     if (value < low) return Colors.green;
//     if (value >= low && value <= high) return Colors.orange;
//     return Colors.red;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Live Sensor Dashboard")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: GridView.count(
//           crossAxisCount: 2,
//           crossAxisSpacing: 16,
//           mainAxisSpacing: 16,
//           children: [
//             _sensorCard("Temperature", "$temperature°C", FontAwesomeIcons.temperatureHalf, 
//                 getBoxColor(temperature, low: 10, high: 35)),
//             _sensorCard("Humidity", "$humidity%", FontAwesomeIcons.water, 
//                 getBoxColor(humidity, low: 30, high: 70)),
//             _sensorCard("PM2.5", "$pm25 ppm", FontAwesomeIcons.wind, 
//                 getBoxColor(pm25, low: 0, high: 50)),
//             _sensorCard("CO2", "$co2 ppm", FontAwesomeIcons.cloud, 
//                 getBoxColor(co2, low: 350, high: 1000)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _sensorCard(String title, String value, IconData icon, Color color) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color: color,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             FaIcon(icon, size: 40, color: Colors.white),
//             const SizedBox(height: 10),
//             Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
//             const SizedBox(height: 5),
//             Text(value, style: const TextStyle(fontSize: 20, color: Colors.white)),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/mqtt_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
  
  // Add this method to expose the MqttService instance
  MqttService getMqttService() {
    // This creates a temporary state to access the MqttService
    // In a production app, you might want to use a state management solution instead
    final state = _DashboardPageState();
    return state.mqttService;
  }
}

class _DashboardPageState extends State<DashboardPage> {
  double temperature = 0.0;
  double humidity = 0.0;
  double pm25 = 0.0;
  double co2 = 0.0;

  // Make mqttService accessible outside this class
  late MqttService mqttService;

  @override
  void initState() {
    super.initState();
    mqttService = MqttService(onDataReceived: updateData);
    mqttService.connect();
  }

  void updateData(Map<String, dynamic> sensorData) {
    setState(() {
      temperature = double.tryParse(sensorData["temperature"]?.toString() ?? '') ?? 0.0;
      humidity = double.tryParse(sensorData["humidity"]?.toString() ?? '') ?? 0.0;
      pm25 = double.tryParse(sensorData["pm25"]?.toString() ?? '') ?? 0.0;
      co2 = double.tryParse(sensorData["co2"]?.toString() ?? '') ?? 0.0;
    });
  }

  @override
  void dispose() {
    mqttService.disconnect();
    super.dispose();
  }

  Color getBoxColor(double value, {double low = 0, double high = 100}) {
    if (value < low) return Colors.green;
    if (value >= low && value <= high) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Sensor Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _sensorCard("Temperature", "$temperature°C", FontAwesomeIcons.temperatureHalf, 
                getBoxColor(temperature, low: 10, high: 35)),
            _sensorCard("Humidity", "$humidity%", FontAwesomeIcons.water, 
                getBoxColor(humidity, low: 30, high: 70)),
            _sensorCard("PM2.5", "$pm25 ppm", FontAwesomeIcons.wind, 
                getBoxColor(pm25, low: 0, high: 50)),
            _sensorCard("CO2", "$co2 ppm", FontAwesomeIcons.cloud, 
                getBoxColor(co2, low: 350, high: 1000)),
          ],
        ),
      ),
    );
  }

  Widget _sensorCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 20, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}