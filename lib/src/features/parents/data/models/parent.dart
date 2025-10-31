import 'package:appwrite/models.dart';
import 'package:equatable/equatable.dart';

class Parent extends Equatable {
  final String id;
  final String name;
  final String username;
  final String email;
  final DateTime? dob;
  final String? avatarUrl;
  final List<String>? kids;

  const Parent({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.dob,
    this.avatarUrl,
    this.kids,
  });

  factory Parent.fromDocument(Document document) {
    return Parent(
      id: document.$id,
      name: document.data['name'] as String? ?? '',
      username: document.data['username'] as String? ?? '',
      email: document.data['email'] as String? ?? '',
      dob: document.data['dob'] != null ? DateTime.parse(document.data['dob'] as String) : null,
      avatarUrl: document.data['avatar_url'] as String?,
      kids: document.data['kids'] != null ? List<String>.from(document.data['kids']) : null,
    );
  }

  factory Parent.fromUser(String userId, Map<String, dynamic> prefs, String email) {
    return Parent(
      id: userId,
      name: prefs['name'] as String? ?? '',
      username: prefs['username'] as String? ?? '',
      email: email,
      dob: prefs['dob'] != null ? DateTime.parse(prefs['dob'] as String) : null,
      avatarUrl: prefs['avatar_url'] as String?,
      kids: prefs['kids'] != null ? List<String>.from(prefs['kids']) : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        email,
        dob,
        avatarUrl,
        kids,
      ];
}