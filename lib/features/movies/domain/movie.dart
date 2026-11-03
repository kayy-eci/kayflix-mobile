/// A movie row as returned by `GET /api/movies`.
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.rating,
    required this.duration,
    required this.genres,
  });

  final int id;
  final String title;
  final int year;
  final String rating;
  final String duration;
  final String genres;

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Tanpa Judul',
      year: (json['year'] as num?)?.toInt() ?? 0,
      rating: json['rating']?.toString() ?? '-',
      duration: json['duration']?.toString() ?? '-',
      genres: json['genres']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'title': title,
      'year': year,
      'rating': rating,
      'duration': duration,
      'genres': genres,
    };
  }

  List<String> get genreList => genres
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  String get yearLabel => year > 0 ? '$year' : '-';

  /// The backend does not compute a match score, so we derive a stable one
  /// from the movie id. It keeps the Netflix card look without fake randomness.
  int get matchPercent => 80 + ((id * 7) % 19);

  bool sharesGenreWith(Movie other) {
    final mine = genreList.map((e) => e.toLowerCase()).toSet();
    return other.genreList
        .map((e) => e.toLowerCase())
        .any((genre) => mine.contains(genre));
  }
}
