import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/auth/presentation/screens/pin_login_screen.dart';
import 'package:game_sentry/src/features/settings/presentation/notifiers/theme_notifier.dart';
import 'package:game_sentry/src/features/settings/presentation/notifiers/system_tray_notifier.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:game_sentry/src/features/auth/presentation/screens/mobile_auth_screen.dart';

import 'package:local_notifier/local_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('cache');
  await localNotifier.setup(
    appName: 'game_sentry',
  );
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: const Size(400, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await trayManager.destroy();

    String iconPath = 'assets/images/logo/game_sentry_logo.png';

    await trayManager.setIcon(iconPath);

    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show',
        ),
        MenuItem(
          key: 'hide_window',
          label: 'Hide',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);

    trayManager.addListener(MyTrayListener());
  }

  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final systemTraySettings = ref.watch(systemTrayProvider);
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            if (systemTraySettings.enableSystemTray) {
              trayManager.setIcon('assets/images/logo/game_sentry_logo.png');
              if (systemTraySettings.minimizeToTrayOnClose) {
                windowManager.setPreventClose(true);
              } else {
                windowManager.setPreventClose(false);
              }
            } else {
              trayManager.destroy();
              windowManager.setPreventClose(false);
            }
          }
          return const MyApp();
        },
      ),
    ),
  );
}

class MyTrayListener extends TrayListener {
  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        windowManager.show();
        windowManager.focus();
        break;
      case 'hide_window':
        windowManager.hide();
        break;
      case 'exit_app':
        windowManager.destroy();
        break;
    }
  }
}

class MyApp extends ConsumerStatefulWidget { // Change to ConsumerStatefulWidget
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WindowListener { // Add WindowListener
  @override
  void initState() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
    }
    super.initState();
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final systemTraySettings = ref.read(systemTrayProvider);
      if (systemTraySettings.enableSystemTray && systemTraySettings.minimizeToTrayOnClose) {
        await windowManager.hide();
      } else {
        await windowManager.destroy();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);

    Widget getInitialScreen() {
      // Use Google Sign In on mobile platforms, PIN login on desktop
      if (Platform.isAndroid || Platform.isIOS) {
        return const MobileAuthScreen();
      } else {
        return const PinLoginScreen();
      }
    }

    return MaterialApp(
      title: 'Game Sentry',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: getInitialScreen(),
    );
  }
}