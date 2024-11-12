import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String description;
  final String videoUrl;
  final String thumbnail;
  final DateTime createdAt;
  final List<String> tags;
  final List likes;
  final List comments;
  final List<String> skills;

  Post({
    required this.id,
    required this.userId,
    required this.description,
    required this.videoUrl,
    required this.thumbnail,
    required this.createdAt,
    required this.tags,
    required this.likes,
    required this.comments,
    required this.skills,
  });

  factory Post.fromJson(Map<String, dynamic> json, {String? id}) {
    return Post(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      // createdAt: (json['createdAt'] as Timestamp).toDate(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
      likes: List<String>.from(json['likes'] ?? []),
      comments: List<String>.from(json['comments'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
    );
  }
}
