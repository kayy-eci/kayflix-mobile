import '../../../core/network/api_client.dart';
import '../domain/movie.dart';

class MovieRepository {
  MovieRepository(this._api);

  final ApiClient _api;

  Future<List<Movie>> fetchAll() async {
    final response = await _api.get('/api/movies');
    final data = response['data'];

    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map((item) => Movie.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<void> create(Movie movie) async {
    await _api.post('/api/movies', data: movie.toRequestJson());
  }

  Future<void> update(int id, Movie movie) async {
    await _api.put('/api/movies/$id', data: movie.toRequestJson());
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/movies/$id');
  }
}
