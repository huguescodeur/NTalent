// ignore_for_file: cast_from_null_always_fails, unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nt/models/user_model.dart';
import 'package:nt/screens/chat/chat_screen.dart';
import 'package:nt/screens/profile/profile_screen.dart';
import 'package:nt/services/providers/auth_provider.dart';
import 'package:nt/services/providers/get_user_infos_provider.dart';

class ApplicationsScreen extends ConsumerWidget {
  final String opportunityId;

  const ApplicationsScreen({required this.opportunityId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('opportunities')
            .doc(opportunityId)
            .collection('applications')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final application = snapshot.data!.docs[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(application['userId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final athlete =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final athleteId = userSnapshot.data!.id;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(athlete['profileImage'] ?? ''),
                      // Fallback if image is null or empty
                      child: athlete['profileImage']?.isEmpty ?? true
                          ? Text(athlete['name']?[0] ?? '?')
                          : null,
                    ),
                    title: Text(athlete['name'] ?? 'Unknown'),
                    subtitle: Text(athlete['sport'] ?? 'No sport specified'),
                    trailing: IconButton(
                      icon: const Icon(Icons.message),
                      onPressed: () => _startChat(context, ref, athleteId),
                    ),
                    onTap: () => _viewProfile(context, athleteId),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _startChat(
      BuildContext context, WidgetRef ref, String athleteId) async {
    final user = ref.watch(userProvider);
    if (user == null) return;

    // Create or get existing chat
    final chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.id)
        .get();

    QueryDocumentSnapshot? existingChat =
        chatQuery.docs.cast<QueryDocumentSnapshot>().firstWhere(
              (doc) => (doc.data() as Map<String, dynamic>)['participants']
                  .contains(athleteId),
              orElse: () => null as QueryDocumentSnapshot,
            );

    String chatId;
    if (existingChat != null) {
      chatId = existingChat.id;
    } else {
      // Create new chat
      final chatRef = await FirebaseFirestore.instance.collection('chats').add({
        'participants': [user.id, athleteId],
        'lastMessage': null,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      chatId = chatRef.id;
    }

    if (context.mounted) {
      // Get other user's data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(athleteId)
          .get();

      if (!context.mounted) return;

      if (userDoc.exists) {
        final otherUser = UserModel.fromJson({
          ...userDoc.data()!,
          'id': userDoc.id,
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUser: otherUser,
            ),
          ),
        );
      }
    }
  }

  void _viewProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          userId: userId,
          isCurrentUser: false,
        ),
      ),
    );
  }
}
