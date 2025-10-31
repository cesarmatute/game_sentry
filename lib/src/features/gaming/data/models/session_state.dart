import 'package:equatable/equatable.dart';
import 'package:game_sentry/src/features/kids/data/models/kid.dart';

class SessionState extends Equatable {
  final Kid kid;
  final bool isActive;
  final Duration dailyTimeUsed;
  final Duration timeUntilBreak;
  final Duration dailyTimeRemaining;
  final bool breakWarning;
  final Duration currentSessionTime;
  final bool canStart;
  final String? validationMessage;
  final int sessionPlayed; // Added sessionPlayed

  const SessionState({
    required this.kid,
    this.isActive = false,
    this.dailyTimeUsed = Duration.zero,
    this.timeUntilBreak = Duration.zero,
    this.dailyTimeRemaining = Duration.zero,
    this.breakWarning = false,
    this.currentSessionTime = Duration.zero,
    this.canStart = true,
    this.validationMessage,
    this.sessionPlayed = 0, // Added sessionPlayed
  });

  SessionState copyWith({
    Kid? kid,
    bool? isActive,
    Duration? dailyTimeUsed,
    Duration? timeUntilBreak,
    Duration? dailyTimeRemaining,
    bool? breakWarning,
    Duration? currentSessionTime,
    bool? canStart,
    String? validationMessage,
    int? sessionPlayed, // Added sessionPlayed
  }) {
    return SessionState(
      kid: kid ?? this.kid,
      isActive: isActive ?? this.isActive,
      dailyTimeUsed: dailyTimeUsed ?? this.dailyTimeUsed,
      timeUntilBreak: timeUntilBreak ?? this.timeUntilBreak,
      dailyTimeRemaining: dailyTimeRemaining ?? this.dailyTimeRemaining,
      breakWarning: breakWarning ?? this.breakWarning,
      currentSessionTime: currentSessionTime ?? this.currentSessionTime,
      canStart: canStart ?? this.canStart,
      validationMessage: validationMessage ?? this.validationMessage,
      sessionPlayed: sessionPlayed ?? this.sessionPlayed, // Added sessionPlayed
    );
  }

  @override
  List<Object?> get props => [
        kid,
        isActive,
        dailyTimeUsed,
        timeUntilBreak,
        dailyTimeRemaining,
        breakWarning,
        currentSessionTime,
        canStart,
        validationMessage,
        sessionPlayed, // Added sessionPlayed
      ];
}