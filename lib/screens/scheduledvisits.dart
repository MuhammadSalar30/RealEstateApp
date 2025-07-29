import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ScheduledVisitsPage extends StatelessWidget {
  const ScheduledVisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to see your visits.")),
      );
    }

    final visitsQuery = FirebaseFirestore.instance
        .collection('scheduled_visits')
        .where('userId', isEqualTo: user.uid)
        .orderBy('visitDate');

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Scheduled Visits"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: visitsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No scheduled visits found."));
          }

          final visits = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final data = visits[index].data() as Map<String, dynamic>;
            final date = data['visitDate'] ?? '';
              final slot = data['timeSlot'] ?? '';
              final type = data['propertyType'] ?? '';
              final location = data['propertyLocation'] ?? '';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text('$type in $location'),
                  subtitle: Text('On $date at $slot'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
