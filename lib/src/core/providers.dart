import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/core/appwrite_client.dart';
import 'package:game_sentry/src/core/storage_service.dart';
import 'package:game_sentry/src/features/auth/data/pin_repository.dart';
import 'package:game_sentry/src/features/kids/data/kids_repository.dart';
import 'package:game_sentry/src/features/parents/data/parents_repository.dart';

final appwriteClientProvider = Provider<Client>((ref) {
  return client;
});

final pinRepositoryProvider = Provider<PinRepository>((ref) {
  return PinRepository();
});

final parentsRepositoryProvider = Provider<ParentsRepository>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return ParentsRepository(client);
});

final kidsRepositoryProvider = Provider<KidsRepository>((ref) {
  final client = ref.watch(appwriteClientProvider);
  final parentsRepository = ref.watch(parentsRepositoryProvider);
  return KidsRepository(client, parentsRepository);
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return StorageService(client);
});