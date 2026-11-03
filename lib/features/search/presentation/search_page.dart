import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/movie_grid.dart';
import '../../../core/widgets/state_views.dart';
import '../../movies/domain/movie.dart';
import '../../movies/presentation/movie_providers.dart';
import '../../my_list/presentation/my_list_controller.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(String value) {
    setState(() => _query = value.trim().toLowerCase());
  }

  List<Movie> _filter(List<Movie> movies) {
    if (_query.isEmpty) return movies;
    return movies.where((movie) {
      return movie.title.toLowerCase().contains(_query) ||
          movie.genres.toLowerCase().contains(_query) ||
          movie.yearLabel.contains(_query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(moviesProvider);
    final myList = ref.watch(myListProvider).value ?? const <int>{};
    final genres = ref.watch(genresProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _update,
          style: const TextStyle(color: Colors.white, fontSize: 15.5),
          cursorColor: AppColors.red,
          decoration: InputDecoration(
            filled: false,
            hintText: 'Cari judul, genre, atau tahun',
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14.5,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      _controller.clear();
                      _update('');
                    },
                  ),
          ),
        ),
      ),
      body: moviesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(
          message: error is Exception
              ? error.toString().replaceFirst('ApiException: ', '')
              : 'Gagal memuat katalog.',
          onRetry: () => ref.invalidate(moviesProvider),
        ),
        data: (movies) {
          final results = _filter(movies);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_query.isEmpty && genres.isNotEmpty)
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: genres.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final genre = genres[index];
                      return ActionChip(
                        label: Text(genre),
                        onPressed: () {
                          _controller.text = genre;
                          _update(genre);
                        },
                        backgroundColor: AppColors.card,
                        side: const BorderSide(color: AppColors.border),
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                child: Text(
                  _query.isEmpty
                      ? 'Semua judul (${results.length})'
                      : '${results.length} hasil untuk "$_query"',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.search_off,
                        title: 'Tidak ditemukan',
                        message:
                            'Coba kata kunci lain, atau telusuri lewat genre.',
                      )
                    : MovieGrid(
                        movies: results,
                        inList: myList,
                        onTap: (movie) =>
                            context.push('/movie/${movie.id}'),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
