// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:nt/models/post_model.dart';
// import 'package:nt/screens/posts/create_post_screen.dart';
// import 'package:nt/widgets/post_card.dart';

// class FeedScreen extends StatelessWidget {
//   const FeedScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sbrain'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: () {
//               Navigator.of(context).push(MaterialPageRoute(
//                 builder: (context) => const CreatePostScreen(),
//               ));
//             },
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('posts').snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return Container();
//           }

//           final posts = snapshot.data!.docs.map((doc) {
//             return Post.fromJson(doc.data() as Map<String, dynamic>);
//           }).toList();

//           return ListView.builder(
//             itemCount: posts.length,
//             itemBuilder: (context, index) {
//               return PostCard(
//                 post: posts[index],
//                 postId: posts[index].id,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nt/models/post_model.dart';
import 'package:nt/screens/posts/create_post_screen.dart';
import 'package:nt/widgets/post_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  Future<void> _refreshPosts() async {
    // Force refresh by fetching the latest data from Firestore
    await FirebaseFirestore.instance.collection('posts').get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sbrain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CreatePostScreen(),
              ));
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs.map((doc) {
            return Post.fromJson(doc.data() as Map<String, dynamic>);
          }).toList();

          return RefreshIndicator(
            onRefresh: _refreshPosts,
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostCard(
                  post: posts[index],
                  postId: posts[index].id,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
