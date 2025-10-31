import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/core/providers.dart';
import 'package:game_sentry/src/features/gaming/data/models/gaming_session.dart';

const String databaseId = '68ac6bad003066ce8ae3';
const String gamingSessionsCollectionId = '68ac7472000987d8264b'; // Using existing sessions collection

final gamingSessionsRepositoryProvider = Provider<GamingSessionsRepository>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return GamingSessionsRepository(client);
});

class GamingSessionsRepository {
  final Client _client;
  late final Databases _databases;

  GamingSessionsRepository(this._client) {
    _databases = Databases(_client);
  }

  // Create a new gaming session
  Future<GamingSession> createSession({
    required String kidId,
    required TimeOfDay startTime,
  }) async {
    try {
      final now = DateTime.now();
      
      // ignore: deprecated_member_use
      final response = await _databases.createDocument(
        databaseId: databaseId,
        collectionId: gamingSessionsCollectionId,
        documentId: ID.unique(),
        data: {
          'kid_id': kidId,
          'status': true, // true = active session
          'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
          'stop_time': '',
          'duration': 0,
        },
      );
      final session = GamingSession.fromDocument(response);
      return session;
    } on AppwriteException {
      rethrow;
    }
  }

  // Update an existing gaming session
  Future<GamingSession> updateSession(GamingSession session) async {
    try {
      // ignore: deprecated_member_use
      final response = await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: gamingSessionsCollectionId,
        documentId: session.id,
        data: session.toMap(),
      );
      return GamingSession.fromDocument(response);
    } on AppwriteException {
      rethrow;
    }
  }

  // Get active session for a kid
  Future<GamingSession?> getActiveSession(String kidId) async {
    try {
      debugPrint('Querying active session for kid: $kidId');
      
      // ignore: deprecated_member_use
      final response = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: gamingSessionsCollectionId,
        queries: [
          Query.equal('kid_id', kidId),
          Query.equal('status', true), // true = active sessions
          Query.orderDesc('\$createdAt'),
          Query.limit(1),
        ],
      );
      
      debugPrint('Found ${response.documents.length} active sessions for kid: $kidId');
      
      if (response.documents.isEmpty) return null;
      final session = GamingSession.fromDocument(response.documents.first);
      debugPrint('Active session found: ${session.id}, status: ${session.status}');
      return session;
    } on AppwriteException catch (e) {
      debugPrint('Appwrite error getting active session: ${e.message}');
      rethrow;
    }
  }

  // Get sessions for a kid for a specific date
  Future<List<GamingSession>> getSessionsForDate(String kidId, DateTime date) async {
    try {
      // ignore: deprecated_member_use
      final response = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: gamingSessionsCollectionId,
        queries: [
          Query.equal('kid_id', kidId),
          Query.equal('date', '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
          Query.orderAsc('start_time'),
        ],
      );
      
      return response.documents.map((doc) => GamingSession.fromDocument(doc)).toList();
    } on AppwriteException {
      rethrow;
    }
  }

  // Get recent sessions for a kid (for break time calculation)
  Future<List<GamingSession>> getRecentSessions(String kidId, {int limit = 5}) async {
    try {
      // ignore: deprecated_member_use
      final response = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: gamingSessionsCollectionId,
        queries: [
          Query.equal('kid_id', kidId),
          Query.equal('status', false), // false = completed sessions
          Query.orderDesc('\$updatedAt'),
          Query.limit(limit),
        ],
      );
      
      return response.documents.map((doc) => GamingSession.fromDocument(doc)).toList();
    } on AppwriteException {
      rethrow;
    }
  }

  // Complete a gaming session
  Future<GamingSession> completeSession(String sessionId, Duration totalDuration) async {
    try {
      final now = DateTime.now();
      final stopTime = TimeOfDay.fromDateTime(now);
      
      // ignore: deprecated_member_use
      final response = await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: gamingSessionsCollectionId,
        documentId: sessionId,
        data: {
          'stop_time': '${stopTime.hour.toString().padLeft(2, '0')}:${stopTime.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
          'duration': totalDuration.inMinutes,
          'status': false, // false = completed session
        },
      );
      return GamingSession.fromDocument(response);
    } on AppwriteException {
      rethrow;
    }
  }

  // Delete a gaming session (admin function)
  Future<void> deleteSession(String sessionId) async {
    try {
      // ignore: deprecated_member_use
      await _databases.deleteDocument(
        databaseId: databaseId,
        collectionId: gamingSessionsCollectionId,
        documentId: sessionId,
      );
    } on AppwriteException {
      rethrow;
    }
  }

  // Calculate total time played today
  Future<Duration> getTodaysTotalTime(String kidId) async {
    final today = DateTime.now();
    final sessions = await getSessionsForDate(kidId, today);
    
    Duration totalTime = Duration.zero;
    for (final session in sessions) {
      if (session.status == SessionStatus.completed && session.duration != null) {
        totalTime += session.duration!;
      } else if (session.status == SessionStatus.active) {
        // Calculate current session time
        final now = DateTime.now();
        final sessionStartDateTime = session.fullStartDateTime;
        final currentDuration = now.difference(sessionStartDateTime);
        totalTime += currentDuration;
      }
    }
    
    return totalTime;
  }
}