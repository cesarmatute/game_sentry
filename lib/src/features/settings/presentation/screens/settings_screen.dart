import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/settings/presentation/notifiers/connection_test_notifier.dart';
import 'package:game_sentry/src/features/settings/presentation/notifiers/theme_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionTestNotifierProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                ref.read(connectionTestNotifierProvider.notifier).testConnection();
              },
              child: const Text('Test Connection'),
            ),
            const SizedBox(height: 20),
            Text('Connection Status: ${connectionStatus.name}'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Dark Mode'),
                Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    ref.read(themeNotifierProvider.notifier).toggleTheme();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
