import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../session/presentation/session_controller.dart';

/// My List has no backend support, so it lives on the device, scoped per user.
final myListProvider =
    AsyncNotifierProvider<MyListController, Set<int>>(MyListController.new);

class MyListController extends AsyncNotifier<Set<int>> {
  static const String _prefix = 'kayflix.mylist.';

  @override
  Future<Set<int>> build() async {
    final session = ref.watch(sessionControllerProvider).value;
    final userId = session?.user.id ?? 0;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('$_prefix$userId') ?? const <String>[];
    return stored.map(int.tryParse).whereType<int>().toSet();
  }

  bool contains(int movieId) => state.value?.contains(movieId) ?? false;

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
