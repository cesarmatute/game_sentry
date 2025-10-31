
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/settings/presentation/notifiers/theme_notifier.dart';
import 'package:game_sentry/src/features/settings/presentation/notifiers/system_tray_notifier.dart';
import 'package:game_sentry/src/features/settings/presentation/notifiers/sound_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final systemTraySettings = ref.watch(systemTrayProvider);
    final soundSettings = ref.watch(soundProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeNotifierProvider.notifier).toggleTheme();
            },
          ),
          SwitchListTile(
            title: const Text('Enable System Tray'),
            value: systemTraySettings.enableSystemTray,
            onChanged: (value) {
              ref.read(systemTrayProvider.notifier).setEnableSystemTray(value);
            },
          ),
          if (systemTraySettings.enableSystemTray) // Only show if system tray is enabled
            SwitchListTile(
              title: const Text('Minimize to Tray on Close'),
              value: systemTraySettings.minimizeToTrayOnClose,
              onChanged: (value) {
                ref.read(systemTrayProvider.notifier).setMinimizeToTrayOnClose(value);
              },
            ),
          SwitchListTile(
            title: const Text('Enable Sound Notifications'),
            value: soundSettings.enableSoundNotifications,
            onChanged: (value) {
              ref.read(soundProvider.notifier).setEnableSoundNotifications(value);
            },
          ),
        ],
      ),
    );
  }
}
