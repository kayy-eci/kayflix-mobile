import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/movie_art.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../movies/domain/movie.dart';
import '../../movies/presentation/movie_providers.dart';
import '../../my_list/presentation/my_list_controller.dart';
import '../../session/presentation/session_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(moviesProvider);
    final myList = ref.watch(myListProvider).value ?? const <int>{};
    final isAdmin =
        ref.watch(sessionControllerProvider).value?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 16,
        title: const BrandLogo(fontSize: 24),
        actions: [
          IconButton(
            tooltip: 'Cari',
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search, size: 23),
          ),
          const SizedBox(width: 4),
        ],
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC000000), Colors.transparent],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.red,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          ref.invalidate(moviesProvider);
          try {
            await ref.read(moviesProvider.future);
          } catch (_) {
            // The error state is rendered from the provider.
          }
        },
        child: moviesAsync.when(
          loading: () => const BrowseSkeleton(),
          error: (error, _) => _FillScroll(
            child: ErrorStateView(
              message: error is Exception
                  ? error.toString().replaceFirst('ApiException: ', '')
                  : 'Gagal memuat katalog film.',
              onRetry: () => ref.invalidate(moviesProvider),
            ),
          ),
          data: (movies) => _HomeContent(
            movies: movies,
            myList: myList,
            isAdmin: isAdmin,
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.movies,
    required this.myList,
    required this.isAdmin,
  });

  final List<Movie> movies;
  final Set<int> myList;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight + 8;

    if (movies.isEmpty) {
      return _FillScroll(
        child: EmptyStateView(
          title: 'Katalog masih kosong',
          message: isAdmin
              ? 'Tambahkan film pertama lewat menu admin.'
              : 'Belum ada film yang tersedia. Coba lagi nanti.',
          actionLabel: isAdmin ? 'Kelola Film' : null,
          onAction: isAdmin ? () => context.push('/admin') : null,
        ),
      );
    }

    final hero = List<Movie>.of(movies)
      ..sort((a, b) => b.year.compareTo(a.year));
    final featured = hero.first;
    final popular = List<Movie>.of(movies);
    final recommended = List<Movie>.of(movies)
      ..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    final saved = movies.where((movie) => myList.contains(movie.id)).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, topInset, 16, 0),
            child: _Hero(movie: featured),
          ),
        ),
        SliverToBoxAdapter(
          child: _MovieRow(
            title: 'Populer di Kayflix',
            movies: popular,
            myList: myList,
          ),
        ),
        SliverToBoxAdapter(
          child: _MovieRow(
            title: 'Rekomendasi untuk Kamu',
            movies: recommended,
            myList: myList,
          ),
        ),
        SliverToBoxAdapter(
          child: _MovieRow(
            title: 'Daftar Saya',
            movies: saved,
            myList: myList,
            emptyHint: 'Simpan film untuk menontonnya nanti.',
          ),
        ),
        SliverToBoxAdapter(
          child: _ContinueRow(movies: movies),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final meta = [
      movie.yearLabel,
      movie.duration,
      movie.rating,
      if (movie.genreList.isNotEmpty) movie.genreList.first,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 310,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.posterGradientFor(movie.id),
              ),
            ),
            Positioned(
              top: -50,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
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
                  colors: [Colors.transparent, Color(0xF2000000)],
                  stops: [0.25, 1],
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xB3000000), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BARU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Baru Ditambahkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -0.6,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${movie.matchPercent}% Match',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      for (final item in meta)
                        Text(
                          item,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: () =>
                              context.push('/movie/${movie.id}/play'),
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: const Text('Mainkan'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 44,
                        child: TextButton.icon(
                          onPressed: () =>
                              context.push('/movie/${movie.id}'),
                          icon: const Icon(Icons.info_outline, size: 19),
                          label: const Text('Info'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.18),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieRow extends StatelessWidget {
  const _MovieRow({
    required this.title,
    required this.movies,
    required this.myList,
    this.emptyHint,
  });

  final String title;
  final List<Movie> movies;
  final Set<int> myList;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: 112,
          child: movies.isEmpty
              ? ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _AddCard(hint: emptyHint ?? 'Belum ada judul.'),
                  ],
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: movies.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return MovieCard(
                      movie: movie,
                      inList: myList.contains(movie.id),
                      onTap: () => context.push('/movie/${movie.id}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/search'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 196,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline,
                color: AppColors.textSecondary, size: 26),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                hint,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A lightweight "Continue watching" row, since the backend keeps no history.
/// It simply surfaces the newest titles.
class _ContinueRow extends StatelessWidget {
  const _ContinueRow({required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    final latest = List<Movie>.of(movies)
      ..sort((a, b) => b.year.compareTo(a.year));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Rilis Terbaru'),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: latest.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final movie = latest[index];
              return MovieCard(
                movie: movie,
                onTap: () => context.push('/movie/${movie.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Makes an error/empty view fill the viewport while staying pull-to-refresh
/// scrollable.
class _FillScroll extends StatelessWidget {
  const _FillScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: child,
            ),
          ],
        );
      },
    );
  }
}
