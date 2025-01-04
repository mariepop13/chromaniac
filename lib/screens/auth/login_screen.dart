import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../services/auth_service.dart';
import '../../utils/logger/app_logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  // Debounce timer for input validation
  Timer? _debounceTimer;
  late AnimationController _animationController;
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    // Add listeners to focus nodes
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // Optional: Add any specific focus change logic
    setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();

    // Remove listeners before disposing
    _emailFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  void _onEmailChanged(String value) {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Use a more robust debounce mechanism
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Ensure widget is still mounted and input hasn't changed
      if (!mounted) return;

      // Validate email with current value
      final validationResult = _validateEmail(value);

      // Use a null-safe setState to prevent multiple rebuilds
      if (mounted) {
        setState(() {
          _errorMessage = validationResult;
        });
      }
    });
  }

  void _onPasswordChanged(String value) {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Use a more robust debounce mechanism
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Ensure widget is still mounted and input hasn't changed
      if (!mounted) return;

      // Validate password with current value
      final validationResult = _validatePassword(value);

      // Use a null-safe setState to prevent multiple rebuilds
      if (mounted) {
        setState(() {
          _errorMessage = validationResult;
        });
      }
    });
  }

  // Add explicit validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email cannot be empty';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(value) ? null : 'Invalid email format';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password cannot be empty';
    return value.length >= 6 ? null : 'Password must be at least 6 characters';
  }

  Future<void> _performAuthAction(
    Future<void> Function(AuthService authService) authAction,
    String successMessage,
  ) async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      AppLogger.w('Form validation failed');
      return;
    }

    // Prevent multiple simultaneous submissions
    if (_isLoading) {
      AppLogger.w('Authentication in progress');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await Future.any([
        _wrapWithPerformanceLogging(authAction(authService)),
        Future.delayed(const Duration(seconds: 10),
            () => throw TimeoutException('Operation timed out'))
      ]);

      if (!mounted) return;

      _emailController.clear();
      _passwordController.clear();

      Navigator.of(context).pop(true);
      _showSnackBar(successMessage);
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Operation timed out. Please try again.';
      });
      AppLogger.e('Authentication timed out');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message.isNotEmpty
            ? e.message
            : 'Authentication failed. Please check your credentials.';
      });
      AppLogger.e('Auth failed: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      AppLogger.e('Unexpected auth error: $e');
    } finally {
      stopwatch.stop();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Wrapper to add performance logging
  Future<T> _wrapWithPerformanceLogging<T>(Future<T> action) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await Future.microtask(() => action);
      stopwatch.stop();
      return result;
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }

  Future<void> _login() => _performAuthAction(
        (authService) => authService.signInWithEmail(
            _emailController.text.trim(), _passwordController.text.trim()),
        'Successfully logged in',
      );

  Future<void> _signup() => _performAuthAction(
        (authService) => authService.signUpWithEmail(
            _emailController.text.trim(), _passwordController.text.trim()),
        'Account created successfully',
      );

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter your email first');
      return;
    }

    await _performAuthAction(
      (authService) => authService.resetPassword(email),
      'Password reset email sent',
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Listener(
        onPointerDown: (event) {
          // Additional handling for pointer events on web
          if (kIsWeb) {
            try {
              // Attempt to handle potential input element conflicts
              FocusScope.of(context).requestFocus(FocusNode());
            } catch (e) {
              developer.log('Pointer event handling error',
                  name: 'LoginScreen.pointerEventHandling',
                  error: {
                    'error': e.toString(),
                    'timestamp': DateTime.now().toIso8601String()
                  });
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Authentication'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                developer.log('Back button pressed',
                    name: 'LoginScreen.backNavigation',
                    error: {'timestamp': DateTime.now().toIso8601String()});
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: ListView(
                physics: const ClampingScrollPhysics(),
                children: [
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: _onEmailChanged,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validateEmail,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorMaxLines: 2,
                      errorStyle: const TextStyle(color: Colors.redAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    onChanged: _onPasswordChanged,
                    obscureText: _obscurePassword,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorMaxLines: 2,
                      errorStyle: const TextStyle(color: Colors.redAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Login'),
                                ),
                                ElevatedButton(
                                  onPressed: _signup,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Sign Up'),
                                ),
                              ],
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
}
