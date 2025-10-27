// lib/models/user.dart
class User {
  String id;
  String username;
  String role;
  String? token;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'role': role, 'token': token};
  }
}
