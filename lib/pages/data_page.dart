import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  List<Map<String, dynamic>> sensorData = [];
  String selectedInterval = "Daily";

  // Add date range selection
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();

  // Store min and max values for better chart scaling
  Map<String, double> minValues = {
    'temperature': double.infinity,
    'humidity': double.infinity,
    'pm25': double.infinity,
    'co2': double.infinity,
  };

  Map<String, double> maxValues = {
    'temperature': double.negativeInfinity,
    'humidity': double.negativeInfinity,
    'pm25': double.negativeInfinity,
    'co2': double.negativeInfinity,
  };

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "https://r6y3av2nb3.execute-api.ap-southeast-1.amazonaws.com/fetchSensorData",
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> parsedData =
            data.map((e) => e as Map<String, dynamic>).toList();

        // Sort data by timestamp (earliest to latest)
        parsedData.sort(
          (a, b) => DateTime.parse(
            a["timestamp"],
          ).compareTo(DateTime.parse(b["timestamp"])),
        );

        // Calculate min/max values for better scaling
        for (var entry in parsedData) {
          for (var key in ['temperature', 'humidity', 'pm25', 'co2']) {
            double value = double.tryParse(entry[key].toString()) ?? 0.0;
            if (value < minValues[key]!) minValues[key] = value;
            if (value > maxValues[key]!) maxValues[key] = value;
          }
        }

        setState(() {
          sensorData = parsedData;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
          isLoading = false;
        });
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching data: $e";
        isLoading = false;
      });
      print("Error fetching data: $e");
    }
  }

  List<Map<String, dynamic>> filterDataByTimeRange() {
    if (sensorData.isEmpty) return [];

    return sensorData.where((entry) {
      DateTime timestamp = DateTime.parse(entry["timestamp"]);
      return timestamp.isAfter(startDate) &&
          timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  String formatTimestamp(DateTime timestamp) {
    switch (selectedInterval) {
      case "Monthly":
        return DateFormat('MMM yyyy').format(timestamp);
      case "Weekly":
        return DateFormat('d MMM').format(timestamp);
      case "Daily":
        return DateFormat('d MMM').format(timestamp);
      case "Hourly":
        return DateFormat('HH:mm').format(timestamp);
      case "Minute":
        return DateFormat('HH:mm').format(timestamp);
      default:
        return DateFormat('d MMM HH:mm').format(timestamp);
    }
  }

  List<FlSpot> getChartData(
    String key,
    List<Map<String, dynamic>> filteredData,
  ) {
    if (filteredData.isEmpty) return [];

    return List.generate(filteredData.length, (i) {
      double value = double.tryParse(filteredData[i][key].toString()) ?? 0.0;
      // X-axis is now timestamp in milliseconds since epoch
      double x =
          DateTime.parse(
            filteredData[i]["timestamp"],
          ).millisecondsSinceEpoch.toDouble();
      return FlSpot(x, value);
    });
  }

  // Helper function to get interval for x-axis ticks based on selected time range
  double getXAxisInterval(List<Map<String, dynamic>> filteredData) {
    if (filteredData.isEmpty || filteredData.length == 1) return 1;

    double firstTimestamp =
        DateTime.parse(
          filteredData.first["timestamp"],
        ).millisecondsSinceEpoch.toDouble();
    double lastTimestamp =
        DateTime.parse(
          filteredData.last["timestamp"],
        ).millisecondsSinceEpoch.toDouble();
    double range = lastTimestamp - firstTimestamp;

    int divisions = 5; // Number of divisions on x-axis
    return range / divisions;
  }

  Widget buildGraph(
    String title,
    String key,
    List<Color> gradientColors,
    List<Map<String, dynamic>> filteredData,
  ) {
    if (filteredData.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "No data available for the selected time range",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    // Calculate y-axis range with some padding
    double minY = (minValues[key]! * 0.9).clamp(0, double.infinity);
    double maxY = maxValues[key]! * 1.1;

    // Calculate x-axis range from timestamps in filtered data
    double minX =
        DateTime.parse(
          filteredData.first["timestamp"],
        ).millisecondsSinceEpoch.toDouble();
    double maxX =
        DateTime.parse(
          filteredData.last["timestamp"],
        ).millisecondsSinceEpoch.toDouble();

    // Calculate interval for x-axis ticks
    double xAxisInterval = getXAxisInterval(filteredData);

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${minValues[key]!.toStringAsFixed(1)} - ${maxValues[key]!.toStringAsFixed(1)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxY - minY) / 5,
                    verticalInterval: xAxisInterval,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(color: Colors.grey, strokeWidth: 0.5);
                    },
                    getDrawingVerticalLine: (value) {
                      return const FlLine(color: Colors.grey, strokeWidth: 0.5);
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (maxY - minY) / 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: xAxisInterval,
                        getTitlesWidget: (value, meta) {
                          DateTime date = DateTime.fromMillisecondsSinceEpoch(
                            value.toInt(),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Transform.rotate(
                              angle:
                                  0.5, // Slightly rotated for better readability
                              child: Text(
                                formatTimestamp(date),
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
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
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: getChartData(key, filteredData),
                      isCurved: true,
                      gradient: LinearGradient(colors: gradientColors),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show:
                            filteredData.length <
                            30, // Only show dots when data points are few
                      ),
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
                          final DateTime date =
                              DateTime.fromMillisecondsSinceEpoch(
                                spot.x.toInt(),
                              );
                          return LineTooltipItem(
                            '${DateFormat('yyyy-MM-dd HH:mm').format(date)}\n${spot.y.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    enabled: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTimeRangeSelector() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Range Selection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null && picked != startDate) {
                            setState(() {
                              startDate = picked;
                              // Ensure end date is not before start date
                              if (endDate.isBefore(startDate)) {
                                endDate = startDate.add(
                                  const Duration(days: 1),
                                );
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Date'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat('yyyy-MM-dd').format(endDate)),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                          );
                          if (picked != null && picked != endDate) {
                            setState(() {
                              endDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Time Interval:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: selectedInterval,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedInterval = newValue!;
                    });
                  },
                  items:
                      [
                        'Monthly',
                        'Weekly',
                        'Daily',
                        'Hourly',
                        'Minute',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 110,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        endDate = DateTime.now();
                        startDate = endDate.subtract(const Duration(days: 1));
                        selectedInterval = 'Hourly';
                      });
                    },
                    child: const Text(
                      '24 Hours',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        endDate = DateTime.now();
                        startDate = endDate.subtract(const Duration(days: 7));
                        selectedInterval = 'Daily';
                      });
                    },
                    child: const Text('7 Days', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        endDate = DateTime.now();
                        startDate = endDate.subtract(const Duration(days: 30));
                        selectedInterval = 'Daily';
                      });
                    },
                    child: const Text(
                      '30 Days',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter data based on selected time range
    final filteredData = filterDataByTimeRange();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sensor Data Analysis"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(errorMessage!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: fetchData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  buildTimeRangeSelector(),
                  buildGraph("Temperature (°C)", "temperature", [
                    Colors.redAccent,
                    Colors.red,
                  ], filteredData),
                  buildGraph("Humidity (%)", "humidity", [
                    Colors.blueAccent,
                    Colors.blue,
                  ], filteredData),
                  buildGraph("PM2.5 (ppm)", "pm25", [
                    Colors.greenAccent,
                    Colors.green,
                  ], filteredData),
                  buildGraph("CO2 (ppm)", "co2", [
                    Colors.orangeAccent,
                    Colors.orange,
                  ], filteredData),
                ],
              ),
    );
  }
}
