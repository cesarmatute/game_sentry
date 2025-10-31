class ParentModel {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? dob;
  final String? name;
  final String? updatedAt;

  ParentModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.dob,
    this.name,
    this.updatedAt,
  });

  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      id: map['\$id'],
      username: map['username'],
      email: map['email'],
      avatarUrl: map['avatar_url'],
      dob: map['dob'],
      name: map['name'],
      updatedAt: map['\$updatedAt'],
    );
  }

  Map<String, dynamic> toMap() => {
        '\$id': id,
        'username': username,
        'email': email,
        'avatar_url': avatarUrl,
        'dob': dob,
        'name': name,
        '\$updatedAt': updatedAt,
      };
}