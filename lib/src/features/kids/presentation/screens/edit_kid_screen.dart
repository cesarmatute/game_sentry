import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:game_sentry/src/core/providers.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/features/kids/data/kids_repository.dart';
import 'package:game_sentry/src/features/selection/selected_kid_provider.dart';
import 'package:game_sentry/src/features/kids/data/models/kid.dart';

class EditKidScreen extends ConsumerStatefulWidget {
  final Kid kid;
  const EditKidScreen({super.key, required this.kid});

  @override
  ConsumerState<EditKidScreen> createState() => _EditKidScreenState();
}

class _EditKidScreenState extends ConsumerState<EditKidScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  DateTime? _selectedDate;
  late Duration _selectedDuration;
  late Duration _selectedSessionDuration;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  TimeOfDay? _lunchStartTime;
  TimeOfDay? _lunchEndTime;
  late Duration _minBreakTime;
  late bool _enforceBrushing;
  late bool _enforceLunchBreak;
  String? _selectedAvatarPath;

  @override
  void initState() {
    super.initState();
    final kid = widget.kid;
    _usernameController = TextEditingController(text: kid.username);
    _selectedDate = kid.dob;
    _selectedDuration = Duration(minutes: kid.maximumDailyLimit);
    _selectedSessionDuration = Duration(minutes: kid.maximumSessionLimit);
    _startTime = TimeOfDay(
            hour: int.parse(kid.playtimeStart.split(':')[0]),
            minute: int.parse(kid.playtimeStart.split(':')[1]),
          );
    _endTime = TimeOfDay(
            hour: int.parse(kid.playtimeEnd.split(':')[0]),
            minute: int.parse(kid.playtimeEnd.split(':')[1]),
          );
    _lunchStartTime = TimeOfDay(
            hour: int.parse(kid.lunchBreakStart.split(':')[0]),
            minute: int.parse(kid.lunchBreakStart.split(':')[1]),
          );
    _lunchEndTime = TimeOfDay(
            hour: int.parse(kid.lunchBreakEnd.split(':')[0]),
            minute: int.parse(kid.lunchBreakEnd.split(':')[1]),
          );
    _minBreakTime = Duration(minutes: kid.minimumBreak);
    _enforceBrushing = kid.enforceBrush;
    _enforceLunchBreak = kid.enforceLunchBreak;
    _selectedAvatarPath = kid.avatarUrl;
  }



  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _chooseAvatar(BuildContext context) async {
    final List<String> avatarPaths = [
      'assets/images/avatars/120x120/avatar_1.jpg',
      'assets/images/avatars/120x120/avatar_2.jpg',
      'assets/images/avatars/120x120/avatar_3.jpg',
      'assets/images/avatars/120x120/avatar_4.jpg',
      'assets/images/avatars/120x120/avatar_5.jpg',
      'assets/images/avatars/120x120/avatar_6.jpg',
      'assets/images/avatars/120x120/avatar_7.jpg',
      'assets/images/avatars/120x120/avatar_8.jpg',
    ];

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Choose Avatar'),
            content: SizedBox(
              width: double.maxFinite,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: avatarPaths.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatarPath = avatarPaths[index];
                      });
                      Navigator.pop(context);
                    },
                                    child: CircleAvatar(
                                      backgroundImage: AssetImage(avatarPaths[index]),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        });
                      }
                    
                      Future<void> _uploadAvatar() async {
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                          maxHeight: 500,
                          maxWidth: 500,
                        );

                        if (image != null) {
                          try {
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  content: Row(
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(width: 20),
                                      const Text('Uploading avatar...'),
                                    ],
                                  ),
                                );
                              },
                            );

                            // For now, just set the local file path
                            // In a real implementation, we'd upload to Appwrite storage
                            setState(() {
                              _selectedAvatarPath = image.path;
                            });

                            // Close the loading dialog
                            navigator.pop();
                          } catch (e) {
                            // Close the loading dialog if it's still open
                            if (navigator.canPop()) {
                              navigator.pop();
                            }

                            // Show error message
                            if (scaffoldMessenger.mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text('Error uploading avatar: $e')),
                              );
                            }
                          }
                        }
                      }
                    
                      @override
                      Widget build(BuildContext context) {
                        ImageProvider? backgroundImage;
                        final avatarUrl = _selectedAvatarPath ?? widget.kid.avatarUrl;
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
                            title: const Text('Edit Kid'),
                            actions: [
                              IconButton(
                                onPressed: () async {
                                              final navigator = Navigator.of(context);
                                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                                              if (_formKey.currentState!.validate()) {
                                                final kidsRepository = ref.read(kidsRepositoryProvider);
                                
                                                try {
                                                  await kidsRepository.updateKid(
                                                    kidId: widget.kid.id,
                                                    username: _usernameController.text,
                                                    dob: _selectedDate,
                                                    avatarUrl: _selectedAvatarPath,
                                                    maxDailyPlaytime: _selectedDuration.inMinutes,
                                                    maxSessionLimit: _selectedSessionDuration.inMinutes,
                                                    minBreakTime: _minBreakTime.inMinutes,
                                                    playtimeStart: _startTime != null ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}' : null,
                                                    playtimeEnd: _endTime != null ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}' : null,
                                                    lunchBreakStart: _lunchStartTime != null ? '${_lunchStartTime!.hour.toString().padLeft(2, '0')}:${_lunchStartTime!.minute.toString().padLeft(2, '0')}' : null,
                                                    lunchBreakEnd: _lunchEndTime != null ? '${_lunchEndTime!.hour.toString().padLeft(2, '0')}:${_lunchEndTime!.minute.toString().padLeft(2, '0')}' : null,
                                                    enforceBrush: _enforceBrushing,
                                                    enforceLunchBreak: _enforceLunchBreak,
                                                  );

                                                  final updatedKid = await kidsRepository.getKid(widget.kid.id);
                                                  ref.read(selectedKidProvider.notifier).kid = updatedKid;
                                
                                                  final userId = ref.read(authNotifierProvider).user?.$id;
                                                  if (userId != null) {
                                                    ref.invalidate(kidsListProvider(userId));
                                                    ref.invalidate(authNotifierProvider);
                                                    // Also invalidate the kidsListProvider for the parent
                                                    ref.invalidate(kidsListProvider(widget.kid.parentId));
                                                  }
                                
                                                  if (scaffoldMessenger.mounted) {
                                                    scaffoldMessenger.showSnackBar(
                                                      const SnackBar(
                                                          content: Text('Kid updated successfully!')),
                                                    );
                                                  }
                                                  if (navigator.canPop()) {
                                                    navigator.pop();
                                                  }
                                                } catch (e) {
                                                  if (scaffoldMessenger.mounted) {
                                                    scaffoldMessenger.showSnackBar(
                                                      SnackBar(content: Text('Error: $e')),
                                                    );
                                                  }
                                                }
                                              }
                                            },                                icon: const Icon(Icons.save),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final navigator = Navigator.of(context);
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Kid'),
                                      content: const Text('Are you sure you want to delete this kid?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                    
                                  if (confirmed == true) {
                                    final kidsRepository = ref.read(kidsRepositoryProvider);
                                    final userId = ref.read(authNotifierProvider).user?.$id;
                    
                                    try {
                                      await kidsRepository.deleteKid(widget.kid.id);
                    
                                      if (userId != null) {
                                        ref.invalidate(kidsListProvider(userId));
                                        ref.invalidate(authNotifierProvider);
                                        // Also invalidate the kidsListProvider for the parent
                                        ref.invalidate(kidsListProvider(widget.kid.parentId));
                                      }
                    
                                      if (scaffoldMessenger.mounted) {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                              content: Text('Kid deleted successfully!')),
                                        );
                                      }
                                      if (navigator.canPop()) {
                                        navigator.pop();
                                      }
                                    } catch (e) {
                                      if (scaffoldMessenger.mounted) {
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete),
                              ),
                            ],
                          ),
                          body: Column(
                            children: [
                              const SizedBox(height: 20),
                              CircleAvatar(
                                radius: 80,
                                backgroundImage: backgroundImage,
                                child: backgroundImage == null
                                    ? const Icon(Icons.camera_alt, size: 80)
                                    : null,
                              ),          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _chooseAvatar(context),
                child: const Text('Choose Avatar'),
              ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: () {
                  _uploadAvatar();
                },
                child: const Text('Upload Avatar'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text('Username',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Date of Birth',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'No date chosen'
                              : '${_selectedDate!.toLocal()}'.split(' ')[0],
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: const Text('Choose Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Max Daily Playtime',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${_selectedDuration.inHours} h, ${_selectedDuration.inMinutes.remainder(60)} m',
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                DateTime(0).add(_selectedDuration),
                              ),
                            );
                            if (time != null) {
                              setState(() {
                                _selectedDuration = Duration(
                                    hours: time.hour, minutes: time.minute);
                              });
                            }
                          },
                          child: const Text('Choose Time'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Max Session Limit',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${_selectedSessionDuration.inHours} h, ${_selectedSessionDuration.inMinutes.remainder(60)} m',
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                DateTime(0).add(_selectedSessionDuration),
                              ),
                            );
                            if (time != null) {
                              setState(() {
                                _selectedSessionDuration = Duration(
                                    hours: time.hour, minutes: time.minute);
                              });
                            }
                          },
                          child: const Text('Choose Time'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Allowed Playtime Range',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time'),
                              TextButton(
                                onPressed: () async {
                                  final TimeOfDay? time = await showTimePicker(
                                    context: context,
                                    initialTime: _startTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _startTime = time;
                                    });
                                  }
                                },
                                child: Text(_startTime?.format(context) ??
                                    'Choose Time'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time'),
                              TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: _endTime?.format(context) ??
                                      'Choose Time',
                                ),
                                onTap: () async {
                                  final TimeOfDay? time = await showTimePicker(
                                    context: context,
                                    initialTime: _endTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _endTime = time;
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (_startTime != null && _endTime != null) {
                                    final now = DateTime.now();
                                    final start = DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                        _startTime!.hour,
                                        _startTime!.minute);
                                    final end = DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                        _endTime!.hour,
                                        _endTime!.minute);
                                    if (end.isBefore(start)) {
                                      return 'End time must be after start time';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Lunch Break Range',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time'),
                              TextButton(
                                onPressed: () async {
                                  final TimeOfDay? time = await showTimePicker(
                                    context: context,
                                    initialTime: 
                                        _lunchStartTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _lunchStartTime = time;
                                    });
                                  }
                                },
                                child: Text(_lunchStartTime?.format(context) ??
                                    'Choose Time'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time'),
                              TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: _lunchEndTime?.format(context) ??
                                      'Choose Time',
                                ),
                                onTap: () async {
                                  final TimeOfDay? time = await showTimePicker(
                                    context: context,
                                    initialTime: 
                                        _lunchEndTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _lunchEndTime = time;
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (_lunchStartTime != null &&
                                      _lunchEndTime != null) {
                                    final now = DateTime.now();
                                    final start = DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                        _lunchStartTime!.hour,
                                        _lunchStartTime!.minute);
                                    final end = DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                        _lunchEndTime!.hour,
                                        _lunchEndTime!.minute);
                                    if (end.isBefore(start)) {
                                      return 'End time must be after start time';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Minimum Break Time',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${_minBreakTime.inHours} h, ${_minBreakTime.inMinutes.remainder(60)} m',
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                DateTime(0).add(_minBreakTime),
                              ),
                            );
                            if (time != null) {
                              setState(() {
                                _minBreakTime = Duration(
                                    hours: time.hour, minutes: time.minute);
                              });
                            }
                          },
                          child: const Text('Choose Time'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text(
                          'Enforce Brushing Teeth After Lunch',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      value: _enforceBrushing,
                      onChanged: (bool value) {
                        setState(() {
                          _enforceBrushing = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text('Enforce Lunch Break', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Require the child to take a lunch break'),
                      value: _enforceLunchBreak,
                      onChanged: (bool value) {
                        setState(() {
                          _enforceLunchBreak = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
