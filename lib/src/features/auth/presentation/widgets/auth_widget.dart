import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/core/providers.dart'; // Import for parentsRepositoryProvider
import 'package:appwrite/models.dart' as appwrite_models;

import 'package:game_sentry/src/features/auth/presentation/screens/login_screen.dart';
import 'package:game_sentry/src/features/home/presentation/screens/home_screen.dart';
import 'package:game_sentry/src/features/profile/presentation/screens/profile_screen.dart';

class AuthWidget extends ConsumerWidget {
  const AuthWidget({super.key, required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (authState.authStatus) {
      case AuthStatus.authenticated:
        // Check if user profile is complete by checking database
        return FutureBuilder<bool>(
          future: _isProfileComplete(ref, authState.user!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (snapshot.hasError) {
              // If there's an error, show profile screen to allow user to complete profile
              return const ProfileScreen();
            }
            
            // If profile is complete, show home screen, otherwise show profile screen
            return snapshot.data! ? const HomeScreen() : const ProfileScreen();
          },
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.uninitialized:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
  }
  
  Future<bool> _isProfileComplete(WidgetRef ref, appwrite_models.User user) async {
    try {
      // First check if profile is marked as completed in user prefs
      final profileCompleted = user.prefs.data['profile_completed'] as bool?;
      if (profileCompleted == true) {
        return true;
      }
      
      // If not explicitly marked as completed, check the database fields
      final parentsRepository = ref.read(parentsRepositoryProvider);
      
      // Try to get parent from database
      final parent = await parentsRepository.getParent(user.$id);
      
      // Check if required fields are present
      final isUsernameValid = parent.username.isNotEmpty;
      final isDobValid = parent.dob != null;
      
      return isUsernameValid && isDobValid;
    } catch (e) {
      // If parent doesn't exist in database or there's an error, profile is not complete
      return false;
    }
  }
}