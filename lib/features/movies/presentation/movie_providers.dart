import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/presentation/session_controller.dart';
import '../data/movie_repository.dart';
import '../domain/movie.dart';

final movieRepositoryProvider = Provider<MovieRepository>(
  (ref) => MovieRepository(ref.watch(apiClientProvider)),
);

/// The whole catalogue. The backend has no pagination or filters yet, so we
/// fetch once and derive every screen from this list.
final moviesProvider = FutureProvider<List<Movie>>(
  (ref) => ref.watch(movieRepositoryProvider).fetchAll(),
);

final movieByIdProvider = Provider.family<Movie?, int>((ref, id) {
  final movies = ref.watch(moviesProvider).value;
  if (movies == null) return null;
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
});

final similarMoviesProvider = Provider.family<List<Movie>, Movie>((ref, movie) {
  final movies = ref.watch(moviesProvider).value ?? const <Movie>[];
  return movies
      .where((candidate) =>
          candidate.id != movie.id && candidate.sharesGenreWith(movie))
      .take(10)
      .toList(growable: false);
});

final genresProvider = Provider<List<String>>((ref) {
  final movies = ref.watch(moviesProvider).value ?? const <Movie>[];
  final genres = <String>{};
  for (final movie in movies) {
    genres.addAll(movie.genreList);
  }
  final sorted = genres.toList()..sort();
  return sorted;
});
