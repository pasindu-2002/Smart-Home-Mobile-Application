import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoorEventsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Door Events'),
        backgroundColor: Color(0xFF1D1E33),
      ),
      body: DoorEventsList(),
    );
  }
}

class DoorEventsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('door_events')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!.docs;

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final timestamp = (event['timestamp'] as Timestamp).toDate();
            final userName = event['userName'];
            final action = event['action'];

            return ListTile(
              title: Text('$userName $action the door'),
              subtitle: Text('${timestamp.toLocal()}'),
            );
          },
        );
      },
    );
  }
}
