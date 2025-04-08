import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  List<Map<String, dynamic>> sensorData = [];
  String selectedInterval = "Daily";

  double minX = 0;
  double maxX = 10; // Default zoom level

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://r6y3av2nb3.execute-api.ap-southeast-1.amazonaws.com/fetchSensorData",
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          sensorData = data.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  List<Map<String, dynamic>> filterDataByTime() {
    if (selectedInterval == "Minute") return sensorData;
    DateTime now = DateTime.now();

    return sensorData.where((entry) {
      DateTime timestamp = DateTime.parse(entry["timestamp"]);
      if (selectedInterval == "Daily") {
        return timestamp.day == now.day && timestamp.month == now.month;
      } else if (selectedInterval == "Weekly") {
        return timestamp.isAfter(now.subtract(Duration(days: 7)));
      } else if (selectedInterval == "Monthly") {
        return timestamp.month == now.month;
      }
      return false;
    }).toList();
  }

  List<FlSpot> getChartData(String key) {
    List<Map<String, dynamic>> filteredData = filterDataByTime();
    return List.generate(filteredData.length, (i) {
      double value = double.tryParse(filteredData[i][key].toString()) ?? 0.0;
      return FlSpot(i.toDouble(), value);
    });
  }

  Widget buildGraph(String title, String key, List<Color> gradientColors) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: GestureDetector(
                onScaleUpdate: (details) {
                  setState(() {
                    double scaleFactor = details.scale.clamp(0.5, 2.0);
                    double range = (sensorData.length / scaleFactor).clamp(
                      5,
                      sensorData.length.toDouble(),
                    );
                    minX = (minX - range / 4).clamp(
                      0,
                      sensorData.length - range,
                    );
                    maxX = minX + range;
                  });
                },
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 1,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: Colors.grey,
                          strokeWidth: 0.5,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return const FlLine(
                          color: Colors.grey,
                          strokeWidth: 0.5,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 25,
                          interval: (maxX - minX) / 5, // Adjust based on zoom
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey),
                    ),
                    minX: minX,
                    maxX: maxX,
                    minY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        spots: getChartData(key),
                        isCurved: true,
                        gradient: LinearGradient(colors: gradientColors),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors:
                                gradientColors
                                    .map((color) => color.withOpacity(0.3))
                                    .toList(),
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        

                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                      enabled: true,
                      touchCallback: (
                        FlTouchEvent event,
                        LineTouchResponse? response,
                      ) {
                        if (event is FlPanUpdateEvent) {
                          setState(() {
                            double panAmount = (maxX - minX) / 10;
                            minX = (minX - panAmount).clamp(
                              0,
                              sensorData.length.toDouble() - 5,
                            );
                            maxX = (maxX - panAmount).clamp(
                              5,
                              sensorData.length.toDouble(),
                            );
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historical Data"),
        actions: [
          DropdownButton<String>(
            value: selectedInterval,
            onChanged: (String? newValue) {
              setState(() {
                selectedInterval = newValue!;
              });
            },
            items:
                [
                  "Monthly",
                  "Weekly",
                  "Daily",
                  "Minute",
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
          ),
        ],
      ),
      body:
          sensorData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  buildGraph("Temperature (°C)", "temperature", [
                    Colors.redAccent,
                    Colors.red,
                  ]),
                  buildGraph("Humidity (%)", "humidity", [
                    Colors.blueAccent,
                    Colors.blue,
                  ]),
                  buildGraph("PM2.5 (ppm)", "pm25", [
                    Colors.greenAccent,
                    Colors.green,
                  ]),
                  buildGraph("CO2 (ppm)", "co2", [
                    Colors.orangeAccent,
                    Colors.orange,
                  ]),
                ],
              ),
    );
  }
}
