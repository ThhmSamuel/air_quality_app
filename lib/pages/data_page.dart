import 'package:flutter/material.dart';

class DataPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Historical Data")),
      body: Center(
        child: Text(
          "Data Page (Fetch & Show Data from DynamoDB)",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
