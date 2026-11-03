import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/jwt_payload.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/session_repository.dart';
import '../domain/session.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
  client.onUnauthorized = () {
    // Deferred: a 401 can happen while the session itself is loading.
    ref.read(sessionControllerProvider.notifier).forceLogout();
  };
  ref.onDispose(client.close);
  return client;
});

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(apiClientProvider)),
);

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, Session?>(SessionController.new);

class SessionController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.read();
    if (token == null) return null;

    final payload = JwtPayload.tryParse(token);
    if (payload == null || payload.isExpired) {
      await storage.clear();
      return null;
    }

    try {
      final user = await ref.read(sessionRepositoryProvider).fetchProfile();
      return Session(
        token: token,
        user: user,
        role: payload.role ?? user.role ?? 'user',
        expiresAt: payload.expiresAt,
      );
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await storage.clear();
        return null;
      }
      rethrow;
    }
  }

  /// Throws on failure so the login form can display the message.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final repository = ref.read(sessionRepositoryProvider);
    final storage = ref.read(tokenStorageProvider);

    final token = await repository.login(email: email, password: password);
    await storage.write(token);

    try {
      final payload = JwtPayload.tryParse(token);
      final user = await repository.fetchProfile();

      state = AsyncData(
        Session(
          token: token,
          user: user,
          role: payload?.role ?? user.role ?? 'user',
          expiresAt: payload?.expiresAt,
        ),
      );
    } catch (_) {
      await storage.clear();
      rethrow;
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) {
    return ref.read(sessionRepositoryProvider).register(
          username: username,
          email: email,
          password: password,
        );
  }

  Future<void> refreshProfile() async {
    final current = state.value;
    if (current == null) return;

    try {
      final user = await ref.read(sessionRepositoryProvider).fetchProfile();
      state = AsyncData(current.copyWith(user: user));
    } catch (_) {
      // Keep the cached profile; the next explicit refresh will retry.
    }
  }

  Future<void> updateProfile({
    required String username,
    required String email,
    required String password,
  }) async {
    final current = state.value;
    if (current == null) {
      throw const ApiException('Sesi tidak ditemukan. Silakan masuk kembali.');
    }

    await ref.read(sessionRepositoryProvider).updateUser(
          id: current.user.id,
          username: username,
          email: email,
          password: password,
        );
    await refreshProfile();
  }

  Future<void> uploadAvatar({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final current = state.value;
    if (current == null) {
      throw const ApiException('Sesi tidak ditemukan. Silakan masuk kembali.');
    }

    await ref.read(sessionRepositoryProvider).uploadAvatar(
          id: current.user.id,
          bytes: bytes,
          filename: filename,
          mimeType: mimeType,
        );
    await refreshProfile();
  }

  Future<void> deleteAccount() async {
    final current = state.value;
    if (current == null) return;

    await ref.read(sessionRepositoryProvider).deleteAccount(current.user.id);
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }

  Future<void> signOut() async {
    await ref.read(sessionRepositoryProvider).logout();
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }

  void forceLogout() {
    Future<void>.microtask(() async {
      if (!ref.mounted) return;
      await ref.read(tokenStorageProvider).clear();
      if (!ref.mounted) return;
      state = const AsyncData(null);
    });
  }
}
