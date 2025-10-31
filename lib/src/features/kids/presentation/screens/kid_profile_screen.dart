import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:game_sentry/src/features/kids/presentation/screens/edit_kid_screen.dart';
import 'package:game_sentry/src/features/selection/selected_kid_provider.dart';
import 'package:game_sentry/src/features/home/presentation/screens/home_screen.dart';

class KidProfileScreen extends ConsumerWidget {
  const KidProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kid = ref.watch(selectedKidProvider);

    if (kid == null) {
      return const Scaffold(
        body: Center(
          child: Text('No kid selected'),
        ),
      );
    }
    final avatarUrl = kid.avatarUrl;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kid Profile'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditKidScreen(kid: kid),
                ),
              );
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  key: ValueKey(avatarUrl),
                  radius: 50,
                  backgroundImage: backgroundImage,
                  child: backgroundImage == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 20),
                _buildInfoCard(
                  context,
                  'Basic Information',
                  [
                    _buildInfoRow('Username', kid.username),
                    if (kid.dob != null)
                      _buildInfoRow(
                        'Date of Birth',
                        '${kid.dob!.year}-${kid.dob!.month.toString().padLeft(2, '0')}-${kid.dob!.day.toString().padLeft(2, '0')}',
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoCard(
                  context,
                  'Playtime Settings',
                  [
                    _buildInfoRow(
                      'Daily Limit',
                      '${kid.maximumDailyLimit} minutes',
                    ),
                    _buildInfoRow(
                      'Session Limit',
                      '${kid.maximumSessionLimit} minutes',
                    ),
                    _buildInfoRow(
                      'Minimum Break',
                      '${kid.minimumBreak} minutes',
                    ),
                    _buildInfoRow(
                      'Playtime Hours',
                      '${kid.playtimeStart} - ${kid.playtimeEnd}',
                    ),
                    _buildInfoRow(
                      'Lunch Break',
                      '${kid.lunchBreakStart} - ${kid.lunchBreakEnd}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoCard(
                  context,
                  'Additional Settings',
                  [
                    _buildInfoRow(
                      'Enforce Brushing',
                      kid.enforceBrush ? 'Yes' : 'No',
                    ),
                    _buildInfoRow(
                      'PIN Required',
                      kid.hasPin ? 'Yes' : 'No',
                    ),
                  ],
                ),
                const SizedBox(height: 80), // Add extra space at the bottom
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
        child: const Icon(Icons.family_restroom),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}