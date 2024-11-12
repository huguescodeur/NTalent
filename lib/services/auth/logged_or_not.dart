import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nt/screens/auth/login_screen.dart';
import 'package:nt/screens/home_screen.dart';

class LoggedOrNot extends StatelessWidget {
  const LoggedOrNot({super.key});

  static const String idScreen = "loggedOrNot";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
// * User is logged in
          if (snapshot.hasData) {
            return const HomeScreen();
          }

// * User is NOT logged in
          else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
