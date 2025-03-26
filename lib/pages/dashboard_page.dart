import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String temperature = "0.0";
  String humidity = "0.0";
  String pm25 = "0.0";
  String co2 = "0.0";

  late MqttService mqttService;

  @override
  void initState() {
    super.initState();
    mqttService = MqttService(onDataReceived: updateData);
    mqttService.connect();
  }

  void updateData(Map<String, dynamic> sensorData) {
    setState(() {
      temperature = sensorData["temperature"].toString();
      humidity = sensorData["humidity"].toString();
      pm25 = sensorData["pm25"].toString();
      co2 = sensorData["co2"].toString();
    });
  }

  @override
  void dispose() {
    mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Sensor Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Temperature: $temperature °C", style: TextStyle(fontSize: 24)),
            Text("Humidity: $humidity %", style: TextStyle(fontSize: 24)),
            Text("PM25: $pm25 ppm", style: TextStyle(fontSize: 24)),
            Text("CO2: $co2 ppm", style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
