<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'booking_screen.dart';
class AdminHome extends StatelessWidget {
  final List<String> logs = [
    "User Ravi booked Tractor",
    "Agent earned ₹2000",
    "User Kumar booked Plough",
    "Agent earned ₹1500"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),

      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.info),
            title: Text(logs[index]),
          );
        },
      ),
    );
  }
=======
import 'package:flutter/material.dart';
import 'booking_screen.dart';
class AdminHome extends StatelessWidget {
  final List<String> logs = [
    "User Ravi booked Tractor",
    "Agent earned ₹2000",
    "User Kumar booked Plough",
    "Agent earned ₹1500"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),

      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.info),
            title: Text(logs[index]),
          );
        },
      ),
    );
  }
>>>>>>> d314aebe5da72d346a98d707b27d1b0f1d86d376
}