import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../session/presentation/session_controller.dart';

/// Likes have no backend support either, so they are stored per user on device.
final likesProvider =
    AsyncNotifierProvider<LikesController, Set<int>>(LikesController.new);

class LikesController extends AsyncNotifier<Set<int>> {
  static const String _prefix = 'kayflix.likes.';

  @override
  Future<Set<int>> build() async {
    final session = ref.watch(sessionControllerProvider).value;
    final userId = session?.user.id ?? 0;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('$_prefix$userId') ?? const <String>[];
    return stored.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> toggle(int movieId) async {
    final current = <int>{...?state.value};
    if (!current.remove(movieId)) {
      current.add(movieId);
    }
    state = AsyncData(current);

    final session = ref.read(sessionControllerProvider).value;
    final userId = session?.user.id ?? 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_prefix$userId',
      current.map((id) => id.toString()).toList(),
    );
  }
}
