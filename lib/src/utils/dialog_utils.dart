import 'package:flutter/material.dart';
import 'package:game_sentry/src/features/kids/data/models/kid.dart';

Future<Kid?> showKidSelectionDialog(BuildContext context, List<Kid> kids) async {
  // Sort kids alphabetically by username
  final sortedKids = List<Kid>.from(kids);
  sortedKids.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
  
  return showDialog<Kid?>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Choose a Kid'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedKids.length,
            itemBuilder: (BuildContext context, int index) {
              final kid = sortedKids[index];
              return ListTile(
                title: Text(kid.username),
                onTap: () {
                  Navigator.of(context).pop(kid);
                },
              );
            },
          ),
        ),
      );
    },
  );
}
