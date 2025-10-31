import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundSettings {
  final bool enableSoundNotifications;

  const SoundSettings({
    required this.enableSoundNotifications,
  });

  SoundSettings copyWith({
    bool? enableSoundNotifications,
  }) {
    return SoundSettings(
      enableSoundNotifications: enableSoundNotifications ?? this.enableSoundNotifications,
    );
  }
}

final soundProvider = NotifierProvider<SoundNotifier, SoundSettings>(SoundNotifier.new);

class SoundNotifier extends Notifier<SoundSettings> {
  @override
  SoundSettings build() {
    Future.microtask(_loadSoundSettings);
    return const SoundSettings(enableSoundNotifications: true);
  }

  Future<void> _loadSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enableSoundNotifications = prefs.getBool('enableSoundNotifications') ?? true;
    state = SoundSettings(
      enableSoundNotifications: enableSoundNotifications,
    );
  }

  Future<void> setEnableSoundNotifications(bool enabled) async {
    state = state.copyWith(enableSoundNotifications: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableSoundNotifications', enabled);
  }
}