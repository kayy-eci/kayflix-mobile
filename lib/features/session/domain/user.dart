/// Account data returned by `GET /api/profile` and friends.
class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.role,
  });

  final int id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final String? role;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: (json['username'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      profileImageUrl: _emptyToNull(json['profile_image_url'] as String?),
      role: _emptyToNull(json['role'] as String?),
    );
  }

  User copyWith({
    String? username,
    String? email,
    String? profileImageUrl,
    String? role,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
    );
  }

  String get initial {
    if (username.trim().isEmpty) return '?';
    return username.trim().substring(0, 1).toUpperCase();
  }

  static String? _emptyToNull(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}
