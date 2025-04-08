import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart'; // Required for rootBundle
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  Function(Map<String, dynamic>)? onDataReceived;

  MqttService({this.onDataReceived}) {
    client = MqttServerClient.withPort(
      'a232e1qhm7j0vy-ats.iot.ap-southeast-1.amazonaws.com', // AWS IoT Endpoint
      'flutter_client',
      8883,
    );

    client.secure = true;
    client.logging(on: true);
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

        Map<String, dynamic> sensorData = jsonDecode(payload);
        if (onDataReceived != null) {
          onDataReceived!(sensorData);
        }
      });

      print('Connected to AWS IoT!');
    } catch (e) {
      print('MQTT Connection Failed: $e');
    }
  }

  void disconnect() {
    client.disconnect();
    print('MQTT Disconnected');
  }
}
