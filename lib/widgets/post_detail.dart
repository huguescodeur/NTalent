import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nt/models/post_model.dart';
import 'package:nt/widgets/post_card.dart';

class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({required this.postId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Pour que l'AppBar soit transparente
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final postData = snapshot.data!.data() as Map<String, dynamic>;
          final post = Post.fromJson(postData);

          return PostCard(
            post: post,
            postId: postId,
          );
        },
      ),
    );
  }
}
