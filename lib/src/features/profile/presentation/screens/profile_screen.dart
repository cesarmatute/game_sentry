import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:game_sentry/src/features/auth/data/auth_repository.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/core/providers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _selectedDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      // Set initial values from user data
      _nameController.text = user.name;
      _emailController.text = user.email;
      
      // Set username from user prefs if available, otherwise use name
      final usernameFromPrefs = user.prefs.data['username'] as String?;
      if (usernameFromPrefs != null && usernameFromPrefs.isNotEmpty) {
        _usernameController.text = usernameFromPrefs;
      } else {
        _usernameController.text = user.name; // Fallback to user name
      }
      
      // Load parent data from database to override initial values if exists
      _loadParentData(user.$id);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadParentData(String parentId) async {
    try {
      final parent = await ref.read(parentsRepositoryProvider).getParent(parentId);
      
      // Only update the form fields if the parent data is different from what's already there
      // This prevents flickering when the data is the same
      setState(() {
        // Only update name if it's different
        if (parent.name.isNotEmpty && parent.name != _nameController.text) {
          _nameController.text = parent.name;
        }
        
        // Only update username if it's different
        if (parent.username.isNotEmpty && parent.username != _usernameController.text) {
          _usernameController.text = parent.username;
        }
        
        // Only update email if it's different
        if (parent.email.isNotEmpty && parent.email != _emailController.text) {
          _emailController.text = parent.email;
        }
        
        // Only update DOB if it's different
        if (parent.dob != null && parent.dob != _selectedDate) {
          _selectedDate = parent.dob;
        }
      });
      
      // If parent doesn't have an avatar, try to fetch it from Google
      if (parent.avatarUrl == null || parent.avatarUrl!.isEmpty) {
        await _fetchAndSaveGoogleAvatar(parentId);
      }
    } catch (e) {
      // Parent data not found or error loading, keep the data from user prefs
      // Try to fetch avatar from Google since parent doesn't exist in database yet
      await _fetchAndSaveGoogleAvatar(parentId);
    }
  }
  
  Future<void> _fetchAndSaveGoogleAvatar(String parentId) async {
    try {
      final account = Account(ref.read(appwriteClientProvider));
      
      // Get the user's sessions to find the Google session and access token
      final sessions = await account.listSessions();
      final googleSession = sessions.sessions.firstWhere(
        (session) => session.provider == 'google',
        orElse: () => throw Exception('Google session not found'),
      );
      
      // Use the access token to fetch user info from Google
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {
          'Authorization': 'Bearer ${googleSession.providerAccessToken}',
        },
      );
      
      if (response.statusCode == 200) {
        final userInfo = json.decode(response.body);
        final avatarUrl = userInfo['picture'] as String?;
        
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          // Save the avatar URL in the parents database
          try {
            final existingParent = await ref.read(parentsRepositoryProvider).getParent(parentId);
            await ref.read(parentsRepositoryProvider).updateParent(
              id: parentId,
              name: _nameController.text,
              username: _usernameController.text,
              email: _emailController.text,
              dob: _selectedDate,
              avatarUrl: avatarUrl,
              kids: existingParent.kids, // Preserve existing kids list
            );
          } catch (e) {
            // If update fails, try to create the parent record
            try {
              await ref.read(parentsRepositoryProvider).createParent(
                id: parentId,
                name: _nameController.text,
                username: _usernameController.text,
                email: _emailController.text,
                dob: _selectedDate,
                avatarUrl: avatarUrl,
                kids: [], // Empty kids list for now
              );
            } catch (createError) {
              // Silently fail if we can't save the avatar
            }
          }
          
          // Update the UI to show the avatar
          setState(() {});
        }
      }
    } catch (e) {
      // Silently fail if we can't fetch the avatar
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAgeRestrictionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Age Restriction'),
        content: const Text('You must be 18 years or older to use this app.'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (!_isEditing) return;

    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your date of birth')),
        );
        return;
      }

      final today = DateTime.now();
      final eighteenYearsAgo = DateTime(today.year - 18, today.month, today.day);
      if (_selectedDate!.isAfter(eighteenYearsAgo)) {
        _showAgeRestrictionDialog();
      } else {
        final currentContext = context;
        final user = ref.read(authNotifierProvider).user;
        if (user == null) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text('Error: Not logged in')),
          );
          return;
        }

        final parentId = user.$id;
        final email = user.email;
        final avatarUrl = _getGoogleAvatarUrl();
        final parentsRepository = ref.read(parentsRepositoryProvider);

        Future<void> save() async {
          try {
            final existingParent = await parentsRepository.getParent(parentId);
            await parentsRepository.updateParent(
              id: parentId,
              name: _nameController.text.isNotEmpty ? _nameController.text : existingParent.name,
              username: _usernameController.text.isNotEmpty ? _usernameController.text : existingParent.username,
              email: email.isNotEmpty ? email : existingParent.email,
              dob: _selectedDate ?? existingParent.dob,
              avatarUrl: avatarUrl ?? existingParent.avatarUrl,
              kids: existingParent.kids,
            );
          } catch (e) {
            await parentsRepository.createParent(
              id: parentId,
              name: _nameController.text,
              username: _usernameController.text,
              email: email,
              dob: _selectedDate,
              avatarUrl: avatarUrl,
              kids: [],
            );
          }
        }

        save().then((_) async {
          // Also update the user prefs
          final updatedUser = await ref.read(authRepositoryProvider).updateProfile(
                name: _nameController.text,
                username: _usernameController.text,
                dob: _selectedDate!,
              );
          
          // Update the auth state with the updated user
          ref.read(authNotifierProvider.notifier).updateUser(updatedUser);

          if (!currentContext.mounted) return;
          setState(() {
            _isEditing = false;
          });
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully')),
          );
        }).catchError((error) {
          if (!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Error saving profile: $error')),
          );
        });
      }
    }
  }

  String? _getGoogleAvatarUrl() {
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      // Try to get the avatar URL from user prefs
      final avatarUrl = user.prefs.data['avatar'] as String?;
      
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        return avatarUrl;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
            )
          else
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Builder(
                  builder: (context) {
                    final avatarUrl = _getGoogleAvatarUrl();
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
                    return CircleAvatar(
                      radius: 50,
                      backgroundImage: backgroundImage,
                      child: backgroundImage == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: _isEditing
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        }
                      : null,
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'No date selected'
                            : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                    if (_isEditing)
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('Select Date'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}