// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nt/screens/auth/signup_screen.dart';
// import 'package:nt/screens/home_screen.dart';
// import 'package:nt/services/providers/auth_provider.dart';

// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends ConsumerState<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Login')),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             TextFormField(
//               controller: _emailController,
//               decoration: const InputDecoration(labelText: 'Email'),
//               validator: (value) {
//                 if (value?.isEmpty ?? true) {
//                   return 'Please enter your email';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             TextFormField(
//               controller: _passwordController,
//               decoration: const InputDecoration(labelText: 'Password'),
//               obscureText: true,
//               validator: (value) {
//                 if (value?.isEmpty ?? true) {
//                   return 'Please enter your password';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _handleLogin,
//               child: const Text('Login'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(builder: (_) => const SignUpScreen()),
//                 );
//               },
//               child: const Text('Don\'t have an account? Sign Up'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _handleLogin() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       try {
//         final auth = ref.read(authProvider.notifier);
//         await auth.signIn(
//           email: _emailController.text,
//           password: _passwordController.text,
//         );

//         if (mounted) {
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (_) => const HomeScreen()),
//           );
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       }
//     }
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nt/screens/auth/forgot_password_screen.dart';
import 'package:nt/screens/auth/signup_screen.dart';
import 'package:nt/screens/home_screen.dart';
import 'package:nt/services/auth/auth_theme.dart';
import 'package:nt/services/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AuthTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            // padding: const EdgeInsets.all(24.0),
            padding: const EdgeInsets.only(
                left: 24.0, top: 110, right: 24.0, bottom: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // App Logo
                  const Icon(
                    Icons.sports_handball,
                    size: 80,
                    color: AuthTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AuthTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AuthTheme.textColor.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: AuthTheme.inputDecoration('Email')
                        .copyWith(prefixIcon: const Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your email';
                      }
                      if (!value!.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: AuthTheme.inputDecoration('Password').copyWith(
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AuthTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login Button
                  // ElevatedButton(
                  //   style: AuthTheme.primaryButtonStyle,
                  //   onPressed: _handleLogin,
                  //   child: const Text(
                  //     'Login',
                  //     style: TextStyle(
                  //       fontSize: 16,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  // ),
                  ElevatedButton(
                    style: AuthTheme.primaryButtonStyle,
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          )
                        : const Text(
                            'Connexion',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          color: AuthTheme.textColor.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Register',
                          style: TextStyle(
                            color: AuthTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> _handleLogin() async {
  //   if (_formKey.currentState?.validate() ?? false) {
  //     setState(() {
  //       _isLoading = true;
  //     });

  //     try {
  //       final auth = ref.read(authProvider.notifier);
  //       // await auth.signIn(
  //       //   email: _emailController.text,
  //       //   password: _passwordController.text,
  //       // );

  //       if (mounted) {
  //         Navigator.of(context).pushReplacement(
  //           MaterialPageRoute(builder: (_) => const HomeScreen()),
  //         );
  //       }
  //     } on FirebaseAuthException catch (e) {
  //       String message = "Une erreur est survenue";
  //       if (e.code == 'invalid-credential') {
  //         message = "Email ou mot de passe incorrect !";
  //       }
  //       //  else if (e.code == 'user-not-found') {
  //       //   message = "Aucun utilisateur trouvé";
  //       // }
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(message),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     } finally {
  //       if (mounted) {
  //         setState(() {
  //           _isLoading = false;
  //         });
  //       }
  //     }
  //   }
  // }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String email = _emailController.text;
      // // Vérifier si l'utilisateur a entré un username plutôt qu'un email
      // if (!email.contains('@')) {
      //   // Chercher l'email correspondant au username
      //   final userDoc = await FirebaseFirestore.instance
      //       .collection('users')
      //       .where('email', isEqualTo: _emailController.text.toLowerCase())
      //       .limit(1)
      //       .get();
      //   if (userDoc.docs.isEmpty) {
      //     throw FirebaseAuthException(
      //       code: 'user-not-found',
      //       message: "Nom d'utilisateur non trouvé",
      //     );
      //   }
      //   email = userDoc.docs.first.get('email');
      // }
      // // Vérifier le type d'utilisateur avant la connexion
      // final userDoc = await FirebaseFirestore.instance
      //     .collection('users')
      //     .where('email', isEqualTo: email)
      //     .limit(1)
      //     .get();
      // if (userDoc.docs.isNotEmpty) {
      //   final userType = userDoc.docs.first.data()['role'];
      //   if (userType != 'client') {
      //     setState(() => _isLoading = false);
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(
      //         content: Text(
      //             'Ce compte n\'est pas autorisé sur l\'application mobile'),
      //         backgroundColor: Colors.red,
      //       ),
      //     );
      //     return;
      //     // throw Exception(
      //     //     'Ce compte n\'est pas autorisé sur l\'application mobile');
      //   }
      // }
      // Connexion avec email/password
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      )
          .then((value) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connexion réussie"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ));
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      print("erreur: $e");
      String message = "Une erreur est survenue";
      if (e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'wrong-password') {
        message = "Email ou mot de passe incorrect !";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      print("erreur erreur: $e");
    }
  }
}
