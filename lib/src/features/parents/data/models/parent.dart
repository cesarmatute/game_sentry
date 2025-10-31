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
  final int pin;
  final DateTime? pinCreated;

  const Parent({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.dob,
    this.avatarUrl,
    this.kids,
    this.pin = 0,
    this.pinCreated,
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
      pin: document.data['pin'] as int? ?? 0,
      pinCreated: document.data['pin_created'] != null ? DateTime.parse(document.data['pin_created'] as String) : null,
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
      pin: prefs['pin'] as int? ?? 0,
      pinCreated: prefs['pin_created'] != null ? DateTime.parse(prefs['pin_created'] as String) : null,
    );
  }

  Parent copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    DateTime? dob,
    String? avatarUrl,
    List<String>? kids,
    int? pin,
    DateTime? pinCreated,
  }) {
    return Parent(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      kids: kids ?? this.kids,
      pin: pin ?? this.pin,
      pinCreated: pinCreated ?? this.pinCreated,
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
        pin,
        pinCreated,
      ];
}