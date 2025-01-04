import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

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
        );
        return result;
      } on AuthException catch (authError) {
        // Log authentication error
        AppLogger.e('Sign-Up Error: ${authError.message}');
        rethrow;
      } on FormatException catch (formatError) {
        // Specific handling for JSON parsing errors
        AppLogger.e('JSON Parsing Error', error: {
          'message': formatError.message,
        });
        throw AuthException('Sign-up failed: Invalid response');
      }
    } catch (e) {
      AppLogger.e('Unexpected sign-up error: $e');
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
        final result = await _supabase.auth.signInWithPassword(
          email: email.trim(),
          password: password.trim(),
        );
        return result;
      } on AuthException catch (authError) {
        // Log authentication error
        AppLogger.e('Sign-In Error: ${authError.message}');
        rethrow;
      } on FormatException catch (formatError) {
        // Specific handling for JSON parsing errors
        AppLogger.e('JSON Parsing Error', error: {
          'message': formatError.message,
        });
        throw AuthException('Sign-in failed: Invalid response');
      }
    } catch (e) {
      AppLogger.e('Unexpected sign-in error: $e');
      rethrow;
    }
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
