import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Thin wrapper around Dio that adds the bearer token, maps errors to
/// [ApiException] and notifies the session layer when a token is rejected.
class ApiClient {
  ApiClient({
    required this.tokenStorage,
    String? baseUrl,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 25),
        headers: const {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage tokenStorage;
  late final Dio _dio;

  /// Set by the session provider.
  void Function()? onUnauthorized;

  Dio get dio => _dio;

  void close() => _dio.close(force: true);

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) {
    return _request(() => _dio.get<dynamic>(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> post(String path, {Object? data}) {
    return _request(() => _dio.post<dynamic>(path, data: data));
  }

  Future<Map<String, dynamic>> put(String path, {Object? data}) {
    return _request(() => _dio.put<dynamic>(path, data: data));
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _request(() => _dio.delete<dynamic>(path));
  }

  Future<Map<String, dynamic>> upload(String path, FormData formData) {
    return _request(() => _dio.post<dynamic>(path, data: formData));
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() run,
  ) async {
    try {
      final response = await run();
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'data': data};
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ApiException _mapError(DioException error) {
    final response = error.response;

    if (response == null) {
      final isTimeout = error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;

      if (isTimeout) {
        return const ApiException(
          'Server terlalu lama merespons. Coba lagi sebentar.',
        );
      }

      return ApiException(
        'Tidak dapat terhubung ke ${_dio.options.baseUrl}. '
        'Pastikan backend berjalan dan perangkat berada di jaringan yang sama.',
      );
    }

    final status = response.statusCode;
    final body = response.data;

    var message = _defaultMessage(status);
    final details = <String>[];

    if (body is Map) {
      final backendMessage = body['message'];
      if (backendMessage is String && backendMessage.trim().isNotEmpty) {
        message = backendMessage;
      }

      final errors = body['errors'];
      if (errors is List) {
        for (final item in errors) {
          if (item is Map && item['message'] is String) {
            details.add(item['message'] as String);
          }
        }
      }
    }

    return ApiException(message, statusCode: status, details: details);
  }

  String _defaultMessage(int? status) {
    switch (status) {
      case 400:
        return 'Data yang dikirim tidak valid.';
      case 401:
        return 'Sesi kamu sudah berakhir. Silakan masuk kembali.';
      case 403:
        return 'Kamu tidak punya akses untuk aksi ini.';
      case 404:
        return 'Data tidak ditemukan.';
      case 409:
        return 'Data sudah digunakan.';
      default:
        return 'Terjadi kesalahan pada server.';
    }
  }
}
