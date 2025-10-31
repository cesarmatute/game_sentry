import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/core/utils/duration_formatter.dart';
import 'package:game_sentry/src/features/gaming/data/models/session_state.dart';

import 'package:game_sentry/src/features/kids/presentation/widgets/kid_custom_drawer.dart';
import 'package:game_sentry/src/features/parents/presentation/screens/parent_dashboard_screen.dart';

import 'package:game_sentry/src/features/gaming/presentation/notifiers/gaming_session_notifier.dart';
import 'package:game_sentry/src/features/gaming/presentation/widgets/lunch_brushing_dialog.dart';

import 'package:game_sentry/src/core/providers.dart';
import 'package:game_sentry/src/features/kids/data/models/kid.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/features/selection/selected_kid_provider.dart';

class KidHomeScreen extends ConsumerWidget {
  const KidHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedKid = ref.watch(selectedKidProvider);

  // If no kid is selected, try to select one automatically
    // Also refresh kid count to ensure switch button works correctly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSelectKid(context, ref);
      ref.read(authNotifierProvider.notifier).refreshKidCount();
      // Refresh the selected kid data from the database to get latest changes
      _refreshSelectedKidData(context, ref);
    });
    
    // Add this to trigger refresh when selectedKid changes
    ref.listen(selectedKidProvider, (previous, next) {
      if (next != null && previous?.id != next.id) {
        // Trigger refresh when a different kid is selected
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshSelectedKidData(context, ref);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Kid\'s View: ${selectedKid?.username ?? 'N/A'}'),
      ),
      drawer: const KidCustomDrawer(key: ValueKey('kid_drawer')),
      body: selectedKid != null 
          ? _GamingTimerWidget(key: ValueKey(selectedKid.id), kid: selectedKid)
          : const Center(
              child: Text('No kid selected'),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
          );
        },
        child: const Icon(Icons.family_restroom),
      ),
    );
  }

  void _checkAndSelectKid(BuildContext context, WidgetRef ref) {
    final selectedKid = ref.read(selectedKidProvider);
    if (selectedKid == null) {
      // No kid is selected, try to select one
      _selectKidAutomatically(context, ref);
    }
  }

  Future<void> _selectKidAutomatically(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(authNotifierProvider).user?.$id;
    if (userId == null) return;

    try {
      final kidsRepository = ref.read(kidsRepositoryProvider);
      final kidList = await kidsRepository.getKids(userId);
      // Sort kids alphabetically by username
      kidList.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));

      if (kidList.isEmpty) {
        // No kids available
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No kids available')),
          );
        }
      } else if (kidList.length == 1) {
        // Only one kid, select it automatically
        ref.read(selectedKidProvider.notifier).kid = kidList.first;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected ${kidList.first.username}')),
          );
        }
      } else {
        // Multiple kids, show selection dialog
        if (context.mounted) {
          final Kid? selectedKid = await showDialog<Kid?>( 
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Select a Kid'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: kidList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final kid = kidList[index];
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
                      return ListTile(
                        leading: Material(
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: CircleAvatar(
                            backgroundImage: backgroundImage,
                            child: backgroundImage == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                        ),
                        title: Text(kid.username),
                        onTap: () {
                          Navigator.of(context).pop(kid);
                        },
                      );
                    },
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );

          if (selectedKid != null) {
            ref.read(selectedKidProvider.notifier).kid = selectedKid;
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading kids: $e')),
        );
      }
    }
  }
  
  // Refresh the selected kid data from the database
  Future<void> _refreshSelectedKidData(BuildContext context, WidgetRef ref) async {
    final selectedKid = ref.read(selectedKidProvider);
    if (selectedKid == null) return;
    
    final userId = ref.read(authNotifierProvider).user?.$id;
    if (userId == null) return;
    
    try {
      final kidsRepository = ref.read(kidsRepositoryProvider);
      final kidList = await kidsRepository.getKids(userId);
      
      // Find the updated version of the selected kid
      final updatedKid = kidList.firstWhere(
        (kid) => kid.id == selectedKid.id,
        orElse: () => selectedKid, // fallback to current if not found
      );
      
      // Check if the kid data actually changed
      if (updatedKid.enforceLunchBreak != selectedKid.enforceLunchBreak ||
          updatedKid.enforceBrush != selectedKid.enforceBrush ||
          updatedKid.maximumDailyLimit != selectedKid.maximumDailyLimit ||
          updatedKid.maximumSessionLimit != selectedKid.maximumSessionLimit ||
          updatedKid.playtimeStart != selectedKid.playtimeStart ||
          updatedKid.playtimeEnd != selectedKid.playtimeEnd ||
          updatedKid.lunchBreakStart != selectedKid.lunchBreakStart ||
          updatedKid.lunchBreakEnd != selectedKid.lunchBreakEnd ||
          updatedKid.avatarUrl != selectedKid.avatarUrl) {
        
        debugPrint('Kid data changed - refreshing...');
        debugPrint('Old enforceLunchBreak: ${selectedKid.enforceLunchBreak}');
        debugPrint('New enforceLunchBreak: ${updatedKid.enforceLunchBreak}');
        
        // Update the gaming session notifier with the new kid data
        ref.read(gamingSessionNotifierProvider.notifier).updateKidData(updatedKid);
        
        // Update the selected kid with fresh data
        ref.read(selectedKidProvider.notifier).kid = updatedKid;
        
        debugPrint('Updated selectedKid and gaming session notifier with fresh data');
      }
    } catch (e) {
      debugPrint('Error refreshing kid data: $e');
    }
  }
}

// Gaming Timer Widget
class _GamingTimerWidget extends ConsumerWidget {
  final Kid kid;
  
  const _GamingTimerWidget({super.key, required this.kid});

  String _formatDurationWithUnits(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(gamingSessionForKidProvider(kid.id));
    
    // Fallback to a default state if the specific kid's state isn't available
    final displayState = sessionState ?? SessionState(
      kid: kid,
      canStart: true,
      dailyTimeUsed: Duration(seconds: kid.dailyPlayed),
      timeUntilBreak: Duration(
        minutes: kid.maximumSessionLimit - (kid.sessionPlayed ~/ 60),
      ).abs(),
      dailyTimeRemaining: Duration(
        minutes: kid.maximumDailyLimit - (kid.dailyPlayed ~/ 60),
      ).abs(),
      currentSessionTime: Duration(seconds: kid.sessionPlayed),
      isActive: false,
    );
    
    // Check if the kid data in the session state is different from the current kid
    // This can happen when the kid data is updated externally (e.g., from parent view)
    if (displayState.kid.enforceLunchBreak != kid.enforceLunchBreak ||
        displayState.kid.enforceBrush != kid.enforceBrush) {
      // Update the gaming session notifier with the latest kid data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gamingSessionNotifierProvider.notifier).updateKidData(kid);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Welcome message
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: kid.avatarUrl != null
                        ? (kid.avatarUrl!.startsWith('http')
                            ? NetworkImage(kid.avatarUrl!)
                            : (kid.avatarUrl!.startsWith('assets/')
                                ? AssetImage(kid.avatarUrl!)
                                : FileImage(File(kid.avatarUrl!)) as ImageProvider))
                        : null,
                    child: kid.avatarUrl == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome, ${kid.username}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayState.isActive ? 'Gaming in progress...' : 'Ready to play?',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20), 
          
          // Time remaining displays
          Row(
            children: [
              Expanded(
                child: _TimeCard(
                  title: 'Time Until Break',
                  timeRemaining: displayState.timeUntilBreak,
                  maxTime: Duration(minutes: kid.maximumSessionLimit),
                  color: displayState.breakWarning ? Colors.orange : Colors.blue,
                  icon: Icons.timer,
                  isWarning: displayState.breakWarning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeCard(
                  title: 'Daily Time',
                  timeRemaining: displayState.dailyTimeRemaining,
                  maxTime: Duration(minutes: kid.maximumDailyLimit),
                  color: Colors.green,
                  icon: Icons.today,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20), 
          
          // Session controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (displayState.isActive) ...[
                    // Active session controls
                    Text(
                      'Session Started',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Playing for: ${_formatDurationWithUnits(displayState.currentSessionTime)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (displayState.breakWarning) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade700, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Break coming up in ${formatDuration(displayState.timeUntilBreak)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final success = await ref
                            .read(gamingSessionNotifierProvider.notifier)
                            .stopSession();
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Session stopped!'))
                          );
                        }
                      },
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Gaming'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else ...[
                    // Start session controls
                    if (displayState.canStart) ...[
                      Text(
                        'Ready to Start Gaming?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final notifier = ref.read(gamingSessionNotifierProvider.notifier);
                          
                          // Check if we need to ask about lunch
                          if (notifier.shouldAskAboutLunch()) {
                            await LunchBrushingDialog.showLunchDialog(context, kid);
                            return; // Dialog will update state, triggering rebuild
                          }
                          
                          // Check if we need to ask about teeth brushing
                          if (notifier.shouldAskAboutTeethBrushing()) {
                            await LunchBrushingDialog.showBrushingDialog(context, kid);
                            return; // Dialog will update state, triggering rebuild
                          }
                          
                          // Try to start session
                          final success = await notifier.startSession();
                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gaming session started!'))
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Gaming'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else ...[
                      // Cannot start - show reason
                      Icon(
                        Icons.block,
                        size: 48,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gaming Not Available',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayState.validationMessage ?? 'Unknown restriction',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

// Time card widget for displaying remaining time
class _TimeCard extends StatelessWidget {
  final String title;
  final Duration timeRemaining;
  final Duration maxTime;
  final Color color;
  final IconData icon;
  final bool isWarning;
  
  const _TimeCard({
    required this.title,
    required this.timeRemaining,
    required this.maxTime,
    required this.color,
    required this.icon,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final rawProgress = maxTime.inMilliseconds > 0 
        ? timeRemaining.inMilliseconds / maxTime.inMilliseconds 
        : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);
    
    return Card(
      color: isWarning ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(icon, color: color, size: 32),
                if (isWarning)
                  Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              formatDuration(timeRemaining),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withAlpha(80),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            if (isWarning) ...[
              const SizedBox(height: 8),
              Text(
                'Break soon!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

