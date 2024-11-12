import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nt/models/user_model.dart';

final userProvider = StateNotifierProvider<UserState, UserModel?>((ref) {
  return UserState();
});

class UserState extends StateNotifier<UserModel?> {
  UserState() : super(null) {
    _listenAuthChanges();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Future<void> _fetchUser(String userId) async {
  //   final ref = FirebaseFirestore.instance
  //       .collection("users")
  //       .doc(userId)
  //       .withConverter(
  //         fromFirestore: (snapshots, _) =>
  //             UserModel.fromJson(snapshots.data()!),
  //         toFirestore: (UserModel user, _) => user.toJson(),
  //       );
  //   final docUser = await ref.get();
  //   if (docUser.exists && mounted) {
  //     state = docUser.data();
  //   }
  //   ref.snapshots().listen((snapshot) {
  //     if (snapshot.exists && mounted) {
  //       state = snapshot.data();
  //     }
  //   });
  // }
  Future<void> _fetchUser(String userId) async {
    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .withConverter(
          fromFirestore: (snapshots, _) {
            final data = snapshots.data()!;
            print("Fetched user data: $data");
            return UserModel.fromJson(data..['id'] = snapshots.id);
          },
          toFirestore: (UserModel user, _) => user.toJson(),
        );
    final docUser = await ref.get();
    if (docUser.exists && mounted) {
      print("User document exists");
      state = docUser.data();
    } else {
      print("User document does not exist");
    }
    ref.snapshots().listen((snapshot) {
      if (snapshot.exists && mounted) {
        print("User data updated: ${snapshot.data()}");
        state = snapshot.data();
      }
    });
  }

  // Future<void> _fetchUser(String userId) async {
  //   final ref = FirebaseFirestore.instance
  //       .collection("users")
  //       .doc(userId)
  //       .withConverter(
  //         fromFirestore: (snapshots, _) {
  //           print("Fetched user data: ${snapshots.data()}");
  //           return UserModel.fromJson(snapshots.data()!);
  //         },
  //         toFirestore: (UserModel user, _) => user.toJson(),
  //       );
  //   final docUser = await ref.get();
  //   if (docUser.exists && mounted) {
  //     print("User document exists");
  //     state = docUser.data();
  //   } else {
  //     print("User document does not exist");
  //   }
  //   ref.snapshots().listen((snapshot) {
  //     if (snapshot.exists && mounted) {
  //       print("User data updated: ${snapshot.data()}");
  //       state = snapshot.data();
  //     }
  //   });
  // }

  // void _listenAuthChanges() {
  //   _auth.authStateChanges().listen((User? user) {
  //     if (user != null) {
  //       _fetchUser(user.uid);
  //     } else {
  //       state = null;
  //     }
  //   });
  // }
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
