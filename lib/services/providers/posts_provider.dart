import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nt/models/post_model.dart';

final postsProvider = StreamProvider.autoDispose((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Post(
        id: doc.id,
        userId: data['userId'],
        description: data['description'],
        videoUrl: data['videoUrl'],
        thumbnail: data['thumbnail'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        tags: List<String>.from(data['tags'] ?? []),
        likes: data['likes'] ?? 0,
        comments: data['comments'] ?? 0,
        skills: List<String>.from(data['skills'] ?? []),
      );
    }).toList();
  });
});
