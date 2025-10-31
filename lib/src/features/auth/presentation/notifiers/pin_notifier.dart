import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/core/providers.dart';
import 'package:game_sentry/src/features/auth/data/pin_repository.dart';
import 'package:game_sentry/src/features/parents/data/parents_repository.dart';

class PinNotifier extends Notifier<PinState> {
  @override
  PinState build() {
    return PinState.initial();
  }

  PinRepository get _pinRepository => ref.read(pinRepositoryProvider);
  ParentsRepository get _parentsRepository => ref.read(parentsRepositoryProvider);

  Future<bool> verifyPin(String pinString) async {
    state = state.copyWith(status: PinStatus.verifying);
    
    try {
      // Validate that the pin is a valid 6-digit number
      if (!_pinRepository.validatePin(pinString)) {
        state = state.copyWith(status: PinStatus.error, errorMessage: 'Invalid PIN format');
        return false;
      }
      
      // Convert string to integer
      final pin = int.tryParse(pinString) ?? -1;
      
      // Search for parent with matching PIN in the database
      // ignore: deprecated_member_use
      final parents = await _parentsRepository.getAllParents();
      final matchingParent = parents.firstWhere(
        (parent) => parent.pin == pin,
        orElse: () => throw Exception('No parent found with this PIN'),
      );
      
      // PIN is valid and we found the parent
      state = state.copyWith(status: PinStatus.verified);
      return true;
    } on Exception catch (e) {
      // No parent found with this PIN
      state = state.copyWith(status: PinStatus.error, errorMessage: 'Invalid PIN');
      return false;
    } catch (e) {
      state = state.copyWith(status: PinStatus.error, errorMessage: 'Verification failed');
      return false;
    }
  }
  
  void clearError() {
    if (state.status == PinStatus.error) {
      state = state.copyWith(status: PinStatus.idle, errorMessage: null);
    }
  }
  
  // Method to find a parent by PIN for authentication purposes
  Future<String?> getParentIdByPin(int pin) async {
    try {
      // Search for parent with matching PIN in the database
      // ignore: deprecated_member_use
      final parents = await _parentsRepository.getAllParents();
      final matchingParent = parents.firstWhere(
        (parent) => parent.pin == pin,
        orElse: () => throw Exception('No parent found with this PIN'),
      );
      
      return matchingParent.id;
    } on Exception catch (e) {
      return null;
    }
  }
}

final pinNotifierProvider = NotifierProvider<PinNotifier, PinState>(PinNotifier.new);

enum PinStatus { idle, verifying, verified, error }

class PinState {
  final PinStatus status;
  final String? errorMessage;

  const PinState({
    required this.status,
    this.errorMessage,
  });

  factory PinState.initial() {
    return const PinState(status: PinStatus.idle);
  }

  PinState copyWith({
    PinStatus? status,
    String? errorMessage,
  }) {
    return PinState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}