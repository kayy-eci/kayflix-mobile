import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/movie_art.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../movies/domain/movie.dart';
import '../../movies/presentation/movie_providers.dart';
import '../../my_list/presentation/likes_controller.dart';
import '../../my_list/presentation/my_list_controller.dart';

class MovieDetailPage extends ConsumerWidget {
  const MovieDetailPage({super.key, required this.movieId});

  final int movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(moviesProvider);
    final movie = ref.watch(movieByIdProvider(movieId));

    if (movie == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: moviesAsync.isLoading
            ? const LoadingView()
            : const EmptyStateView(
                icon: Icons.movie_outlined,
                title: 'Film tidak ditemukan',
                message: 'Judul ini mungkin sudah dihapus dari katalog.',
              ),
      );
    }

    final inList = ref.watch(myListProvider).value?.contains(movie.id) ??
        false;
    final liked = ref.watch(likesProvider).value?.contains(movie.id) ??
        false;
    final similar = ref.watch(similarMoviesProvider(movie));
    final myList = ref.watch(myListProvider).value ?? const <int>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: false,
            backgroundColor: AppColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleButton(
                icon: Icons.arrow_back,
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _DetailHero(movie: movie),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${movie.matchPercent}% Match',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      RatingBadge(rating: movie.rating),
                      const SizedBox(width: 12),
                      Text(
                        movie.yearLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        movie.duration,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PlayButton(movie: movie),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ref
                              .read(myListProvider.notifier)
                              .toggle(movie.id),
                          icon: Icon(
                            inList
                                ? Icons.bookmark_added
                                : Icons.bookmark_add_outlined,
                            size: 19,
                          ),
                          label: Text(inList ? 'Tersimpan' : 'Daftar Saya'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        width: 54,
                        child: OutlinedButton(
                          onPressed: () =>
                              ref.read(likesProvider.notifier).toggle(movie.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                liked ? AppColors.red : Colors.white,
                            side: BorderSide(
                              color: liked
                                  ? AppColors.red
                                  : AppColors.border,
                            ),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Icon(
                            liked
                                ? Icons.thumb_up_rounded
                                : Icons.thumb_up_outlined,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final genre in movie.genreList)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            genre,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Tentang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${movie.title} adalah judul ${movie.genreList.join(', ')} '
                    'rilisan ${movie.yearLabel} dengan durasi ${movie.duration}. '
                    'Rating ${movie.rating}. Tonton sekarang di Kayflix.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Pemutar video masih berupa demo karena server belum menyediakan streaming.',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.9),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (similar.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Judul Serupa'),
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: similar.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = similar[index];
                        return MovieCard(
                          movie: item,
                          inList: myList.contains(item.id),
                          onTap: () => context.push('/movie/${item.id}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.posterGradientFor(movie.id),
          ),
        ),
        Positioned(
          top: -40,
          right: -30,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.background],
              stops: [0.35, 1],
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 16,
          child: Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.6,
              shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => context.push('/movie/${movie.id}/play'),
        icon: const Icon(Icons.play_arrow_rounded, size: 24),
        label: const Text('Mainkan'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 21, color: Colors.white),
        ),
      ),
    );
  }
}
