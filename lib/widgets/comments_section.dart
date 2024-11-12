import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nt/services/providers/get_user_infos_provider.dart';
import 'package:nt/widgets/comment_tile.dart';

class CommentsSection extends ConsumerStatefulWidget {
  final String postId;
  const CommentsSection({required this.postId, super.key});

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _commentController = TextEditingController();
  String? replyingTo;
  String? replyingToUsername;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final comment = snapshot.data!.docs[index];
                    return CommentTile(
                      commentId: comment.id,
                      postId: widget.postId,
                      userId: comment['userId'],
                      text: comment['text'],
                      timestamp: comment['createdAt'] != null
                          ? (comment['createdAt'] as Timestamp).toDate()
                          : DateTime.now(),
                      onReply: (username) {
                        setState(() {
                          replyingTo = comment.id;
                          replyingToUsername = username;
                        });
                        _commentController.text = '@$username ';
                        _commentController.selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: _commentController.text.length),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Text('Replying to @$replyingToUsername'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        replyingTo = null;
                        replyingToUsername = null;
                        _commentController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: replyingTo == null
                          ? 'Add a comment...'
                          : 'Add your reply...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    final user = ref.watch(userProvider);
    // final userInfo = ref.watch(userInfosProvider(user?.id));

    if (user == null || _commentController.text.isEmpty) return;

    try {
      final commentData = {
        'userId': user.id,
        'text': _commentController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'replyTo': replyingTo,
        'likes': [],
      };

      if (replyingTo != null) {
        // Ajouter comme réponse à un commentaire
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(replyingTo)
            .collection('replies')
            .add(commentData);
      } else {
        // Ajouter comme nouveau commentaire
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .add(commentData);
      }

      _commentController.clear();
      setState(() {
        replyingTo = null;
        replyingToUsername = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
