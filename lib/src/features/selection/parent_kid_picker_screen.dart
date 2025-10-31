import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/features/parents/presentation/screens/parent_dashboard_screen.dart';
import 'package:appwrite/models.dart' as appwrite_models;

class ParentKidPickerScreen extends ConsumerStatefulWidget {
  const ParentKidPickerScreen({super.key});

  @override
  ConsumerState<ParentKidPickerScreen> createState() => _ParentKidPickerScreenState();
}

class _ParentKidPickerScreenState extends ConsumerState<ParentKidPickerScreen> {
  bool _isLocalAccountMode = false;
  String _localParentName = '';
  String _localParentEmail = '';

  @override
  Widget build(BuildContext context) {
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
              
              // For desktop, show a local parent selection or account setup screen
              Card(
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.supervisor_account,
                        size: 60,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Parent Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Show local parent options
                      if (authState.authStatus == AuthStatus.authenticated && authState.user != null) ...[
                        // If authenticated, show current parent info
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: authState.user?.prefs.data['avatar_url'] != null
                              ? NetworkImage(authState.user!.prefs.data['avatar_url'] as String)
                              : null,
                          child: authState.user?.prefs.data['avatar_url'] == null
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          authState.user?.name ?? 'Parent',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kids: ${authState.kidCount}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ParentDashboardScreen(),
                              ),
                            );
                          },
                          child: const Text('Manage Kids'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref.read(authNotifierProvider.notifier).logout();
                          },
                          child: const Text('Switch Account'),
                        ),
                      ] else if (_isLocalAccountMode) ...[
                        // Local account setup form
                        const Text(
                          'Create Local Parent Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Parent Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _localParentName = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Email (optional)',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            setState(() {
                              _localParentEmail = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _localParentName.isNotEmpty 
                              ? () async {
                                  // Create a mock user for local account
                                  final mockUser = appwrite_models.User(
                                    $id: 'desktop_${DateTime.now().millisecondsSinceEpoch}',
                                    name: _localParentName,
                                    email: _localParentEmail.isNotEmpty ? _localParentEmail : 'desktop_user@game_sentry.com',
                                    prefs: appwrite_models.Preferences(data: {}),
                                    registration: DateTime.now().toIso8601String(),
                                    status: true,
                                    passwordUpdate: DateTime.now().toIso8601String(),
                                    phone: '',
                                    emailVerification: true,
                                    phoneVerification: false,
                                    $createdAt: DateTime.now().toIso8601String(),
                                    $updatedAt: DateTime.now().toIso8601String(),
                                    labels: [],
                                    mfa: false,
                                    targets: [],
                                    accessedAt: DateTime.now().toIso8601String(),
                                  );
                                  
                                  // Update auth state to simulate login
                                  ref.read(authNotifierProvider.notifier).updateUser(mockUser);
                                  
                                  // Navigate to parent dashboard after creating account
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ParentDashboardScreen(),
                                    ),
                                  );
                                }
                              : null,
                          child: const Text('Create Account'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLocalAccountMode = false;
                            });
                          },
                          child: const Text('Back to Options'),
                        ),
                      ] else ...[
                        // If not authenticated, provide options for desktop
                        const Text(
                          'Manage gaming time for your kids',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            // Show the local account form
                            setState(() {
                              _isLocalAccountMode = true;
                            });
                          },
                          child: const Text('Setup Local Account'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            // This is where Google Sign In would be for desktop if needed
                            // But based on your requirement, we'll just show info
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Mobile Only'),
                                content: const Text('Google Sign In is only available on mobile devices. For desktop, use local account setup.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Google Sign In Info'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
