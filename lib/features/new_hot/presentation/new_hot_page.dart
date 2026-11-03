import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/movie_art.dart';
import '../../../core/widgets/state_views.dart';
import '../../movies/domain/movie.dart';
import '../../movies/presentation/movie_providers.dart';
import '../../my_list/presentation/my_list_controller.dart';

class NewHotPage extends ConsumerWidget {
  const NewHotPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(moviesProvider);
    final myList = ref.watch(myListProvider).value ?? const <int>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Baru & Populer'),
        backgroundColor: AppColors.background,
      ),
      body: RefreshIndicator(
        color: AppColors.red,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          ref.invalidate(moviesProvider);
          try {
            await ref.read(moviesProvider.future);
          } catch (_) {}
        },
        child: moviesAsync.when(
          loading: () => const LoadingView(label: 'Memuat judul terbaru...'),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.6,
                child: ErrorStateView(
                  message: error is Exception
                      ? error.toString().replaceFirst('ApiException: ', '')
                      : 'Gagal memuat katalog.',
                  onRetry: () => ref.invalidate(moviesProvider),
                ),
              ),
            ],
          ),
          data: (movies) {
            if (movies.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyStateView(
                    title: 'Belum ada judul',
                    message: 'Nanti akan muncul film terbaru di sini.',
                  ),
                ],
              );
            }

            final sorted = List<Movie>.of(movies)
              ..sort((a, b) => b.year.compareTo(a.year));

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: sorted.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      '10 teratas di Kayflix hari ini',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                final movie = sorted[index - 1];
                return _RankedTile(
                  rank: index,
                  movie: movie,
                  inList: myList.contains(movie.id),
                  onTap: () => context.push('/movie/${movie.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _RankedTile extends StatelessWidget {
  const _RankedTile({
    required this.rank,
    required this.movie,
    required this.inList,
    required this.onTap,
  });

  final int rank;
  final Movie movie;
  final bool inList;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: rank >= 10 ? 38 : 46,
                height: 1,
                fontWeight: FontWeight.w900,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = const Color(0xFF6E6E6E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: GradientPoster(
                seed: movie.id,
                title: movie.title,
                showTitle: false,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${movie.yearLabel} • ${movie.duration}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    RatingBadge(rating: movie.rating),
                    const SizedBox(width: 8),
                    if (inList)
                      const Icon(
                        Icons.bookmark,
                        size: 14,
                        color: AppColors.red,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
