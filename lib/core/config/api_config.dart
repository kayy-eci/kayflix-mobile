/// Central place for the backend location.
///
/// The default points at the dev tunnel that forwards to the Express backend
/// on port 8000, so emulator, simulator, web and physical devices all reach
/// the same server without a per-platform host.
///
/// Override it for a different backend (lan, localhost, another tunnel)
/// without editing this file:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000`
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Dev tunnel forwarding to the Kayflix Express API.
  static const String _tunnel = 'https://hfvwgq71-8000.asse.devtunnels.ms';

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return _tunnel;
  }
}