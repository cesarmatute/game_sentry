import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/core/providers.dart';
import 'package:game_sentry/src/features/parents/data/models/parent.dart';
import 'package:game_sentry/src/features/kids/data/models/kid.dart';
import 'package:game_sentry/src/features/kids/presentation/screens/kid_home_screen.dart';
import 'package:game_sentry/src/features/selection/selected_kid_provider.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/features/kids/data/kids_repository.dart';


class KidPickerScreen extends ConsumerStatefulWidget {
  final Parent? selectedParent;

  const KidPickerScreen({super.key, this.selectedParent});

  @override
  ConsumerState<KidPickerScreen> createState() => _KidPickerScreenState();
}

class _KidPickerScreenState extends ConsumerState<KidPickerScreen> {
  Kid? _selectedKid;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildAvatar(String? avatarUrl) {
    ImageProvider? backgroundImage;
    if (avatarUrl != null) {
      if (avatarUrl.startsWith('http')) {
        backgroundImage = NetworkImage(avatarUrl);
      } else if (avatarUrl.startsWith('assets/')) {
        backgroundImage = AssetImage(avatarUrl);
      } else {
        // Assume it's a file path if it starts with neither 'http' nor 'assets/'
        backgroundImage = FileImage(File(avatarUrl));
      }
    }

    return CircleAvatar(
      key: ValueKey(avatarUrl),
      radius: 50,
      backgroundImage: backgroundImage,
      child: backgroundImage == null
          ? const Icon(Icons.person, size: 50)
          : null,
    );
  }

  @override
  void initState() {
    super.initState();
    // Force refresh of the kids list to ensure latest data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectedParent != null) {
        ref.invalidate(kidsListProvider(widget.selectedParent!.id));
      } else {
        // For mobile flow, get parent ID from authenticated user
        final authState = ref.read(authNotifierProvider);
        if (authState.user != null) {
          ref.invalidate(kidsListProvider(authState.user!.$id));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the parent ID from either the passed parent (desktop) or authenticated user (mobile)
    String parentId = '';
    if (widget.selectedParent != null) {
      parentId = widget.selectedParent!.id;
    } else {
      // For mobile, get the parent ID from the authenticated user
      final authState = ref.watch(authNotifierProvider);
      if (authState.user != null) {
        parentId = authState.user!.$id;
      }
    }

    // Use the real-time provider for improved consistency
    final kidsAsyncValue = ref.watch(kidsListProvider(parentId));

    return Scaffold(
      appBar: AppBar(
        title: widget.selectedParent != null 
          ? Text('Select Kid for ${widget.selectedParent!.name}')
          : const Text('Select Your Kid'),
      ),
      body: kidsAsyncValue.when(
        data: (kids) {
          if (kids.isEmpty) {
            return const Center(child: Text('No kids found for this parent.'));
          }

          // Initialize _selectedKid if it's null
          if (_selectedKid == null && kids.isNotEmpty) {
            _selectedKid = kids.first;
          }

          return Column(
            children: [
              Expanded(
                child: Row(
                  children: <Widget>[
                    if (kids.length > 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                      ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.horizontal,
                        physics: const PageScrollPhysics(),
                        itemCount: kids.length,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedKid = kids[index];
                          });
                        },
                        itemBuilder: (context, index) {
                          final kid = kids[index];
                          return GestureDetector(
                            onDoubleTap: () async {
                              final navigator = Navigator.of(context);
                              // Fetch the most recent kid data from the database to ensure latest avatar and other info
                              final kidsRepository = ref.read(kidsRepositoryProvider);
                              final freshKid = await kidsRepository.getKid(kids[index].id);
                              ref.read(selectedKidProvider.notifier).kid = freshKid;
                              debugPrint('Selected kid: ${freshKid.username}');
                              navigator.pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const KidHomeScreen()),
                                (route) => false,
                              );
                            },
                            child: Center(
                              child: Card(
                                margin: const EdgeInsets.all(16.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildAvatar(kid.avatarUrl),
                                      const SizedBox(height: 16),
                                      Text(
                                        kid.username,
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (kids.length > 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _selectedKid != null
                      ? () async {
                          final navigator = Navigator.of(context);
                          // Fetch the most recent kid data from the database to ensure latest avatar and other info
                          final kidsRepository = ref.read(kidsRepositoryProvider);
                          final freshKid = await kidsRepository.getKid(_selectedKid!.id);
                          ref.read(selectedKidProvider.notifier).kid = freshKid;
                          if (_selectedKid != null) {
                            debugPrint('Selected kid: ${freshKid.username}');
                          }
                          navigator.pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const KidHomeScreen()),
                            (route) => false,
                          );
                        }
                      : null,
                  child: const Text('Confirm Selection'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading kids: $err')),
      ),
    );
  }
}