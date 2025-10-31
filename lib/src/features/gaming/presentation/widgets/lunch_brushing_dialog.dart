import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/gaming/presentation/notifiers/gaming_session_notifier.dart';
import 'package:game_sentry/src/features/kids/data/models/kid.dart';

class LunchBrushingDialog extends ConsumerWidget {
  final Kid kid;
  final String question;
  final bool isLunchQuestion;

  const LunchBrushingDialog({
    super.key,
    required this.kid,
    required this.question,
    required this.isLunchQuestion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(isLunchQuestion ? 'Lunch Time Check' : 'Teeth Brushing Check'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLunchQuestion ? Icons.restaurant : Icons.clean_hands,
            size: 64,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final notifier = ref.read(gamingSessionNotifierProvider.notifier);
            if (isLunchQuestion) {
              notifier.setHasHadLunch(false);
            } else {
              notifier.setHasBrushedTeeth(false);
            }
            Navigator.of(context).pop();
          },
          child: const Text('No'),
        ),
        ElevatedButton(
          onPressed: () async {
            final notifier = ref.read(gamingSessionNotifierProvider.notifier);
            if (isLunchQuestion) {
              notifier.setHasHadLunch(true);
              Navigator.of(context).pop();
              
              // If the kid had lunch and teeth brushing is enforced, show the brushing dialog
              if (kid.enforceBrush) {
                // Use WidgetsBinding to ensure we show the dialog after the current one closes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    showBrushingDialog(context, kid);
                  }
                });
              }
            } else {
              notifier.setHasBrushedTeeth(true);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Yes'),
        ),
      ],
    );
  }

  static Future<void> showLunchDialog(BuildContext context, Kid kid) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LunchBrushingDialog(
        kid: kid,
        question: 'Did you have lunch today?',
        isLunchQuestion: true,
      ),
    );
  }

  static Future<void> showBrushingDialog(BuildContext context, Kid kid) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LunchBrushingDialog(
        kid: kid,
        question: 'Did you brush your teeth after lunch?',
        isLunchQuestion: false,
      ),
    );
  }
}
