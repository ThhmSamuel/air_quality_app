import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Account Settings")),
      body: Center(
        child: Text(
          "Account Page (User Info & Settings)",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
