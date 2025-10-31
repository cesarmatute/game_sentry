import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/gaming/data/models/session_state.dart';
import 'package:game_sentry/src/features/kids/data/models/kid.dart';

// Define a custom provider that can handle different kids using a parameter approach
final gamingSessionNotifierProvider = 
    NotifierProvider<GamingSessionNotifier, SessionState?>(GamingSessionNotifier.new);

final gamingSessionForKidProvider = 
    Provider.family<SessionState?, String>((ref, kidId) {
  final globalState = ref.watch(gamingSessionNotifierProvider);
  // Return the state only if it matches the requested kid ID
  return globalState?.kid.id == kidId ? globalState : null;
});

class GamingSessionNotifier extends Notifier<SessionState?> {
  @override
  SessionState? build() {
    // Initialize with a default state
    return null;
  }
  
  void initializeWithKid(Kid kid) {
    state = SessionState(
      kid: kid,
      canStart: true,
    );
  }
  
  void updateKidData(Kid updatedKid) {
    if (state != null) {
      state = state!.copyWith(kid: updatedKid);
    }
  }
  
  Future<bool> startSession() async {
    if (state?.canStart == true) {
      state = state?.copyWith(isActive: true);
      return true;
    }
    return false;
  }
  
  Future<bool> stopSession() async {
    if (state?.isActive == true) {
      state = state?.copyWith(isActive: false);
      return true;
    }
    return false;
  }
  
  Future<void> setHasHadLunch(bool value) async {
    if (state != null) {
      state = state!.copyWith(
        kid: state!.kid.copyWith(hasHadLunchToday: value),
      );
    }
  }
  
  Future<void> setHasBrushedTeeth(bool value) async {
    if (state != null) {
      state = state!.copyWith(
        kid: state!.kid.copyWith(hasBrushedTeethAfterLunch: value),
      );
    }
  }
  
  bool shouldAskAboutLunch() {
    if (state != null) {
      return state!.kid.enforceLunchBreak && !state!.kid.hasHadLunchToday;
    }
    return false;
  }
  
  bool shouldAskAboutTeethBrushing() {
    if (state != null) {
      return state!.kid.enforceBrush && 
             state!.kid.hasHadLunchToday && 
             !state!.kid.hasBrushedTeethAfterLunch;
    }
    return false;
  }
}