import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nt/screens/profile/profile_screen.dart';
import 'package:nt/widgets/post_detail.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _posts = [];
  List<QueryDocumentSnapshot> _users = [];
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
  }

  Future<void> _loadInitialPosts() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      if (mounted) {
        setState(() {
          _posts = snapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Erreur lors du chargement des posts: $e');
    }
  }

  Future<void> _handleSearch(String query) async {
    // Si la recherche est vide, on revient à l'affichage initial
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _users = [];
      });
      await _loadInitialPosts();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      // Recherche de posts (convertir en minuscules pour la recherche)
      final postsSnapshot =
          await FirebaseFirestore.instance.collection('posts').get();

      // Recherche d'utilisateurs
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Filtrer les résultats localement
      final filteredPosts = postsSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final description =
            (data['description'] ?? '').toString().toLowerCase();
        return description.contains(query.toLowerCase());
      }).toList();

      final filteredUsers = usersSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final bio = (data['bio'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            bio.contains(query.toLowerCase());
      }).toList();

      if (mounted) {
        setState(() {
          _posts = filteredPosts;
          _users = filteredUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Erreur lors de la recherche: $e');
    }
  }

  void _handleUserTap(Map<String, dynamic> userData) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUser = userData['id'] == currentUserId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          userId: userData['id'],
          isCurrentUser: isCurrentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher des talents...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _handleSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(15),
                  ),
                  onChanged: _handleSearch,
                ),
              ),
            ),

            // Indicateur de chargement
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),

            // Message si aucun résultat
            if (_isSearching && _posts.isEmpty && _users.isEmpty && !_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Aucun résultat trouvé'),
              ),

            // Contenu principal
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Résultats des utilisateurs (uniquement pendant la recherche)

                  if (_isSearching && _users.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final userData =
                              _users[index].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                              child: ClipOval(
                                child: Image(
                                  image: NetworkImage(
                                      userData['profileImage'] ?? ''),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person);
                                  },
                                ),
                              ),
                            ),
                            title: Text(userData['name'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (userData['location'] != null)
                                  Text(userData['location']),
                                if (userData['bio'] != null)
                                  Text(
                                    userData['bio'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            trailing: (userData['sport'] != null)
                                ? Text(userData['sport'])
                                : const Text(""),
                            onTap: () => _handleUserTap(userData),
                          );
                        },
                        childCount: _users.length,
                      ),
                    ),
                  // Grille de vidéos
                  if (_posts.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(2),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        itemBuilder: (context, index) {
                          final postData =
                              _posts[index].data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => PostDetailScreen(
                                  postId: _posts[index].id,
                                ),
                              ));
                            },
                            child: Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 0.8,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image(
                                      image: NetworkImage(
                                          postData['thumbnail'] ?? ''),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.video_library,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.favorite,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (postData['likes'] as List?)
                                                ?.length
                                                .toString() ??
                                            '0',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: _posts.length,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
