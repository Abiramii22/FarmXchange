import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AgentsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Available Tractors")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('agents').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var agents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: agents.length,
            itemBuilder: (context, index) {
              var data = agents[index];

              return Card(
                child: ListTile(
                  title: Text(data['machine']),
                  subtitle: Text(
                      "${data['engineCapacity']} | ₹${data['hourlyRate']}/hr"),
                  trailing: ElevatedButton(
                    child: Text("Book"),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .add({
                        'machine': data['machine'],
                        'price': data['hourlyRate'],
                        'status': 'Pending',
                        'date': '2026-05-04',
                        'createdAt': Timestamp.now(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Booked ✅")),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}