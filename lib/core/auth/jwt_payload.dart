import 'dart:convert';

/// The subset of the JWT payload the backend issues.
///
/// The backend signs `{ id, email, role, jti }` with a one hour expiry.
class JwtPayload {
  const JwtPayload({
    this.id,
    this.email,
    this.role,
    this.expiresAt,
  });

  final int? id;
  final String? email;
  final String? role;
  final DateTime? expiresAt;

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    // Treat a token that expires within the next 30 seconds as expired.
    return exp.isBefore(DateTime.now().add(const Duration(seconds: 30)));
  }

  static JwtPayload? tryParse(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded);
      if (map is! Map<String, dynamic>) return null;

      final exp = map['exp'];
      return JwtPayload(
        id: (map['id'] as num?)?.toInt(),
        email: map['email'] as String?,
        role: map['role'] as String?,
        expiresAt: exp is num
            ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000)
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}
