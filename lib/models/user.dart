// lib/models/user.dart
class User {
  final String id;
  final String username;
  final String role;
  final String? token; // Make token nullable

  User({
    required this.id,
    required this.username,
    required this.role,
    this.token, // Make token optional
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // FIXED: Handle both 'id' and '_id' for MongoDB/backend compatibility
    final userId = json['id'] ?? json['_id'];
    final idStr = userId?.toString() ?? '';
    if (idStr.isEmpty) {
      print('Warning: User JSON missing valid id/_id. Response: $json');
    }

    return User(
      id: idStr,
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      token: json['token'] as String?, // Handle nullable token
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      if (token != null) 'token': token, // Only include token if not null
    };
  }
}
