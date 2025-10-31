
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import '../../../settings/presentation/notifiers/sound_notifier.dart';

class TimerState {
  final Duration duration;
  final bool isRunning;

  const TimerState({required this.duration, required this.isRunning});
}

class TimerNotifier extends Notifier<TimerState> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  TimerState build() {
    ref.onDispose(() {
      _stopwatch.stop();
      _timer?.cancel();
      _audioPlayer.dispose();
    });
    
    return const TimerState(duration: Duration.zero, isRunning: false);
  }

  void start() async {
    if (!state.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        state = TimerState(duration: _stopwatch.elapsed, isRunning: true);
      });
      state = TimerState(duration: _stopwatch.elapsed, isRunning: true);

      // Play start sound if enabled
      final soundSettings = ref.read(soundProvider);
      if (soundSettings.enableSoundNotifications) {
        await _audioPlayer.play(AssetSource('sounds/start.wav'));
      }

      LocalNotification notification = LocalNotification(
        title: 'Timer Started',
        body: 'The timer has started.',
      );
      notification.show();
    }
  }

  void stop() async {
    if (state.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
      state = TimerState(duration: _stopwatch.elapsed, isRunning: false);

      // Play stop sound if enabled
      final soundSettings = ref.read(soundProvider);
      if (soundSettings.enableSoundNotifications) {
        await _audioPlayer.play(AssetSource('sounds/stop.wav'));
      }

      LocalNotification notification = LocalNotification(
        title: 'Timer Stopped',
        body: 'The timer has stopped.',
      );
      notification.show();
    }
  }

  void reset() async {
    _stopwatch.reset();
    state = TimerState(duration: Duration.zero, isRunning: false);

    // Play stop sound when resetting if enabled
    final soundSettings = ref.read(soundProvider);
    if (soundSettings.enableSoundNotifications) {
      await _audioPlayer.play(AssetSource('sounds/stop.wav'));
    }
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(TimerNotifier.new);
