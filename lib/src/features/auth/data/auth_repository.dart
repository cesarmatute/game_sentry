import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:appwrite/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/appwrite_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(client);
});

class AuthRepository {
  AuthRepository(this._client);
  final Client _client;

  Future<void> signInWithGoogle() async {
    try {
      final account = Account(_client);
      await account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: 'http://localhost/',
      );
      // After successful OAuth, get the current session and store its ID
      final session = await account.getSession(sessionId: 'current');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appwrite_session_id', session.$id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Account(_client).deleteSession(sessionId: 'current');
  }

  Future<appwrite_models.User?> getCurrentUser() async {
    try {
      final account = Account(_client);
      final user = await account.get();
      return user;
    } catch (e) {
      // If account.get() fails, try to restore session from shared_preferences
      final prefs = await SharedPreferences.getInstance();
      final storedSessionId = prefs.getString('appwrite_session_id');

      if (storedSessionId != null) {
        try {
          final account = Account(_client); // Declare account here
          // Attempt to get the session using the stored ID
          await account.getSession(sessionId: storedSessionId);
          // If successful, then the session is valid, try to get the user again
          final user = await account.get();
          return user;
        } catch (e) {
          // Session restoration failed, clear stored session ID
          await prefs.remove('appwrite_session_id');
          return null;
        }
      }
      return null;
    }
  }

  Future<void> updateDob(DateTime dob) async {
    try {
      final account = Account(_client);
      
      // Get current user to preserve existing prefs
      final currentUser = await account.get();
      final currentPrefs = currentUser.prefs.data;
      
      // Update only the dob field, preserving existing ones
      final updatedPrefs = Map<String, dynamic>.from(currentPrefs);
      updatedPrefs['dob'] = dob.toIso8601String();
      
      await account.updatePrefs(
        prefs: updatedPrefs,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<appwrite_models.User> updateProfile({
    required String name,
    required String username,
    required DateTime dob,
  }) async {
    try {
      final account = Account(_client);
      await account.updateName(name: name);
      
      // Get current user to preserve existing prefs
      final currentUser = await account.get();
      final currentPrefs = currentUser.prefs.data;
      
      // Update only the specific fields, preserving existing ones
      final updatedPrefs = Map<String, dynamic>.from(currentPrefs);
      updatedPrefs['username'] = username;
      updatedPrefs['profile_completed'] = true;
      updatedPrefs['dob'] = dob.toIso8601String();
      
      return await account.updatePrefs(
        prefs: updatedPrefs,
      );
    } catch (e) {
      rethrow;
    }
  }
}