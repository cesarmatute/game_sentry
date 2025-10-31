import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/core/providers.dart';
import 'package:game_sentry/src/features/auth/data/auth_repository.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/features/kids/data/kids_repository.dart';
import 'package:game_sentry/src/features/kids/presentation/screens/add_kid_screen.dart';
import 'package:game_sentry/src/features/kids/presentation/screens/edit_kid_screen.dart';
import 'package:game_sentry/src/features/kids/data/models/kid.dart'; // Import Kid model
import 'package:game_sentry/src/features/selection/selected_kid_provider.dart';
import 'dart:io';

class ManageKidsScreen extends ConsumerStatefulWidget {
  const ManageKidsScreen({super.key});

  @override
  ConsumerState<ManageKidsScreen> createState() => _ManageKidsScreenState();
}

class _ManageKidsScreenState extends ConsumerState<ManageKidsScreen> {
  late Future<List<Kid>> _kidsFuture;

  @override
  void initState() {
    super.initState();
    _kidsFuture = _fetchKids();
  }

  Future<List<Kid>> _fetchKids() async {
    final authRepository = ref.read(authRepositoryProvider);
    final kidsRepository = ref.read(kidsRepositoryProvider);
    final user = await authRepository.getCurrentUser();
    if (user != null) {
      final kids = await kidsRepository.getKids(user.$id);
      // Sort kids alphabetically by username
      kids.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
      return kids;
    }
    return <Kid>[];
  }

  Future<void> _handleSelectedKidDeletion(String parentId) async {
    try {
      final kidsRepository = ref.read(kidsRepositoryProvider);
      final remainingKids = await kidsRepository.getKids(parentId);
      // Sort kids alphabetically by username for consistency
      remainingKids.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
      
      if (remainingKids.isEmpty) {
        // No kids left, clear selection
        ref.read(selectedKidProvider.notifier).kid = null;
      } else if (remainingKids.length == 1) {
        // Only one kid remaining, auto-select it
        ref.read(selectedKidProvider.notifier).kid = remainingKids.first;
      } else {
        // Multiple kids remaining, clear selection so user can choose
        ref.read(selectedKidProvider.notifier).kid = null;
      }
    } catch (e) {
      // If we can't fetch kids, just clear the selection to be safe
      ref.read(selectedKidProvider.notifier).state = null;
    }
  }

  Future<void> _deleteKid(String kidId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Kid'),
        content: const Text('Are you sure you want to delete this kid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final authRepository = ref.read(authRepositoryProvider);
        final kidsRepository = ref.read(kidsRepositoryProvider);
        
        // Check if the kid being deleted is currently selected
        final currentSelectedKid = ref.read(selectedKidProvider);
        final isSelectedKidDeleted = currentSelectedKid?.id == kidId;
        
        await kidsRepository.deleteKid(kidId);
        final user = await authRepository.getCurrentUser();
        if (user != null) {
          ref.invalidate(kidsListProvider(user.$id)); // Invalidate the kidsListProvider
        }
        // Update kid count in auth state by refreshing from database
        await ref.read(authNotifierProvider.notifier).refreshKidCount();
        
        // Handle selected kid logic if the deleted kid was selected
        if (isSelectedKidDeleted && user != null) {
          await _handleSelectedKidDeletion(user.$id);
        }
        
        if (!mounted) return;
        setState(() {
          _kidsFuture = _fetchKids();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kid deleted successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Kids'),
      ),
      body: FutureBuilder<List<Kid>>(
        future: _kidsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No kids found.'));
          } else {
            final kids = snapshot.data!;
            return ListView.builder(
              itemCount: kids.length,
              itemBuilder: (context, index) {
                final kid = kids[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: kid.avatarUrl != null
                        ? (kid.avatarUrl!.startsWith('http')
                            ? NetworkImage(kid.avatarUrl!)
                            : (kid.avatarUrl!.startsWith('assets/')
                                ? AssetImage(kid.avatarUrl!)
                                : FileImage(File(kid.avatarUrl!))) as ImageProvider?)
                        : null,
                    child: kid.avatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(kid.username),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteKid(kid.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditKidScreen(kid: kid),
                      ),
                    ).then((_) {
                      // Refresh the list after editing
                      setState(() {
                        _kidsFuture = _fetchKids();
                      });
                    });
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddKidScreen()),
          ).then((_) {
            // Refresh the list after adding a new kid
            setState(() {
              _kidsFuture = _fetchKids();
            });
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}