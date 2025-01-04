import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'dart:async' show TimeoutException;

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  SupabaseClient get _supabase => SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      // Validate input before making the request
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email and password cannot be empty');
      }

      // Validate email format
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email.trim())) {
        throw AuthException('Invalid email format');
      }

      // Validate password strength
      if (password.trim().length < 6) {
        throw AuthException('Password must be at least 6 characters long');
      }

      try {
        final result = await _supabase.auth.signUp(
          email: email.trim(),
          password: password.trim(),
        ).timeout(
          const Duration(seconds: 15),  // Increased timeout
          onTimeout: () => throw TimeoutException('Network request timed out'),
        );

        // Additional validation of the response
        if (result.session == null && result.user == null) {
          throw AuthException('Invalid signup response');
        }

        return result;
      } on AuthException catch (authError) {
        // Log authentication error with more context
        AppLogger.e('Sign-Up Error: ${authError.message}', error: {
          'statusCode': authError.statusCode,
          'email': email.replaceRange(2, email.indexOf('@'), '***'),
        });
        rethrow;
      } on TimeoutException {
        AppLogger.e('Sign-Up Network Timeout', error: {
          'email': email.replaceRange(2, email.indexOf('@'), '***'),
          'action': 'signUp',
        });
        throw AuthException('Network connection is slow or unavailable. Please check your internet connection.');
      } on FormatException catch (formatError) {
        // Detailed JSON parsing error logging
        AppLogger.e('Sign-Up JSON Parsing Error', error: {
          'message': formatError.message,
          'source': formatError.source,
          'email': email.replaceRange(2, email.indexOf('@'), '***'),
        });
        throw AuthException('Server response is invalid. Please check your network connection.');
      } catch (e) {
        // Catch-all for unexpected errors
        AppLogger.e('Unexpected sign-up error', error: {
          'error': e.toString(),
          'type': e.runtimeType.toString(),
          'email': email.replaceRange(2, email.indexOf('@'), '***'),
        });
        throw AuthException('An unexpected signup error occurred. Please try again.');
      }
    } catch (e) {
      AppLogger.e('Sign-up process error', error: {
        'error': e.toString(),
        'type': e.runtimeType.toString(),
      });
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      // Validate input before making the request
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email and password cannot be empty');
      }

      try {
        // Add network timeout and more robust error handling
        final result = await _supabase.auth.signInWithPassword(
          email: email.trim(),
          password: password.trim(),
        ).timeout(
          const Duration(seconds: 15),  // Increased timeout
          onTimeout: () => throw TimeoutException('Network request timed out'),
        );

        // Additional validation of the response
        if (result.session == null && result.user == null) {
          throw AuthException('Invalid authentication response');
        }

        return result;
      } on TimeoutException {
        AppLogger.e('Sign-In Network Timeout', error: {
          'email': email.replaceRange(2, email.indexOf('@'), '***'),
          'action': 'signInWithPassword',
        });
        throw AuthException('Network connection is slow or unavailable. Please check your internet connection.');
      } on AuthException catch (authError) {
        // More comprehensive authentication error logging
        AppLogger.e('Sign-In Authentication Error', error: {
          'message': authError.message,
          'statusCode': authError.statusCode,
          'email': email.replaceRange(2, email.indexOf('@'), '***'),
        });
        rethrow;
      } on FormatException catch (formatError) {
        // Detailed JSON parsing error logging with context
        AppLogger.e('Sign-In JSON Parsing Error', error: {
          'message': formatError.message,
          'source': formatError.source,
          'email': email.replaceRange(2, email.indexOf('@'), '***'),
          'networkDiagnostics': {
            'canReachSupabase': await _checkSupabaseConnection(),
            'jsonParsingDetails': _analyzeJsonParsingError(formatError),
          },
        });
        throw AuthException('Server response is invalid. Please check your network connection.');
      } catch (e) {
        // Comprehensive catch-all for unexpected errors
        AppLogger.e('Unexpected Sign-In Error', error: {
          'error': e.toString(),
          'type': e.runtimeType.toString(),
          'email': email.replaceRange(2, email.indexOf('@'), '***'),
        });
        throw AuthException('An unexpected authentication error occurred. Please try again.');
      }
    } catch (e) {
      AppLogger.e('Sign-in Process Error', error: {
        'error': e.toString(),
        'type': e.runtimeType.toString(),
      });
      rethrow;
    }
  }

  // Network connectivity diagnostic method
  Future<bool> _checkSupabaseConnection() async {
    try {
      // Attempt a simple health check
      final response = await _supabase.from('profiles').select().limit(1);
      return response.isNotEmpty;
    } catch (e) {
      AppLogger.e('Supabase Connection Check Failed', error: {
        'error': e.toString(),
      });
      return false;
    }
  }

  // Analyze JSON parsing error details
  Map<String, dynamic> _analyzeJsonParsingError(FormatException formatError) {
    return {
      'errorMessage': formatError.message,
      'source': formatError.source?.toString(),
      'stackTraceString': formatError.toString(),
      'possibleCauses': [
        'Incomplete network response',
        'Firewall or proxy interference',
        'Supabase server-side issue',
        'Unexpected response format',
      ],
      'recommendedActions': [
        'Check internet connection',
        'Verify Supabase configuration',
        'Retry authentication',
        'Contact support if issue persists',
      ],
    };
  }

  Future<bool> signInWithGoogle() async {
    try {
      return await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.chromaniac://login-callback',
      );
    } catch (e) {
      AppLogger.e('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      return await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.chromaniac://login-callback',
      );
    } catch (e) {
      AppLogger.e('Apple Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      AppLogger.e('Password Reset Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      AppLogger.e('Sign-Out Error: $e');
      rethrow;
    }
  }
}
