import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'package:logger/logger.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final logger = Logger();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  SupabaseClient get _supabase => SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      logger.e('Error signing up: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      logger.e('Error signing in: $e');
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
      logger.e('Error signing in with Google: $e');
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
      logger.e('Error signing in with Apple: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      logger.e('Error resetting password: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      logger.e('Error signing out: $e');
      rethrow;
    }
  }
}
