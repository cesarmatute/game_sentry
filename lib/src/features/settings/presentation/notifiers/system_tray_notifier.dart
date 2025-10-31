import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemTraySettings {
  final bool enableSystemTray;
  final bool minimizeToTrayOnClose;

  const SystemTraySettings({
    required this.enableSystemTray,
    required this.minimizeToTrayOnClose,
  });

  SystemTraySettings copyWith({
    bool? enableSystemTray,
    bool? minimizeToTrayOnClose,
  }) {
    return SystemTraySettings(
      enableSystemTray: enableSystemTray ?? this.enableSystemTray,
      minimizeToTrayOnClose: minimizeToTrayOnClose ?? this.minimizeToTrayOnClose,
    );
  }
}

final systemTrayProvider = NotifierProvider<SystemTrayNotifier, SystemTraySettings>(SystemTrayNotifier.new);

class SystemTrayNotifier extends Notifier<SystemTraySettings> {
  @override
  SystemTraySettings build() {
    Future.microtask(_loadSystemTraySettings);
    return const SystemTraySettings(enableSystemTray: true, minimizeToTrayOnClose: true);
  }

  Future<void> _loadSystemTraySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enableSystemTray = prefs.getBool('enableSystemTray') ?? true;
    final minimizeToTrayOnClose = prefs.getBool('minimizeToTrayOnClose') ?? true;
    state = SystemTraySettings(
      enableSystemTray: enableSystemTray,
      minimizeToTrayOnClose: minimizeToTrayOnClose,
    );
  }

  Future<void> setEnableSystemTray(bool enabled) async {
    state = state.copyWith(enableSystemTray: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableSystemTray', enabled);
  }

  Future<void> setMinimizeToTrayOnClose(bool enabled) async {
    state = state.copyWith(minimizeToTrayOnClose: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('minimizeToTrayOnClose', enabled);
  }
}