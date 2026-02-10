import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Update user's name in Supabase
  Future<void> updateUserName(String newName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'name': newName}),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update user's address in Supabase
  Future<void> updateUserAddress(String newAddress) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'address': newAddress}),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Upload profile picture
  Future<String> uploadProfilePicture(Uint8List imageBytes, String fileName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      final String fileExt = fileName.split('.').last;
      final String newFileName = '${user.id}.$fileExt';
      final String filePath = 'avatars/$newFileName';

      // Upload to Supabase Storage
      await _supabase.storage.from('ProductScan').uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final String publicUrl = _supabase.storage.from('ProductScan').getPublicUrl(filePath);

      // Update user metadata with avatar URL
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );

      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Delete profile picture
  Future<void> deleteProfilePicture() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      final avatarUrl = user.userMetadata?['avatar_url'] as String?;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        // Extract file path from URL
        final uri = Uri.parse(avatarUrl);
        final pathSegments = uri.pathSegments;
        final filePath = pathSegments.sublist(pathSegments.indexOf('ProductScan') + 1).join('/');

        // Delete from storage
        await _supabase.storage.from('ProductScan').remove([filePath]);

        // Update user metadata to remove avatar URL
        await _supabase.auth.updateUser(
          UserAttributes(data: {'avatar_url': null}),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get profile picture URL
  String? getProfilePictureUrl() {
    final user = _supabase.auth.currentUser;
    return user?.userMetadata?['avatar_url'] as String?;
  }
}