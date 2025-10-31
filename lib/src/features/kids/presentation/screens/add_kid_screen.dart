import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/core/providers.dart';
import 'package:game_sentry/src/features/auth/data/auth_repository.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/features/kids/data/kids_repository.dart';


class AddKidScreen extends ConsumerStatefulWidget {
  const AddKidScreen({super.key});

  @override
  ConsumerState<AddKidScreen> createState() => _AddKidScreenState();
}

class _AddKidScreenState extends ConsumerState<AddKidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  
  DateTime? _selectedDate;
  Duration _selectedDuration = const Duration(hours: 3, minutes: 30);
  Duration _selectedSessionDuration = const Duration(hours: 2);
  TimeOfDay? _startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay? _endTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay? _lunchStartTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay? _lunchEndTime = const TimeOfDay(hour: 14, minute: 0);
  Duration _minBreakTime = const Duration(hours: 1);
  bool _enforceBrushing = false;
  bool _enforceLunchBreak = true; // Default to true as per requirements
  String? _selectedAvatarPath;

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

    showDialog(context: context, builder: (BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    ImageProvider? backgroundImage;
    if (_selectedAvatarPath != null) {
      if (_selectedAvatarPath!.startsWith('http')) {
        backgroundImage = NetworkImage(_selectedAvatarPath!);
      } else if (_selectedAvatarPath!.startsWith('assets/')) {
        backgroundImage = AssetImage(_selectedAvatarPath!);
      } else {
        backgroundImage = FileImage(File(_selectedAvatarPath!));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Kid'),
        actions: [
          IconButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                try {
                  final authRepository = ref.read(authRepositoryProvider);
                  final kidsRepository = ref.read(kidsRepositoryProvider);
                  final user = await authRepository.getCurrentUser();

                  if (user != null) {
                    await kidsRepository.addKid(
                      parentId: user.$id,
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
                    ref.invalidate(kidsListProvider(user.$id)); // Invalidate the kidsListProvider
                    // Update kid count in auth state by refreshing from database
                    await ref.read(authNotifierProvider.notifier).refreshKidCount();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Kid added successfully!')),
                    );
                    navigator.pop();
                  } else {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Error: Could not get current user.')),
                    );
                  }
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 80,
            backgroundImage: backgroundImage,
            child: backgroundImage == null ? const Icon(Icons.camera_alt, size: 80) : null,
          ),
          const SizedBox(height: 10),
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
                  // TODO: Implement upload avatar logic
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
                    const Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    const Text('Date of Birth', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    const Text('Max Daily Playtime', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                _selectedDuration = Duration(hours: time.hour, minutes: time.minute);
                              });
                            }
                          },
                          child: const Text('Choose Time'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Max Session Limit', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                _selectedSessionDuration = Duration(hours: time.hour, minutes: time.minute);
                              });
                            }
                          },
                          child: const Text('Choose Time'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Allowed Playtime Range', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                child: Text(_startTime?.format(context) ?? 'Choose Time'),
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
                                  hintText: _endTime?.format(context) ?? 'Choose Time',
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
                                    final start = DateTime(now.year, now.month, now.day, _startTime!.hour, _startTime!.minute);
                                    final end = DateTime(now.year, now.month, now.day, _endTime!.hour, _endTime!.minute);
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
                    const Text('Lunch Break Range', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                    initialTime: _lunchStartTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _lunchStartTime = time;
                                    });
                                  }
                                },
                                child: Text(_lunchStartTime?.format(context) ?? 'Choose Time'),
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
                                  hintText: _lunchEndTime?.format(context) ?? 'Choose Time',
                                ),
                                onTap: () async {
                                  final TimeOfDay? time = await showTimePicker(
                                    context: context,
                                    initialTime: _lunchEndTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _lunchEndTime = time;
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (_lunchStartTime != null && _lunchEndTime != null) {
                                    final now = DateTime.now();
                                    final start = DateTime(now.year, now.month, now.day, _lunchStartTime!.hour, _lunchStartTime!.minute);
                                    final end = DateTime(now.year, now.month, now.day, _lunchEndTime!.hour, _lunchEndTime!.minute);
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
                    const Text('Minimum Break Time', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                _minBreakTime = Duration(hours: time.hour, minutes: time.minute);
                              });
                            }
                          },
                          child: const Text('Choose Time'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text('Enforce Brushing Teeth After Lunch', style: TextStyle(fontWeight: FontWeight.bold)),
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

