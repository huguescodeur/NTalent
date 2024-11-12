import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OpportunityCard extends StatelessWidget {
  final String title;
  final String description;
  final String sport;
  final String location;
  final DateTime deadline;
  final VoidCallback onTap;

  const OpportunityCard({
    required this.title,
    required this.description,
    required this.sport,
    required this.location,
    required this.deadline,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            Text('Sport: $sport'),
            Text('Location: $location'),
            Text('Deadline: ${DateFormat.yMMMd().format(deadline)}'),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
