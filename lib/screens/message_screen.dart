import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/50'),
            ),
            title: const Text('Recruiter Name'),
            subtitle: const Text('Latest message preview...'),
            trailing: const Text('2h ago'),
            onTap: () {
              // Navigate to chat
            },
          );
        },
      ),
    );
  }
}
