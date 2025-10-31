import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/selection/selected_kid_provider.dart';
import 'package:game_sentry/src/features/kids/presentation/screens/kid_home_screen.dart';
import 'package:game_sentry/src/features/kids/presentation/screens/kid_profile_screen.dart';
import 'package:game_sentry/src/features/selection/parent_kid_picker_screen.dart';
import 'package:game_sentry/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:game_sentry/src/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:game_sentry/src/features/kids/presentation/screens/manage_kids_screen.dart';

class KidCustomDrawer extends ConsumerWidget {
  const KidCustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedKid = ref.watch(selectedKidProvider);

    final List<Widget> menuItems = [
      ListTile(
        leading: const Icon(Icons.home),
        title: const Text('Home'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const KidHomeScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.bar_chart),
        title: const Text('Statistics'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const StatisticsScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.person),
        title: const Text('Profile'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KidProfileScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.settings),
        title: const Text('Settings'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
      const Divider(),
      ListTile(
        leading: const Icon(Icons.swap_horiz),
        title: const Text('Change User'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const ParentKidPickerScreen()),
            (route) => false,
          );
        },
      ),
    ];

    final avatarUrl = selectedKid?.avatarUrl;
    ImageProvider? backgroundImage;
    if (avatarUrl != null) {
      if (avatarUrl.startsWith('http')) {
        backgroundImage = NetworkImage(avatarUrl);
      } else if (avatarUrl.startsWith('assets/')) {
        backgroundImage = AssetImage(avatarUrl);
      } else {
        backgroundImage = FileImage(File(avatarUrl));
      }
    }



    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(selectedKid?.username ?? 'No Kid Selected'),
            accountEmail: null,
            currentAccountPicture: CircleAvatar(
              backgroundImage: backgroundImage,
              child: backgroundImage == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          ...menuItems,
        ],
      ),
    );
  }
}
