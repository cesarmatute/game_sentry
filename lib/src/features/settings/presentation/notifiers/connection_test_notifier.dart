import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/core/providers.dart';

enum ConnectionStatus { initial, loading, success, error }

final connectionTestNotifierProvider = NotifierProvider<ConnectionTestNotifier, ConnectionStatus>(ConnectionTestNotifier.new);

class ConnectionTestNotifier extends Notifier<ConnectionStatus> {
  @override
  ConnectionStatus build() {
    return ConnectionStatus.initial;
  }

  Client get _client => ref.read(appwriteClientProvider);

  Future<void> testConnection() async {
    state = ConnectionStatus.loading;
    try {
      final account = Account(_client);
      await account.get();
      state = ConnectionStatus.success;
    } catch (e) {
      state = ConnectionStatus.error;
    }
  }
}
