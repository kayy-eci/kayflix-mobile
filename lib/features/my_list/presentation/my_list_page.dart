import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/movie_grid.dart';
import '../../../core/widgets/state_views.dart';
import '../../movies/presentation/movie_providers.dart';
import '../../my_list/presentation/my_list_controller.dart';

class MyListPage extends ConsumerWidget {
  const MyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(moviesProvider);
    final myListAsync = ref.watch(myListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Saya'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: 'Cari film',
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: moviesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(
          message: error is Exception
              ? error.toString().replaceFirst('ApiException: ', '')
              : 'Gagal memuat daftar film.',
          onRetry: () => ref.invalidate(moviesProvider),
        ),
        data: (movies) {
          if (myListAsync.isLoading) return const LoadingView();

          final ids = myListAsync.value ?? const <int>{};
          final saved = movies
              .where((movie) => ids.contains(movie.id))
              .toList(growable: false);

          if (saved.isEmpty) {
            return EmptyStateView(
              icon: Icons.bookmark_border,
              title: 'Daftar Saya masih kosong',
              message:
                  'Tekan tombol "Daftar Saya" pada halaman film untuk menyimpannya di sini.',
              actionLabel: 'Jelajahi film',
              onAction: () => context.go('/home'),
            );
          }

          return MovieGrid(
            movies: saved,
            inList: ids,
            onTap: (movie) => context.push('/movie/${movie.id}'),
            header: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                '${saved.length} judul tersimpan',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
