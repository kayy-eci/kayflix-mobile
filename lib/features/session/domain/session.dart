import 'user.dart';

/// An authenticated session: the JWT plus the account it belongs to.
class Session {
  const Session({
    required this.token,
    required this.user,
    required this.role,
    this.expiresAt,
  });

  final String token;
  final User user;
  final String role;
  final DateTime? expiresAt;

  bool get isAdmin => role == 'admin';

  Session copyWith({User? user}) {
    return Session(
      token: token,
      user: user ?? this.user,
      role: role,
      expiresAt: expiresAt,
    );
  }
}
