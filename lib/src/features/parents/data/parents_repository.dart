import 'package:appwrite/appwrite.dart';
import 'package:game_sentry/src/features/parents/data/models/parent.dart';

// Database ID from kids repository
const String databaseId = '68ac6bad003066ce8ae3'; 
// Actual parents collection ID from your Appwrite
const String parentsCollectionId = '68ac6bf700351706b986'; 

class ParentsRepository {
  final Client _client;
  late final Databases _databases;

  ParentsRepository(this._client) {
    _databases = Databases(_client);
  }

  Future<Parent> createParent({
    required String id,
    required String name,
    required String username,
    required String email,
    DateTime? dob,
    String? avatarUrl,
    List<String>? kids,
  }) async {
    try {
      // ignore: deprecated_member_use
      final response = await _databases.createDocument(
        databaseId: databaseId,
        collectionId: parentsCollectionId,
        documentId: id, // Use the user ID as the document ID
        data: {
          'name': name,
          'username': username.isNotEmpty ? username : name, // Use name as fallback if username is empty
          'email': email,
          'dob': dob?.toIso8601String(),
          'avatar_url': avatarUrl,
          'kids': kids,
        },
      );
      return Parent.fromDocument(response);
    } on AppwriteException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Parent> getParent(String parentId) async {
    try {
      // ignore: deprecated_member_use
      final response = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: parentsCollectionId,
        documentId: parentId,
      );
      return Parent.fromDocument(response);
    } on AppwriteException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Parent> updateParent({
    required String id,
    required String name,
    required String username,
    required String email,
    DateTime? dob,
    String? avatarUrl,
    List<String>? kids,
  }) async {
    try {
      // ignore: deprecated_member_use
      final response = await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: parentsCollectionId,
        documentId: id,
        data: {
          'name': name,
          'username': username.isNotEmpty ? username : name, // Use name as fallback if username is empty
          'email': email,
          'dob': dob?.toIso8601String(),
          'avatar_url': avatarUrl,
          'kids': kids,
        },
      );
      return Parent.fromDocument(response);
    } on AppwriteException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> addKidToParent(String parentId, String kidId) async {
    try {
      // Get the current parent document to preserve all existing data
      // ignore: deprecated_member_use
      final parent = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: parentsCollectionId,
        documentId: parentId,
      );
      
      // Get the existing kids list or create a new one
      final existingKids = List<String>.from(parent.data['kids'] ?? []);
      
      // Only add the kid if it's not already in the list
      if (!existingKids.contains(kidId)) {
        existingKids.add(kidId);
        
        // Update only the kids field, not the entire parent data
        // ignore: deprecated_member_use
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: parentsCollectionId,
          documentId: parentId,
          data: {
            'kids': existingKids,
          },
        );
      }
    } on AppwriteException {
      rethrow;
    }
  }
  
  Future<void> removeKidFromParent(String parentId, String kidId) async {
    try {
      // Get the current parent document to preserve all existing data
      // ignore: deprecated_member_use
      final parent = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: parentsCollectionId,
        documentId: parentId,
      );
      
      // Get the existing kids list or create a new one
      final existingKids = List<String>.from(parent.data['kids'] ?? []);
      
      // Only update if the kid is actually in the list
      if (existingKids.contains(kidId)) {
        existingKids.remove(kidId);
        
        // Update only the kids field, not the entire parent data
        // ignore: deprecated_member_use
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: parentsCollectionId,
          documentId: parentId,
          data: {
            'kids': existingKids,
          },
        );
      }
    } on AppwriteException {
      rethrow;
    }
  }

  Future<List<Parent>> getAllParents() async {
    try {
      // ignore: deprecated_member_use
      final response = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: parentsCollectionId,
        queries: [Query.limit(100)],
      );
      return response.documents.map((doc) => Parent.fromDocument(doc)).toList();
    } on AppwriteException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}