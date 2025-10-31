import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/features/auth/presentation/widgets/auth_widget.dart';
import 'package:game_sentry/src/features/home/presentation/widgets/custom_drawer.dart';
import 'package:game_sentry/src/features/kids/data/kids_repository.dart';
import 'package:game_sentry/src/features/selection/selected_kid_provider.dart';

import 'package:game_sentry/src/features/kids/presentation/screens/kid_home_screen.dart';

import 'package:game_sentry/src/features/kids/data/models/kid.dart';
import 'package:game_sentry/src/utils/dialog_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to redirect to login screen if user logs out
    final authState = ref.watch(authNotifierProvider);
    if (authState.authStatus == AuthStatus.unauthenticated) {
      // If user is unauthenticated, redirect to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AuthWidget(authState: AuthState(AuthStatus.unauthenticated))),
        );
      });
    }
    
    final userId = authState.user?.$id;
    final kidsAsyncValue = userId != null ? ref.watch(kidsListProvider(userId)) : const AsyncValue.loading();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Sentry'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: const CustomDrawer(), // Add the custom drawer here
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                "Welcome back, ${authState.user?.name ?? '...'}!"),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: kidsAsyncValue.when(
        data: (kidList) {
          final hasKids = kidList.isNotEmpty;
          return FloatingActionButton(
            onPressed: () async {
              if (hasKids) {
                final navigator = Navigator.of(context);
                final currentSelectedKid = ref.read(selectedKidProvider);

                if (currentSelectedKid != null) {
                  navigator.pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const KidHomeScreen()),
                  );
                } else {
                  if (kidList.length > 1) {
                    final Kid? selectedKid =
                        await showKidSelectionDialog(context, kidList);
                    if (selectedKid != null) {
                      ref.read(selectedKidProvider.notifier).state =
                          selectedKid;
                      navigator.pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => const KidHomeScreen()),
                      );
                    }
                  } else if (kidList.length == 1) {
                    ref.read(selectedKidProvider.notifier).state =
                        kidList.first;
                    navigator.pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const KidHomeScreen()),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No kids found for this parent.'),
                  ),
                );
              }
            },
            child: const Icon(Icons.child_care),
          );
        },
        loading: () => const FloatingActionButton(
            onPressed: null, child: Icon(Icons.hourglass_empty)),
        error: (err, stack) => FloatingActionButton(
            onPressed: null, child: Icon(Icons.error)),
      ),
    );
  }
}