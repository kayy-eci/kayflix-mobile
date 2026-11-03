/// A user-presentable error raised by the API layer.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.details = const [],
  });

  final String message;
  final int? statusCode;

  /// Extra messages from the backend (for example Zod issues).
  final List<String> details;

  bool get isUnauthorized => statusCode == 401;

  /// Prefer a field level message when the backend sends one.
  String get userMessage {
    if (details.isNotEmpty) return details.first;
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
