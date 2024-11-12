import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nt/services/auth/auth_theme.dart';
import 'package:nt/services/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

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
            padding: const EdgeInsets.only(
                left: 24.0, top: 110, right: 24.0, bottom: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    _emailSent ? Icons.check_circle_outline : Icons.lock_reset,
                    size: 80,
                    color: AuthTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _emailSent ? 'Email Sent!' : 'Reset Password',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AuthTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emailSent
                        ? 'Please check your email for instructions to reset your password'
                        : 'Enter your email address and we\'ll send you instructions to reset your password',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AuthTheme.textColor.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (!_emailSent) ...[
                    TextFormField(
                      controller: _emailController,
                      decoration: AuthTheme.inputDecoration('Email').copyWith(
                          prefixIcon: const Icon(Icons.email_outlined)),
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
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: AuthTheme.primaryButtonStyle,
                      onPressed: _isLoading ? null : () {},
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : const Text(
                              'Renitialiser ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ] else ...[
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: AuthTheme.primaryButtonStyle,
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (!_emailSent)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Remember your password? ',
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

  // Future<void> _handleResetPassword() async {
  //   if (_formKey.currentState?.validate() ?? false) {
  //     setState(() {
  //       _isLoading = true;
  //     });

  //     try {
  //       final auth = ref.read(authProvider.notifier);
  //       await auth.resetPassword(_emailController.text);

  //       if (mounted) {
  //         setState(() {
  //           _emailSent = true;
  //           _isLoading = false;
  //         });
  //       }
  //     } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(e.toString()),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //       if (mounted) {
  //         setState(() {
  //           _isLoading = false;
  //         });
  //       }
  //     }
  //   }
  // }
}
