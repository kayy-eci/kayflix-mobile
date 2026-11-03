import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/user.dart';

class SessionRepository {
  SessionRepository(this._api);

  final ApiClient _api;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/api/auth/login',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final token = response['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Server tidak mengirim token login.');
    }
    return token;
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _api.post(
      '/api/users',
      data: {
        'username': username.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
  }

  Future<User> fetchProfile() async {
    final response = await _api.get('/api/profile');
    final data = response['data'];
    if (data is Map) {
      return User.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('Format data profil tidak valid.');
  }

  Future<void> updateUser({
    required int id,
    required String username,
    required String email,
    required String password,
  }) async {
    await _api.put(
      '/api/users/$id',
      data: {
        'username': username.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
  }

  Future<String> uploadAvatar({
    required int id,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final form = FormData.fromMap({
      'profileImage': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    final response = await _api.upload('/api/users/$id/profile-image', form);
    final data = response['data'];
    if (data is Map && data['profileImageUrl'] is String) {
      return data['profileImageUrl'] as String;
    }
    throw const ApiException(
      'Upload berhasil tetapi server tidak mengirim URL gambar.',
    );
  }

  Future<void> deleteAccount(int id) async {
    await _api.delete('/api/users/$id');
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {
      // The backend logout is a no-op; never block sign-out on it.
    }
  }
}
