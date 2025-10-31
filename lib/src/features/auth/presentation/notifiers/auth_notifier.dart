import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/auth/data/auth_repository.dart';
import 'package:game_sentry/src/features/parents/data/parents_repository.dart';
import 'package:game_sentry/src/core/providers.dart' as core_providers;
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthState {
  final AuthStatus authStatus;
  final appwrite_models.User? user;
  final int kidCount;

  const AuthState(this.authStatus, {this.user, this.kidCount = 0});

  AuthState copyWith({
    AuthStatus? authStatus,
    appwrite_models.User? user,
    int? kidCount,
  }) {
    return AuthState(
      authStatus ?? this.authStatus,
      user: user ?? this.user,
      kidCount: kidCount ?? this.kidCount,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.onDispose(() {
      // Cleanup if needed
    });
    
    // Initialize auth status
    Future.microtask(() {
      checkAuthStatus();
    });
    
    return const AuthState(AuthStatus.uninitialized);
  }

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  ParentsRepository get _parentsRepository => ref.read(core_providers.parentsRepositoryProvider);
  Client get _client => ref.read(core_providers.appwriteClientProvider);
  late final Databases _databases = Databases(_client);

  Future<void> checkAuthStatus() async {
    // Try to get the current user with retries
    appwrite_models.User? user;
    int attempts = 0;
    const maxAttempts = 5;
    
    while (user == null && attempts < maxAttempts) {
      attempts++;
      await Future.delayed(Duration(milliseconds: 500 * attempts)); // Exponential backoff
      user = await _authRepository.getCurrentUser();
    }
    
    if (user != null) {
      try {
        await _parentsRepository.getParent(user.$id);
        state = state.copyWith(
          authStatus: AuthStatus.authenticated,
          user: user,
          kidCount: 0, // Will be updated by refreshKidCount
        );
        // Get accurate kid count from database
        await refreshKidCount();
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          // Parent document not found, create it
          // Check if username exists in user prefs, otherwise use user.name
          final usernameFromPrefs = user.prefs.data['username'] as String?;
          final username = usernameFromPrefs != null && usernameFromPrefs.isNotEmpty 
              ? usernameFromPrefs 
              : user.name;
              
          await _parentsRepository.createParent(
            id: user.$id,
            name: user.name,
            username: username,
            email: user.email,
            pin: 0, // Default PIN is 0
          );
          state = state.copyWith(
            authStatus: AuthStatus.authenticated,
            user: user,
            kidCount: 0, // Will be updated by refreshKidCount
          );
          // Get accurate kid count from database
          await refreshKidCount();
        } else {
          rethrow;
        }
      }
    } else {
      state = state.copyWith(authStatus: AuthStatus.unauthenticated);
    }
  }

  Future<void> login() async {
    try {
      await _authRepository.signInWithGoogle();
      // The OAuth flow redirects to the app, so we'll check the auth status after a short delay
      await Future.delayed(const Duration(seconds: 2)); // Add delay for session to establish
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        try {
          await _parentsRepository.getParent(user.$id);
          state = state.copyWith(
            authStatus: AuthStatus.authenticated,
            user: user,
            kidCount: 0, // Will be updated by refreshKidCount
          );
          // Get accurate kid count from database
          await refreshKidCount();
        } on AppwriteException catch (e) {
          if (e.code == 404) {
            // Parent document not found, create it
            // Check if username exists in user prefs, otherwise use user.name
            final usernameFromPrefs = user.prefs.data['username'] as String?;
            final username = usernameFromPrefs != null && usernameFromPrefs.isNotEmpty 
                ? usernameFromPrefs 
                : user.name;
                
            await _parentsRepository.createParent(
              id: user.$id,
              name: user.name,
              username: username,
              email: user.email,
              pin: 0, // Default PIN is 0
            );
            state = state.copyWith(
              authStatus: AuthStatus.authenticated,
              user: user,
              kidCount: 0, // Will be updated by refreshKidCount
            );
            // Get accurate kid count from database
            await refreshKidCount();
          } else {
            rethrow;
          }
        }
      } else {
        // If user is still null after delay, something went wrong.
        state = state.copyWith(authStatus: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      state = state.copyWith(authStatus: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.signOut();
      state = state.copyWith(authStatus: AuthStatus.unauthenticated, user: null);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateUserWithPin(appwrite_models.User user, int pin) async {
    try {
      // Update or create parent document with the PIN
      await _parentsRepository.updateParentPin(user.$id, pin);
      
      // Update auth state to show the user as authenticated
      state = state.copyWith(
        authStatus: AuthStatus.authenticated,
        user: user,
        kidCount: 0, // Initialize to 0, will be updated by refreshKidCount if needed
      );
    } catch (e) {
      // If parent doesn't exist, create it with the PIN
      try {
        await _parentsRepository.createParent(
          id: user.$id,
          name: user.name,
          username: user.name,
          email: user.email,
          pin: pin,
        );
        
        state = state.copyWith(
          authStatus: AuthStatus.authenticated,
          user: user,
          kidCount: 0, // Initialize to 0, will be updated by refreshKidCount if needed
        );
      } catch (createError) {
        // If everything fails, just update the auth state without updating the parent
        state = state.copyWith(
          authStatus: AuthStatus.authenticated,
          user: user,
          kidCount: 0,
        );
      }
    }
  }
  
  void updateUser(appwrite_models.User user) {
    // For desktop local accounts, we don't have Appwrite sessions,
    // but we still update the auth state to show the user as authenticated
    state = state.copyWith(
      authStatus: AuthStatus.authenticated,
      user: user,
      kidCount: 0, // Initialize to 0, will be updated by refreshKidCount if needed
    );
    
    // Note: For desktop local accounts, we don't create parent documents in Appwrite,
    // since these are just mock users for testing functionality
  }
  
  // Method to refresh kid count from database
  Future<void> refreshKidCount() async {
    if (state.user != null) {
      try {
        // ignore: deprecated_member_use
        final response = await _databases.listDocuments(
          databaseId: '68ac6bad003066ce8ae3',
          collectionId: '68ac6f6200015002985b',
          queries: [
            Query.equal('parent_id', state.user!.$id),
          ],
        );
        state = state.copyWith(kidCount: response.documents.length);
      } catch (e) {
        // If we can't get the count, keep the existing one
        // Silently ignore this error as it's not critical
      }
    }
  }
  
  // Method to increment kid count
  void incrementKidCount() {
    state = state.copyWith(kidCount: state.kidCount + 1);
  }
  
  // Method to decrement kid count
  void decrementKidCount() {
    final newCount = state.kidCount - 1;
    state = state.copyWith(kidCount: newCount < 0 ? 0 : newCount);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
