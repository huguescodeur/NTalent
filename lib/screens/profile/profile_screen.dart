import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nt/models/user_model.dart';
import 'package:nt/screens/auth/login_screen.dart';
import 'package:nt/screens/chat/chat_screen.dart';
import 'package:nt/screens/profile/edit_profile_screen.dart';
import 'package:nt/widgets/post_detail.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final bool isCurrentUser;

  const ProfileScreen({
    required this.userId,
    this.isCurrentUser = false,
    super.key,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool isFollowing = false;
  late TabController _tabController;

  // Modifier la signature de la méthode pour accepter userData comme paramètre
  // Widget _buildActionButtons(Map<String, dynamic> userData) {
  //   if (widget.isCurrentUser) {
  //     return ElevatedButton(
  //       onPressed: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => EditProfileScreen(
  //               userId: widget.userId!,
  //               userData: userData,
  //             ),
  //           ),
  //         );
  //       },
  //       child: const Text('Modifier mon profil'),
  //     );
  //   } else {
  //     return Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         if (isFollowing) ...[
  //           Expanded(
  //             child: ElevatedButton(
  //               onPressed: () {
  //                 // Naviguer vers la page de messagerie
  //                 // TODO: Implémenter la navigation vers la page de messagerie
  //               },
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.white,
  //                 side: BorderSide(color: Theme.of(context).primaryColor),
  //               ),
  //               child: const Text(
  //                 'Message',
  //                 style: TextStyle(color: Colors.black),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(width: 8),
  //           Container(
  //             height: 36,
  //             width: 36,
  //             decoration: BoxDecoration(
  //               border: Border.all(color: Colors.grey[300]!),
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: IconButton(
  //               padding: EdgeInsets.zero,
  //               icon: const Icon(Icons.person_remove, size: 20),
  //               onPressed: _toggleFollow,
  //             ),
  //           ),
  //         ] else
  //           Expanded(
  //             child: ElevatedButton(
  //               onPressed: _toggleFollow,
  //               child: const Text('Suivre'),
  //             ),
  //           ),
  //       ],
  //     );
  //   }
  // }

  Widget _buildActionButtons(Map<String, dynamic> userData) {
    if (widget.isCurrentUser) {
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(
                userId: widget.userId!,
                userData: userData,
              ),
            ),
          );
        },
        child: const Text('Modifier mon profil'),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isFollowing) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  // Créer ou récupérer l'ID du chat
                  final chatId = await _createOrGetChat();

                  // Convertir userData en UserModel
                  final otherUser = UserModel(
                    id: widget.userId!,
                    name: userData['name'] ?? '',
                    profileImage: userData['profileImage'],
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chatId,
                        otherUser: otherUser,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
                child: const Text(
                  'Message',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.person_remove, size: 20),
                onPressed: _toggleFollow,
              ),
            ),
          ] else
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleFollow,
                child: const Text('Suivre'),
              ),
            ),
        ],
      );
    }
  }

// Ajoutez cette méthode pour créer ou récupérer un chat
  Future<String> _createOrGetChat() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return '';

    // Vérifier si un chat existe déjà
    final querySnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    // Rechercher un chat existant avec l'autre utilisateur
    for (final doc in querySnapshot.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(widget.userId)) {
        return doc.id;
      }
    }

    // Si aucun chat n'existe, en créer un nouveau
    final newChatRef =
        await FirebaseFirestore.instance.collection('chats').add({
      'participants': [currentUserId, widget.userId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newChatRef.id;
  }

  @override
  void initState() {
    super.initState();
    _checkFollowingStatus();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkFollowingStatus() async {
    if (!widget.isCurrentUser) {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      if (currentUserDoc.exists) {
        final following =
            List<String>.from(currentUserDoc.data()?['following'] ?? []);
        setState(() {
          isFollowing = following.contains(widget.userId);
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final targetUserRef =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);

    if (isFollowing) {
      batch.update(currentUserRef, {
        'following': FieldValue.arrayRemove([widget.userId]),
        'followingCount': FieldValue.increment(-1),
      });
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayRemove([currentUserId]),
        'followersCount': FieldValue.increment(-1),
      });
    } else {
      batch.update(currentUserRef, {
        'following': FieldValue.arrayUnion([widget.userId]),
        'followingCount': FieldValue.increment(1),
      });
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayUnion([currentUserId]),
        'followersCount': FieldValue.increment(1),
      });
    }

    await batch.commit();
    setState(() {
      isFollowing = !isFollowing;
    });
  }

  Widget _buildPostedVideos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune vidéo publiée'));
        }

        return GridView.builder(
          // Important: Remove any physics parameter here to allow scrolling
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final post =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PostDetailScreen(
                    postId: snapshot
                        .data!.docs[index].id, // Utilisez l'ID du document
                  ),
                ));
              },
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(post['thumbnail'] ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black.withOpacity(0.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            (post['likes'] as List<dynamic>?)
                                    ?.length
                                    .toString() ??
                                '0',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLikedVideos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('likes', arrayContains: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune vidéo likée'));
        }

        return GridView.builder(
          // Important: Remove any physics parameter here to allow scrolling
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final post =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PostDetailScreen(
                    postId: snapshot.data!.docs[index].id,
                  ),
                ));
              },
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(post['thumbnail'] ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black.withOpacity(0.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            (post['likes'] as List<dynamic>?)
                                    ?.length
                                    .toString() ??
                                '0',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn(String title, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(title),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null || widget.userId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Invalid user ID')),
      );
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 560, // Increased height to accommodate TabBar
                  pinned: true,
                  floating: true,
                  title: const Text('Profile'),
                  actions: [
                    if (widget.isCurrentUser)
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: const EdgeInsets.only(
                        // top: 100,
                        left: 16,
                        right: 16,
                        // Increased bottom padding to prevent overlap with TabBar
                        bottom: 60,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                              userData['profileImage'] ??
                                  'https://via.placeholder.com/100',
                            ),
                            child: userData['profileImage']?.isEmpty ?? true
                                ? Text(userData['name']?[0] ?? '?')
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userData['name'] ?? 'Unknown',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userData['bio'] ?? 'No bio available',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: "${userData['sport']}, " ?? '',
                                style: const TextStyle(color: Colors.black),
                              ),
                              TextSpan(
                                text: userData['position'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          Text(userData['location'] ?? ''),
                          const SizedBox(height: 16),
                          if ((userData['skills'] as List<dynamic>?)
                                  ?.isNotEmpty ??
                              false)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: (userData['skills'] as List<dynamic>?)
                                      ?.map((skill) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        skill.toString(),
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }).toList() ??
                                  [],
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn('Poste(s)',
                                  userData['postsCount']?.toString() ?? '0'),
                              _buildStatColumn(
                                  'Abonné(s)',
                                  userData['followersCount']?.toString() ??
                                      '0'),
                              _buildStatColumn(
                                  'Suivies(s)',
                                  userData['followingCount']?.toString() ??
                                      '0'),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('posts')
                                    .where('userId', isEqualTo: widget.userId)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return _buildStatColumn('Likes', '0');
                                  }

                                  int totalLikes =
                                      snapshot.data!.docs.fold(0, (sum, doc) {
                                    final likes =
                                        doc['likes'] as List<dynamic>? ?? [];
                                    return sum + likes.length;
                                  });

                                  return _buildStatColumn(
                                      "J'aime(s)", totalLikes.toString());
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildActionButtons(
                                userData), // Passez userData ici
                          ),

                          // if (widget.isCurrentUser)
                          //   ElevatedButton(
                          //     onPressed: () {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (context) => EditProfileScreen(
                          //             userId: widget.userId!,
                          //             userData: userData,
                          //           ),
                          //         ),
                          //       );
                          //     },
                          //     child: const Text('Modifier mon profil'),
                          //   )
                          // else
                          //   ElevatedButton(
                          //     onPressed: _toggleFollow,
                          //     child: Text(
                          //         isFollowing ? 'Ne plus suivre' : 'Suivre'),
                          //   ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Vidéos Publiées'),
                          Tab(text: 'Vidéos Likées'),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildPostedVideos(),
                _buildLikedVideos(),
              ],
            ),
          );
        },
      ),
    );
  }
}
