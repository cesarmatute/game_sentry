
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/kids/data/models/kid.dart';

final selectedKidProvider = NotifierProvider<SelectedKidNotifier, Kid?>(SelectedKidNotifier.new);

class SelectedKidNotifier extends Notifier<Kid?> {
  @override
  Kid? build() {
    return null; // Initially no kid is selected
  }
  
  set kid(Kid? value) {
    state = value;
  }
}
