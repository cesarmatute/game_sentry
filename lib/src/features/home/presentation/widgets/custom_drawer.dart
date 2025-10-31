import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/profile/presentation/screens/profile_screen.dart';
import 'package:game_sentry/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:game_sentry/src/features/kids/presentation/screens/manage_kids_screen.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  ref.watch(authNotifierProvider).user?.name ?? 'Guest',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.child_care),
            title: const Text('Manage Kids'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageKidsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              showAboutDialog(
                context: context,
                applicationName: 'Game Sentry',
                applicationVersion: '1.0.0',
                children: const [
                  Text('A fun and safe gaming app for kids!'),
                  SizedBox(height: 10),
                  Text('Designed to help kids manage their gaming time with fun rules and activities.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}