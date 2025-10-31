import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/features/gaming/data/models/session_state.dart';
import 'package:game_sentry/src/features/gaming/presentation/notifiers/gaming_session_notifier.dart';
import 'package:game_sentry/src/features/home/presentation/widgets/custom_drawer.dart';
import 'package:game_sentry/src/features/kids/data/kids_repository.dart';
import 'package:game_sentry/src/features/kids/data/models/kid.dart';
import 'package:game_sentry/src/features/kids/presentation/screens/edit_kid_screen.dart';
import 'package:game_sentry/src/features/kids/presentation/screens/kid_home_screen.dart';
import 'package:game_sentry/src/features/selection/selected_kid_provider.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).refreshKidCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.$id;
    
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Authentication required')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${authState.user?.name ?? 'Parent'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(authNotifierProvider.notifier).refreshKidCount();
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Summary
                _buildStatsSummary(authState.kidCount),
                const SizedBox(height: 20),
                
                // Add Kid Button
                if (authState.kidCount < 4) // Limit to 4 kids for demo
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/add-kid'); // TODO: Implement navigation
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add New Kid'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                
                // Kids List Header
                const Text(
                  'Your Kids',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Kids List
                _KidsList(parentId: userId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(int kidCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatCard(
              title: 'Kids',
              value: kidCount.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Active Sessions',
              value: '0', // TODO: Implement real-time active sessions count
              icon: Icons.timer,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Today\'s Play',
              value: '0h', // TODO: Implement today's total playtime
              icon: Icons.pie_chart,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _KidsList extends ConsumerWidget {
  final String parentId;

  const _KidsList({required this.parentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kidsAsync = ref.watch(kidsListProvider(parentId));

    return kidsAsync.when(
      data: (kids) {
        if (kids.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No kids added yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kids.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final kid = kids[index];
            return Dismissible(
              key: Key(kid.id), // Unique key for each Dismissible
              direction: DismissDirection.horizontal,
              background: Container(
                color: Colors.green, // Swipe right for Manage Play
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.play_circle, color: Colors.white, size: 40.0),
              ),
              secondaryBackground: Container(
                color: Colors.blue, // Swipe left for Edit Kid
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.edit, color: Colors.white, size: 40.0),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  // Swipe right: Manage Play
                  ref.read(selectedKidProvider.notifier).kid = kid;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const KidHomeScreen(),
                    ),
                  );
                  return false; // Don't dismiss the item
                } else if (direction == DismissDirection.endToStart) {
                  // Swipe left: Edit Kid
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditKidScreen(kid: kid),
                    ),
                  );
                  return false; // Don't dismiss the item
                }
                return false; // Should not happen with horizontal direction
              },
              child: _KidCard(kid: kid),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _KidCard extends ConsumerWidget {
  final Kid kid;

  const _KidCard({required this.kid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get session state for this specific kid using the new provider pattern
    final sessionState = ref.watch(gamingSessionForKidProvider(kid.id));
    
    // If no specific session state is available for this kid, use a default state
    final displayState = sessionState ?? SessionState(
      kid: kid,
      dailyTimeUsed: Duration(seconds: kid.dailyPlayed),
      timeUntilBreak: Duration(
        minutes: kid.maximumSessionLimit - (kid.sessionPlayed ~/ 60),
      ).abs(),
      dailyTimeRemaining: Duration(
        minutes: kid.maximumDailyLimit - (kid.dailyPlayed ~/ 60),
      ).abs(),
      currentSessionTime: Duration(seconds: kid.sessionPlayed),
      isActive: false, // Default to not active since we can't access the state for this specific kid
      canStart: true,  // Default to true since we can't check the actual state
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: kid.avatarUrl != null
                      ? (kid.avatarUrl!.startsWith('http')
                          ? NetworkImage(kid.avatarUrl!)
                          : (kid.avatarUrl!.startsWith('assets/')
                              ? AssetImage(kid.avatarUrl!)
                              : FileImage(File(kid.avatarUrl!))) as ImageProvider?)
                      : null,
                  child: kid.avatarUrl == null
                      ? Icon(Icons.person, size: 32)
                      : null,
                ),
                const SizedBox(width: 16),
                // Kid name and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kid.username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayState.isActive 
                          ? 'Playing now' 
                          : 'Available to play',
                        style: TextStyle(
                          color: displayState.isActive ? Colors.green : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: displayState.isActive ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SmallStat(
                  label: 'Today',
                  value: '${displayState.dailyTimeUsed.inHours}h ${displayState.dailyTimeUsed.inMinutes.remainder(60)}m',
                  icon: Icons.today,
                ),
                _SmallStat(
                  label: 'Time Until Break',
                  value: displayState.timeUntilBreak.inMinutes > 0 
                      ? '${displayState.timeUntilBreak.inMinutes}m' 
                      : '<1m',
                  icon: Icons.timer,
                ),
                _SmallStat(
                  label: 'Remaining',
                  value: '${displayState.dailyTimeRemaining.inHours}h ${displayState.dailyTimeRemaining.inMinutes.remainder(60)}m',
                  icon: Icons.hourglass_bottom,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quick actions
          ],
        ),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SmallStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}