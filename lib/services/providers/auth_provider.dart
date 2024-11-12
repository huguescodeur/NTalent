// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:nt/models/user_model.dart';

// final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
//   return AuthNotifier();
// });

// class AuthNotifier extends StateNotifier<User?> {
//   AuthNotifier() : super(null) {
//     _init();
//   }

//   Future<void> _init() async {
//     firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) {
//       if (user != null) {
//         // Fetch user data from Firestore and update state
//       } else {
//         state = null;
//       }
//     });
//   }

//   Future<void> signUp({
//     required String email,
//     required String password,
//     required String name,
//     required String role,
//     String? sport,
//   }) async {
//     try {
//       final credential = await firebase_auth.FirebaseAuth.instance
//           .createUserWithEmailAndPassword(email: email, password: password);

//       // Create user profile in Firestore
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> signIn({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       await firebase_auth.FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email, password: password);
//     } catch (e) {
//       rethrow;
//     }
//   }

// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:nt/models/user_model.dart';

// // final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
// //   return AuthNotifier();
// // });

// final authProvider =
//     StateNotifierProvider<AuthNotifier, Map<String, dynamic>?>((ref) {
//   return AuthNotifier();
// });

// class AuthNotifier extends StateNotifier<User?> {
//   AuthNotifier() : super(null) {
//     _init();
//   }

//   // Future<void> _init() async {
//   //   firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) {
//   //     if (user != null) {
//   //       // Fetch user data from Firestore and update state
//   //     } else {
//   //       state = null;
//   //     }
//   //   });
//   // }

//   Future<void> _init() async {
//     firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) async {
//       if (user != null) {
//         // Récupérer les données de l'utilisateur à partir de Firestore
//         final userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();
//         if (userDoc.exists) {
//           state = userDoc.data()
//               as User?; // Stocker les données sous forme de `Map<String, dynamic>`
//         }
//       } else {
//         state = null; // Réinitialiser l'état si l'utilisateur se déconnecte
//       }
//     });
//   }

//   // Future<void> signUp({
//   //   required String email,
//   //   required String password,
//   //   required String name,
//   //   required String role,
//   //   String? sport,
//   // }) async {
//   //   try {
//   //     final credential = await firebase_auth.FirebaseAuth.instance
//   //         .createUserWithEmailAndPassword(email: email, password: password);

//   //     // Create user profile in Firestore
//   //   } catch (e) {
//   //     rethrow;
//   //   }
//   // }

//   // Future<void> signIn({
//   //   required String email,
//   //   required String password,
//   // }) async {
//   //   try {
//   //     await firebase_auth.FirebaseAuth.instance
//   //         .signInWithEmailAndPassword(email: email, password: password);
//   //   } catch (e) {
//   //     rethrow;
//   //   }
//   // }

//   Future<void> sendPasswordResetEmail(String email) async {
//     try {
//       await firebase_auth.FirebaseAuth.instance
//           .sendPasswordResetEmail(email: email);
//     } catch (e) {
//       throw Exception('Failed to send password reset email: $e');
//     }
//   }

//   Future<bool> checkEmailExists(String email) async {
//     try {
//       final methods = await firebase_auth.FirebaseAuth.instance
//           .fetchSignInMethodsForEmail(email);
//       return methods.isNotEmpty;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> resetPassword(String email) async {
//     try {
//       final emailExists = await checkEmailExists(email);
//       if (!emailExists) {
//         throw 'No account found with this email';
//       }
//       await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
//         email: email,
//       );
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // Future<void> resetPassword(String email) async {
//   //   try {
//   //     await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
//   //       email: email,
//   //     );
//   //   } catch (e) {
//   //     rethrow;
//   //   }
//   // }
// }
