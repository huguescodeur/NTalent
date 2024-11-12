// user_infos_async.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nt/models/user_model.dart';

final userProvider = StateNotifierProvider<UserState, UserModel?>((ref) {
  return UserState();
});

// Provider pour obtenir les informations d'un utilisateur spécifique par son ID
final userInfosProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  if (userId.isEmpty) return null;

  try {
    final docSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!docSnapshot.exists) return null;

    final data = docSnapshot.data()!;
    return UserModel.fromJson({...data, 'id': docSnapshot.id});
  } catch (e) {
    print('Error fetching user info: $e');
    return null;
  }
});

class UserState extends StateNotifier<UserModel?> {
  UserState() : super(null) {
    _listenAuthChanges();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _fetchUser(String userId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      if (!docSnapshot.exists || !mounted) return;

      final data = docSnapshot.data()!;
      state = UserModel.fromJson({...data, 'id': docSnapshot.id});

      // Listen to real-time updates
      FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final data = snapshot.data()!;
          state = UserModel.fromJson({...data, 'id': snapshot.id});
        }
      });
    } catch (e) {
      print('Error fetching user: $e');
    }
  }

  void _listenAuthChanges() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        print("User authenticated: ${user.uid}");
        _fetchUser(user.uid);
      } else {
        print("User not authenticated");
        state = null;
      }
    });
  }

  Future<void> refreshUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _fetchUser(user.uid);
    }
  }
}
