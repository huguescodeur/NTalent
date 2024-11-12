import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nt/models/user_model.dart';
import 'package:nt/services/providers/user_infos_async.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentTile extends ConsumerStatefulWidget {
  final String commentId;
  final String postId;
  final String userId;
  final String text;
  final DateTime timestamp;
  final Function(String username) onReply;

  const CommentTile({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.text,
    required this.timestamp,
    required this.onReply,
    super.key,
  });

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {
  bool _isRepliesVisible = false;

  Widget _buildUserAvatar(UserModel? userInfo) {
    if (userInfo == null || userInfo.profileImage == null) {
      return const CircleAvatar(radius: 20);
    }
    return CircleAvatar(
      backgroundImage: NetworkImage(userInfo.profileImage!),
      radius: 20,
    );
  }

  Widget _buildUserName(UserModel? userInfo) {
    return Text(
      userInfo?.name ?? 'Unknown User',
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildReplyButton(UserModel? userInfo) {
    return TextButton(
      onPressed: () {
        if (userInfo != null) {
          widget.onReply(userInfo.name);
        }
      },
      child: const Text('Reply'),
    );
  }

  Widget _buildRepliesSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(widget.commentId)
          .collection('replies')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final replies = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isRepliesVisible)
              Padding(
                padding: const EdgeInsets.only(left: 68),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isRepliesVisible = true;
                    });
                  },
                  child: Text(
                    'View ${replies.length} replies',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            if (_isRepliesVisible)
              ...replies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: CommentTile(
                    commentId: reply.id,
                    postId: widget.postId,
                    userId: reply['userId'],
                    text: reply['text'],
                    timestamp: reply['createdAt'] != null
                        ? (reply['createdAt'] as Timestamp).toDate()
                        : DateTime.now(),
                    onReply: widget.onReply,
                  ),
                );
              }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoAsync = ref.watch(userInfosProvider(widget.userId));

    return userInfoAsync.when(
      data: (userInfo) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserAvatar(userInfo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserName(userInfo),
                      const SizedBox(height: 4),
                      Text(widget.text),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            timeago.format(widget.timestamp,
                                locale: 'en_short'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          _buildReplyButton(userInfo),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {
                    // TODO: Implement like functionality
                  },
                ),
              ],
            ),
          ),
          _buildRepliesSection(context),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading user info')),
    );
  }
}
