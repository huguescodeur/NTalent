// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nt/models/user_model.dart';
// import 'package:nt/screens/home_screen.dart';
// import 'package:nt/services/providers/auth_provider.dart';

// class SignUpScreen extends ConsumerStatefulWidget {
//   // Changer en ConsumerStatefulWidget
//   const SignUpScreen({super.key});

//   @override
//   ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
// }

// class _SignUpScreenState extends ConsumerState<SignUpScreen> {
//   // Changer en ConsumerState
//   final _formKey = GlobalKey<FormState>();
//   String _selectedRole = UserRole.athlete;
//   String? _selectedSport;
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Sign Up')),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             TextFormField(
//               controller: _nameController,
//               decoration: const InputDecoration(labelText: 'Full Name'),
//               validator: (value) {
//                 if (value?.isEmpty ?? true) {
//                   return 'Please enter your name';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
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
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: _selectedRole,
//               decoration: const InputDecoration(labelText: 'I am a'),
//               items: [
//                 DropdownMenuItem(
//                   value: UserRole.athlete,
//                   child: const Text('Athlete'),
//                 ),
//                 DropdownMenuItem(
//                   value: UserRole.recruiter,
//                   child: const Text('Recruiter'),
//                 ),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   _selectedRole = value!;
//                 });
//               },
//             ),
//             if (_selectedRole == UserRole.athlete) ...[
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: _selectedSport,
//                 decoration: const InputDecoration(labelText: 'Sport'),
//                 items: [
//                   'Basketball',
//                   'Football',
//                   'Track & Field',
//                   'Baseball',
//                   'Soccer'
//                 ].map((sport) {
//                   return DropdownMenuItem(
//                     value: sport,
//                     child: Text(sport),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedSport = value;
//                   });
//                 },
//               ),
//             ],
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _handleSignUp,
//               child: const Text('Sign Up'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _handleSignUp() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       try {
//         // Utilisez ref pour lire le authProvider
//         final auth = ref.read(authProvider.notifier);
//         await auth.signUp(
//           email: _emailController.text,
//           password: _passwordController.text,
//           name: _nameController.text,
//           role: _selectedRole,
//           sport: _selectedSport,
//         );

//         // Navigate to home on success
//         if (mounted) {
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (_) => const HomeScreen()),
//           );
//         }
//       } catch (e) {
//         // Show error message
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
import 'package:nt/models/user_model.dart';
import 'package:nt/screens/home_screen.dart';
import 'package:nt/services/providers/auth_provider.dart';
import 'package:nt/services/auth/auth_theme.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = UserRole.athlete;
  String? _selectedSport;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AuthTheme.backgroundColor,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   iconTheme: IconThemeData(color: AuthTheme.textColor),
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            // padding: const EdgeInsets.all(24.0),
            padding: const EdgeInsets.only(
                left: 24.0, top: 40, right: 24.0, bottom: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    Icons.sports_handball,
                    size: 80,
                    color: AuthTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AuthTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AuthTheme.textColor.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _nameController,
                    decoration: AuthTheme.inputDecoration('Full Name')
                        .copyWith(prefixIcon: const Icon(Icons.person_outline)),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                      if (value!.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: AuthTheme.inputDecoration('I am a').copyWith(
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: UserRole.athlete,
                        child: const Text('Athlete'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.recruiter,
                        child: const Text('Recruiter'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                        if (value != UserRole.athlete) {
                          _selectedSport = null;
                        }
                      });
                    },
                  ),
                  if (_selectedRole == UserRole.athlete) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSport,
                      decoration: AuthTheme.inputDecoration('Sport').copyWith(
                        prefixIcon: const Icon(Icons.sports),
                      ),
                      items: [
                        'Basketball',
                        'Football',
                        'Track & Field',
                        'Baseball',
                        'Soccer'
                      ].map((sport) {
                        return DropdownMenuItem(
                          value: sport,
                          child: Text(sport),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSport = value;
                        });
                      },
                      validator: (value) {
                        if (_selectedRole == UserRole.athlete &&
                            value == null) {
                          return 'Please select your sport';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: AuthTheme.primaryButtonStyle,
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          )
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: AuthTheme.textColor.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Login',
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

  // Future<void> _handleSignUp() async {
  //   if (_formKey.currentState?.validate() ?? false) {
  //     setState(() {
  //       _isLoading = true;
  //     });

  //     try {
  //       final auth = ref.read(authProvider.notifier);
  //       // await auth.signUp(
  //       //   email: _emailController.text,
  //       //   password: _passwordController.text,
  //       //   name: _nameController.text,
  //       //   role: _selectedRole,
  //       //   sport: _selectedSport,
  //       // );

  //       if (mounted) {
  //         Navigator.of(context).pushReplacement(
  //           MaterialPageRoute(builder: (_) => const HomeScreen()),
  //         );
  //       }
  //     } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(e.toString()),
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final emailDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.toLowerCase())
          .get();

      if (emailDoc.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cet email existe déjà"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final userId = userCredential.user!.uid;

      final userModel = UserModel(
        id: userId,
        name: _nameController.text,
        email: _emailController.text,
        role: _selectedRole,
        sport: _selectedSport,
        position: null,
        location: null,
        profileImage: null,
        bio: '',
        skills: [],
        stats: {},
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(userModel.toJson())
          .then((value) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inscription réussie"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ));
      });

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Inscription réussie"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = "Une erreur est survenue";

      if (e.code == 'weak-password') {
        message = 'Le mot de passe est trop faible';
      } else if (e.code == 'email-already-in-use') {
        message = 'Cet email est déjà utilisé';
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
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
