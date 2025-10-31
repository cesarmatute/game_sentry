import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/core/providers.dart';
import 'package:game_sentry/src/features/kids/data/models/kid.dart';
import 'package:game_sentry/src/features/parents/data/parents_repository.dart';

const String databaseId = '68ac6bad003066ce8ae3';
const String kidsCollectionId = '68ac6f6200015002985b';

final kidsListProvider = FutureProvider.family<List<Kid>, String>((ref, parentId) async {
  final kidsRepository = ref.watch(kidsRepositoryProvider);
  return kidsRepository.getKids(parentId);
});

final kidProvider = FutureProvider.family<Kid, String>((ref, kidId) async {
  final kidsRepository = ref.watch(kidsRepositoryProvider);
  return kidsRepository.getKid(kidId);
});

class KidsRepository {
  final Client _client;
  late final Databases _databases;

  KidsRepository(this._client, ParentsRepository parentsRepository) {
    _databases = Databases(_client);
  }

  Future<List<Kid>> getKids(String parentId) async {
    try {
      // ignore: deprecated_member_use
      final response = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        queries: [
          Query.equal('parent_id', parentId),
        ],
      );
      return response.documents.map((doc) => Kid.fromDocument(doc)).toList();
    } on AppwriteException {
      rethrow;
    }
  }

  Future<Kid> getKid(String kidId) async {
    try {
      // ignore: deprecated_member_use
      final document = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
      );
      return Kid.fromDocument(document);
    } on AppwriteException {
      rethrow;
    }
  }

  Future<void> addKid({
    required String parentId,
    required String username,
    DateTime? dob,
    String? avatarUrl,
    required int maxDailyPlaytime,
    required int maxSessionLimit,
    required int minBreakTime,
    required String? playtimeStart,
    required String? playtimeEnd,
    required String? lunchBreakStart,
    required String? lunchBreakEnd,
    required bool enforceBrush,
    required bool enforceLunchBreak,
  }) async {
    try {
      // ignore: deprecated_member_use
      await _databases.createDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: ID.unique(),
        data: {
          'parent_id': parentId,
          'username': username,
          'dob': dob != null ? '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}' : null,
          'avatar_url': avatarUrl,
          'has_pin': false, // Add missing has_pin field with default value
          'maximum_daily_limit': maxDailyPlaytime,
          'maximum_session_limit': maxSessionLimit,
          'minimum_break': minBreakTime,
          'playtime_start': playtimeStart,
          'playtime_end': playtimeEnd,
          'lunch_break_start': lunchBreakStart,
          'lunch_break_end': lunchBreakEnd,
          'enforce_brush': enforceBrush,
          'enforce_lunch_break': enforceLunchBreak,
          'daily_played': 0, // Initialize daily played minutes with 0
          'last_date_played': null, // Initialize as null
          'session_played': 0, // Initialize session played minutes with 0
          'last_break_time': null, // Initialize as null
          'last_mandatory_break': null, // Initialize as null
          'banked_time': 0, // Initialize with 0 banked time
          'max_banked_time': 2, // Default max banked time (2 hours)
          'has_had_lunch_today': false,
          'has_brushed_teeth_after_lunch': false,
        },
      );

      // DISABLE parent update to prevent orphan kids issue
      // The parent update was causing existing kids to lose their parent_id
      // We'll track kid count through direct database queries instead
      // await _parentsRepository.addKidToParent(parentId, newKid.$id);
    } on AppwriteException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteKid(String kidId) async {
    try {
      // ignore: deprecated_member_use
      await _databases.deleteDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
      );

      // DISABLE parent update to prevent relationship conflicts
      // The parent update was causing issues with kid relationships
      // await _parentsRepository.removeKidFromParent(parentId, kidId);
    } on AppwriteException {
      rethrow;
    }
  }

  Future<void> updateKid({
    required String kidId,
    required String username,
    DateTime? dob,
    String? avatarUrl,
    required int maxDailyPlaytime,
    required int maxSessionLimit,
    required int minBreakTime,
    required String? playtimeStart,
    required String? playtimeEnd,
    required String? lunchBreakStart,
    required String? lunchBreakEnd,
    required bool enforceBrush,
    required bool enforceLunchBreak,
  }) async {
    try {
      // First, get the current kid document to preserve the parent_id
      // ignore: deprecated_member_use
      final currentKid = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
      );
      
      final parentId = currentKid.data['parent_id'] as String? ?? '';
      
      // ignore: deprecated_member_use
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
        data: {
          'parent_id': parentId,
          'username': username,
          'dob': dob != null ? '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}' : null,
          'avatar_url': avatarUrl,
          'has_pin': currentKid.data['has_pin'] as bool? ?? false,
          'maximum_daily_limit': maxDailyPlaytime,
          'maximum_session_limit': maxSessionLimit,
          'minimum_break': minBreakTime,
          'playtime_start': playtimeStart,
          'playtime_end': playtimeEnd,
          'lunch_break_start': lunchBreakStart,
          'lunch_break_end': lunchBreakEnd,
          'enforce_brush': enforceBrush,
          'enforce_lunch_break': enforceLunchBreak,
          'daily_played': currentKid.data['daily_played'] as int? ?? 0, // Preserve existing daily played time
          'last_date_played': currentKid.data['last_date_played'], // Preserve existing last date played
          'session_played': currentKid.data['session_played'] as int? ?? 0, // Preserve existing session played time
          'last_break_time': currentKid.data['last_break_time'], // Preserve existing last break time
          'last_mandatory_break': currentKid.data['last_mandatory_break'], // Preserve existing last mandatory break
        },
      );
    } on AppwriteException {
      rethrow;
    }
  }

  Future<void> updateLastMandatoryBreak(String kidId, DateTime timestamp) async {
    try {
      // ignore: deprecated_member_use
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
        data: {
          'last_mandatory_break': timestamp.toIso8601String(),
        },
      );
    } on AppwriteException {
      rethrow;
    }
  }
  
  Future<void> updateDailyPlayed(String kidId, int dailyPlayed) async {
    try {
      // ignore: deprecated_member_use
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
        data: {
          'daily_played': dailyPlayed,
          'last_date_played': DateTime.now().toIso8601String(), // Update the date when daily playtime is updated
        },
      );
    } on AppwriteException {
      rethrow;
    }
  }
  
  Future<void> updateSessionPlayed(String kidId, int sessionPlayed) async {
    try {
      // ignore: deprecated_member_use
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
        data: {
          'session_played': sessionPlayed,
        },
      );
    } on AppwriteException {
      rethrow;
    }
  }
  
  Future<void> updateLastBreakTime(String kidId, DateTime breakTime) async {
    try {
      // ignore: deprecated_member_use
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
        data: {
          'last_break_time': breakTime.toIso8601String(),
        },
      );
    } on AppwriteException {
      rethrow;
    }
  }
  
  Future<void> updateBankedTime(String kidId, Duration bankedTime) async {
    try {
      // ignore: deprecated_member_use
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
        data: {
          'banked_time': bankedTime.inMinutes,
        },
      );
    } on AppwriteException {
      rethrow;
    }
  }
  
  Future<void> updateMaxBankedTime(String kidId, Duration maxBankedTime) async {
    try {
      // ignore: deprecated_member_use
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
        data: {
          'max_banked_time': maxBankedTime.inHours.toInt(),
        },
      );
    } on AppwriteException {
      rethrow;
    }
  }
  
  Future<void> updateHasHadLunchToday(String kidId, bool hasHadLunch) async {
    try {
      // ignore: deprecated_member_use
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
        data: {
          'has_had_lunch_today': hasHadLunch,
        },
      );
    } on AppwriteException catch (e) {
      // If the field doesn't exist in the database, ignore the error
      if (e.message != null && e.message!.contains('Unknown attribute')) {
        debugPrint('Skipping update of has_had_lunch_today - field not in database schema');
        return;
      }
      rethrow;
    }
  }
  
  Future<void> updateHasBrushedTeethAfterLunch(String kidId, bool hasBrushedTeeth) async {
    try {
      // ignore: deprecated_member_use
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
        data: {
          'has_brushed_teeth_after_lunch': hasBrushedTeeth,
        },
      );
    } on AppwriteException catch (e) {
      // If the field doesn't exist in the database, ignore the error
      if (e.message != null && e.message!.contains('Unknown attribute')) {
        debugPrint('Skipping update of has_brushed_teeth_after_lunch - field not in database schema');
        return;
      }
      rethrow;
    }
  }
  
  Future<void> resetDailyFlags(String kidId) async {
    try {
      // Reset daily flags at the start of a new day
      // ignore: deprecated_member_use
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: kidsCollectionId,
        documentId: kidId,
        data: {
          'has_had_lunch_today': false,
          'has_brushed_teeth_after_lunch': false,
        },
      );
    } on AppwriteException catch (e) {
      // If the fields don't exist in the database, ignore the error
      if (e.message != null && e.message!.contains('Unknown attribute')) {
        debugPrint('Skipping reset of daily flags - fields not in database schema');
        return;
      }
      rethrow;
    }
  }
  

}