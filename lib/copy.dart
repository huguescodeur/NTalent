import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nt/models/post_model.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final String postId;

  const PostCard({super.key, required this.post, required this.postId});

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = true;

  final userId = FirebaseAuth.instance.currentUser!.uid;
  bool isLiked = false;

  // Vérifier si l'utilisateur a déjà liké ce post
  Future<void> _checkIfLiked() async {
    final postDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();

    if (postDoc.exists) {
      List<String> likes = List<String>.from(postDoc.data()?['likes'] ?? []);
      setState(() {
        isLiked = likes.contains(userId);
      });
    }
  }

  // Fonction pour toggler le like
  Future<void> _toggleLike() async {
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    if (isLiked) {
      // Supprimer le like
      await postRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      // Ajouter le like
      await postRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }

    setState(() {
      isLiked = !isLiked;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _checkIfLiked();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.network(widget.post.videoUrl);

    try {
      await _videoController.initialize();
      await _videoController.setLooping(true);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de la vidéo: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _videoController.play();
      } else {
        _videoController.pause();
      }
    });
  }

  void _playVideoIfVisible(bool isVisible) {
    if (_isVideoInitialized) {
      if (isVisible && !_videoController.value.isPlaying && _isPlaying) {
        _videoController.play();
      } else if (!isVisible && _videoController.value.isPlaying) {
        _videoController.pause();
      }
    }
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info shimmer
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Avatar shimmer
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Name and time shimmer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 80,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Video placeholder shimmer
          Container(
            height: 400,
            color: Colors.white,
          ),
          // Actions and description shimmer
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 200,
                  height: 16,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchUserInfo(String userId) async {
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('fr', timeago.FrMessages());

    return FutureBuilder<Map<String, dynamic>>(
      future: fetchUserInfo(widget.post.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !_isVideoInitialized) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: _buildShimmerEffect(),
          );
        }

        final userInfo = snapshot.data!;
        final userName = userInfo['name'] ?? 'Anonymous';
        final userPhoto =
            userInfo['photoUrl'] ?? 'https://via.placeholder.com/50';

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(userPhoto),
                ),
                title: Text(userName),
                subtitle: Text(
                  timeago.format(widget.post.createdAt, locale: 'fr'),
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(child: Text('Report')),
                    const PopupMenuItem(child: Text('Share')),
                  ],
                ),
              ),
              VisibilityDetector(
                key: Key(widget.post.videoUrl),
                onVisibilityChanged: (visibilityInfo) {
                  final visiblePercentage =
                      visibilityInfo.visibleFraction * 100;
                  _playVideoIfVisible(visiblePercentage > 50);
                },
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 400,
                        // width: double.infinity,
                        child: AspectRatio(
                          aspectRatio: _videoController.value.aspectRatio,
                          child: VideoPlayer(_videoController),
                        ),
                      ),
                      // Icône de pause qui apparaît brièvement lors du tap
                      if (!_isPlaying)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pause,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                          onPressed: _toggleLike,
                        ),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined),
                          onPressed: () {
                            // Logique pour ouvrir la section des commentaires
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            // Logique pour le partage
                          },
                        ),
                      ],
                    ),
                    widget.post.likes.isEmpty
                        ? Text(
                            '${widget.post.likes.length} like',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : Text(
                            '${widget.post.likes.length} likes',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
