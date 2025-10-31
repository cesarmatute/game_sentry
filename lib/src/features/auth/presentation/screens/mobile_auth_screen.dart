import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/core/providers.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/features/parents/presentation/screens/parent_dashboard_screen.dart';
import 'package:game_sentry/src/features/auth/data/pin_repository.dart';

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
      appBar: authState.authStatus == AuthStatus.authenticated ? AppBar(
        title: const Text('Mobile App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ) : null,
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
              
              if (authState.authStatus == AuthStatus.unauthenticated || authState.authStatus == AuthStatus.uninitialized)
                Column(
                  children: [
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
                )
              else if (authState.authStatus == AuthStatus.authenticated)
                Column(
                  children: [
                    const Text(
                      'Generate PIN for Desktop Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _generatePin(context);
                      },
                      icon: const Icon(Icons.key),
                      label: const Text('Generate 6-Digit PIN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Use this PIN to log in to the desktop version of the app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _generatePin(BuildContext context) async {
    final pinRepo = PinRepository();
    final user = ref.read(authNotifierProvider).user;
    final parentsRepository = ref.read(parentsRepositoryProvider);
    
    if (user != null) {
      final pin = int.parse(pinRepo.generateAndStorePin(user.$id));
      
      try {
        // Update the parent's PIN in the database
        await parentsRepository.updateParentPin(user.$id, pin);
        
        // Show the generated PIN to the user
        _showPinDialog(context, pin.toString());
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating PIN: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Handle case where user is not authenticated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showPinDialog(BuildContext context, String pin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Your Desktop PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter this PIN on your desktop version of Game Sentry:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pin,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This PIN will expire in 5 minutes and can only be used once.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}