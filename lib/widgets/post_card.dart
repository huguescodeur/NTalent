// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nt/models/post_model.dart';
import 'package:nt/screens/posts/edit_post_screen.dart';
import 'package:nt/widgets/comments_section.dart';
import 'package:nt/widgets/shimmer_effet.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:rxdart/rxdart.dart';

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
  bool _isDescriptionExpanded = false;

  final userId = FirebaseAuth.instance.currentUser!.uid;
  bool isLiked = false;

  Stream<int> getCommentCount() {
    final commentsStream = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .snapshots();

    return commentsStream.switchMap((commentSnapshot) {
      final commentCount = commentSnapshot.docs.length;

      final replyStreams = commentSnapshot.docs.map((comment) {
        return FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(comment.id)
            .collection('replies')
            .snapshots()
            .map((replySnapshot) => replySnapshot.docs.length);
      });

      return CombineLatestStream.list<int>(replyStreams).map((replyCounts) {
        final totalReplies = replyCounts.fold(0, (sum, count) => sum + count);
        return commentCount + totalReplies;
      });
    });
  }

  Future<void> _deletePost() async {
    try {
      // Commencer une transaction batch
      final batch = FirebaseFirestore.instance.batch();

      // Référence du post
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(widget.postId);

      // Référence de l'utilisateur
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.post.userId);

      // Obtenir les références de stockage
      final videoRef = FirebaseStorage.instance
          .ref()
          .child('posts')
          .child(widget.post.userId)
          .child('${widget.postId}.mp4');

      final thumbnailRef = FirebaseStorage.instance
          .ref()
          .child('thumbnails')
          .child(widget.post.userId)
          .child('${widget.postId}.jpg');

      // Supprimer les fichiers du storage
      await videoRef.delete();
      await thumbnailRef.delete();

      // Supprimer le document du post
      batch.delete(postRef);

      // Décrémenter le compteur de posts de l'utilisateur
      batch.update(userRef, {
        'postsCount': FieldValue.increment(-1),
      });

      // Exécuter le batch
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: ${e.toString()}')),
        );
      }
    }
  }

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

  // @override
  // void dispose() {
  //   _videoController.dispose();
  //   super.dispose();
  // }

  // @override
  // void dispose() {
  //   if (_videoController.value.isInitialized) {
  //     _videoController.dispose();
  //   }
  //   super.dispose();
  // }

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

  Future<Map<String, dynamic>> fetchUserInfo(String userId) async {
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot.data() ?? {};
  }

  void _showMoreOptions(BuildContext context) {
    // Obtenir le contexte le plus proche possible du Scaffold
    final scaffoldContext = Scaffold.of(context).context;

    showModalBottomSheet(
      context: scaffoldContext,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(context);
                // Utiliser le contexte du Scaffold pour la navigation
                final result = await Navigator.push(
                  scaffoldContext,
                  MaterialPageRoute(
                    builder: (context) => EditPostScreen(
                      postId: widget.postId,
                      description: widget.post.description,
                      skills: List<String>.from(widget.post.skills ?? []),
                    ),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: scaffoldContext,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Post'),
                    content: const Text(
                      'Are you sure you want to delete this post? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          Navigator.pop(context);
                          _deletePost().then((_) {
                            // Après la suppression, naviguer vers l'écran précédent
                            if (Navigator.canPop(scaffoldContext)) {
                              Navigator.pop(scaffoldContext);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    final size = MediaQuery.of(context).size;

    return FutureBuilder<Map<String, dynamic>>(
      future: fetchUserInfo(widget.post.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !_isVideoInitialized) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: buildShimmerEffect(context: context),
          );
        }

        final userInfo = snapshot.data!;
        final userName = userInfo['name'] ?? 'Anonymous';
        final userPhoto =
            userInfo['profileImage'] ?? 'https://via.placeholder.com/50';

        return Container(
          height: size.height,
          width: size.width,
          color: Colors.black,
          child: Stack(
            children: [
              // Video Container
              Center(
                child: Container(
                  width: size.width,
                  height: size.height,
                  color: Colors.black,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VisibilityDetector(
                        key: Key(widget.post.videoUrl),
                        onVisibilityChanged: (visibilityInfo) {
                          final visiblePercentage =
                              visibilityInfo.visibleFraction * 100;
                          _playVideoIfVisible(visiblePercentage > 50);
                        },
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: VideoPlayer(_videoController),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Pause Icon Overlay
              if (!_isPlaying)
                Center(
                  child: Container(
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
                ),

              // User Info Overlay (Top)
              Positioned(
                top: 40,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(userPhoto),
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            timeago.format(widget.post.createdAt, locale: 'fr'),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    if (widget.post.userId ==
                        userId) // Montrer seulement si c'est le post de l'utilisateur
                      IconButton(
                          icon:
                              const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () => _showMoreOptions(context)),
                  ],
                ),
              ),

              // Actions Overlay (Right)
              Positioned(
                right: 10,
                bottom: 100,
                child: Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        size: 30,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text(
                      widget.post.likes.length.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    IconButton(
                      icon: const Icon(
                        Icons.comment_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => DraggableScrollableSheet(
                            initialChildSize: 0.9,
                            minChildSize: 0.5,
                            maxChildSize: 0.9,
                            builder: (_, controller) =>
                                CommentsSection(postId: widget.postId),
                          ),
                        );
                      },
                    ),

                    StreamBuilder<int>(
                      stream: getCommentCount(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            '0',
                            style: TextStyle(color: Colors.white),
                          );
                        }
                        return Text(
                          snapshot.data?.toString() ?? '0',
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                    ),

                    // const SizedBox(height: 20),
                    // IconButton(
                    //   icon: const Icon(
                    //     Icons.share,
                    //     color: Colors.white,
                    //     size: 30,
                    //   ),
                    //   onPressed: () {},
                    // ),
                  ],
                ),
              ),

              // Description Overlay (Bottom)
              Positioned(
                bottom: 30,
                left: 10,
                right: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Text(
                        widget.post.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        maxLines: _isDescriptionExpanded ? null : 2,
                        overflow: _isDescriptionExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.post.description.length > 50)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Text(
                          _isDescriptionExpanded ? 'Voir moins' : 'Voir plus',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
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

/*onPressed: () {
                          print("More Vertical");
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
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
                                  ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: const Text('Edit'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditPostScreen(
                                            postId: widget.postId,
                                            description:
                                                widget.post.description,
                                            skills: List<String>.from(
                                                widget.post.skills ?? []),
                                          ),
                                        ),
                                      );
                                      if (result == true && mounted) {
                                        setState(() {});
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete,
                                        color: Colors.red),
                                    title: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Post'),
                                          content: const Text(
                                            'Are you sure you want to delete this post? This action cannot be undone.',
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text('Cancel'),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                            TextButton(
                                              child: const Text('Delete',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deletePost();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          );
                        }, */