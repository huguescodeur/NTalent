class Comment {
  final String id;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });
}
