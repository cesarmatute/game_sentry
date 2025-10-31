
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/selection/parent_kid_picker_screen.dart';
import 'package:game_sentry/src/features/selection/selected_kid_provider.dart';
import 'package:game_sentry/src/features/gaming/presentation/notifiers/timer_notifier.dart';
import 'package:game_sentry/src/features/settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _buildRuleCard(String title, String subtitle) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildBooleanRuleCard(String title, bool value) {
    return Card(
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: value,
        onChanged: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedKid = ref.watch(selectedKidProvider);
    final timerState = ref.watch(timerProvider);

    String formatDuration(Duration duration) {
      String hours = (duration.inHours).toString();
      String minutes = (duration.inMinutes % 60).toString();
      String seconds = (duration.inSeconds % 60).toString();
      return "${hours}h ${minutes}m ${seconds}s";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                selectedKid?.username ?? 'No Kid Selected',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: null,
              currentAccountPicture: CircleAvatar(
                child: Text(selectedKid?.username.substring(0, 1) ?? '-'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.switch_account),
              title: const Text('Change Parent/Kid'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const ParentKidPickerScreen()),
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: selectedKid == null
          ? const Center(child: Text('No Kid Selected'))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            formatDuration(timerState.duration),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (timerState.isRunning) {
                                    ref.read(timerProvider.notifier).stop();
                                  } else {
                                    ref.read(timerProvider.notifier).start();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: timerState.isRunning ? Colors.red : Colors.green,
                                ),
                                child: Text(timerState.isRunning ? 'Stop' : 'Start'),
                              ),
                              const SizedBox(width: 16), // Space between buttons
                              ElevatedButton(
                                onPressed: timerState.isRunning ? null : () {
                                  ref.read(timerProvider.notifier).reset();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text(
                      'Gaming Rules for ${selectedKid.username}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        children: [
                          _buildRuleCard('Max Daily Playtime', '${selectedKid.maximumDailyLimit} minutes'),
                          _buildRuleCard('Max Session Limit', '${selectedKid.maximumSessionLimit} minutes'),
                          _buildRuleCard('Min Break Time', '${selectedKid.minimumBreak} minutes'),
                          _buildRuleCard('Playtime Hours', '${selectedKid.playtimeStart} - ${selectedKid.playtimeEnd}'),
                          _buildRuleCard('Lunch Break', '${selectedKid.lunchBreakStart} - ${selectedKid.lunchBreakEnd}'),
                          _buildBooleanRuleCard('Enforce Brushing', selectedKid.enforceBrush),
                          _buildBooleanRuleCard('Enforce Lunch Break', selectedKid.enforceLunchBreak),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
