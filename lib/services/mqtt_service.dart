import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  Function(Map<String, dynamic>)? onDataReceived;

  MqttService({this.onDataReceived}) {
    client = MqttServerClient.withPort('a232e1qhm7j0vy-ats.iot.ap-southeast-1.amazonaws.com', 'flutter_client', 8883);
    client.secure = true;
  }

  Future<void> connect() async {
    try {
      await client.connect();
      client.subscribe("sensor/data", MqttQos.atMostOnce);
      client.updates!.listen((messages) {
        final MqttPublishMessage recMessage = messages[0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

        Map<String, dynamic> sensorData = jsonDecode(payload);
        if (onDataReceived != null) {
          onDataReceived!(sensorData);
        }
      });
    } catch (e) {
      print('MQTT Connection Failed: $e');
    }
  }

  void disconnect() {
    client.disconnect();
    print('MQTT Disconnected');
  }
}
