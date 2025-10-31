import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/features/parents/presentation/screens/parent_dashboard_screen.dart';

class MobileAuthScreen extends ConsumerStatefulWidget {
  const MobileAuthScreen({super.key});

  @override
  ConsumerState<MobileAuthScreen> createState() => _MobileAuthScreenState();
}

class _MobileAuthScreenState extends ConsumerState<MobileAuthScreen> {
  @override
  void initState() {
    super.initState();
    // Check if user is already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (authState.authStatus == AuthStatus.authenticated) {
        // If already authenticated, navigate directly to parent dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.authStatus == AuthStatus.authenticated && next.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
        );
      }
    });

    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.family_restroom,
                size: 100,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 32),
              const Text(
                'Game Sentry',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A healthy gaming time manager for kids',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              authState.authStatus == AuthStatus.uninitialized
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).login();
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              if (authState.authStatus == AuthStatus.unauthenticated && authState.user == null)
                const Text(
                  'Please sign in to manage your kids\' gaming time',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}